/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck Backend - FIWARE-based Environmental Monitoring System
 * Main application entry point
 */

const express = require("express");
const cors = require("cors");
const compression = require("compression");
const dotenv = require("dotenv");
const cron = require("node-cron");
const http = require("http");

// Load environment variables
dotenv.config();

const app = express();
const server = http.createServer(app);
const io = require("socket.io")(server, { cors: { origin: "*" } });
const PORT = process.env.PORT || 3000;
// Performance middleware
app.use(compression());

// Realtime store (mock for dev)
const { store } = require("./realtime");

// Database Connection
const { Pool } = require("pg");
const db = new Pool({
  connectionString:
    process.env.DATABASE_URL ||
    "postgresql://ecocheck_user:ecocheck_pass@localhost:5432/ecocheck",
});
db.on("connect", () => console.log("🐘 Connected to PostgreSQL database"));

// --- Utility Functions ---
function getHaversineDistance(coords1, coords2) {
  const toRad = (x) => (x * Math.PI) / 180;
  const R = 6371e3; // Earth radius in metres

  const dLat = toRad(coords2.lat - coords1.lat);
  const dLon = toRad(coords2.lon - coords1.lon);
  const lat1 = toRad(coords1.lat);
  const lat2 = toRad(coords2.lat);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.sin(dLon / 2) * Math.sin(dLon / 2) * Math.cos(lat1) * Math.cos(lat2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c; // in metres
}

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Static serve for NGSI-LD contexts
const path = require("path");
app.use(
  "/contexts",
  express.static(path.join(__dirname, "..", "public", "contexts"))
);

// FIWARE notification endpoint (Orion-LD Subscriptions)
app.post("/fiware/notify", (req, res) => {
  try {
    console.log("[FIWARE][Notify]", JSON.stringify(req.body));
  } catch (e) {
    console.log("[FIWARE][Notify] Received notification");
  }
  return res.status(204).send();
});

// Health check endpoint
app.get("/health", (req, res) => {
  res.status(200).json({
    status: "OK",
    timestamp: new Date().toISOString(),
    service: "EcoCheck Backend",
    version: "1.0.0",
  });
});

// API Routes
app.get("/api/status", (req, res) => {
  res.json({
    message: "EcoCheck Backend is running",
    fiware_status: "Connected", // TODO: Implement actual FIWARE connection check
    timestamp: new Date().toISOString(),
  });
});

// FIWARE Context Broker integration endpoints
// Proxy Orion-LD version for frontend (avoids CORS and cross-network issues)
app.get("/api/fiware/version", async (req, res) => {
  try {
    const orionUrl = process.env.ORION_LD_URL || "http://localhost:1026";
    const response = await require("axios").get(`${orionUrl}/version`, {
      timeout: 4000,
    });
    res.json({ ok: true, data: response.data });
  } catch (e) {
    res.status(503).json({ ok: false, error: e.message });
  }
});

app.get("/api/entities", async (req, res) => {
  // TODO: Implement FIWARE Orion Context Broker integration
  res.json({
    message: "FIWARE entities endpoint - To be implemented",
    entities: [],
  });
});

app.post("/api/entities", async (req, res) => {
  // TODO: Implement entity creation in FIWARE
  res.json({
    message: "Entity creation endpoint - To be implemented",
    data: req.body,
  });
});

// Environmental data endpoints
app.get("/api/environmental-data", (req, res) => {
  // TODO: Implement environmental data retrieval
  res.json({
    message: "Environmental data endpoint - To be implemented",
    data: [],
  });
});

// Waste collection routes optimization
app.post("/api/optimize-routes", (req, res) => {
  // TODO: Implement routing optimization algorithm
  res.json({
    message: "Route optimization endpoint - To be implemented",
    optimized_routes: [],
  });
});

// CN7: Check-in endpoint with late detection
app.post("/api/rt/checkin", async (req, res) => {
  const { route_id, point_id, vehicle_id } = req.body;

  if (!route_id || !point_id || !vehicle_id) {
    return res
      .status(400)
      .json({ ok: false, error: "Missing route_id, point_id, or vehicle_id" });
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

      console.log(
        `✅ Resolved ${openAlerts.length} alert(s) for point ${point_id}`
      );
    }
  } catch (err) {
    console.error("Error resolving alerts on check-in:", err);
    // Don't fail the check-in if alert resolution fails
  }

  if (result.status === "late_checkin") {
    try {
      const { rows } = await db.query(
        "SELECT 1 FROM alerts WHERE route_id = $1 AND point_id = $2 AND status = $3 AND alert_type = $4 LIMIT 1",
        [route_id, point_id, "open", "late_checkin"]
      );

      if (rows.length === 0) {
        console.log(
          `🚨 LATE CHECK-IN DETECTED! Route: ${route_id}, Point: ${point_id}`
        );
        // Use NULL for route_id if not a valid UUID to satisfy FK constraint
        const routeIdForInsert =
          typeof route_id === "string" &&
          /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/.test(
            route_id
          )
            ? route_id
            : null;
        await db.query(
          `INSERT INTO alerts (alert_type, point_id, vehicle_id, route_id, severity, status, details)
           VALUES ($1, $2, $3, $4, $5, $6, $7)`,
          [
            "late_checkin",
            point_id,
            vehicle_id,
            routeIdForInsert,
            "warning", // Late check-ins are warnings
            "open",
            JSON.stringify({ detected_at: new Date().toISOString() }),
          ]
        );
      }
      return res
        .status(200)
        .json({ ok: true, status: "late_checkin_recorded" });
    } catch (err) {
      console.error("Error creating late check-in alert:", err);
      return res
        .status(500)
        .json({ ok: false, error: "Failed to record late check-in alert" });
    }
  }

  res.json({ ok: true, ...result });
});

// Realtime mock endpoints for demo UI
const randomInRange = (min, max) => Math.random() * (max - min) + min;
const TYPES = ["household", "recyclable", "bulky"];
const LEVELS = ["low", "medium", "high"];

app.get("/api/rt/checkins", (req, res) => {
  // Generate random check-ins around HCMC with CN5-compliant status mapping
  const center = { lat: 10.78, lon: 106.7 };
  const n = Number(req.query.n || 30);
  const points = Array.from({ length: n }).map(() => {
    const isGhost = Math.random() < 0.12; // ~12% ghost (no trash)
    const type = isGhost
      ? "ghost"
      : TYPES[Math.floor(Math.random() * TYPES.length)];
    const level = isGhost
      ? "none"
      : LEVELS[Math.floor(Math.random() * LEVELS.length)];
    const lat = center.lat + randomInRange(-0.08, 0.08);
    const lon = center.lon + randomInRange(-0.08, 0.08);
    // Occasionally mark as incident (bulky or issue)
    const incident = !isGhost && Math.random() < 0.05;
    return {
      id: `${Date.now()}-${Math.random().toString(36).slice(2, 6)}`,
      type,
      level,
      incident,
      lat,
      lon,
      ts: Date.now(),
    };
  });
  res.set("Cache-Control", "no-store").json({ ok: true, data: points });
});

// Realtime endpoints (viewport + delta)
app.get("/api/rt/points", (req, res) => {
  const bbox = (req.query.bbox || "").split(",").map(parseFloat);
  const since = req.query.since ? Number(req.query.since) : undefined;
  const data = store.getPoints({
    bbox: bbox.length === 4 ? bbox : undefined,
    since,
  });
  res.set("Cache-Control", "no-store").json({ ok: true, ...data });
});

app.get("/api/rt/vehicles", (req, res) => {
  res
    .set("Cache-Control", "no-store")
    .json({ ok: true, data: store.getVehicles(), serverTime: Date.now() });
});

// Socket.IO for fleet broadcast
io.on("connection", (socket) => {
  socket.emit("fleet:init", store.getVehicles());
});
setInterval(() => {
  store.tickVehicles();
  io.emit("fleet", store.getVehicles());
}, 1000);

app.get("/api/analytics/summary", (req, res) => {
  res.json({
    ok: true,
    data: {
      routesActive: 12,
      collectionRate: 0.85,
      todayTons: 3.2,
      totalTons: 122.3,
      completed: 934,
      fuelSaving: 0.085,
      byType: { household: 62, recyclable: 31, bulky: 7 }
    },
  });
});

