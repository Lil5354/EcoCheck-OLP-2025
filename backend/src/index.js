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

// Realtime mock endpoints for demo UI
const randomInRange = (min, max) => Math.random() * (max - min) + min;
const TYPES = ['household', 'recyclable', 'bulky'];
const LEVELS = ['low', 'medium', 'high'];

app.get('/api/rt/checkins', (req, res) => {
  // Generate a handful of random check-ins around HCMC
  const center = { lat: 10.78, lon: 106.70 };
  const n = Number(req.query.n || 30);
  const points = Array.from({ length: n }).map(() => {
    const type = TYPES[Math.floor(Math.random() * TYPES.length)];
    const level = LEVELS[Math.floor(Math.random() * LEVELS.length)];
    const lat = center.lat + randomInRange(-0.08, 0.08);
    const lon = center.lon + randomInRange(-0.08, 0.08);
    return { id: `${Date.now()}-${Math.random().toString(36).slice(2,6)}`, type, level, lat, lon, ts: Date.now() };
  });
  res.json({ ok: true, data: points });
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

// Alerts endpoint
app.get('/api/rt/alerts', (req, res) => {
  const now = Date.now();
  const alerts = Array.from({ length: 8 }).map((_, i) => ({
    id: `A${i + 1}`,
    time: new Date(now - i * 600000).toLocaleTimeString(),
    point: `P${20 + i}`,
    vehicle: ['V01', 'V02', 'V03'][i % 3],
    level: ['warning', 'critical'][i % 2],
    status: ['open', 'ack'][i % 2]
  }));
  res.json({ ok: true, data: alerts });
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
