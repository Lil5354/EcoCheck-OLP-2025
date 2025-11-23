/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck Backend - FIWARE-based Environmental Monitoring System
 * Main application entry point
 */

const express = require('express');
const cors = require('cors');
const compression = require('compression');
const dotenv = require('dotenv');
const cron = require('node-cron');
const http = require('http');

// Load environment variables
dotenv.config();

const app = express();
const server = http.createServer(app);
const io = require('socket.io')(server, { cors: { origin: '*'} })
const PORT = process.env.PORT || 3000;
// Performance middleware
app.use(compression());

// Realtime store (mock for dev)
const { store } = require('./realtime');


// Database Connection
const { Pool } = require('pg');
const db = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://ecocheck_user:ecocheck_pass@localhost:5432/ecocheck',
});
db.on('connect', () => console.log('🐘 Connected to PostgreSQL database'));

// --- Utility Functions ---
function getHaversineDistance(coords1, coords2) {
  const toRad = (x) => (x * Math.PI) / 180;
  const R = 6371e3; // Earth radius in metres

  const dLat = toRad(coords2.lat - coords1.lat);
  const dLon = toRad(coords2.lon - coords1.lon);
  const lat1 = toRad(coords1.lat);
  const lat2 = toRad(coords2.lat);

  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
          Math.sin(dLon / 2) * Math.sin(dLon / 2) * Math.cos(lat1) * Math.cos(lat2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c; // in metres
}


// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Static serve for NGSI-LD contexts
const path = require('path');
app.use('/contexts', express.static(path.join(__dirname, '..', 'public', 'contexts')));

// FIWARE notification endpoint (Orion-LD Subscriptions)
app.post('/fiware/notify', (req, res) => {
  try {
    console.log('[FIWARE][Notify]', JSON.stringify(req.body));
  } catch (e) {
    console.log('[FIWARE][Notify] Received notification');
  }
  return res.status(204).send();
});


// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    service: 'EcoCheck Backend',
    version: '1.0.0'
  });
});

// API Routes
app.get('/api/status', (req, res) => {
  res.json({
    message: 'EcoCheck Backend is running',
    fiware_status: 'Connected', // TODO: Implement actual FIWARE connection check
    timestamp: new Date().toISOString()
  });
});

// FIWARE Context Broker integration endpoints
// Proxy Orion-LD version for frontend (avoids CORS and cross-network issues)
app.get('/api/fiware/version', async (req, res) => {
  try {
    const orionUrl = process.env.ORION_LD_URL || 'http://localhost:1026';
    const response = await require('axios').get(`${orionUrl}/version`, { timeout: 4000 });
    res.json({ ok: true, data: response.data });
  } catch (e) {
    res.status(503).json({ ok: false, error: e.message });
  }
});

app.get('/api/entities', async (req, res) => {
  // TODO: Implement FIWARE Orion Context Broker integration
  res.json({
    message: 'FIWARE entities endpoint - To be implemented',
    entities: []
  });
});

app.post('/api/entities', async (req, res) => {
  // TODO: Implement entity creation in FIWARE
  res.json({
    message: 'Entity creation endpoint - To be implemented',
    data: req.body
  });
});

// Environmental data endpoints
app.get('/api/environmental-data', (req, res) => {
  // TODO: Implement environmental data retrieval
  res.json({
    message: 'Environmental data endpoint - To be implemented',
    data: []
  });
});

// Waste collection routes optimization
app.post('/api/optimize-routes', (req, res) => {
  // TODO: Implement routing optimization algorithm
  res.json({
    message: 'Route optimization endpoint - To be implemented',
    optimized_routes: []
  });
});