// Master data endpoints
// GET /api/master/fleet - Get all vehicles
app.get("/api/master/fleet", async (req, res) => {
  try {
    const { rows } = await db.query(
      `SELECT 
        v.id,
        v.plate,
        v.type,
        v.capacity_kg as capacity,
        v.accepted_types as types,
        v.status,
        v.depot_id
      FROM vehicles v
      ORDER BY v.plate ASC`
    );

    res.json({
      ok: true,
      data: rows.map(row => ({
        id: row.id,
        plate: row.plate,
        type: row.type,
        capacity: row.capacity,
        capacity_kg: row.capacity, // Alias for compatibility
        types: row.types || [],
        status: row.status || 'available',
        depot_id: row.depot_id,
      })),
    });
  } catch (error) {
    console.error('[Master] Get fleet error:', error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// GET /api/master/depots - Get all depots
app.get("/api/master/depots", async (req, res) => {
  try {
    const { rows } = await db.query(
      `SELECT 
        id, 
        name, 
        address, 
        status, 
        capacity_vehicles, 
        opening_hours,
        ST_X(geom::geometry) as lon,
        ST_Y(geom::geometry) as lat
       FROM depots
       ORDER BY name ASC`
    );
    
    res.json({
      ok: true,
      data: rows.map(row => ({
        id: row.id,
        name: row.name,
        address: row.address,
        status: row.status,
        capacityVehicles: row.capacity_vehicles,
        openingHours: row.opening_hours,
        lon: parseFloat(row.lon),
        lat: parseFloat(row.lat),
      })),
    });
  } catch (error) {
    console.error('[Master] Get depots error:', error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// GET /api/master/dumps - Get all dumps
app.get("/api/master/dumps", async (req, res) => {
  try {
    const { rows } = await db.query(
      `SELECT 
        id, 
        name, 
        address, 
        status, 
        capacity_tons, 
        opening_hours,
        ST_X(geom::geometry) as lon,
        ST_Y(geom::geometry) as lat
       FROM dumps
       ORDER BY name ASC`
    );

    res.json({
      ok: true,
      data: rows.map(row => ({
        id: row.id,
        name: row.name,
        address: row.address,
        status: row.status,
        capacity_tons: row.capacity_tons,
        opening_hours: row.opening_hours,
        lon: parseFloat(row.lon),
        lat: parseFloat(row.lat),
      })),
    });
  } catch (error) {
    console.error('[Master] Get dumps error:', error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Middleware: Check manager role (simplified for now)
const requireManager = async (req, res, next) => {
  // TODO: Extract from JWT token in production
  const userId = req.headers['x-user-id'] || req.query.manager_id;
  if (!userId) {
    // For testing, allow without authentication
    // In production, return 401 Unauthorized
    // return res.status(401).json({ ok: false, error: 'Unauthorized' });
  }
  req.userId = userId;
  next();
};

// POST /api/master/depots - Create depot
app.post("/api/master/depots", requireManager, async (req, res) => {
  try {
    const { name, address, lon, lat, capacity_vehicles, opening_hours, status } = req.body;
    
    if (!name || lon === undefined || lat === undefined) {
      return res.status(400).json({ ok: false, error: "name, lon, and lat are required" });
    }

    const { rows } = await db.query(
      `INSERT INTO depots (id, name, address, geom, capacity_vehicles, opening_hours, status)
       VALUES (gen_random_uuid(), $1, $2, ST_SetSRID(ST_MakePoint($3, $4), 4326), $5, $6, $7)
       RETURNING id, name, address, ST_X(geom::geometry) as lon, ST_Y(geom::geometry) as lat, capacity_vehicles, opening_hours, status`,
      [name, address || null, lon, lat, capacity_vehicles || 10, opening_hours || '18:00-06:00', status || 'active']
    );

    res.json({
      ok: true,
      data: {
        id: rows[0].id,
        name: rows[0].name,
        address: rows[0].address,
        lon: parseFloat(rows[0].lon),
        lat: parseFloat(rows[0].lat),
        capacity_vehicles: rows[0].capacity_vehicles,
        opening_hours: rows[0].opening_hours,
        status: rows[0].status,
      },
    });
  } catch (error) {
    console.error('[Master] Create depot error:', error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// PATCH /api/master/depots/:id - Update depot
app.patch("/api/master/depots/:id", requireManager, async (req, res) => {
  try {
    const { id } = req.params;
    const { name, address, lon, lat, capacity_vehicles, opening_hours, status } = req.body;

    const updates = [];
    const values = [];
    let paramIndex = 1;

    if (name !== undefined) {
      updates.push(`name = $${paramIndex++}`);
      values.push(name);
    }
    if (address !== undefined) {
      updates.push(`address = $${paramIndex++}`);
      values.push(address);
    }
    if (lon !== undefined && lat !== undefined) {
      updates.push(`geom = ST_SetSRID(ST_MakePoint($${paramIndex}, $${paramIndex + 1}), 4326)`);
      values.push(lon, lat);
      paramIndex += 2;
    }
    if (capacity_vehicles !== undefined) {
      updates.push(`capacity_vehicles = $${paramIndex++}`);
      values.push(capacity_vehicles);
    }
    if (opening_hours !== undefined) {
      updates.push(`opening_hours = $${paramIndex++}`);
      values.push(opening_hours);
    }
    if (status !== undefined) {
      // Validate and normalize status
      const validStatuses = ['available', 'in_use', 'maintenance', 'retired'];
      let normalizedStatus = status.toLowerCase();
      if (normalizedStatus === 'ready') normalizedStatus = 'available';
      if (!validStatuses.includes(normalizedStatus)) {
        return res.status(400).json({ ok: false, error: `Invalid status. Must be one of: ${validStatuses.join(', ')}` });
      }
      updates.push(`status = $${paramIndex++}`);
      values.push(normalizedStatus);
    }

    if (updates.length === 0) {
      return res.status(400).json({ ok: false, error: "No fields to update" });
    }

    updates.push(`updated_at = now()`);
    values.push(id);

    const { rows } = await db.query(
      `UPDATE depots 
       SET ${updates.join(', ')}
       WHERE id = $${paramIndex}
       RETURNING id, name, address, ST_X(geom::geometry) as lon, ST_Y(geom::geometry) as lat, capacity_vehicles, opening_hours, status`,
      values
    );

    if (rows.length === 0) {
      return res.status(404).json({ ok: false, error: "Depot not found" });
    }

    res.json({
      ok: true,
      data: {
        id: rows[0].id,
        name: rows[0].name,
        address: rows[0].address,
        lon: parseFloat(rows[0].lon),
        lat: parseFloat(rows[0].lat),
        capacity_vehicles: rows[0].capacity_vehicles,
        opening_hours: rows[0].opening_hours,
        status: rows[0].status,
      },
    });
  } catch (error) {
    console.error('[Master] Update depot error:', error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// DELETE /api/master/depots/:id - Delete depot
app.delete("/api/master/depots/:id", requireManager, async (req, res) => {
  try {
    const { id } = req.params;

    const { rowCount } = await db.query(
      `UPDATE depots SET status = 'inactive' WHERE id = $1`,
      [id]
    );

    if (rowCount === 0) {
      return res.status(404).json({ ok: false, error: "Depot not found" });
    }

    res.json({ ok: true, message: "Depot deleted" });
  } catch (error) {
    console.error('[Master] Delete depot error:', error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// POST /api/master/dumps - Create dump
app.post("/api/master/dumps", requireManager, async (req, res) => {
  try {
    const { name, address, lon, lat, capacity_tons, opening_hours, status } = req.body;
    
    if (!name || lon === undefined || lat === undefined) {
      return res.status(400).json({ ok: false, error: "name, lon, and lat are required" });
    }

    const { rows } = await db.query(
      `INSERT INTO dumps (id, name, address, geom, capacity_tons, opening_hours, status)
       VALUES (gen_random_uuid(), $1, $2, ST_SetSRID(ST_MakePoint($3, $4), 4326), $5, $6, $7)
       RETURNING id, name, address, ST_X(geom::geometry) as lon, ST_Y(geom::geometry) as lat, capacity_tons, opening_hours, status`,
      [name, address || null, lon, lat, capacity_tons || null, opening_hours || '18:00-06:00', status || 'active']
    );

    res.json({
      ok: true,
      data: {
        id: rows[0].id,
        name: rows[0].name,
        address: rows[0].address,
        lon: parseFloat(rows[0].lon),
        lat: parseFloat(rows[0].lat),
        capacity_tons: rows[0].capacity_tons,
        opening_hours: rows[0].opening_hours,
        status: rows[0].status,
      },
    });
  } catch (error) {
    console.error('[Master] Create dump error:', error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// PATCH /api/master/dumps/:id - Update dump
app.patch("/api/master/dumps/:id", requireManager, async (req, res) => {
  try {
    const { id } = req.params;
    const { name, address, lon, lat, capacity_tons, opening_hours, status } = req.body;

    const updates = [];
    const values = [];
    let paramIndex = 1;

    if (name !== undefined) {
      updates.push(`name = $${paramIndex++}`);
      values.push(name);
    }
    if (address !== undefined) {
      updates.push(`address = $${paramIndex++}`);
      values.push(address);
    }
    if (lon !== undefined && lat !== undefined) {
      updates.push(`geom = ST_SetSRID(ST_MakePoint($${paramIndex}, $${paramIndex + 1}), 4326)`);
      values.push(lon, lat);
      paramIndex += 2;
    }
    if (capacity_tons !== undefined) {
      updates.push(`capacity_tons = $${paramIndex++}`);
      values.push(capacity_tons);
    }
    if (opening_hours !== undefined) {
      updates.push(`opening_hours = $${paramIndex++}`);
      values.push(opening_hours);
    }
    if (status !== undefined) {
      // Validate and normalize status
      const validStatuses = ['available', 'in_use', 'maintenance', 'retired'];
      let normalizedStatus = status.toLowerCase();
      if (normalizedStatus === 'ready') normalizedStatus = 'available';
      if (!validStatuses.includes(normalizedStatus)) {
        return res.status(400).json({ ok: false, error: `Invalid status. Must be one of: ${validStatuses.join(', ')}` });
      }
      updates.push(`status = $${paramIndex++}`);
      values.push(normalizedStatus);
    }

    if (updates.length === 0) {
      return res.status(400).json({ ok: false, error: "No fields to update" });
    }

    updates.push(`updated_at = now()`);
    values.push(id);

    const { rows } = await db.query(
      `UPDATE dumps 
       SET ${updates.join(', ')}
       WHERE id = $${paramIndex}
       RETURNING id, name, address, ST_X(geom::geometry) as lon, ST_Y(geom::geometry) as lat, capacity_tons, opening_hours, status`,
      values
    );

    if (rows.length === 0) {
      return res.status(404).json({ ok: false, error: "Dump not found" });
    }

    res.json({
      ok: true,
      data: {
        id: rows[0].id,
        name: rows[0].name,
        address: rows[0].address,
        lon: parseFloat(rows[0].lon),
        lat: parseFloat(rows[0].lat),
        capacity_tons: rows[0].capacity_tons,
        opening_hours: rows[0].opening_hours,
        status: rows[0].status,
      },
    });
  } catch (error) {
    console.error('[Master] Update dump error:', error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// DELETE /api/master/dumps/:id - Delete dump
app.delete("/api/master/dumps/:id", requireManager, async (req, res) => {
  try {
    const { id } = req.params;

    const { rowCount } = await db.query(
      `UPDATE dumps SET status = 'inactive' WHERE id = $1`,
      [id]
    );

    if (rowCount === 0) {
      return res.status(404).json({ ok: false, error: "Dump not found" });
    }

    res.json({ ok: true, message: "Dump deleted" });
  } catch (error) {
    console.error('[Master] Delete dump error:', error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// POST /api/master/fleet - Create vehicle
app.post("/api/master/fleet", requireManager, async (req, res) => {
  try {
    const { plate, type, capacity, capacity_kg, types, status, depot_id } = req.body;
    
    if (!plate || !type || (!capacity && !capacity_kg)) {
      return res.status(400).json({ ok: false, error: "plate, type, and capacity are required" });
    }

    const vehicleId = `VH${String(Date.now()).slice(-6)}`;
    const capacityValue = capacity || capacity_kg || 0;
    const acceptedTypes = Array.isArray(types) ? types : (types ? [types] : []);
    
    // Validate and normalize status (DB constraint: 'available', 'in_use', 'maintenance', 'retired')
    const validStatuses = ['available', 'in_use', 'maintenance', 'retired'];
    let normalizedStatus = (status || 'available').toLowerCase();
    // Map common status values to valid ones
    if (normalizedStatus === 'ready') normalizedStatus = 'available';
    if (!validStatuses.includes(normalizedStatus)) {
      normalizedStatus = 'available';
    }

    const { rows } = await db.query(
      `INSERT INTO vehicles (id, plate, type, capacity_kg, accepted_types, status, depot_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING id, plate, type, capacity_kg, accepted_types, status, depot_id`,
      [vehicleId, plate, type, capacityValue, acceptedTypes, normalizedStatus, depot_id || null]
    );

    res.json({
      ok: true,
      data: {
        id: rows[0].id,
        plate: rows[0].plate,
        type: rows[0].type,
        capacity: rows[0].capacity_kg,
        capacity_kg: rows[0].capacity_kg,
        types: rows[0].accepted_types || [],
        status: rows[0].status,
        depot_id: rows[0].depot_id,
      },
    });
  } catch (error) {
    console.error('[Master] Create vehicle error:', error);
    if (error.code === '23505') { // Unique violation
      return res.status(409).json({ ok: false, error: "Biển số đã tồn tại" });
    }
    res.status(500).json({ ok: false, error: error.message });
  }
});

// PATCH /api/master/fleet/:id - Update vehicle
app.patch("/api/master/fleet/:id", requireManager, async (req, res) => {
  try {
    const { id } = req.params;
    const { plate, type, capacity, capacity_kg, types, status, depot_id } = req.body;

    const updates = [];
    const values = [];
    let paramIndex = 1;

    if (plate !== undefined) {
      updates.push(`plate = $${paramIndex++}`);
      values.push(plate);
    }
    if (type !== undefined) {
      updates.push(`type = $${paramIndex++}`);
      values.push(type);
    }
    if (capacity !== undefined || capacity_kg !== undefined) {
      updates.push(`capacity_kg = $${paramIndex++}`);
      values.push(capacity || capacity_kg);
    }
    if (types !== undefined) {
      updates.push(`accepted_types = $${paramIndex++}`);
      values.push(Array.isArray(types) ? types : [types]);
    }
    if (status !== undefined) {
      // Validate and normalize status
      const validStatuses = ['available', 'in_use', 'maintenance', 'retired'];
      let normalizedStatus = status.toLowerCase();
      if (normalizedStatus === 'ready') normalizedStatus = 'available';
      if (!validStatuses.includes(normalizedStatus)) {
        return res.status(400).json({ ok: false, error: `Invalid status. Must be one of: ${validStatuses.join(', ')}` });
      }
      updates.push(`status = $${paramIndex++}`);
      values.push(normalizedStatus);
    }
    if (depot_id !== undefined) {
      updates.push(`depot_id = $${paramIndex++}`);
      values.push(depot_id || null);
    }

    if (updates.length === 0) {
      return res.status(400).json({ ok: false, error: "No fields to update" });
    }

    updates.push(`updated_at = now()`);
    values.push(id);

    const { rows } = await db.query(
      `UPDATE vehicles 
       SET ${updates.join(', ')}
       WHERE id = $${paramIndex}
       RETURNING id, plate, type, capacity_kg, accepted_types, status, depot_id`,
      values
    );

    if (rows.length === 0) {
      return res.status(404).json({ ok: false, error: "Vehicle not found" });
    }

    res.json({
      ok: true,
      data: {
        id: rows[0].id,
        plate: rows[0].plate,
        type: rows[0].type,
        capacity: rows[0].capacity_kg,
        capacity_kg: rows[0].capacity_kg,
        types: rows[0].accepted_types || [],
        status: rows[0].status,
        depot_id: rows[0].depot_id,
      },
    });
  } catch (error) {
    console.error('[Master] Update vehicle error:', error);
    if (error.code === '23505') {
      return res.status(409).json({ ok: false, error: "Biển số đã tồn tại" });
    }
    res.status(500).json({ ok: false, error: error.message });
  }
});

// DELETE /api/master/fleet/:id - Delete vehicle
app.delete("/api/master/fleet/:id", requireManager, async (req, res) => {
  try {
    const { id } = req.params;

    const { rowCount } = await db.query(
      `DELETE FROM vehicles WHERE id = $1`,
      [id]
    );

    if (rowCount === 0) {
      return res.status(404).json({ ok: false, error: "Vehicle not found" });
    }

    res.json({ ok: true, message: "Vehicle deleted" });
  } catch (error) {
    console.error('[Master] Delete vehicle error:', error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Collection points endpoint
app.get("/api/points", (req, res) => {
  const center = { lat: 10.78, lon: 106.7 };
  const n = 120;
  const points = Array.from({ length: n }).map((_, i) => {
    const type = TYPES[Math.floor(Math.random() * TYPES.length)];
    const lat = center.lat + randomInRange(-0.08, 0.08);
    const lon = center.lon + randomInRange(-0.08, 0.08);
    const demand = Math.floor(randomInRange(20, 120));
    const status = Math.random() < 0.1 ? "grey" : "active";
    return { id: `P${i + 1}`, type, lat, lon, demand, status };
  });
  res.json({ ok: true, data: points });
});

// VRP optimization endpoint
const VRPOptimizer = require("./services/vrp-optimizer");
const RoutePersister = require("./services/route-persister");
const FIWARERoutePublisher = require("./services/fiware-route-publisher");

const vrpOptimizer = new VRPOptimizer(db);
const routePersister = new RoutePersister(db);
const fiwarePublisher = new FIWARERoutePublisher();

app.post("/api/vrp/optimize", requireManager, async (req, res) => {
  try {
    const {
      scheduled_date,
      depot_id,
      dump_id,
      vehicles = [],
      constraints = {},
      save_to_database = false, // Optional: save routes immediately
      publish_to_fiware = false, // Optional: publish to FIWARE
    } = req.body;

    // Validate required fields
    if (!scheduled_date || !depot_id || !dump_id) {
      return res.status(400).json({
        ok: false,
        error: "scheduled_date, depot_id, and dump_id are required",
      });
    }

    if (!Array.isArray(vehicles) || vehicles.length === 0) {
      return res.status(400).json({
        ok: false,
        error: "At least one vehicle is required",
      });
    }

    // Run optimization
    const optimizationResult = await vrpOptimizer.optimize({
      scheduled_date,
      depot_id,
      dump_id,
      vehicles: vehicles.map((v) => v.id || v),
      constraints,
    });

    // Optionally save to database
    let savedRouteIds = [];
    if (save_to_database) {
      savedRouteIds = await routePersister.saveRoutes(
        optimizationResult.routes,
        {
          scheduled_date,
          depot_id,
          dump_id,
        }
      );

      // Optionally publish to FIWARE
      if (publish_to_fiware && savedRouteIds.length > 0) {
        for (const routeId of savedRouteIds) {
          const routeDetails = await routePersister.getRouteDetails(routeId);
          if (routeDetails) {
            await fiwarePublisher.publishRoute(routeDetails);
          }
        }
      }
    }

    res.json({
      ok: true,
      data: {
        ...optimizationResult,
        saved_route_ids: savedRouteIds,
      },
    });
  } catch (error) {
    console.error("[VRP] Optimization error:", error);
    res.status(500).json({
      ok: false,
      error: error.message || "Route optimization failed",
    });
  }
});

// Save optimized routes to database
app.post("/api/vrp/save-routes", requireManager, async (req, res) => {
  try {
    const { routes, scheduled_date, depot_id, dump_id } = req.body;

    if (!routes || !Array.isArray(routes) || routes.length === 0) {
      return res.status(400).json({
        ok: false,
        error: "routes array is required",
      });
    }

    if (!scheduled_date || !depot_id || !dump_id) {
      return res.status(400).json({
        ok: false,
        error: "scheduled_date, depot_id, and dump_id are required",
      });
    }

    const savedRouteIds = await routePersister.saveRoutes(routes, {
      scheduled_date,
      depot_id,
      dump_id,
    });

    // Publish to FIWARE (optional, non-blocking)
    if (savedRouteIds.length > 0) {
      for (const routeId of savedRouteIds) {
        try {
          const routeDetails = await routePersister.getRouteDetails(routeId);
          if (routeDetails) {
            await fiwarePublisher.publishRoute(routeDetails);
          }
        } catch (error) {
          console.error(`Failed to publish route ${routeId} to FIWARE:`, error);
          // Continue even if FIWARE publishing fails
        }
      }
    }

    res.json({
      ok: true,
      data: {
        message: "Routes saved successfully",
        route_ids: savedRouteIds,
        total_routes: savedRouteIds.length,
      },
    });
  } catch (error) {
    console.error("[VRP] Save routes error:", error);
    res.status(500).json({
      ok: false,
      error: error.message || "Failed to save routes",
    });
  }
});

// Dispatch endpoints
app.post("/api/dispatch/send-routes", (req, res) => {
  res.json({ ok: true, data: { message: "Routes dispatched" } });
});

app.post("/api/dispatch/reroute", (req, res) => {
  res.json({
    ok: true,
    data: {
      message: "Re-route created",
      routeId: `R${Math.floor(Math.random() * 1000)}`,
    },
  });
});

// --- CN7: Alerts API ---
app.get("/api/alerts", async (req, res) => {
  try {
    const { rows } = await db.query(
      `SELECT
         a.alert_id, 
         a.alert_type, 
         a.severity, 
         a.status, 
         a.created_at,
         a.point_id, 
         COALESCE(
           (SELECT cs.address FROM collection_schedules cs WHERE cs.id IN (SELECT rs.point_id FROM route_stops rs WHERE rs.point_id = p.id LIMIT 1)),
           ua.address_text,
           CONCAT('Điểm ', SUBSTRING(p.id::text, 1, 8))
         ) as point_name,
         a.vehicle_id, 
         v.plate as license_plate,
         a.route_id,
         a.details
       FROM alerts a
       LEFT JOIN vehicles v ON a.vehicle_id = v.id
       LEFT JOIN points p ON a.point_id = p.id
       LEFT JOIN user_addresses ua ON p.address_id = ua.id
       LEFT JOIN collection_schedules cs ON cs.id = p.id
       ORDER BY a.created_at DESC
       LIMIT 50`
    );
    res.json({ ok: true, data: rows });
  } catch (err) {
    console.error("Error fetching alerts:", err);
    res.status(500).json({ ok: false, error: "Failed to fetch alerts" });
  }
});

app.post("/api/alerts/:alertId/dispatch", async (req, res) => {
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
      return res
        .status(404)
        .json({ ok: false, error: "Alert or associated point not found" });
    }
    const alertData = alertResult.rows[0];

    // 2. Get all currently active vehicles from database
    // Try to get vehicle location from active route's last stop (via collection_schedules), fallback to depot location
    const vehiclesResult = await db.query(
      `SELECT 
        v.id,
        v.plate,
        v.type,
        v.status,
        -- Get vehicle location from active route's last stop (via collection_schedules), or depot location
        COALESCE(
          (SELECT cs.latitude
           FROM route_stops rs 
           JOIN routes r ON rs.route_id = r.id 
           JOIN collection_schedules cs ON rs.point_id = cs.id
           WHERE r.vehicle_id = v.id 
             AND r.status = 'in_progress' 
           ORDER BY rs.seq DESC LIMIT 1),
          (SELECT ST_Y(d.geom::geometry) FROM depots d WHERE d.id = v.depot_id)
        ) as lat,
        COALESCE(
          (SELECT cs.longitude
           FROM route_stops rs 
           JOIN routes r ON rs.route_id = r.id 
           JOIN collection_schedules cs ON rs.point_id = cs.id
           WHERE r.vehicle_id = v.id 
             AND r.status = 'in_progress' 
           ORDER BY rs.seq DESC LIMIT 1),
          (SELECT ST_X(d.geom::geometry) FROM depots d WHERE d.id = v.depot_id)
        ) as lon
      FROM vehicles v
      WHERE v.status IN ('available', 'in_use')
      ORDER BY v.id
      LIMIT 20`
    );

    const activeVehicles = vehiclesResult.rows.filter(v => v.lat && v.lon);

    if (activeVehicles.length === 0) {
      // Fallback to in-memory store if no database vehicles
      const storeVehicles = store.getVehicles();
      if (storeVehicles.length > 0) {
        const vehiclesWithDistance = storeVehicles.map((v) => ({
          id: v.id,
          plate: v.id,
          distance: getHaversineDistance(
            { lat: alertData.lat, lon: alertData.lon },
            { lat: v.lat, lon: v.lon }
          ),
        }));
        const suggestedVehicles = vehiclesWithDistance
          .sort((a, b) => a.distance - b.distance)
          .slice(0, 3);
        return res.json({ ok: true, data: suggestedVehicles });
      }
      return res.json({
        ok: true,
        data: [],
        message: "No active vehicles available",
      });
    }

    // 3. Calculate the distance to the missed point for each vehicle
    const vehiclesWithDistance = activeVehicles.map((v) => ({
      id: v.id,
      plate: v.plate,
      type: v.type,
      distance: getHaversineDistance(
        { lat: alertData.lat, lon: alertData.lon },
        { lat: parseFloat(v.lat), lon: parseFloat(v.lon) }
      ) * 1000, // Convert to meters
    }));

    // 4. Sort by distance and take the top 3
    const suggestedVehicles = vehiclesWithDistance
      .sort((a, b) => a.distance - b.distance)
      .slice(0, 3);

    res.json({ ok: true, data: suggestedVehicles });
  } catch (err) {
    console.error(`Error processing dispatch for alert ${alertId}:`, err);
    res
      .status(500)
      .json({ ok: false, error: "Failed to process dispatch request" });
  }
});

// CN7: Assign vehicle to alert and create re-route
app.post("/api/alerts/:alertId/assign", async (req, res) => {
  const { alertId } = req.params;
  const { vehicle_id } = req.body;

  if (!vehicle_id) {
    return res
      .status(400)
      .json({ ok: false, error: "Missing vehicle_id in request body" });
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
      return res
        .status(404)
        .json({ ok: false, error: "Alert not found or already processed" });
    }

    const alert = alertResult.rows[0];

    // 2. Create a new route in the database for the re-routing
    const { v4: uuidv4 } = require("uuid");
    const newRouteId = uuidv4();
    const now = new Date();

    await db.query(
      `INSERT INTO routes (id, vehicle_id, start_at, status, meta)
       VALUES ($1::uuid, $2::text, $3::timestamptz, $4::text, $5::jsonb)`,
      [
        newRouteId,
        vehicle_id,
        now.toISOString(),
        "in_progress",
        JSON.stringify({
          type: "incident_response",
          original_alert_id: parseInt(alertId),
          original_route_id: alert.original_route_id,
          created_by: "dynamic_dispatch",
        }),
      ]
    );

    // 3. Add the incident point as a route stop
    const stopId = uuidv4();
    await db.query(
      `INSERT INTO route_stops (id, route_id, point_id, seq, status, planned_eta)
       VALUES ($1::uuid, $2::uuid, $3::uuid, $4::int, $5::text, $6::timestamptz)`,
      [stopId, newRouteId, alert.point_id, 1, "pending", now.toISOString()]
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
             'assigned_at', $2::text,
             'new_route_id', $3::text
           )
       WHERE alert_id = $4::int`,
      [vehicle_id, now.toISOString(), newRouteId, parseInt(alertId)]
    );

    // 5. Start the route in the in-memory store
    store.startRoute(newRouteId, vehicle_id, [
      {
        point_id: alert.point_id,
        lat: alert.lat,
        lon: alert.lon,
      },
    ]);

    console.log(
      `✅ Alert ${alertId} assigned to vehicle ${vehicle_id}, new route ${newRouteId} created`
    );

    res.json({
      ok: true,
      data: {
        message: "Vehicle assigned successfully",
        route_id: newRouteId,
        vehicle_id: vehicle_id,
        alert_id: parseInt(alertId),
      },
    });
  } catch (err) {
    console.error(`Error assigning vehicle to alert ${alertId}:`, err);
    res.status(500).json({ ok: false, error: "Failed to assign vehicle" });
  }
});

// Analytics endpoints
app.get("/api/analytics/timeseries", (req, res) => {
  const now = Date.now();
  const series = Array.from({ length: 24 }).map((_, i) => ({
    t: new Date(now - (23 - i) * 3600e3).toISOString(),
    value: Math.round(60 + 30 * Math.sin(i / 4) + Math.random() * 10),
  }));

  // Mock data for waste by type (donut chart)
  const byType = {
    household: Math.round(40 + Math.random() * 20),
    recyclable: Math.round(25 + Math.random() * 15),
    bulky: Math.round(15 + Math.random() * 10),
  };

  res.json({ ok: true, data: series, series, byType }); // Keep both 'data' and 'series' for compatibility
});

app.get("/api/analytics/predict", (req, res) => {
  const days = Number(req.query.days || 7);
  const today = new Date();
  const actual = Array.from({ length: days }).map((_, i) => ({
    d: new Date(
      today.getFullYear(),
      today.getMonth(),
      today.getDate() - days + i
    )
      .toISOString()
      .slice(0, 10),
    v: Math.round(50 + Math.random() * 10),
  }));
  const forecast = Array.from({ length: days }).map((_, i) => ({
    d: new Date(today.getFullYear(), today.getMonth(), today.getDate() + i)
      .toISOString()
      .slice(0, 10),
    v: Math.round(55 + Math.random() * 12),
  }));
  res.json({ ok: true, data: { actual, forecast } });
});

// Exceptions endpoint

// --- CN7: Dynamic Dispatch - Incident Detection ---
const MISSED_POINT_DISTANCE_THRESHOLD = 500; // meters

cron.schedule("*/15 * * * * *", async () => {
  console.log("🛰️  Running Missed Point Detection...");
  const activeRoutes = store.getActiveRoutes();

  for (const route of activeRoutes) {
    if (route.status !== "inprogress") continue;

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
            "SELECT 1 FROM alerts WHERE route_id = $1 AND point_id = $2 AND status = $3 LIMIT 1",
            [route.route_id, point.point_id, "open"]
          );

          if (rows.length === 0) {
            console.log(
              `🚨 MISSED POINT DETECTED! Route: ${route.route_id}, Point: ${point.point_id}`
            );
            // Create a new alert in the database
            // Ensure FK safety: if route_id is not a UUID, store NULL; vehicle_id may not exist in DB (mock IDs), also store NULL
            const routeIdForInsert =
              typeof route.route_id === "string" &&
              /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/.test(
                route.route_id
              )
                ? route.route_id
                : null;
            const vehicleIdForInsert = null;
            await db.query(
              `INSERT INTO alerts (alert_type, point_id, vehicle_id, route_id, severity, status, details)
               VALUES ($1, $2, $3, $4, $5, $6, $7)`,
              [
                "missed_point",
                point.point_id,
                vehicleIdForInsert,
                routeIdForInsert,
                "critical", // Missed points are considered critical
                "open",
                JSON.stringify({
                  detected_at: new Date().toISOString(),
                  vehicle_location: { lat: vehicle.lat, lon: vehicle.lon },
                }),
              ]
            );
          }
        } catch (err) {
          console.error("Error creating missed point alert:", err);
        }
      }
    }
  }
});

// --- Testing Endpoints (CN7) ---
// Start a mock route so the cron can detect missed points
app.post("/api/test/start-route", async (req, res) => {
  try {
    const { route_id = 1, vehicle_id = "V01" } = req.body || {};
    // Take first 5 points from the in-memory store
    const points = Array.from(store.points.values())
      .slice(0, 5)
      .map((p) => ({
        point_id: p.id,
        lat: p.lat,
        lon: p.lon,
      }));

    if (points.length === 0) {
      return res
        .status(500)
        .json({ ok: false, error: "No points available in store" });
    }

    store.startRoute(route_id, vehicle_id, points);
    return res.json({
      ok: true,
      message: `Test route ${route_id} started for vehicle ${vehicle_id}`,
      points: points.map((p) => p.point_id),
    });
  } catch (err) {
    console.error("Error starting test route:", err);
    return res
      .status(500)
      .json({ ok: false, error: "Failed to start test route" });
  }
});

// GET /api/exceptions - Get all exceptions (for manager)
app.get("/api/exceptions", requireManager, async (req, res) => {
  try {
    const { status, route_id, limit = 50, offset = 0 } = req.query;
    
    let query = `
      SELECT 
        e.id,
        e.route_id,
        e.stop_id,
        e.type,
        e.reason,
        e.photo_url,
        e.status,
        e.approved_by,
        e.approved_at,
        e.plan,
        e.scheduled_at,
        e.created_at,
        e.updated_at,
        -- Route information
        r.vehicle_id,
        v.plate as vehicle_plate,
        -- Stop information
        rs.seq as stop_sequence,
        cs.address as stop_address,
        cs.latitude as stop_latitude,
        cs.longitude as stop_longitude,
        -- Approver information
        u.profile->>'name' as approver_name
      FROM exceptions e
      LEFT JOIN routes r ON e.route_id = r.id
      LEFT JOIN vehicles v ON r.vehicle_id = v.id
      LEFT JOIN route_stops rs ON e.stop_id = rs.id
      LEFT JOIN collection_schedules cs ON rs.point_id = cs.id
      LEFT JOIN users u ON e.approved_by = u.id
      WHERE 1=1
    `;
    const params = [];
    let paramIndex = 1;

    if (status) {
      query += ` AND e.status = $${paramIndex}`;
      params.push(status);
      paramIndex++;
    }

    if (route_id) {
      query += ` AND e.route_id = $${paramIndex}`;
      params.push(route_id);
      paramIndex++;
    }

    query += ` ORDER BY e.created_at DESC LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    params.push(parseInt(limit, 10), parseInt(offset, 10));

    const { rows } = await db.query(query, params);

    // Format response
    const formattedData = rows.map(row => ({
      id: row.id,
      route_id: row.route_id,
      stop_id: row.stop_id,
      type: row.type,
      reason: row.reason,
      photo_url: row.photo_url,
      status: row.status,
      approved_by: row.approved_by,
      approved_at: row.approved_at ? row.approved_at.toISOString() : null,
      plan: row.plan,
      scheduled_at: row.scheduled_at ? row.scheduled_at.toISOString() : null,
      created_at: row.created_at ? row.created_at.toISOString() : null,
      updated_at: row.updated_at ? row.updated_at.toISOString() : null,
      // Additional info
      vehicle_id: row.vehicle_id,
      vehicle_plate: row.vehicle_plate,
      stop_sequence: row.stop_sequence,
      stop_address: row.stop_address,
      stop_location: row.stop_latitude && row.stop_longitude 
        ? `${row.stop_latitude.toFixed(5)}, ${row.stop_longitude.toFixed(5)}`
        : null,
      approver_name: row.approver_name,
      // Legacy format for frontend compatibility
      time: row.created_at ? new Date(row.created_at).toLocaleString('vi-VN') : 'N/A',
      location: row.stop_address || (row.stop_latitude && row.stop_longitude 
        ? `${row.stop_latitude.toFixed(5)}, ${row.stop_longitude.toFixed(5)}`
        : 'N/A')
    }));

    res.json({ ok: true, data: formattedData });
  } catch (error) {
    console.error('[Exceptions] Get exceptions error:', error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// POST /api/exceptions/:id/approve - Approve exception
app.post("/api/exceptions/:id/approve", requireManager, async (req, res) => {
  try {
    const { id } = req.params;
    const { plan, scheduled_at } = req.body;
    const userId = req.user?.id || null; // Get from auth middleware if available

    const { rows } = await db.query(
      `UPDATE exceptions 
       SET status = 'approved',
           approved_by = $1,
           approved_at = NOW(),
           plan = $2,
           scheduled_at = $3,
           updated_at = NOW()
       WHERE id = $4 AND status = 'pending'
       RETURNING id, status, approved_at, plan`,
      [userId, plan || null, scheduled_at || null, id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ ok: false, error: "Exception not found or already processed" });
    }

    res.json({ ok: true, data: { message: "Approved", exception: rows[0] } });
  } catch (error) {
    console.error('[Exceptions] Approve exception error:', error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// POST /api/exceptions/:id/reject - Reject exception
app.post("/api/exceptions/:id/reject", requireManager, async (req, res) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    const userId = req.user?.id || null; // Get from auth middleware if available

    if (!reason) {
      return res.status(400).json({ ok: false, error: "Reason is required for rejection" });
    }

    const { rows } = await db.query(
      `UPDATE exceptions 
       SET status = 'rejected',
           approved_by = $1,
           approved_at = NOW(),
           reason = COALESCE(reason, '') || ' | Lý do từ chối: ' || $2,
           updated_at = NOW()
       WHERE id = $3 AND status = 'pending'
       RETURNING id, status, approved_at`,
      [userId, reason, id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ ok: false, error: "Exception not found or already processed" });
    }

    res.json({ ok: true, data: { message: "Rejected", exception: rows[0] } });
  } catch (error) {
    console.error('[Exceptions] Reject exception error:', error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// ==================== MANAGER MIDDLEWARE ====================
// Note: requireManager is defined earlier in the file (line ~429)

// ==================== SCHEDULE API ====================
// GET /api/schedules - Get all collection schedules (for manager)
app.get("/api/schedules", requireManager, async (req, res) => {
  try {
    const { citizen_id, status, scheduled_date, limit = 50, offset = 0 } = req.query;

    // Query with JOIN to get citizen information
    let query = `
      SELECT 
        cs.id,
        cs.citizen_id,
        cs.scheduled_date,
        cs.time_slot,
        cs.waste_type,
        cs.estimated_weight_kg,
        cs.latitude,
        cs.longitude,
        cs.address,
        cs.status,
        cs.priority,
        cs.employee_id,
        cs.route_id,
        cs.notes,
        cs.completed_at,
        cs.cancelled_at,
        cs.cancelled_reason,
        cs.created_at,
        cs.updated_at,
        -- Citizen information
        u.phone as citizen_phone,
        u.email as citizen_email,
        u.profile->>'name' as citizen_name,
        -- Assigned employee information
        p.name as employee_name,
        p.role as employee_role
      FROM collection_schedules cs
      LEFT JOIN users u ON cs.citizen_id = u.id
      LEFT JOIN personnel p ON cs.employee_id = p.id
      WHERE 1=1
    `;
    const params = [];
    let paramIndex = 1;

    if (citizen_id) {
      query += ` AND cs.citizen_id = $${paramIndex}`;
      params.push(citizen_id);
      paramIndex++;
    }

    if (status) {
      query += ` AND cs.status = $${paramIndex}`;
      params.push(status);
      paramIndex++;
    }

    if (scheduled_date) {
      query += ` AND cs.scheduled_date = $${paramIndex}::date`;
      params.push(scheduled_date);
      paramIndex++;
    }

    query += ` ORDER BY cs.priority DESC, cs.created_at ASC LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    params.push(parseInt(limit, 10), parseInt(offset, 10));

    const { rows } = await db.query(query, params);

    // Format response to snake_case (matching mobile app format)
    const formattedData = rows.map(row => ({
      id: row.id,
      citizen_id: row.citizen_id,
      citizen_name: row.citizen_name || 'N/A',
      citizen_phone: row.citizen_phone || null,
      citizen_email: row.citizen_email || null,
      scheduled_date: row.scheduled_date ? row.scheduled_date.toISOString().split('T')[0] : null,
      time_slot: row.time_slot,
      waste_type: row.waste_type,
      estimated_weight: row.estimated_weight_kg || 0,
      latitude: row.latitude,
      longitude: row.longitude,
      address: row.address,
      status: row.status,
      priority: row.priority?.toString() || '0',
      employee_id: row.employee_id || null,
      employee_name: row.employee_name || null,
      employee_role: row.employee_role || null,
      route_id: row.route_id || null,
      notes: row.notes || null,
      completed_at: row.completed_at ? row.completed_at.toISOString() : null,
      cancelled_at: row.cancelled_at ? row.cancelled_at.toISOString() : null,
      cancelled_reason: row.cancelled_reason || null,
      created_at: row.created_at.toISOString(),
      updated_at: row.updated_at ? row.updated_at.toISOString() : null,
    }));

    res.json({
      ok: true,
      data: formattedData,
      total: formattedData.length,
    });
  } catch (error) {
    console.error("[Schedule] Get error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Get assigned schedules for worker (worker-specific endpoint)
// Mobile app uses this endpoint to fetch schedules assigned to the logged-in worker
app.get("/api/schedules/assigned", async (req, res) => {
  try {
    const { employee_id, status, limit = 50, offset = 0 } = req.query;

    // Query with JOIN to get citizen and employee information (matching format with /api/schedules)
    let query = `
      SELECT 
        cs.id,
        cs.citizen_id,
        cs.scheduled_date,
        cs.time_slot,
        cs.waste_type,
        cs.estimated_weight_kg,
        cs.latitude,
        cs.longitude,
        cs.address,
        cs.status,
        cs.priority,
        cs.employee_id,
        cs.route_id,
        cs.notes,
        cs.completed_at,
        cs.cancelled_at,
        cs.cancelled_reason,
        cs.created_at,
        cs.updated_at,
        -- Citizen information
        u.phone as citizen_phone,
        u.email as citizen_email,
        u.profile->>'name' as citizen_name,
        -- Assigned employee information
        p.name as employee_name,
        p.role as employee_role
      FROM collection_schedules cs
      LEFT JOIN users u ON cs.citizen_id = u.id
      LEFT JOIN personnel p ON cs.employee_id = p.id
      WHERE cs.employee_id IS NOT NULL
    `;
    const params = [];
    let paramIndex = 1;

    if (employee_id) {
      query += ` AND cs.employee_id = $${paramIndex}`;
      params.push(employee_id);
      paramIndex++;
    }

    if (status) {
      query += ` AND cs.status = $${paramIndex}`;
      params.push(status);
      paramIndex++;
    }

    query += ` ORDER BY cs.scheduled_date DESC, cs.created_at DESC LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    params.push(parseInt(limit, 10), parseInt(offset, 10));

    const { rows } = await db.query(query, params);

    // Format response to match mobile app CollectionRequest model (snake_case)
    const formattedData = rows.map(row => ({
      id: row.id,
      citizen_id: row.citizen_id,
      citizen_name: row.citizen_name || 'N/A',
      citizen_phone: row.citizen_phone || null,
      address: row.address,
      latitude: row.latitude,
      longitude: row.longitude,
      waste_type: row.waste_type,
      estimated_weight: row.estimated_weight_kg || 0,
      description: row.notes || null,
      images: null, // TODO: Add images field to collection_schedules table if needed
      status: row.status,
      priority: row.priority?.toString() || '0',
      scheduled_date: row.scheduled_date ? row.scheduled_date.toISOString().split('T')[0] : null,
      assigned_worker_id: row.employee_id || null,
      assigned_worker_name: row.employee_name || null,
      route_id: row.route_id || null,
      collected_at: row.completed_at ? row.completed_at.toISOString() : null,
      actual_weight: row.meta?.actual_weight || null,
      collection_notes: row.notes || null,
      collection_images: null, // TODO: Add collection_images field if needed
      created_at: row.created_at.toISOString(),
      updated_at: row.updated_at ? row.updated_at.toISOString() : null,
    }));

    console.log(`📋 Found ${formattedData.length} assigned schedules for employee_id: ${employee_id || 'all'}`);

    res.json({
      ok: true,
      data: formattedData,
      total: formattedData.length,
    });
  } catch (error) {
    console.error("[Schedule] Get assigned error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Get schedule by ID
app.get("/api/schedules/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { rows } = await db.query(
      `SELECT 
        cs.*,
        u.phone as citizen_phone,
        u.email as citizen_email,
        u.profile->>'name' as citizen_name,
        p.name as employee_name,
        p.role as employee_role
      FROM collection_schedules cs
      LEFT JOIN users u ON cs.citizen_id = u.id
      LEFT JOIN personnel p ON cs.employee_id = p.id
      WHERE cs.id = $1`,
      [id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ ok: false, error: "Schedule not found" });
    }

    const row = rows[0];
    res.json({ 
      ok: true, 
      data: {
        id: row.id,
        citizen_id: row.citizen_id,
        citizen_name: row.citizen_name || 'N/A',
        citizen_phone: row.citizen_phone || null,
        citizen_email: row.citizen_email || null,
        scheduled_date: row.scheduled_date ? row.scheduled_date.toISOString().split('T')[0] : null,
        time_slot: row.time_slot,
        waste_type: row.waste_type,
        estimated_weight: row.estimated_weight_kg || 0,
        latitude: row.latitude,
        longitude: row.longitude,
        address: row.address,
        status: row.status,
        priority: row.priority?.toString() || '0',
        employee_id: row.employee_id || null,
        employee_name: row.employee_name || null,
        employee_role: row.employee_role || null,
        route_id: row.route_id || null,
        notes: row.notes || null,
        completed_at: row.completed_at ? row.completed_at.toISOString() : null,
        cancelled_at: row.cancelled_at ? row.cancelled_at.toISOString() : null,
        cancelled_reason: row.cancelled_reason || null,
        created_at: row.created_at.toISOString(),
        updated_at: row.updated_at ? row.updated_at.toISOString() : null,
      }
    });
  } catch (error) {
    console.error("[Schedule] Get by ID error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Create new schedule
app.post("/api/schedules", async (req, res) => {
  try {
    const {
      citizen_id,
      scheduled_date,
      time_slot,
      waste_type,
      estimated_weight,
      latitude,
      longitude,
      address,
    } = req.body;

    // Validation
    if (
      !citizen_id ||
      !scheduled_date ||
      !time_slot ||
      !waste_type ||
      !estimated_weight
    ) {
      return res.status(400).json({
        ok: false,
        error:
          "Missing required fields: citizen_id, scheduled_date, time_slot, waste_type, estimated_weight",
      });
    }

    const { rows } = await db.query(
      `INSERT INTO collection_schedules (
        citizen_id, scheduled_date, time_slot, waste_type, estimated_weight_kg,
        latitude, longitude, address, status, priority
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
      RETURNING *`,
      [
        citizen_id,
        scheduled_date,
        time_slot,
        waste_type,
        estimated_weight,
        latitude || null,
        longitude || null,
        address || null,
        "scheduled", // Default status - Đã lên lịch thành công
        0, // Default priority
      ]
    );

    console.log(
      `✅ Schedule created: ${rows[0].id} for citizen ${citizen_id} - Status: scheduled`
    );

    // Emit event to Socket.IO for real-time updates (for web manager & worker apps)
    io.emit("schedule:created", {
      id: rows[0].id,
      schedule_id: rows[0].id, // Keep for backward compatibility
      citizen_id: rows[0].citizen_id,
      scheduled_date: rows[0].scheduled_date,
      time_slot: rows[0].time_slot,
      waste_type: rows[0].waste_type,
      estimated_weight: rows[0].estimated_weight_kg,
      latitude: rows[0].latitude,
      longitude: rows[0].longitude,
      address: rows[0].address,
      status: rows[0].status,
      created_at: rows[0].created_at,
    });

    console.log(
      `📡 Emitted schedule:created event for schedule ${rows[0].id}`
    );

    // Format response to snake_case (matching mobile app format)
    const row = rows[0];
    res.status(201).json({
      ok: true,
      data: {
        id: row.id,
        citizen_id: row.citizen_id,
        scheduled_date: row.scheduled_date ? row.scheduled_date.toISOString().split('T')[0] : null,
        time_slot: row.time_slot,
        waste_type: row.waste_type,
        estimated_weight: row.estimated_weight_kg || 0,
        latitude: row.latitude,
        longitude: row.longitude,
        address: row.address,
        status: row.status,
        priority: row.priority?.toString() || '0',
        employee_id: row.employee_id || null,
        route_id: row.route_id || null,
        notes: row.notes || null,
        completed_at: row.completed_at ? row.completed_at.toISOString() : null,
        cancelled_at: row.cancelled_at ? row.cancelled_at.toISOString() : null,
        cancelled_reason: row.cancelled_reason || null,
        created_at: row.created_at.toISOString(),
        updated_at: row.updated_at ? row.updated_at.toISOString() : null,
      },
      message: "Schedule created successfully",
    });
  } catch (error) {
    console.error("[Schedule] Create error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Update schedule status
app.patch("/api/schedules/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { status, employee_id, actual_weight, notes } = req.body;

    const updates = [];
    const params = [];
    let paramIndex = 1;

    if (status) {
      updates.push(`status = $${paramIndex}`);
      params.push(status);
      paramIndex++;
    }

    if (employee_id) {
      updates.push(`employee_id = $${paramIndex}`);
      params.push(employee_id);
      paramIndex++;
    }

    // Note: actual_weight is stored in meta JSONB for now
    if (actual_weight !== undefined) {
      updates.push(`meta = jsonb_set(COALESCE(meta, '{}'::jsonb), '{actual_weight}', $${paramIndex}::text::jsonb)`);
      params.push(JSON.stringify(actual_weight));
      paramIndex++;
    }

    if (notes) {
      updates.push(`notes = $${paramIndex}`);
      params.push(notes);
      paramIndex++;
    }

    if (status === "completed") {
      updates.push(`completed_at = NOW()`);
    }

    if (updates.length === 0) {
      return res.status(400).json({ ok: false, error: "No fields to update" });
    }

    updates.push("updated_at = NOW()");
    params.push(id);

    const query = `UPDATE collection_schedules SET ${updates.join(
      ", "
    )} WHERE id = $${paramIndex} RETURNING *`;
    const { rows } = await db.query(query, params);

    if (rows.length === 0) {
      return res.status(404).json({ ok: false, error: "Schedule not found" });
    }

    console.log(
      `✅ Schedule updated: ${id} -> status: ${status || "unchanged"}, employee_id: ${employee_id || "unchanged"}`
    );

    // Fetch updated schedule with JOIN to get full information (for response and Socket.IO)
    const { rows: updatedRows } = await db.query(
      `SELECT 
        cs.*,
        u.phone as citizen_phone,
        u.email as citizen_email,
        u.profile->>'name' as citizen_name,
        p.name as employee_name,
        p.role as employee_role
      FROM collection_schedules cs
      LEFT JOIN users u ON cs.citizen_id = u.id
      LEFT JOIN personnel p ON cs.employee_id = p.id
      WHERE cs.id = $1`,
      [id]
    );

    if (updatedRows.length === 0) {
      return res.status(404).json({ ok: false, error: "Schedule not found" });
    }

    const row = updatedRows[0];

    // Emit Socket.IO event for real-time updates (for mobile worker app)
    if (employee_id || status) {
      io.emit("schedule:updated", {
        id: row.id,
        employee_id: row.employee_id,
        employee_name: row.employee_name,
        employee_role: row.employee_role,
        status: row.status,
        scheduled_date: row.scheduled_date,
        time_slot: row.time_slot,
        address: row.address,
        waste_type: row.waste_type,
        estimated_weight_kg: row.estimated_weight_kg,
        updated_at: row.updated_at,
      });
      console.log(`📡 Emitted schedule:updated event for schedule ${id}`);
    }

    // Format response to snake_case (matching mobile app format)
    res.json({
      ok: true,
      data: {
        id: row.id,
        citizen_id: row.citizen_id,
        citizen_name: row.citizen_name || 'N/A',
        citizen_phone: row.citizen_phone || null,
        citizen_email: row.citizen_email || null,
        scheduled_date: row.scheduled_date ? row.scheduled_date.toISOString().split('T')[0] : null,
        time_slot: row.time_slot,
        waste_type: row.waste_type,
        estimated_weight: row.estimated_weight_kg || 0,
        latitude: row.latitude,
        longitude: row.longitude,
        address: row.address,
        status: row.status,
        priority: row.priority?.toString() || '0',
        employee_id: row.employee_id || null,
        employee_name: row.employee_name || null,
        employee_role: row.employee_role || null,
        route_id: row.route_id || null,
        notes: row.notes || null,
        completed_at: row.completed_at ? row.completed_at.toISOString() : null,
        cancelled_at: row.cancelled_at ? row.cancelled_at.toISOString() : null,
        cancelled_reason: row.cancelled_reason || null,
        created_at: row.created_at.toISOString(),
        updated_at: row.updated_at ? row.updated_at.toISOString() : null,
      },
      message: "Schedule updated successfully",
    });
  } catch (error) {
    console.error("[Schedule] Update error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Cancel schedule
app.patch("/api/schedules/:id/cancel", async (req, res) => {
  try {
    const { id } = req.params;
    const { rows } = await db.query(
      `UPDATE schedules 
       SET status = 'cancelled', updated_at = NOW() 
       WHERE schedule_id = $1 AND status = 'pending'
       RETURNING *`,
      [id]
    );

    if (rows.length === 0) {
      return res.status(404).json({
        ok: false,
        error: "Schedule not found or cannot be cancelled",
      });
    }

    console.log(`❌ Schedule cancelled: ${id}`);

    res.json({
      ok: true,
      data: rows[0],
      message: "Schedule cancelled successfully",
    });
  } catch (error) {
    console.error("[Schedule] Cancel error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Delete schedule (soft delete by setting status to cancelled)
app.delete("/api/schedules/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { rows } = await db.query(
      `UPDATE collection_schedules 
       SET status = 'cancelled', cancelled_at = NOW(), updated_at = NOW() 
       WHERE id = $1
       RETURNING *`,
      [id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ ok: false, error: "Schedule not found" });
    }

    console.log(`🗑️ Schedule deleted: ${id}`);

    res.json({
      ok: true,
      message: "Schedule deleted successfully",
    });
  } catch (error) {
    console.error("[Schedule] Delete error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// ==================== ROUTES API (Worker App) ====================
// Get active route for worker
app.get("/api/routes/active", async (req, res) => {
  try {
    const { employee_id } = req.query;

    if (!employee_id) {
      return res.status(400).json({
        ok: false,
        error: "employee_id is required",
      });
    }

    console.log(`🚛 Checking active route for employee: ${employee_id}`);

    // Query active route for employee (driver or collector)
    const routeQuery = `
      SELECT 
        r.id,
        r.vehicle_id,
        r.depot_id,
        r.driver_id,
        r.collector_id,
        r.start_at,
        r.end_at,
        r.status,
        r.created_at,
        r.updated_at,
        -- Driver/Collector name
        p.name as worker_name,
        -- Vehicle plate
        v.plate_number as vehicle_plate,
        -- Depot name
        d.name as depot_name
      FROM routes r
      LEFT JOIN personnel p ON (r.driver_id = p.id OR r.collector_id = p.id) AND p.id = $1
      LEFT JOIN vehicles v ON r.vehicle_id = v.id
      LEFT JOIN depots d ON r.depot_id = d.id
      WHERE (r.driver_id = $1 OR r.collector_id = $1)
        AND r.status IN ('planned', 'in_progress')
      ORDER BY r.start_at DESC
      LIMIT 1
    `;

    const routeResult = await db.query(routeQuery, [employee_id]);

    if (routeResult.rows.length === 0) {
      return res.json({
        ok: true,
        data: null, // No active route
      });
    }

    const route = routeResult.rows[0];

    // Query collection schedules (points) for this route
    const pointsQuery = `
      SELECT 
        cs.id,
        cs.citizen_id,
        cs.scheduled_date,
        cs.waste_type,
        cs.latitude,
        cs.longitude,
        cs.address,
        cs.status,
        cs.completed_at,
        cs.estimated_weight_kg,
        -- Get sequence from route_stops if exists
        COALESCE(rs.seq, ROW_NUMBER() OVER (ORDER BY cs.scheduled_date, cs.created_at))::int as seq
      FROM collection_schedules cs
      LEFT JOIN route_stops rs ON rs.route_id = $1 AND rs.point_id = cs.id
      WHERE cs.route_id = $1
      ORDER BY COALESCE(rs.seq, ROW_NUMBER() OVER (ORDER BY cs.scheduled_date, cs.created_at))
    `;

    const pointsResult = await db.query(pointsQuery, [route.id]);

    // Format points to match mobile app RoutePoint model (snake_case)
    const points = pointsResult.rows.map((row, index) => ({
      id: row.id,
      order: row.seq || (index + 1),
      collection_request_id: row.id, // Same as schedule id
      address: row.address || 'N/A',
      latitude: parseFloat(row.latitude) || 0,
      longitude: parseFloat(row.longitude) || 0,
      waste_type: row.waste_type || null,
      status: row.status === 'completed' ? 'completed' : row.status === 'in_progress' ? 'in_progress' : 'pending',
      arrived_at: null, // TODO: Add actual_arrival_at from route_stops
      completed_at: row.completed_at ? row.completed_at.toISOString() : null,
    }));

    // Format route to match mobile app WorkerRoute model (snake_case)
    const formattedRoute = {
      id: route.id,
      name: `Route ${route.id.substring(0, 8)}`, // Generate route name
      worker_id: employee_id,
      worker_name: route.worker_name || 'N/A',
      vehicle_plate: route.vehicle_plate || null,
      schedule_date: route.start_at ? route.start_at.toISOString().split('T')[0] : new Date().toISOString().split('T')[0],
      status: route.status,
      points: points,
      started_at: route.status === 'in_progress' ? route.start_at?.toISOString() : null,
      completed_at: route.status === 'completed' ? route.end_at?.toISOString() : null,
      total_distance: null, // TODO: Calculate from route_stops
      total_collections: points.length,
      completed_collections: points.filter(p => p.status === 'completed').length,
      created_at: route.created_at.toISOString(),
      updated_at: route.updated_at ? route.updated_at.toISOString() : null,
    };

    console.log(`✅ Found active route: ${route.id} with ${points.length} points`);

    res.json({
      ok: true,
      data: formattedRoute,
    });
  } catch (error) {
    console.error("[Route] Get active error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Start route
app.post("/api/routes/:id/start", async (req, res) => {
  try {
    const { id } = req.params;

    // TODO: Implement route start logic
    console.log(`🚀 Starting route: ${id}`);

    res.json({
      ok: true,
      message: "Route started successfully",
    });
  } catch (error) {
    console.error("[Route] Start error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Complete route
app.post("/api/routes/:id/complete", async (req, res) => {
  try {
    const { id } = req.params;

    // TODO: Implement route completion logic
    console.log(`✅ Completing route: ${id}`);

    res.json({
      ok: true,
      message: "Route completed successfully",
    });
  } catch (error) {
    console.error("[Route] Complete error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// ==================== AUTHENTICATION API ====================
// Login - Supports both email and phone for mobile app compatibility
app.post("/api/auth/login", async (req, res) => {
  try {
    const { phone, email, password } = req.body;

    if (!password || (!phone && !email)) {
      return res.status(400).json({
        ok: false,
        error: "Phone or email and password are required",
      });
    }

    // Query user by phone or email
    let query, params;
    if (email) {
      query = `SELECT id, phone, email, role, status, profile, created_at, updated_at, password_hash
               FROM users WHERE email = $1 AND status = 'active'`;
      params = [email];
    } else {
      query = `SELECT id, phone, email, role, status, profile, created_at, updated_at, password_hash
               FROM users WHERE phone = $1 AND status = 'active'`;
      params = [phone];
    }

    const { rows } = await db.query(query, params);

    if (rows.length === 0) {
      return res.status(401).json({
        ok: false,
        error: "Invalid credentials",
      });
    }

    const user = rows[0];

    // TODO: In production, verify password hash using bcrypt
    // For now, accept any password for demo (or check if password === '123456')
    if (password !== "123456" && password !== user.password_hash) {
      return res.status(401).json({
        ok: false,
        error: "Invalid credentials",
      });
    }

    // Update last login time
    await db.query("UPDATE users SET last_login_at = NOW() WHERE id = $1", [
      user.id,
    ]);

    // For workers, get personnel info
    let personnelData = null;
    if (user.role === 'worker') {
      const personnelQuery = await db.query(
        `SELECT p.id, p.name, p.role as personnel_role, p.phone, p.email, p.depot_id, d.name as depot_name
         FROM personnel p
         LEFT JOIN depots d ON p.depot_id = d.id
         WHERE p.user_id = $1`,
        [user.id]
      );
      if (personnelQuery.rows.length > 0) {
        personnelData = personnelQuery.rows[0];
      }
    }

    console.log(`🔐 User logged in: ${user.email || user.phone} (${user.id})`);

    // Return user data - format compatible with mobile app
    const responseData = {
        id: user.id,
        phone: user.phone,
        email: user.email,
        role: user.role,
        fullName: user.profile?.name || user.profile?.full_name || "User",
        address: user.profile?.address || "",
        latitude: user.profile?.latitude || null,
        longitude: user.profile?.longitude || null,
        isVerified: true,
        isActive: user.status === "active",
        createdAt: user.created_at,
        updatedAt: user.updated_at,
    };

    // Add worker-specific data if personnel exists
    if (personnelData) {
      responseData.workerId = personnelData.id;
      responseData.workerName = personnelData.name;
      responseData.workerRole = personnelData.personnel_role;
      responseData.depotId = personnelData.depot_id;
      responseData.depotName = personnelData.depot_name;
    }

    res.json({
      ok: true,
      data: responseData,
      message: "Login successful",
    });
  } catch (error) {
    console.error("[Auth] Login error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Register
app.post("/api/auth/register", async (req, res) => {
  try {
    const { phone, email, password, fullName } = req.body;

    if (!phone || !password) {
      return res.status(400).json({
        ok: false,
        error: "Phone and password are required",
      });
    }

    // Check if phone already exists
    const existing = await db.query("SELECT id FROM users WHERE phone = $1", [
      phone,
    ]);

    if (existing.rows.length > 0) {
      return res.status(409).json({
        ok: false,
        error: "Phone number already registered",
      });
    }

    // Create new user with UUID
    const { rows } = await db.query(
      `INSERT INTO users (id, phone, email, role, status, profile, password_hash)
       VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6)
       RETURNING id, phone, email, role, status, profile, created_at`,
      [
        phone,
        email || null,
        "citizen", // Default role
        "active",
        JSON.stringify({ name: fullName || "User" }),
        password, // TODO: Hash password in production
      ]
    );

    const user = rows[0];

    console.log(`👤 New user registered: ${user.phone} (${user.id})`);

    res.status(201).json({
      ok: true,
      data: {
        id: user.id,
        phone: user.phone,
        email: user.email,
        role: user.role,
        fullName: user.profile?.name || fullName || "User",
        isActive: true,
        createdAt: user.created_at,
      },
      message: "Registration successful",
    });
  } catch (error) {
    console.error("[Auth] Register error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Get current user profile
app.get("/api/auth/me", async (req, res) => {
  try {
    // TODO: Extract user ID from JWT token in Authorization header
    // For now, use query param
    const userId = req.query.user_id || req.headers["x-user-id"];

    if (!userId) {
      return res.status(401).json({
        ok: false,
        error: "User not authenticated",
      });
    }

    const { rows } = await db.query(
      `SELECT id, phone, email, role, status, profile, created_at, updated_at
       FROM users WHERE id = $1`,
      [userId]
    );

    if (rows.length === 0) {
      return res.status(404).json({
        ok: false,
        error: "User not found",
      });
    }

    const user = rows[0];

    res.json({
      ok: true,
      data: {
        id: user.id,
        phone: user.phone,
        email: user.email,
        role: user.role,
        fullName: user.profile?.name || user.profile?.full_name || "User",
        address: user.profile?.address || "",
        latitude: user.profile?.latitude || null,
        longitude: user.profile?.longitude || null,
        isVerified: true,
        isActive: user.status === "active",
        createdAt: user.created_at,
        updatedAt: user.updated_at,
      },
    });
  } catch (error) {
    console.error("[Auth] Get user error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// ==================== MANAGER API - PERSONNEL MANAGEMENT ====================
// GET /api/manager/personnel - Get all personnel
app.get('/api/manager/personnel', requireManager, async (req, res) => {
  try {
    const { role, status, depot_id } = req.query;
    
    let query = `
      SELECT 
        p.id,
        p.name,
        p.role as personnel_role,
        p.phone,
        p.email,
        p.status,
        p.depot_id,
        p.user_id,
        d.name as depot_name,
        u.email as user_email,
        u.phone as user_phone,
        p.certifications,
        p.hired_at,
        p.created_at,
        p.updated_at
      FROM personnel p
      LEFT JOIN depots d ON p.depot_id = d.id
      LEFT JOIN users u ON p.user_id = u.id
      WHERE 1=1
    `;
    const params = [];
    let paramCount = 1;
    
    if (role) {
      query += ` AND p.role = $${paramCount++}`;
      params.push(role);
    }
    if (status) {
      query += ` AND p.status = $${paramCount++}`;
      params.push(status);
    }
    if (depot_id) {
      query += ` AND p.depot_id = $${paramCount++}`;
      params.push(depot_id);
    }
    
    query += ` ORDER BY p.created_at DESC`;
    
    const { rows } = await db.query(query, params);
    
    res.json({
      ok: true,
      data: rows.map(row => ({
        id: row.id,
        name: row.name,
        role: row.personnel_role,
        phone: row.phone || row.user_phone,
        email: row.email || row.user_email,
        status: row.status,
        depotId: row.depot_id,
        depotName: row.depot_name,
        userId: row.user_id,
        certifications: row.certifications || [],
        hiredAt: row.hired_at,
        createdAt: row.created_at,
        updatedAt: row.updated_at,
      })),
    });
  } catch (error) {
    console.error('[Manager] Get personnel error:', error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// POST /api/manager/personnel - Create worker account
app.post('/api/manager/personnel', requireManager, async (req, res) => {
  try {
    const { name, phone, email, role, depot_id, certifications = [], password } = req.body;
    
    // Validation
    if (!name || !email || !password || !role || !depot_id) {
      return res.status(400).json({
        ok: false,
        error: 'Missing required fields: name, email, password, role, depot_id',
      });
    }
    
    // Validate role
    if (!['driver', 'collector'].includes(role)) {
      return res.status(400).json({
        ok: false,
        error: 'Invalid role. Must be driver or collector',
      });
    }
    
    // Validate email format
    if (!email.includes('@')) {
      return res.status(400).json({
        ok: false,
        error: 'Invalid email format',
      });
    }
    
    // Check if email already exists
    const existingEmail = await db.query('SELECT id FROM users WHERE email = $1', [email]);
    if (existingEmail.rows.length > 0) {
      return res.status(409).json({
        ok: false,
        error: 'Email already registered',
      });
    }
    
    // Check if phone already exists (if provided)
    if (phone) {
      const existingPhone = await db.query('SELECT id FROM users WHERE phone = $1', [phone]);
      if (existingPhone.rows.length > 0) {
        return res.status(409).json({
          ok: false,
          error: 'Phone number already registered',
        });
      }
    }
    
    // Check if depot exists
    const depotCheck = await db.query('SELECT id FROM depots WHERE id = $1', [depot_id]);
    if (depotCheck.rows.length === 0) {
      return res.status(404).json({
        ok: false,
        error: 'Depot not found',
      });
    }
    
    // Start transaction
    await db.query('BEGIN');
    
    try {
      // 1. Create user account with role='worker'
      const { rows: userRows } = await db.query(
        `INSERT INTO users (id, phone, email, role, status, profile, password_hash)
         VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6)
         RETURNING id, phone, email, role, status, created_at`,
        [
          phone || null,
          email,
          'worker', // User role
          'active',
          JSON.stringify({ name }),
          password, // TODO: Hash password with bcrypt in production
        ]
      );
      
      const user = userRows[0];
      
      // 2. Create personnel record
      const { rows: personnelRows } = await db.query(
        `INSERT INTO personnel (id, name, role, phone, email, certifications, status, depot_id, user_id)
         VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6, $7, $8)
         RETURNING id, name, role, phone, email, status, depot_id, user_id, created_at`,
        [
          name,
          role, // Personnel role: driver/collector
          phone || null,
          email,
          certifications,
          'active',
          depot_id,
          user.id,
        ]
      );
      
      await db.query('COMMIT');
      
      const personnel = personnelRows[0];
      
      console.log(`👷 New worker created: ${name} (${personnel.id}) - User: ${user.id}`);
      
      res.status(201).json({
        ok: true,
        data: {
          id: personnel.id,
          userId: user.id,
          name: personnel.name,
          phone: personnel.phone || user.phone,
          email: user.email,
          role: personnel.role,
          depotId: personnel.depot_id,
          status: personnel.status,
          certifications: personnel.certifications || [],
          credentials: {
            email: user.email,
            phone: user.phone,
            password: password, // Return for manager to share with worker
          },
          createdAt: personnel.created_at,
        },
        message: 'Worker account created successfully',
      });
    } catch (err) {
      await db.query('ROLLBACK');
      throw err;
    }
  } catch (error) {
    console.error('[Manager] Create personnel error:', error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// PUT /api/manager/personnel/:id - Update personnel
app.put('/api/manager/personnel/:id', requireManager, async (req, res) => {
  try {
    const { id } = req.params;
    const { name, phone, email, role, depot_id, status, certifications } = req.body;
    
    // Build update query dynamically
    const updates = [];
    const params = [];
    let paramCount = 1;
    
    if (name !== undefined) {
      updates.push(`name = $${paramCount++}`);
      params.push(name);
    }
    if (phone !== undefined) {
      updates.push(`phone = $${paramCount++}`);
      params.push(phone);
    }
    if (email !== undefined) {
      updates.push(`email = $${paramCount++}`);
      params.push(email);
    }
    if (role !== undefined) {
      updates.push(`role = $${paramCount++}`);
      params.push(role);
    }
    if (depot_id !== undefined) {
      updates.push(`depot_id = $${paramCount++}`);
      params.push(depot_id);
    }
    if (status !== undefined) {
      updates.push(`status = $${paramCount++}`);
      params.push(status);
    }
    if (certifications !== undefined) {
      updates.push(`certifications = $${paramCount++}`);
      params.push(certifications);
    }
    
    if (updates.length === 0) {
      return res.status(400).json({
        ok: false,
        error: 'No fields to update',
      });
    }
    
    updates.push(`updated_at = NOW()`);
    params.push(id);
    
    const query = `
      UPDATE personnel 
      SET ${updates.join(', ')}
      WHERE id = $${paramCount}
      RETURNING id, name, role, phone, email, status, depot_id, user_id, updated_at
    `;
    
    const { rows } = await db.query(query, params);
    
    if (rows.length === 0) {
      return res.status(404).json({
        ok: false,
        error: 'Personnel not found',
      });
    }
    
    // Also update user if email/phone changed
    if (email !== undefined || phone !== undefined) {
      const userUpdates = [];
      const userParams = [];
      let userParamCount = 1;
      
      if (email !== undefined) {
        userUpdates.push(`email = $${userParamCount++}`);
        userParams.push(email);
      }
      if (phone !== undefined) {
        userUpdates.push(`phone = $${userParamCount++}`);
        userParams.push(phone);
      }
      
      if (userUpdates.length > 0) {
        userParams.push(rows[0].user_id);
        await db.query(
          `UPDATE users SET ${userUpdates.join(', ')}, updated_at = NOW() WHERE id = $${userParamCount}`,
          userParams
        );
      }
    }
    
    res.json({
      ok: true,
      data: rows[0],
      message: 'Personnel updated successfully',
    });
  } catch (error) {
    console.error('[Manager] Update personnel error:', error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// DELETE /api/manager/personnel/:id - Delete personnel (soft delete)
app.delete('/api/manager/personnel/:id', requireManager, async (req, res) => {
  try {
    const { id } = req.params;
    
    // Soft delete: set status to inactive
    const { rows } = await db.query(
      `UPDATE personnel SET status = 'inactive', updated_at = NOW() WHERE id = $1 RETURNING id`,
      [id]
    );
    
    if (rows.length === 0) {
      return res.status(404).json({
        ok: false,
        error: 'Personnel not found',
      });
    }
    
    // Also deactivate user account
    const personnelData = await db.query('SELECT user_id FROM personnel WHERE id = $1', [id]);
    if (personnelData.rows.length > 0 && personnelData.rows[0].user_id) {
      await db.query(
        `UPDATE users SET status = 'inactive', updated_at = NOW() WHERE id = $1`,
        [personnelData.rows[0].user_id]
      );
    }
    
    res.json({
      ok: true,
      message: 'Personnel deactivated successfully',
    });
  } catch (error) {
    console.error('[Manager] Delete personnel error:', error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// ==================== GAMIFICATION API ====================
// Get user statistics (points, badges, rank)
app.get("/api/gamification/stats/:userId", async (req, res) => {
  try {
    const { userId } = req.params;

    // Get user points
    const pointsQuery = await db.query(
      `SELECT points, level, total_checkins, streak_days
       FROM user_points WHERE user_id = $1`,
      [userId]
    );

    const pointsData = pointsQuery.rows[0] || {
      points: 0,
      level: 1,
      total_checkins: 0,
      streak_days: 0,
    };

    // Determine rank tier based on level
    let rankTier = "Người mới";
    if (pointsData.level >= 10) rankTier = "Huyền thoại";
    else if (pointsData.level >= 7) rankTier = "Chuyên gia";
    else if (pointsData.level >= 5) rankTier = "Chiến binh xanh";
    else if (pointsData.level >= 3) rankTier = "Người tích cực";

    // Get user badges
    const badgesQuery = await db.query(
      `SELECT b.id, b.name, b.description, b.icon_url, b.points_reward, b.rarity,
              ub.earned_at IS NOT NULL as is_unlocked,
              ub.earned_at as unlocked_at
       FROM badges b
       LEFT JOIN user_badges ub ON b.id = ub.badge_id AND ub.user_id = $1
       WHERE b.active = true
       ORDER BY b.points_reward ASC`,
      [userId]
    );

    const badges = badgesQuery.rows.map((row) => ({
      id: row.id,
      name: row.name,
      description: row.description,
      icon: row.icon_url || "🏆",
      requiredPoints: row.points_reward,
      rarity: row.rarity,
      isUnlocked: row.is_unlocked,
      unlockedAt: row.unlocked_at,
    }));

    // Get user rank position
    const rankQuery = await db.query(
      `SELECT COUNT(*) + 1 as rank
       FROM user_points
       WHERE points > (SELECT points FROM user_points WHERE user_id = $1)`,
      [userId]
    );

    const rank = rankQuery.rows[0]?.rank || 1;

    res.json({
      ok: true,
      data: {
        totalPoints: pointsData.points,
        currentPoints: pointsData.points,
        level: pointsData.level,
        rankTier: rankTier,
        rank: rank,
        totalCheckins: pointsData.total_checkins,
        streakDays: pointsData.streak_days,
        badges: badges,
      },
    });
  } catch (error) {
    console.error("[Gamification] Get stats error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Get leaderboard
app.get("/api/gamification/leaderboard", async (req, res) => {
  try {
    const { period = "all", limit = 20 } = req.query;
    const currentUserId = req.query.user_id;

    // TODO: Implement period filtering (week, month, all)
    const { rows } = await db.query(
      `SELECT 
        u.id as user_id,
        u.profile->>'name' as user_name,
        u.profile->>'avatar_url' as avatar_url,
        up.points,
        up.level,
        ROW_NUMBER() OVER (ORDER BY up.points DESC) as rank
       FROM user_points up
       JOIN users u ON u.id = up.user_id
       WHERE u.status = 'active'
       ORDER BY up.points DESC
       LIMIT $1`,
      [limit]
    );

    const leaderboard = rows.map((row) => {
      let rankTier = "Người mới";
      if (row.level >= 10) rankTier = "Huyền thoại";
      else if (row.level >= 7) rankTier = "Chuyên gia";
      else if (row.level >= 5) rankTier = "Chiến binh xanh";
      else if (row.level >= 3) rankTier = "Người tích cực";

      return {
        userId: row.user_id,
        userName: row.user_name || "User",
        avatarUrl: row.avatar_url || null,
        points: row.points,
        level: row.level,
        rankTier: rankTier,
        rank: parseInt(row.rank),
        isCurrentUser: row.user_id === currentUserId,
      };
    });

    res.json({
      ok: true,
      data: leaderboard,
    });
  } catch (error) {
    console.error("[Gamification] Get leaderboard error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Get all badges
app.get("/api/gamification/badges", async (req, res) => {
  try {
    const { rows } = await db.query(
      `SELECT id, code, name, description, icon_url, points_reward, rarity
       FROM badges
       WHERE active = true
       ORDER BY points_reward ASC`
    );

    res.json({
      ok: true,
      data: rows,
    });
  } catch (error) {
    console.error("[Gamification] Get badges error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Claim reward (add points to user)
app.post("/api/gamification/claim-reward", async (req, res) => {
  try {
    const { userId, points, reason } = req.body;

    if (!userId || !points) {
      return res.status(400).json({
        ok: false,
        error: "userId and points are required",
      });
    }

    // Add points transaction
    await db.query(
      `INSERT INTO point_transactions (user_id, points, transaction_type, description)
       VALUES ($1, $2, $3, $4)`,
      [userId, points, "reward", reason || "Reward claimed"]
    );

    // Update user points
    const { rows } = await db.query(
      `UPDATE user_points
       SET points = points + $1,
           updated_at = NOW()
       WHERE user_id = $2
       RETURNING points, level`,
      [points, userId]
    );

    console.log(`🎁 Reward claimed: ${points} points for user ${userId}`);

    res.json({
      ok: true,
      data: {
        totalPoints: rows[0]?.points || 0,
        level: rows[0]?.level || 1,
        pointsAdded: points,
      },
      message: "Reward claimed successfully",
    });
  } catch (error) {
    console.error("[Gamification] Claim reward error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Scheduled tasks for data collection
cron.schedule("*/5 * * * *", () => {
  console.log("Running scheduled environmental data collection...");
  // TODO: Implement scheduled data collection from sensors
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: "Internal Server Error",
    message:
      process.env.NODE_ENV === "development"
        ? err.message
        : "Something went wrong",
  });
});

// 404 handler
app.use("*", (req, res) => {
  res.status(404).json({
    error: "Not Found",
    message: `Route ${req.originalUrl} not found`,
  });
});

// Start server (HTTP + Socket.IO)
server.listen(PORT, () => {
  console.log(`🚀 EcoCheck Backend started on port ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV || "development"}`);
});

module.exports = app;