// CN7: Check-in endpoint with late detection
app.post('/api/rt/checkin', async (req, res) => {
  const { route_id, point_id, vehicle_id } = req.body;

  if (!route_id || !point_id || !vehicle_id) {
    return res.status(400).json({ ok: false, error: 'Missing route_id, point_id, or vehicle_id' });
  }

  const result = store.recordCheckin(route_id, point_id);

  // CN7: Check if this check-in resolves any open/acknowledged alerts for this point
  try {
    const { rows: openAlerts } = await db.query(
      `SELECT alert_id, alert_type, status
       FROM alerts
       WHERE point_id = $1 AND status IN ('open', 'acknowledged')`,
      [point_id]
    );

    if (openAlerts.length > 0) {
      // Resolve all open/acknowledged alerts for this point
      await db.query(
        `UPDATE alerts
         SET status = 'resolved',
             details = jsonb_set(
               COALESCE(details, '{}'::jsonb),
               '{resolved_at}',
               to_jsonb($1::text)
             ) || jsonb_build_object(
               'resolved_by_vehicle', $2,
               'resolved_by_route', $3
             )
         WHERE point_id = $4 AND status IN ('open', 'acknowledged')`,
        [new Date().toISOString(), vehicle_id, route_id, point_id]
      );

      // Update route_stops status to 'completed' for this point on this route
      await db.query(
        `UPDATE route_stops
         SET status = 'completed',
             actual_at = $1,
             actual_arrival_at = $1
         WHERE route_id = $2 AND point_id = $3 AND status = 'pending'`,
        [new Date(), route_id, point_id]
      );

      console.log(`✅ Resolved ${openAlerts.length} alert(s) for point ${point_id}`);
    }
  } catch (err) {
    console.error('Error resolving alerts on check-in:', err);
    // Don't fail the check-in if alert resolution fails
  }

  if (result.status === 'late_checkin') {
    try {
      const { rows } = await db.query(
        'SELECT 1 FROM alerts WHERE route_id = $1 AND point_id = $2 AND status = $3 AND alert_type = $4 LIMIT 1',
        [route_id, point_id, 'open', 'late_checkin']
      );

      if (rows.length === 0) {
        console.log(`🚨 LATE CHECK-IN DETECTED! Route: ${route_id}, Point: ${point_id}`);
        // Use NULL for route_id if not a valid UUID to satisfy FK constraint
        const routeIdForInsert = (typeof route_id === 'string' && /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/.test(route_id)) ? route_id : null;
        await db.query(
          `INSERT INTO alerts (alert_type, point_id, vehicle_id, route_id, severity, status, details)
           VALUES ($1, $2, $3, $4, $5, $6, $7)`,
          [
            'late_checkin',
            point_id,
            vehicle_id,
            routeIdForInsert,
            'warning', // Late check-ins are warnings
            'open',
            JSON.stringify({ detected_at: new Date().toISOString() })
          ]
        );
      }
      return res.status(200).json({ ok: true, status: 'late_checkin_recorded' });

    } catch (err) {
      console.error('Error creating late check-in alert:', err);
      return res.status(500).json({ ok: false, error: 'Failed to record late check-in alert' });
    }
  }

  res.json({ ok: true, ...result });
});

// Realtime mock endpoints for demo UI
const randomInRange = (min, max) => Math.random() * (max - min) + min;
const TYPES = ['household', 'recyclable', 'bulky'];
const LEVELS = ['low', 'medium', 'high'];

app.get('/api/rt/checkins', (req, res) => {
  // Generate random check-ins around HCMC with CN5-compliant status mapping
  const center = { lat: 10.78, lon: 106.70 };
  const n = Number(req.query.n || 30);
  const points = Array.from({ length: n }).map(() => {
    const isGhost = Math.random() < 0.12; // ~12% ghost (no trash)
    const type = isGhost ? 'ghost' : TYPES[Math.floor(Math.random() * TYPES.length)];
    const level = isGhost ? 'none' : LEVELS[Math.floor(Math.random() * LEVELS.length)];
    const lat = center.lat + randomInRange(-0.08, 0.08);
    const lon = center.lon + randomInRange(-0.08, 0.08);
    // Occasionally mark as incident (bulky or issue)
    const incident = !isGhost && Math.random() < 0.05;
    return { id: `${Date.now()}-${Math.random().toString(36).slice(2,6)}`, type, level, incident, lat, lon, ts: Date.now() };
  });
  res.set('Cache-Control','no-store').json({ ok: true, data: points });
});

// Realtime endpoints (viewport + delta)
app.get('/api/rt/points', (req, res) => {
  const bbox = (req.query.bbox||'').split(',').map(parseFloat)
  const since = req.query.since ? Number(req.query.since) : undefined
  const data = store.getPoints({ bbox: bbox.length===4?bbox:undefined, since })
  res.set('Cache-Control','no-store').json({ ok:true, ...data })
})

app.get('/api/rt/vehicles', (req, res) => {
  res.set('Cache-Control','no-store').json({ ok:true, data: store.getVehicles(), serverTime: Date.now() })
})




// Socket.IO for fleet broadcast
io.on('connection', (socket) => {
  socket.emit('fleet:init', store.getVehicles())
})
setInterval(()=>{
  store.tickVehicles()
  io.emit('fleet', store.getVehicles())
}, 1000)

app.get('/api/analytics/summary', (req, res) => {
  res.json({ ok: true, routesActive: 12, collectionRate: 0.85, todayTons: 3.2 });
});

// Master data endpoints
app.get('/api/master/fleet', (req, res) => {
  const mockFleet = [
    { id: 'V01', plate: '51A-123.45', type: 'compactor', capacity: 3000, types: ['household'], status: 'ready' },
    { id: 'V02', plate: '51B-678.90', type: 'mini-truck', capacity: 1200, types: ['recyclable'], status: 'ready' },
    { id: 'V03', plate: '51C-246.80', type: 'electric-trike', capacity: 300, types: ['household','recyclable'], status: 'maintenance' },
  ];
  res.json({ ok: true, data: mockFleet });
});

app.post('/api/master/fleet', (req, res) => {
  res.json({ ok: true, data: { id: 'V' + Date.now(), ...req.body } });
});

app.patch('/api/master/fleet/:id', (req, res) => {
  res.json({ ok: true, data: { id: req.params.id, ...req.body } });
});

app.delete('/api/master/fleet/:id', (req, res) => {
  res.json({ ok: true, message: 'Vehicle deleted' });
});

// Collection points endpoint
app.get('/api/points', (req, res) => {
  const center = { lat: 10.78, lon: 106.70 };
  const n = 120;
  const points = Array.from({ length: n }).map((_, i) => {
    const type = TYPES[Math.floor(Math.random() * TYPES.length)];
    const lat = center.lat + randomInRange(-0.08, 0.08);
    const lon = center.lon + randomInRange(-0.08, 0.08);
    const demand = Math.floor(randomInRange(20, 120));
    const status = Math.random() < 0.1 ? 'grey' : 'active';
    return { id: `P${i+1}`, type, lat, lon, demand, status };
  });
  res.json({ ok: true, data: points });
});

// VRP optimization endpoint
app.post('/api/vrp/optimize', (req, res) => {
  const { vehicles = [], points = [] } = req.body;
  const routes = vehicles.map((v, idx) => ({
    vehicleId: v.id,
    distance: Math.round(8000 + Math.random() * 9000),
    eta: `${1 + idx}:2${idx}`,
    geojson: {
      type: 'FeatureCollection',
      features: [
        {
          type: 'Feature',
          geometry: {
            type: 'LineString',
            coordinates: points.slice(idx, points.length).map(p => [p.lon, p.lat])
          },
          properties: {}
        }
      ]
    },
    stops: points.map((p, i) => ({ id: p.id, seq: i + 1 }))
  }));
  res.json({ ok: true, data: { routes } });
});

// Dispatch endpoints
app.post('/api/dispatch/send-routes', (req, res) => {
  res.json({ ok: true, data: { message: 'Routes dispatched' } });
});

app.post('/api/dispatch/reroute', (req, res) => {
  res.json({ ok: true, data: { message: 'Re-route created', routeId: `R${Math.floor(Math.random() * 1000)}` } });
});

// --- CN7: Alerts API ---
app.get('/api/alerts', async (req, res) => {
  try {
    const { rows } = await db.query(
      `SELECT
         a.alert_id, a.alert_type, a.severity, a.status, a.created_at,
         a.point_id, NULL::text as point_name,
         a.vehicle_id, v.plate as license_plate,
         a.route_id
       FROM alerts a
       LEFT JOIN vehicles v ON a.vehicle_id = v.id
       ORDER BY a.created_at DESC
       LIMIT 50`
    );
    res.json({ ok: true, data: rows });
  } catch (err) {
    console.error('Error fetching alerts:', err);
    res.status(500).json({ ok: false, error: 'Failed to fetch alerts' });
  }
});

app.post('/api/alerts/:alertId/dispatch', async (req, res) => {
  const { alertId } = req.params;

  try {
    // 1. Get the alert details to find the missed point's location
    // Fixed: Use correct table name 'points' and extract lat/lon from geography type
    const alertResult = await db.query(
      `SELECT
         a.alert_id,
         a.point_id,
         ST_Y(p.geom::geometry) as lat,
         ST_X(p.geom::geometry) as lon
       FROM alerts a
       JOIN points p ON a.point_id = p.id
       WHERE a.alert_id = $1`,
      [alertId]
    );

    if (alertResult.rows.length === 0) {
      return res.status(404).json({ ok: false, error: 'Alert or associated point not found' });
    }
    const alertData = alertResult.rows[0];

    // 2. Get all currently active vehicles from the in-memory store
    const activeVehicles = store.getVehicles();

    if (activeVehicles.length === 0) {
      return res.json({ ok: true, data: [], message: 'No active vehicles available' });
    }

    // 3. Calculate the distance to the missed point for each vehicle
    const vehiclesWithDistance = activeVehicles.map(v => ({
      ...v,
      distance: getHaversineDistance(
        { lat: alertData.lat, lon: alertData.lon },
        { lat: v.lat, lon: v.lon }
      )
    }));

    // 4. Sort by distance and take the top 3
    const suggestedVehicles = vehiclesWithDistance
      .sort((a, b) => a.distance - b.distance)
      .slice(0, 3);

    res.json({ ok: true, data: suggestedVehicles });

  } catch (err) {
    console.error(`Error processing dispatch for alert ${alertId}:`, err);
    res.status(500).json({ ok: false, error: 'Failed to process dispatch request' });
  }
});

// CN7: Assign vehicle to alert and create re-route
app.post('/api/alerts/:alertId/assign', async (req, res) => {
  const { alertId } = req.params;
  const { vehicle_id } = req.body;

  if (!vehicle_id) {
    return res.status(400).json({ ok: false, error: 'Missing vehicle_id in request body' });
  }

  try {
    // 1. Get alert and point details
    const alertResult = await db.query(
      `SELECT
         a.alert_id,
         a.alert_type,
         a.point_id,
         a.route_id as original_route_id,
         ST_Y(p.geom::geometry) as lat,
         ST_X(p.geom::geometry) as lon
       FROM alerts a
       JOIN points p ON a.point_id = p.id
       WHERE a.alert_id = $1 AND a.status = 'open'`,
      [alertId]
    );

    if (alertResult.rows.length === 0) {
      return res.status(404).json({ ok: false, error: 'Alert not found or already processed' });
    }

    const alert = alertResult.rows[0];

    // 2. Create a new route in the database for the re-routing
    const { v4: uuidv4 } = require('uuid');
    const newRouteId = uuidv4();
    const now = new Date();

    await db.query(
      `INSERT INTO routes (id, vehicle_id, start_at, status, meta)
       VALUES ($1, $2, $3, $4, $5)`,
      [
        newRouteId,
        vehicle_id,
        now,
        'in_progress',
        JSON.stringify({
          type: 'incident_response',
          original_alert_id: alertId,
          original_route_id: alert.original_route_id,
          created_by: 'dynamic_dispatch'
        })
      ]
    );

    // 3. Add the incident point as a route stop
    const stopId = uuidv4();
    await db.query(
      `INSERT INTO route_stops (id, route_id, point_id, seq, status, planned_eta)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [stopId, newRouteId, alert.point_id, 1, 'pending', now]
    );

    // 4. Update alert status to 'acknowledged'
    await db.query(
      `UPDATE alerts
       SET status = 'acknowledged',
           details = jsonb_set(
             COALESCE(details, '{}'::jsonb),
             '{assigned_vehicle_id}',
             to_jsonb($1::text)
           ) || jsonb_build_object(
             'assigned_at', $2,
             'new_route_id', $3
           )
       WHERE alert_id = $4`,
      [vehicle_id, now.toISOString(), newRouteId, alertId]
    );

    // 5. Start the route in the in-memory store
    store.startRoute(newRouteId, vehicle_id, [
      {
        point_id: alert.point_id,
        lat: alert.lat,
        lon: alert.lon
      }
    ]);

    console.log(`✅ Alert ${alertId} assigned to vehicle ${vehicle_id}, new route ${newRouteId} created`);

    res.json({
      ok: true,
      data: {
        message: 'Vehicle assigned successfully',
        route_id: newRouteId,
        vehicle_id: vehicle_id,
        alert_id: alertId
      }
    });

  } catch (err) {
    console.error(`Error assigning vehicle to alert ${alertId}:`, err);
    res.status(500).json({ ok: false, error: 'Failed to assign vehicle' });
  }
});


// Analytics endpoints
app.get('/api/analytics/timeseries', (req, res) => {
  const now = Date.now();
  const series = Array.from({ length: 24 }).map((_, i) => ({
    t: new Date(now - (23 - i) * 3600e3).toISOString(),
    value: Math.round(60 + 30 * Math.sin(i / 4) + Math.random() * 10)
  }));

  // Mock data for waste by type (donut chart)
  const byType = {
    household: Math.round(40 + Math.random() * 20),
    recyclable: Math.round(25 + Math.random() * 15),
    bulky: Math.round(15 + Math.random() * 10)
  };

  res.json({ ok: true, series, byType, data: series }); // Keep 'data' for backward compatibility
});

app.get('/api/analytics/predict', (req, res) => {
  const days = Number(req.query.days || 7);
  const today = new Date();
  const actual = Array.from({ length: days }).map((_, i) => ({
    d: new Date(today.getFullYear(), today.getMonth(), today.getDate() - days + i).toISOString().slice(0, 10),
    v: Math.round(50 + Math.random() * 10)
  }));
  const forecast = Array.from({ length: days }).map((_, i) => ({
    d: new Date(today.getFullYear(), today.getMonth(), today.getDate() + i).toISOString().slice(0, 10),
    v: Math.round(55 + Math.random() * 12)
  }));
  res.json({ ok: true, data: { actual, forecast } });
});

// Exceptions endpoint

// --- CN7: Dynamic Dispatch - Incident Detection ---
const MISSED_POINT_DISTANCE_THRESHOLD = 500; // meters

cron.schedule('*/15 * * * * *', async () => {
  console.log('🛰️  Running Missed Point Detection...');
  const activeRoutes = store.getActiveRoutes();

  for (const route of activeRoutes) {
    if (route.status !== 'inprogress') continue;

    const vehicle = store.getVehicle(route.vehicle_id);
    if (!vehicle) continue;

    for (const point of route.points.values()) {
      if (point.checked) continue;

      const distance = getHaversineDistance(
        { lat: vehicle.lat, lon: vehicle.lon },
        { lat: point.lat, lon: point.lon }
      );

      // Basic check: if vehicle is far past the point, it's likely missed.
      // A more advanced implementation would check if the point is 'behind' the vehicle's direction of travel.
      if (distance > MISSED_POINT_DISTANCE_THRESHOLD) {
        try {
          // Check if an open alert for this point on this route already exists
          const { rows } = await db.query(
            'SELECT 1 FROM alerts WHERE route_id = $1 AND point_id = $2 AND status = $3 LIMIT 1',
            [route.route_id, point.point_id, 'open']
          );

          if (rows.length === 0) {
            console.log(`🚨 MISSED POINT DETECTED! Route: ${route.route_id}, Point: ${point.point_id}`);
            // Create a new alert in the database
            // Ensure FK safety: if route_id is not a UUID, store NULL; vehicle_id may not exist in DB (mock IDs), also store NULL
            const routeIdForInsert = (typeof route.route_id === 'string' && /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/.test(route.route_id)) ? route.route_id : null;
            const vehicleIdForInsert = null;
            await db.query(
              `INSERT INTO alerts (alert_type, point_id, vehicle_id, route_id, severity, status, details)
               VALUES ($1, $2, $3, $4, $5, $6, $7)`,
              [
                'missed_point',
                point.point_id,
                vehicleIdForInsert,
                routeIdForInsert,
                'critical', // Missed points are considered critical
                'open',
                JSON.stringify({ detected_at: new Date().toISOString(), vehicle_location: { lat: vehicle.lat, lon: vehicle.lon } })
              ]
            );
          }
        } catch (err) {
          console.error('Error creating missed point alert:', err);
        }
      }
    }
  }
});

// --- Testing Endpoints (CN7) ---
// Start a mock route so the cron can detect missed points
app.post('/api/test/start-route', async (req, res) => {
  try {
    const { route_id = 1, vehicle_id = 'V01' } = req.body || {};
    // Take first 5 points from the in-memory store
    const points = Array.from(store.points.values()).slice(0, 5).map(p => ({
      point_id: p.id,
      lat: p.lat,
      lon: p.lon,
    }));

    if (points.length === 0) {
      return res.status(500).json({ ok: false, error: 'No points available in store' });
    }

    store.startRoute(route_id, vehicle_id, points);
    return res.json({ ok: true, message: `Test route ${route_id} started for vehicle ${vehicle_id}`, points: points.map(p=>p.point_id) });
  } catch (err) {
    console.error('Error starting test route:', err);
    return res.status(500).json({ ok: false, error: 'Failed to start test route' });
  }
});


app.get('/api/exceptions', (req, res) => {
  const exceptions = Array.from({ length: 12 }).map((_, i) => ({
    id: `E${i + 1}`,
    time: new Date(Date.now() - i * 5e5).toLocaleString(),
    location: `10.${78 + i}, 106.${70 + i}`,
    type: ['oversize', 'blocked', 'other'][i % 3],
    status: ['pending', 'approved', 'rejected'][i % 3]
  }));
  res.json({ ok: true, data: exceptions });
});

app.post('/api/exceptions/:id/approve', (req, res) => {
  res.json({ ok: true, data: { message: 'Approved' } });
});

app.post('/api/exceptions/:id/reject', (req, res) => {
  res.json({ ok: true, data: { message: 'Rejected' } });
});

// Scheduled tasks for data collection
cron.schedule('*/5 * * * *', () => {
  console.log('Running scheduled environmental data collection...');
  // TODO: Implement scheduled data collection from sensors
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Route ${req.originalUrl} not found`
  });
});

// Start server (HTTP + Socket.IO)
server.listen(PORT, () => {
  console.log(`🚀 EcoCheck Backend started on port ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
});

module.exports = app;
