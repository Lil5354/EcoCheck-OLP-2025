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

// File upload configuration
const multer = require("multer");
const fs = require("fs");
const path = require("path");

// Create uploads directory if not exists
const uploadsDir = path.join(__dirname, "..", "public", "uploads");
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// Configure multer storage
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadsDir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    const ext = path.extname(file.originalname);
    cb(null, file.fieldname + "-" + uniqueSuffix + ext);
  },
});

// File filter for images only
const fileFilter = (req, file, cb) => {
  const allowedTypes = ["image/jpeg", "image/jpg", "image/png", "image/webp"];
  if (allowedTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(
      new Error("Invalid file type. Only JPEG, PNG and WebP are allowed."),
      false
    );
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB max file size
  },
});

// Static serve for uploaded files
app.use("/uploads", express.static(uploadsDir));

// Static serve for NGSI-LD contexts
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

// Image upload endpoint
app.post("/api/upload", upload.single("image"), (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: "No image file provided" });
    }

    // Generate public URL for the uploaded image
    const imageUrl = `${req.protocol}://${req.get("host")}/uploads/${
      req.file.filename
    }`;

    res.status(200).json({
      success: true,
      url: imageUrl,
      filename: req.file.filename,
      size: req.file.size,
      mimetype: req.file.mimetype,
    });
  } catch (error) {
    console.error("Upload error:", error);
    res.status(500).json({ error: error.message || "Upload failed" });
  }
});

// Multiple images upload endpoint
app.post("/api/upload/multiple", upload.array("images", 5), (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({ error: "No image files provided" });
    }

    const imageUrls = req.files.map((file) => ({
      url: `${req.protocol}://${req.get("host")}/uploads/${file.filename}`,
      filename: file.filename,
      size: file.size,
      mimetype: file.mimetype,
    }));

    res.status(200).json({
      success: true,
      images: imageUrls,
      count: imageUrls.length,
    });
  } catch (error) {
    console.error("Upload error:", error);
    res.status(500).json({ error: error.message || "Upload failed" });
  }
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
    const axios = require("axios");
    const response = await axios.get(`${orionUrl}/version`, {
      timeout: 4000,
    });
    res.json({ ok: true, data: response.data });
  } catch (e) {
    // Return success with offline status instead of error
    res.json({
      ok: false,
      error: e.message || "Orion-LD không khả dụng",
      data: {
        "orionld version": "N/A",
        uptime: "N/A",
      },
    });
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
  const { route_id, point_id, vehicle_id, image_url } = req.body;

  if (!route_id || !point_id || !vehicle_id) {
    return res
      .status(400)
      .json({ ok: false, error: "Missing route_id, point_id, or vehicle_id" });
  }

  // Validate that image_url is provided
  if (!image_url) {
    return res
      .status(400)
      .json({ ok: false, error: "Image is required for check-in" });
  }

  const result = store.recordCheckin(route_id, point_id, image_url);

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

app.get("/api/analytics/summary", async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Count active routes
    const activeRoutesResult = await db.query(
      `SELECT COUNT(*) as count FROM routes WHERE status IN ('in_progress', 'assigned')`
    );
    const routesActive = parseInt(activeRoutesResult.rows[0].count) || 0;

    // Calculate collection rate (completed schedules vs total schedules today)
    const scheduleStats = await db.query(
      `SELECT 
        COUNT(*) FILTER (WHERE status = 'completed') as completed,
        COUNT(*) as total
      FROM schedules 
      WHERE DATE(scheduled_date) = DATE($1)`,
      [today]
    );
    const collectionRate =
      scheduleStats.rows[0].total > 0
        ? parseFloat(scheduleStats.rows[0].completed) /
          parseFloat(scheduleStats.rows[0].total)
        : 0;

    // Calculate total weight collected today
    const todayWeight = await db.query(
      `SELECT COALESCE(SUM(actual_weight), 0) as total
      FROM schedules
      WHERE DATE(completed_at) = DATE($1) AND status = 'completed'`,
      [today]
    );
    const todayTons = parseFloat(todayWeight.rows[0].total) / 1000 || 0;

    // Calculate total weight all time
    const totalWeight = await db.query(
      `SELECT COALESCE(SUM(actual_weight), 0) as total
      FROM schedules WHERE status = 'completed'`
    );
    const totalTons = parseFloat(totalWeight.rows[0].total) / 1000 || 0;

    // Count completed check-ins
    const completedCheckins = await db.query(
      `SELECT COUNT(*) as count FROM checkins`
    );
    const completed = parseInt(completedCheckins.rows[0].count) || 0;

    // Calculate waste by type (percentage)
    const wasteByType = await db.query(
      `SELECT 
        waste_type,
        COUNT(*) as count
      FROM schedules
      WHERE status = 'completed'
      GROUP BY waste_type`
    );
    const total = wasteByType.rows.reduce(
      (sum, row) => sum + parseInt(row.count),
      0
    );
    const byType = {};
    wasteByType.rows.forEach((row) => {
      byType[row.waste_type] =
        total > 0 ? Math.round((parseInt(row.count) / total) * 100) : 0;
    });

    res.json({
      ok: true,
      data: {
        routesActive,
        collectionRate: parseFloat(collectionRate.toFixed(2)),
        todayTons: parseFloat(todayTons.toFixed(1)),
        totalTons: parseFloat(totalTons.toFixed(1)),
        completed,
        fuelSaving: 0.09,
        byType: byType,
      },
      // Also return flat for backward compatibility
      routesActive,
      collectionRate: parseFloat(collectionRate.toFixed(2)),
      todayTons: parseFloat(todayTons.toFixed(1)),
      totalTons: parseFloat(totalTons.toFixed(1)),
      completed,
      fuelSaving: 0.09,
      byType: byType,
    });
  } catch (error) {
    console.error("[Analytics] Summary error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// ==================== MASTER DATA - FLEET API ====================
// Get all vehicles
app.get("/api/master/fleet", async (req, res) => {
  try {
    const { status, type, depot_id } = req.query;

    let query = `
      SELECT 
        v.id,
        v.plate,
        v.type,
        v.capacity_kg as capacity,
        v.accepted_types as types,
        v.status,
        v.depot_id,
        v.fuel_type,
        v.current_load_kg,
        v.last_maintenance_at,
        d.name as depot_name,
        v.created_at,
        v.updated_at
      FROM vehicles v
      LEFT JOIN depots d ON v.depot_id = d.id
      WHERE 1=1
    `;
    const params = [];
    let paramIndex = 1;

    if (status) {
      query += ` AND v.status = $${paramIndex++}`;
      params.push(status);
    }

    if (type) {
      query += ` AND v.type = $${paramIndex++}`;
      params.push(type);
    }

    if (depot_id) {
      query += ` AND v.depot_id = $${paramIndex++}`;
      params.push(depot_id);
    }

    query += ` ORDER BY v.created_at DESC`;

    const { rows } = await db.query(query, params);

    // Map database fields to frontend format
    const fleet = rows.map((row) => ({
      id: row.id,
      plate: row.plate,
      type: row.type,
      capacity: row.capacity,
      types: row.types || [],
      status:
        row.status === "available"
          ? "ready"
          : row.status === "in_use"
          ? "in_use"
          : row.status,
      depot_id: row.depot_id,
      depot_name: row.depot_name,
      fuel_type: row.fuel_type,
      current_load_kg: row.current_load_kg,
      last_maintenance_at: row.last_maintenance_at,
      created_at: row.created_at,
      updated_at: row.updated_at,
    }));

    res.json({ ok: true, data: fleet });
  } catch (error) {
    console.error("[Fleet] Get error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Create new vehicle
app.post("/api/master/fleet", async (req, res) => {
  try {
    const { plate, type, capacity, types, status, depot_id, fuel_type } =
      req.body;

    if (!plate || !type || !capacity) {
      return res.status(400).json({
        ok: false,
        error: "Missing required fields: plate, type, capacity",
      });
    }

    // Validate vehicle type
    const validTypes = [
      "compactor",
      "mini-truck",
      "electric-trike",
      "specialized",
    ];
    if (!validTypes.includes(type)) {
      return res.status(400).json({
        ok: false,
        error: `Invalid type. Must be one of: ${validTypes.join(", ")}`,
      });
    }

    // Check if plate already exists
    const existing = await db.query(
      "SELECT id FROM vehicles WHERE plate = $1",
      [plate]
    );
    if (existing.rows.length > 0) {
      return res.status(409).json({
        ok: false,
        error: "Vehicle with this plate number already exists",
      });
    }

    // Generate vehicle ID
    const vehicleId = `VH${Date.now().toString().slice(-6)}`;

    const { rows } = await db.query(
      `INSERT INTO vehicles (
        id, plate, type, capacity_kg, accepted_types, status, depot_id, fuel_type, created_at, updated_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW(), NOW())
      RETURNING *`,
      [
        vehicleId,
        plate,
        type,
        capacity,
        types || [],
        status || "available",
        depot_id || null,
        fuel_type || "diesel",
      ]
    );

    console.log(`✅ Vehicle created: ${vehicleId} (${plate})`);

    res.status(201).json({
      ok: true,
      data: {
        id: rows[0].id,
        plate: rows[0].plate,
        type: rows[0].type,
        capacity: rows[0].capacity_kg,
        types: rows[0].accepted_types || [],
        status: rows[0].status,
        depot_id: rows[0].depot_id,
        fuel_type: rows[0].fuel_type,
      },
      message: "Vehicle created successfully",
    });
  } catch (error) {
    console.error("[Fleet] Create error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Update vehicle
app.patch("/api/master/fleet/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { plate, type, capacity, types, status, depot_id, fuel_type } =
      req.body;

    const updates = [];
    const params = [];
    let paramIndex = 1;

    if (plate !== undefined) {
      // Check if new plate already exists (excluding current vehicle)
      const existing = await db.query(
        "SELECT id FROM vehicles WHERE plate = $1 AND id != $2",
        [plate, id]
      );
      if (existing.rows.length > 0) {
        return res.status(409).json({
          ok: false,
          error: "Vehicle with this plate number already exists",
        });
      }
      updates.push(`plate = $${paramIndex++}`);
      params.push(plate);
    }

    if (type !== undefined) {
      updates.push(`type = $${paramIndex++}`);
      params.push(type);
    }

    if (capacity !== undefined) {
      updates.push(`capacity_kg = $${paramIndex++}`);
      params.push(capacity);
    }

    if (types !== undefined) {
      updates.push(`accepted_types = $${paramIndex++}`);
      params.push(types);
    }

    if (status !== undefined) {
      updates.push(`status = $${paramIndex++}`);
      params.push(status);
    }

    if (depot_id !== undefined) {
      updates.push(`depot_id = $${paramIndex++}`);
      params.push(depot_id);
    }

    if (fuel_type !== undefined) {
      updates.push(`fuel_type = $${paramIndex++}`);
      params.push(fuel_type);
    }

    if (updates.length === 0) {
      return res.status(400).json({ ok: false, error: "No fields to update" });
    }

    updates.push(`updated_at = NOW()`);
    params.push(id);

    const query = `UPDATE vehicles SET ${updates.join(
      ", "
    )} WHERE id = $${paramIndex} RETURNING *`;
    const { rows } = await db.query(query, params);

    if (rows.length === 0) {
      return res.status(404).json({ ok: false, error: "Vehicle not found" });
    }

    console.log(`✅ Vehicle updated: ${id}`);

    res.json({
      ok: true,
      data: {
        id: rows[0].id,
        plate: rows[0].plate,
        type: rows[0].type,
        capacity: rows[0].capacity_kg,
        types: rows[0].accepted_types || [],
        status: rows[0].status,
        depot_id: rows[0].depot_id,
        fuel_type: rows[0].fuel_type,
      },
      message: "Vehicle updated successfully",
    });
  } catch (error) {
    console.error("[Fleet] Update error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Delete vehicle
app.delete("/api/master/fleet/:id", async (req, res) => {
  try {
    const { id } = req.params;

    const { rows } = await db.query(
      "DELETE FROM vehicles WHERE id = $1 RETURNING *",
      [id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ ok: false, error: "Vehicle not found" });
    }

    console.log(`🗑️ Vehicle deleted: ${id}`);

    res.json({
      ok: true,
      message: "Vehicle deleted successfully",
    });
  } catch (error) {
    console.error("[Fleet] Delete error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// ==================== MASTER DATA - DEPOTS API ====================
// Get all depots
app.get("/api/master/depots", async (req, res) => {
  try {
    const { status } = req.query;

    let query = `
      SELECT 
        id,
        name,
        ST_X(geom::geometry) as lon,
        ST_Y(geom::geometry) as lat,
        address,
        capacity_vehicles,
        opening_hours,
        status,
        meta,
        created_at,
        updated_at
      FROM depots
      WHERE 1=1
    `;
    const params = [];
    let paramIndex = 1;

    if (status) {
      query += ` AND status = $${paramIndex++}`;
      params.push(status);
    }

    query += ` ORDER BY created_at DESC`;

    const { rows } = await db.query(query, params);

    res.json({ ok: true, data: rows });
  } catch (error) {
    console.error("[Depots] Get error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Create new depot
app.post("/api/master/depots", async (req, res) => {
  try {
    const {
      name,
      lon,
      lat,
      address,
      capacity_vehicles,
      opening_hours,
      status,
    } = req.body;

    if (!name || lon === undefined || lat === undefined) {
      return res.status(400).json({
        ok: false,
        error: "Missing required fields: name, lon, lat",
      });
    }

    const { v4: uuidv4 } = require("uuid");
    const depotId = uuidv4();

    const { rows } = await db.query(
      `INSERT INTO depots (
        id, name, geom, address, capacity_vehicles, opening_hours, status, created_at, updated_at
      ) VALUES ($1, $2, ST_SetSRID(ST_MakePoint($3, $4), 4326), $5, $6, $7, $8, NOW(), NOW())
      RETURNING 
        id,
        name,
        ST_X(geom::geometry) as lon,
        ST_Y(geom::geometry) as lat,
        address,
        capacity_vehicles,
        opening_hours,
        status,
        created_at,
        updated_at`,
      [
        depotId,
        name,
        lon,
        lat,
        address || null,
        capacity_vehicles || 10,
        opening_hours || "18:00-06:00",
        status || "active",
      ]
    );

    console.log(`✅ Depot created: ${depotId} (${name})`);

    res.status(201).json({
      ok: true,
      data: rows[0],
      message: "Depot created successfully",
    });
  } catch (error) {
    console.error("[Depots] Create error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Update depot
app.patch("/api/master/depots/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const {
      name,
      lon,
      lat,
      address,
      capacity_vehicles,
      opening_hours,
      status,
    } = req.body;

    const updates = [];
    const params = [];
    let paramIndex = 1;

    if (name !== undefined) {
      updates.push(`name = $${paramIndex++}`);
      params.push(name);
    }

    if (lon !== undefined && lat !== undefined) {
      updates.push(
        `geom = ST_SetSRID(ST_MakePoint($${paramIndex}, $${
          paramIndex + 1
        }), 4326)`
      );
      params.push(lon, lat);
      paramIndex += 2;
    }

    if (address !== undefined) {
      updates.push(`address = $${paramIndex++}`);
      params.push(address);
    }

    if (capacity_vehicles !== undefined) {
      updates.push(`capacity_vehicles = $${paramIndex++}`);
      params.push(capacity_vehicles);
    }

    if (opening_hours !== undefined) {
      updates.push(`opening_hours = $${paramIndex++}`);
      params.push(opening_hours);
    }

    if (status !== undefined) {
      updates.push(`status = $${paramIndex++}`);
      params.push(status);
    }

    if (updates.length === 0) {
      return res.status(400).json({ ok: false, error: "No fields to update" });
    }

    updates.push(`updated_at = NOW()`);
    params.push(id);

    const query = `UPDATE depots SET ${updates.join(
      ", "
    )} WHERE id = $${paramIndex} 
      RETURNING 
        id,
        name,
        ST_X(geom::geometry) as lon,
        ST_Y(geom::geometry) as lat,
        address,
        capacity_vehicles,
        opening_hours,
        status,
        created_at,
        updated_at`;
    const { rows } = await db.query(query, params);

    if (rows.length === 0) {
      return res.status(404).json({ ok: false, error: "Depot not found" });
    }

    console.log(`✅ Depot updated: ${id}`);

    res.json({
      ok: true,
      data: rows[0],
      message: "Depot updated successfully",
    });
  } catch (error) {
    console.error("[Depots] Update error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Delete depot
app.delete("/api/master/depots/:id", async (req, res) => {
  try {
    const { id } = req.params;

    const { rows } = await db.query(
      "DELETE FROM depots WHERE id = $1 RETURNING *",
      [id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ ok: false, error: "Depot not found" });
    }

    console.log(`🗑️ Depot deleted: ${id}`);

    res.json({
      ok: true,
      message: "Depot deleted successfully",
    });
  } catch (error) {
    console.error("[Depots] Delete error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// ==================== MASTER DATA - DUMPS API ====================
// Get all dumps
app.get("/api/master/dumps", async (req, res) => {
  try {
    const { status } = req.query;

    let query = `
      SELECT 
        id,
        name,
        ST_X(geom::geometry) as lon,
        ST_Y(geom::geometry) as lat,
        address,
        accepted_waste_types,
        capacity_tons,
        opening_hours,
        status,
        meta,
        created_at,
        updated_at
      FROM dumps
      WHERE 1=1
    `;
    const params = [];
    let paramIndex = 1;

    if (status) {
      query += ` AND status = $${paramIndex++}`;
      params.push(status);
    }

    query += ` ORDER BY created_at DESC`;

    const { rows } = await db.query(query, params);

    res.json({ ok: true, data: rows });
  } catch (error) {
    console.error("[Dumps] Get error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Create new dump
app.post("/api/master/dumps", async (req, res) => {
  try {
    const {
      name,
      lon,
      lat,
      address,
      accepted_waste_types,
      capacity_tons,
      opening_hours,
      status,
    } = req.body;

    if (!name || lon === undefined || lat === undefined) {
      return res.status(400).json({
        ok: false,
        error: "Missing required fields: name, lon, lat",
      });
    }

    const { v4: uuidv4 } = require("uuid");
    const dumpId = uuidv4();

    const { rows } = await db.query(
      `INSERT INTO dumps (
        id, name, geom, address, accepted_waste_types, capacity_tons, opening_hours, status, created_at, updated_at
      ) VALUES ($1, $2, ST_SetSRID(ST_MakePoint($3, $4), 4326), $5, $6, $7, $8, $9, NOW(), NOW())
      RETURNING 
        id,
        name,
        ST_X(geom::geometry) as lon,
        ST_Y(geom::geometry) as lat,
        address,
        accepted_waste_types,
        capacity_tons,
        opening_hours,
        status,
        created_at,
        updated_at`,
      [
        dumpId,
        name,
        lon,
        lat,
        address || null,
        accepted_waste_types || ["household", "recyclable", "bulky"],
        capacity_tons || null,
        opening_hours || "18:00-06:00",
        status || "active",
      ]
    );

    console.log(`✅ Dump created: ${dumpId} (${name})`);

    res.status(201).json({
      ok: true,
      data: rows[0],
      message: "Dump created successfully",
    });
  } catch (error) {
    console.error("[Dumps] Create error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Update dump
app.patch("/api/master/dumps/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const {
      name,
      lon,
      lat,
      address,
      accepted_waste_types,
      capacity_tons,
      opening_hours,
      status,
    } = req.body;

    const updates = [];
    const params = [];
    let paramIndex = 1;

    if (name !== undefined) {
      updates.push(`name = $${paramIndex++}`);
      params.push(name);
    }

    if (lon !== undefined && lat !== undefined) {
      updates.push(
        `geom = ST_SetSRID(ST_MakePoint($${paramIndex}, $${
          paramIndex + 1
        }), 4326)`
      );
      params.push(lon, lat);
      paramIndex += 2;
    }

    if (address !== undefined) {
      updates.push(`address = $${paramIndex++}`);
      params.push(address);
    }

    if (accepted_waste_types !== undefined) {
      updates.push(`accepted_waste_types = $${paramIndex++}`);
      params.push(accepted_waste_types);
    }

    if (capacity_tons !== undefined) {
      updates.push(`capacity_tons = $${paramIndex++}`);
      params.push(capacity_tons);
    }

    if (opening_hours !== undefined) {
      updates.push(`opening_hours = $${paramIndex++}`);
      params.push(opening_hours);
    }

    if (status !== undefined) {
      updates.push(`status = $${paramIndex++}`);
      params.push(status);
    }

    if (updates.length === 0) {
      return res.status(400).json({ ok: false, error: "No fields to update" });
    }

    updates.push(`updated_at = NOW()`);
    params.push(id);

    const query = `UPDATE dumps SET ${updates.join(
      ", "
    )} WHERE id = $${paramIndex} 
      RETURNING 
        id,
        name,
        ST_X(geom::geometry) as lon,
        ST_Y(geom::geometry) as lat,
        address,
        accepted_waste_types,
        capacity_tons,
        opening_hours,
        status,
        created_at,
        updated_at`;
    const { rows } = await db.query(query, params);

    if (rows.length === 0) {
      return res.status(404).json({ ok: false, error: "Dump not found" });
    }

    console.log(`✅ Dump updated: ${id}`);

    res.json({
      ok: true,
      data: rows[0],
      message: "Dump updated successfully",
    });
  } catch (error) {
    console.error("[Dumps] Update error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Delete dump
app.delete("/api/master/dumps/:id", async (req, res) => {
  try {
    const { id } = req.params;

    const { rows } = await db.query(
      "DELETE FROM dumps WHERE id = $1 RETURNING *",
      [id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ ok: false, error: "Dump not found" });
    }

    console.log(`🗑️ Dump deleted: ${id}`);

    res.json({
      ok: true,
      message: "Dump deleted successfully",
    });
  } catch (error) {
    console.error("[Dumps] Delete error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Collection points endpoint
app.get("/api/points", async (req, res) => {
  try {
    const { type, status } = req.query;

    let query = `
      SELECT 
        p.id,
        COALESCE(p.last_waste_type, 'household') as type,
        ST_Y(p.geom::geometry) as lat,
        ST_X(p.geom::geometry) as lon,
        CASE WHEN p.ghost THEN 'grey' ELSE 'active' END as status,
        p.address_id,
        ua.address_text as address,
        ua.label,
        COALESCE(p.total_checkins, 0) as demand
      FROM points p
      LEFT JOIN user_addresses ua ON p.address_id = ua.id
      WHERE 1=1
    `;
    const params = [];
    let paramIndex = 1;

    if (type) {
      query += ` AND p.last_waste_type = $${paramIndex++}`;
      params.push(type);
    }

    if (status) {
      if (status === "grey") {
        query += ` AND p.ghost = true`;
      } else if (status === "active") {
        query += ` AND p.ghost = false`;
      }
    }

    query += ` ORDER BY p.last_checkin_at DESC NULLS LAST
              LIMIT 500`;

    const { rows } = await db.query(query, params);

    const points = rows.map((row) => ({
      id: row.id,
      type: row.type,
      lat: parseFloat(row.lat),
      lon: parseFloat(row.lon),
      demand: parseInt(row.demand) || 0,
      status: row.status,
      address: row.address,
      label: row.label,
    }));

    res.json({ ok: true, data: points });
  } catch (error) {
    console.error("[Points] Get error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Helper function to get route from OSRM (Open Source Routing Machine)
async function getOSRMRoute(waypoints) {
  try {
    if (!waypoints || waypoints.length < 2) {
      return null;
    }

    // Build OSRM API URL
    // Using public OSRM demo server (for production, use your own OSRM instance)
    const coordinates = waypoints.map((wp) => `${wp[0]},${wp[1]}`).join(";");
    const url = `https://router.project-osrm.org/route/v1/driving/${coordinates}?overview=full&geometries=geojson`;

    const axios = require("axios");
    const response = await axios.get(url, {
      timeout: 10000,
      headers: {
        "User-Agent": "EcoCheck-Backend/1.0",
      },
    });

    if (
      response.data &&
      response.data.code === "Ok" &&
      response.data.routes &&
      response.data.routes.length > 0
    ) {
      const route = response.data.routes[0];
      return {
        geometry: route.geometry,
        distance: route.distance,
        duration: route.duration,
      };
    }
    return null;
  } catch (error) {
    console.warn(`[OSRM] Route calculation failed: ${error.message}`);
    return null;
  }
}

// ==================== VRP OPTIMIZATION API ====================
// VRP optimization endpoint
app.post("/api/vrp/optimize", async (req, res) => {
  try {
    const { vehicles = [], points = [], depot, dump, timeWindow } = req.body;

    if (!vehicles || vehicles.length === 0) {
      return res.status(400).json({
        ok: false,
        error: "At least one vehicle is required",
      });
    }

    if (!points || points.length === 0) {
      return res.status(400).json({
        ok: false,
        error: "At least one point is required",
      });
    }

    // Simple VRP algorithm: distribute points evenly among vehicles
    // In production, use a proper VRP solver (OR-Tools, VROOM, etc.)
    const pointsPerVehicle = Math.ceil(points.length / vehicles.length);
    const routes = [];

    for (let i = 0; i < vehicles.length; i++) {
      const vehicle = vehicles[i];
      const startIdx = i * pointsPerVehicle;
      const endIdx = Math.min(startIdx + pointsPerVehicle, points.length);
      const vehiclePoints = points.slice(startIdx, endIdx);

      if (vehiclePoints.length === 0) continue;

      // Build waypoints: depot -> points -> dump
      const waypoints = [];
      if (depot) {
        waypoints.push([depot.lon, depot.lat]);
      }
      vehiclePoints.forEach((p) => {
        waypoints.push([p.lon, p.lat]);
      });
      if (dump) {
        waypoints.push([dump.lon, dump.lat]);
      }

      // Get route from OSRM (road network routing)
      let routeGeometry = null;
      let totalDistance = 0;
      let totalDuration = 0;

      try {
        const osrmRoute = await getOSRMRoute(waypoints);
        if (osrmRoute) {
          routeGeometry = osrmRoute.geometry;
          totalDistance = Math.round(osrmRoute.distance);
          totalDuration = Math.round(osrmRoute.duration);
        } else {
          // Fallback to straight line if OSRM fails
          console.warn(
            `[VRP] OSRM failed for vehicle ${vehicle.id}, using straight line`
          );
          routeGeometry = {
            type: "LineString",
            coordinates: waypoints,
          };
          // Calculate haversine distance as fallback
          for (let j = 1; j < waypoints.length; j++) {
            totalDistance += getHaversineDistance(
              { lat: waypoints[j - 1][1], lon: waypoints[j - 1][0] },
              { lat: waypoints[j][1], lon: waypoints[j][0] }
            );
          }
          totalDistance = Math.round(totalDistance);
          totalDuration = Math.round(totalDistance / 8.33); // Assume 30 km/h = 8.33 m/s
        }
      } catch (error) {
        console.warn(
          `[VRP] Route calculation error for vehicle ${vehicle.id}:`,
          error.message
        );
        // Fallback to straight line
        routeGeometry = {
          type: "LineString",
          coordinates: waypoints,
        };
        for (let j = 1; j < waypoints.length; j++) {
          totalDistance += getHaversineDistance(
            { lat: waypoints[j - 1][1], lon: waypoints[j - 1][0] },
            { lat: waypoints[j][1], lon: waypoints[j][0] }
          );
        }
        totalDistance = Math.round(totalDistance);
        totalDuration = Math.round(totalDistance / 8.33);
      }

      // Estimate ETA from duration (in seconds)
      const hours = Math.floor(totalDuration / 3600);
      const minutes = Math.round((totalDuration % 3600) / 60);
      const eta = `${hours}:${minutes.toString().padStart(2, "0")}`;

      routes.push({
        vehicleId: vehicle.id,
        vehiclePlate: vehicle.plate,
        distance: totalDistance,
        eta: eta,
        geojson: {
          type: "FeatureCollection",
          features: [
            {
              type: "Feature",
              geometry: routeGeometry,
              properties: {
                vehicleId: vehicle.id,
                vehiclePlate: vehicle.plate,
              },
            },
          ],
        },
        stops: vehiclePoints.map((p, idx) => ({
          id: p.id,
          seq: idx + 1,
          lat: p.lat,
          lon: p.lon,
        })),
        depot: depot ? { lat: depot.lat, lon: depot.lon } : null,
        dump: dump ? { lat: dump.lat, lon: dump.lon } : null,
      });
    }

    console.log(
      `✅ VRP optimization completed: ${routes.length} routes for ${vehicles.length} vehicles`
    );

    res.json({ ok: true, data: { routes } });
  } catch (error) {
    console.error("[VRP] Optimize error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Save optimized routes to database
app.post("/api/vrp/save-routes", async (req, res) => {
  try {
    const { routes } = req.body;

    if (!routes || !Array.isArray(routes) || routes.length === 0) {
      return res.status(400).json({
        ok: false,
        error: "Routes array is required",
      });
    }

    const { v4: uuidv4 } = require("uuid");
    const savedRoutes = [];

    for (const routeData of routes) {
      const routeId = uuidv4();
      const now = new Date();

      // Create route
      await db.query(
        `INSERT INTO routes (id, vehicle_id, start_at, status, meta)
         VALUES ($1, $2, $3, $4, $5)`,
        [
          routeId,
          routeData.vehicleId,
          now,
          "pending",
          JSON.stringify({
            optimized: true,
            distance: routeData.distance,
            eta: routeData.eta,
            geojson: routeData.geojson,
          }),
        ]
      );

      // Create route stops
      if (routeData.stops && Array.isArray(routeData.stops)) {
        for (let i = 0; i < routeData.stops.length; i++) {
          const stop = routeData.stops[i];
          const stopId = uuidv4();

          // Get point_id from points table if stop.id is a point identifier
          // For now, assume stop.id is already a valid point_id
          await db.query(
            `INSERT INTO route_stops (id, route_id, point_id, seq, status, planned_eta)
             VALUES ($1, $2, $3, $4, $5, $6)`,
            [stopId, routeId, stop.id, stop.seq || i + 1, "pending", now]
          );
        }
      }

      savedRoutes.push({
        route_id: routeId,
        vehicle_id: routeData.vehicleId,
        stops_count: routeData.stops?.length || 0,
      });
    }

    console.log(`✅ Saved ${savedRoutes.length} optimized routes to database`);

    res.json({
      ok: true,
      data: {
        routes: savedRoutes,
        message: `${savedRoutes.length} routes saved successfully`,
      },
    });
  } catch (error) {
    console.error("[VRP] Save routes error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Dispatch endpoints
app.post("/api/dispatch/send-routes", async (req, res) => {
  try {
    const { routes } = req.body;

    if (!routes || !Array.isArray(routes) || routes.length === 0) {
      return res.status(400).json({
        ok: false,
        error: "Routes array is required",
      });
    }

    // Update route status to 'assigned' or 'in_progress'
    // This marks routes as dispatched to drivers
    for (const route of routes) {
      if (route.route_id) {
        await db.query(
          `UPDATE routes SET status = 'assigned', updated_at = NOW() WHERE id = $1`,
          [route.route_id]
        );
      }
    }

    console.log(`✅ Dispatched ${routes.length} routes to drivers`);

    res.json({
      ok: true,
      data: { message: `${routes.length} routes dispatched successfully` },
    });
  } catch (error) {
    console.error("[Dispatch] Send routes error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
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
         a.alert_id, a.alert_type, a.severity, a.status, a.created_at,
         a.point_id, 
         COALESCE(ua.address_text, ua.label, a.point_id::text, 'N/A') as point_name,
         COALESCE(ua.address_text, ua.label) as location_address,
         a.vehicle_id, v.plate as license_plate,
         a.route_id,
         a.details
       FROM alerts a
       LEFT JOIN vehicles v ON a.vehicle_id = v.id
       LEFT JOIN points p ON a.point_id = p.id
       LEFT JOIN user_addresses ua ON p.address_id = ua.id
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

    // 2. Get all currently active vehicles from the in-memory store
    const activeVehicles = store.getVehicles();

    if (activeVehicles.length === 0) {
      return res.json({
        ok: true,
        data: [],
        message: "No active vehicles available",
      });
    }

    // 3. Calculate the distance to the missed point for each vehicle
    const vehiclesWithDistance = activeVehicles.map((v) => ({
      ...v,
      distance: getHaversineDistance(
        { lat: alertData.lat, lon: alertData.lon },
        { lat: v.lat, lon: v.lon }
      ),
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
    // Parse alertId to integer (alert_id is SERIAL/INTEGER)
    const alertIdInt = parseInt(alertId, 10);
    if (isNaN(alertIdInt)) {
      return res
        .status(400)
        .json({ ok: false, error: "Invalid alert ID format" });
    }

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
      [alertIdInt]
    );

    if (alertResult.rows.length === 0) {
      return res
        .status(404)
        .json({ ok: false, error: "Alert not found or already processed" });
    }

    const alert = alertResult.rows[0];

    // 2. Check if vehicle exists in database, if not, create it for mock vehicles (V01, V02, etc.)
    const vehicleCheck = await db.query(
      "SELECT id FROM vehicles WHERE id = $1",
      [vehicle_id]
    );

    // If vehicle doesn't exist in DB but is a mock vehicle (V01-V99), create it
    const isMockVehicle =
      vehicleCheck.rows.length === 0 && /^V\d{2}$/.test(vehicle_id);

    if (isMockVehicle) {
      // Create mock vehicle in database to satisfy foreign key constraint
      try {
        const insertResult = await db.query(
          `INSERT INTO vehicles (id, plate, type, capacity_kg, accepted_types, status)
           VALUES ($1, $2, $3, $4, $5, $6)
           ON CONFLICT (id) DO UPDATE SET status = EXCLUDED.status
           RETURNING id`,
          [
            vehicle_id,
            vehicle_id, // Use ID as plate for mock vehicles
            "compactor",
            5000,
            ARRAY[("household", "recyclable")],
            "in_use",
          ]
        );
        if (insertResult.rows.length > 0) {
          console.log(
            `✅ Created/updated mock vehicle ${vehicle_id} in database`
          );
        }
      } catch (err) {
        console.error(`❌ Failed to create mock vehicle ${vehicle_id}:`, err);
        return res.status(500).json({
          ok: false,
          error: `Failed to create vehicle: ${err.message}`,
        });
      }
    } else if (vehicleCheck.rows.length === 0) {
      return res.status(400).json({
        ok: false,
        error: `Vehicle ${vehicle_id} not found in database`,
      });
    }

    // 3. Create a new route in the database for the re-routing
    const { v4: uuidv4 } = require("uuid");
    const newRouteId = uuidv4();
    const now = new Date();

    await db.query(
      `INSERT INTO routes (id, vehicle_id, start_at, status, meta)
       VALUES ($1, $2, $3, $4, $5)`,
      [
        newRouteId,
        vehicle_id,
        now,
        "in_progress",
        JSON.stringify({
          type: "incident_response",
          original_alert_id: alertIdInt,
          original_route_id: alert.original_route_id,
          created_by: "dynamic_dispatch",
          is_mock_vehicle: isMockVehicle,
        }),
      ]
    );

    // 4. Add the incident point as a route stop
    const stopId = uuidv4();
    await db.query(
      `INSERT INTO route_stops (id, route_id, point_id, seq, status, planned_eta)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [stopId, newRouteId, alert.point_id, 1, "pending", now]
    );

    // 5. Update alert status to 'acknowledged'
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
       WHERE alert_id = $4`,
      [vehicle_id, now.toISOString(), newRouteId, alertIdInt]
    );

    // 6. Start the route in the in-memory store
    store.startRoute(newRouteId, vehicle_id, [
      {
        point_id: alert.point_id,
        lat: alert.lat,
        lon: alert.lon,
      },
    ]);

    console.log(
      `✅ Alert ${alertIdInt} assigned to vehicle ${vehicle_id}, new route ${newRouteId} created`
    );

    res.json({
      ok: true,
      data: {
        message: "Vehicle assigned successfully",
        route_id: newRouteId,
        vehicle_id: vehicle_id,
        alert_id: alertIdInt,
      },
    });
  } catch (err) {
    console.error(`Error assigning vehicle to alert ${alertId}:`, err);
    res
      .status(500)
      .json({ ok: false, error: err.message || "Failed to assign vehicle" });
  }
});

// Analytics endpoints
app.get("/api/analytics/timeseries", async (req, res) => {
  try {
    const now = new Date();

    // Get weight collected per hour for last 24 hours
    const timeseries = await db.query(
      `SELECT 
        DATE_TRUNC('hour', completed_at) as hour,
        COALESCE(SUM(actual_weight), 0) as total_weight
      FROM schedules
      WHERE completed_at >= NOW() - INTERVAL '24 hours'
        AND status = 'completed'
      GROUP BY hour
      ORDER BY hour ASC`
    );

    // Fill in missing hours with 0
    const series = [];
    for (let i = 23; i >= 0; i--) {
      const hourTime = new Date(now.getTime() - i * 3600000);
      hourTime.setMinutes(0, 0, 0);

      const dataPoint = timeseries.rows.find((row) => {
        const rowHour = new Date(row.hour);
        return rowHour.getTime() === hourTime.getTime();
      });

      series.push({
        t: hourTime.toISOString(),
        value: dataPoint ? Math.round(parseFloat(dataPoint.total_weight)) : 0,
      });
    }

    // Get waste distribution by type
    const wasteByType = await db.query(
      `SELECT 
        waste_type,
        COUNT(*) as count
      FROM schedules
      WHERE status = 'completed'
      GROUP BY waste_type`
    );
    const total = wasteByType.rows.reduce(
      (sum, row) => sum + parseInt(row.count),
      0
    );
    const byType = {};
    wasteByType.rows.forEach((row) => {
      byType[row.waste_type] =
        total > 0 ? Math.round((parseInt(row.count) / total) * 100) : 0;
    });

    res.json({ ok: true, series, byType, data: series });
  } catch (error) {
    console.error("[Analytics] Timeseries error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.get("/api/analytics/predict", async (req, res) => {
  try {
    const days = Number(req.query.days || 7);
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Get actual data for past N days
    const actualData = await db.query(
      `SELECT 
        DATE(completed_at) as day,
        COALESCE(SUM(actual_weight), 0) / 1000.0 as total_tons
      FROM schedules
      WHERE completed_at >= NOW() - INTERVAL '1 day' * $1
        AND status = 'completed'
      GROUP BY day
      ORDER BY day ASC`,
      [days]
    );

    // Create actual array with all days
    const actual = [];
    for (let i = days - 1; i >= 0; i--) {
      const dayDate = new Date(today.getTime() - i * 86400000);
      const dateStr = dayDate.toISOString().slice(0, 10);

      const dataPoint = actualData.rows.find((row) => {
        const rowDate = new Date(row.day);
        return rowDate.toISOString().slice(0, 10) === dateStr;
      });

      actual.push({
        d: dateStr,
        v: dataPoint ? parseFloat(dataPoint.total_tons).toFixed(1) : 0,
      });
    }

    // Simple forecast: calculate average and add slight growth
    const avgWeight =
      actual.reduce((sum, d) => sum + parseFloat(d.v), 0) / actual.length || 50;
    const forecast = [];
    for (let i = 0; i < days; i++) {
      const dayDate = new Date(today.getTime() + i * 86400000);
      const dateStr = dayDate.toISOString().slice(0, 10);

      // Add 2% growth trend
      const forecastValue = avgWeight * (1 + (i * 0.02) / days);
      forecast.push({
        d: dateStr,
        v: parseFloat(forecastValue.toFixed(1)),
      });
    }

    res.json({ ok: true, data: { actual, forecast } });
  } catch (error) {
    console.error("[Analytics] Predict error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// ==================== EXCEPTIONS API ====================
// Get all exceptions
app.get("/api/exceptions", async (req, res) => {
  try {
    const { status, type, route_id } = req.query;

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
        r.id as route_id_display,
        rs.point_id
      FROM exceptions e
      LEFT JOIN routes r ON e.route_id = r.id
      LEFT JOIN route_stops rs ON e.stop_id = rs.id
      WHERE 1=1
    `;
    const params = [];
    let paramIndex = 1;

    if (status) {
      query += ` AND e.status = $${paramIndex++}`;
      params.push(status);
    }

    if (type) {
      query += ` AND e.type = $${paramIndex++}`;
      params.push(type);
    }

    if (route_id) {
      query += ` AND e.route_id = $${paramIndex++}`;
      params.push(route_id);
    }

    query += ` ORDER BY e.created_at DESC LIMIT 100`;

    const { rows } = await db.query(query, params);

    // Format for frontend
    const exceptions = rows.map((row) => ({
      id: row.id,
      time: row.created_at ? new Date(row.created_at).toLocaleString() : "",
      location: row.point_id || "N/A",
      type: row.type || "other",
      status: row.status,
      route_id: row.route_id,
      reason: row.reason,
      photo_url: row.photo_url,
      plan: row.plan,
      approved_by: row.approved_by,
      approved_at: row.approved_at,
      scheduled_at: row.scheduled_at,
    }));

    res.json({ ok: true, data: exceptions });
  } catch (error) {
    console.error("[Exceptions] Get error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Approve exception
app.post("/api/exceptions/:id/approve", async (req, res) => {
  try {
    const { id } = req.params;
    const { plan, scheduled_at } = req.body;

    // TODO: Get current user ID from JWT token
    const approved_by = req.headers["x-user-id"] || null;

    const updates = [];
    const params = [];
    let paramIndex = 1;

    updates.push(`status = $${paramIndex++}`);
    params.push("approved");

    updates.push(`approved_by = $${paramIndex++}`);
    params.push(approved_by);

    updates.push(`approved_at = NOW()`);

    if (plan) {
      updates.push(`plan = $${paramIndex++}`);
      params.push(plan);
    }

    if (scheduled_at) {
      updates.push(`scheduled_at = $${paramIndex++}`);
      params.push(scheduled_at);
    }

    params.push(id);

    const query = `UPDATE exceptions SET ${updates.join(
      ", "
    )} WHERE id = $${paramIndex} RETURNING *`;
    const { rows } = await db.query(query, params);

    if (rows.length === 0) {
      return res.status(404).json({ ok: false, error: "Exception not found" });
    }

    console.log(`✅ Exception approved: ${id}`);

    res.json({
      ok: true,
      data: {
        id: rows[0].id,
        status: rows[0].status,
        plan: rows[0].plan,
        approved_at: rows[0].approved_at,
      },
      message: "Exception approved successfully",
    });
  } catch (error) {
    console.error("[Exceptions] Approve error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Reject exception
app.post("/api/exceptions/:id/reject", async (req, res) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;

    // TODO: Get current user ID from JWT token
    const approved_by = req.headers["x-user-id"] || null;

    const updates = [];
    const params = [];
    let paramIndex = 1;

    updates.push(`status = $${paramIndex++}`);
    params.push("rejected");

    updates.push(`approved_by = $${paramIndex++}`);
    params.push(approved_by);

    updates.push(`approved_at = NOW()`);

    if (reason) {
      updates.push(`reason = COALESCE(reason, '') || $${paramIndex++}`);
      params.push(`\nRejection reason: ${reason}`);
    }

    params.push(id);

    const query = `UPDATE exceptions SET ${updates.join(
      ", "
    )} WHERE id = $${paramIndex} RETURNING *`;
    const { rows } = await db.query(query, params);

    if (rows.length === 0) {
      return res.status(404).json({ ok: false, error: "Exception not found" });
    }

    console.log(`❌ Exception rejected: ${id}`);

    res.json({
      ok: true,
      data: {
        id: rows[0].id,
        status: rows[0].status,
        reason: rows[0].reason,
        approved_at: rows[0].approved_at,
      },
      message: "Exception rejected successfully",
    });
  } catch (error) {
    console.error("[Exceptions] Reject error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

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

app.get("/api/exceptions", async (req, res) => {
  try {
    const { status, type } = req.query;

    let query = `
      SELECT 
        e.id,
        e.created_at as time,
        e.exception_type as type,
        e.status,
        e.description,
        e.photo_url,
        ST_Y(e.location::geometry) as lat,
        ST_X(e.location::geometry) as lon,
        e.approved_by,
        e.approved_at,
        e.meta
      FROM exceptions e
      WHERE 1=1
    `;
    const params = [];
    let paramIndex = 1;

    if (status) {
      query += ` AND e.status = $${paramIndex++}`;
      params.push(status);
    }

    if (type) {
      query += ` AND e.exception_type = $${paramIndex++}`;
      params.push(type);
    }

    query += ` ORDER BY e.created_at DESC LIMIT 50`;

    const { rows } = await db.query(query, params);

    // Format for frontend
    const exceptions = rows.map((row) => ({
      id: row.id,
      time: new Date(row.time).toLocaleString("vi-VN"),
      location: `${row.lat}, ${row.lon}`,
      lat: row.lat,
      lon: row.lon,
      type: row.type,
      status: row.status,
      description: row.description,
      photo_url: row.photo_url,
      approved_by: row.approved_by,
      approved_at: row.approved_at,
      meta: row.meta,
    }));

    res.json({ ok: true, data: exceptions });
  } catch (error) {
    console.error("[Exceptions] Get error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.post("/api/exceptions/:id/approve", async (req, res) => {
  try {
    const { id } = req.params;
    const { approved_by } = req.body;

    const { rows } = await db.query(
      `UPDATE exceptions 
       SET status = 'approved', 
           approved_by = $1, 
           approved_at = NOW(),
           updated_at = NOW()
       WHERE id = $2
       RETURNING *`,
      [approved_by || "admin", id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ ok: false, error: "Exception not found" });
    }

    console.log(`✅ Exception approved: ${id}`);
    res.json({ ok: true, data: { message: "Approved", exception: rows[0] } });
  } catch (error) {
    console.error("[Exceptions] Approve error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.post("/api/exceptions/:id/reject", async (req, res) => {
  try {
    const { id } = req.params;
    const { approved_by, reason } = req.body;

    const { rows } = await db.query(
      `UPDATE exceptions 
       SET status = 'rejected', 
           approved_by = $1, 
           approved_at = NOW(),
           meta = COALESCE(meta, '{}'::jsonb) || jsonb_build_object('rejection_reason', $2),
           updated_at = NOW()
       WHERE id = $3
       RETURNING *`,
      [approved_by || "admin", reason || "No reason provided", id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ ok: false, error: "Exception not found" });
    }

    console.log(`✅ Exception rejected: ${id}`);
    res.json({ ok: true, data: { message: "Rejected", exception: rows[0] } });
  } catch (error) {
    console.error("[Exceptions] Reject error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// ==================== SCHEDULE API ====================
// Get schedules (with optional filters)
app.get("/api/schedules", async (req, res) => {
  try {
    const {
      citizen_id,
      status,
      scheduled_date,
      limit = 50,
      offset = 0,
    } = req.query;

    let query = `
      SELECT 
        s.*,
        u.profile->>'name' as citizen_name,
        u.phone as citizen_phone,
        p.name as employee_name,
        p.role as employee_role,
        d.name as depot_name
      FROM schedules s
      LEFT JOIN users u ON s.citizen_id = u.id::text
      LEFT JOIN personnel p ON s.employee_id = p.id
      LEFT JOIN depots d ON p.depot_id = d.id
      WHERE 1=1
    `;
    const params = [];
    let paramIndex = 1;

    if (citizen_id) {
      query += ` AND s.citizen_id = $${paramIndex}`;
      params.push(citizen_id);
      paramIndex++;
    }

    if (status) {
      query += ` AND s.status = $${paramIndex}`;
      params.push(status);
      paramIndex++;
    }

    if (scheduled_date) {
      query += ` AND DATE(s.scheduled_date) = $${paramIndex}`;
      params.push(scheduled_date);
      paramIndex++;
    }

    query += ` ORDER BY s.created_at DESC LIMIT $${paramIndex} OFFSET $${
      paramIndex + 1
    }`;
    params.push(limit, offset);

    const { rows } = await db.query(query, params);

    res.json({
      ok: true,
      data: rows,
      total: rows.length,
    });
  } catch (error) {
    console.error("[Schedule] Get error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Get assigned schedules for worker (worker-specific endpoint)
app.get("/api/schedules/assigned", async (req, res) => {
  try {
    const { employee_id, status, limit = 50, offset = 0 } = req.query;

    let query = `
      SELECT * FROM schedules 
      WHERE employee_id IS NOT NULL
    `;
    const params = [];
    let paramIndex = 1;

    if (employee_id) {
      query += ` AND employee_id = $${paramIndex}`;
      params.push(employee_id);
      paramIndex++;
    }

    if (status) {
      query += ` AND status = $${paramIndex}`;
      params.push(status);
      paramIndex++;
    }

    query += ` ORDER BY scheduled_date DESC, created_at DESC LIMIT $${paramIndex} OFFSET $${
      paramIndex + 1
    }`;
    params.push(limit, offset);

    const { rows } = await db.query(query, params);

    console.log(`📋 Found ${rows.length} assigned schedules`);

    res.json({
      ok: true,
      data: rows,
      total: rows.length,
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
      "SELECT * FROM schedules WHERE schedule_id = $1",
      [id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ ok: false, error: "Schedule not found" });
    }

    res.json({ ok: true, data: rows[0] });
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
      photo_urls, // Add photo_urls field
      notes,
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

    // Insert new schedule with photo_urls
    const { rows: insertRows } = await db.query(
      `INSERT INTO schedules (
        citizen_id, scheduled_date, time_slot, waste_type, estimated_weight,
        latitude, longitude, address, photo_urls, notes, status, priority
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
      RETURNING schedule_id`,
      [
        citizen_id,
        scheduled_date,
        time_slot,
        waste_type,
        estimated_weight,
        latitude || null,
        longitude || null,
        address || null,
        photo_urls || null, // Store photo URLs array
        notes || null,
        "scheduled", // Default status - Đã lên lịch thành công
        0, // Default priority
      ]
    );

    const newScheduleId = insertRows[0].schedule_id;

    // Fetch complete schedule with joined data (same as GET /api/schedules)
    const { rows } = await db.query(
      `SELECT 
        s.*,
        u.profile->>'name' as citizen_name,
        u.phone as citizen_phone,
        p.name as employee_name,
        p.role as employee_role,
        d.name as depot_name
      FROM schedules s
      LEFT JOIN users u ON s.citizen_id = u.id::text
      LEFT JOIN personnel p ON s.employee_id = p.id
      LEFT JOIN depots d ON p.depot_id = d.id
      WHERE s.schedule_id = $1`,
      [newScheduleId]
    );

    const newSchedule = rows[0];

    console.log(
      `✅ Schedule created: ${newScheduleId} for citizen ${citizen_id} (${
        newSchedule.citizen_name
      }) - Status: scheduled - Photos: ${photo_urls ? photo_urls.length : 0}`
    );

    // Emit event to Socket.IO for real-time updates (for web manager & worker apps)
    io.emit("schedule:created", {
      schedule_id: newSchedule.schedule_id,
      citizen_id: newSchedule.citizen_id,
      citizen_name: newSchedule.citizen_name,
      citizen_phone: newSchedule.citizen_phone,
      scheduled_date: newSchedule.scheduled_date,
      time_slot: newSchedule.time_slot,
      waste_type: newSchedule.waste_type,
      estimated_weight: newSchedule.estimated_weight,
      latitude: newSchedule.latitude,
      longitude: newSchedule.longitude,
      address: newSchedule.address,
      photo_urls: newSchedule.photo_urls,
      status: newSchedule.status,
      created_at: newSchedule.created_at,
    });

    console.log(
      `📡 Emitted schedule:created event for schedule ${newScheduleId}`
    );

    res.status(201).json({
      ok: true,
      data: newSchedule,
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

    if (actual_weight !== undefined) {
      updates.push(`actual_weight = $${paramIndex}`);
      params.push(actual_weight);
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

    const query = `UPDATE schedules SET ${updates.join(
      ", "
    )} WHERE schedule_id = $${paramIndex} RETURNING schedule_id`;
    const { rows: updateRows } = await db.query(query, params);

    if (updateRows.length === 0) {
      return res.status(404).json({ ok: false, error: "Schedule not found" });
    }

    // Fetch complete schedule with joined data (same as GET /api/schedules)
    const { rows } = await db.query(
      `SELECT 
        s.*,
        u.profile->>'name' as citizen_name,
        u.phone as citizen_phone,
        p.name as employee_name,
        p.role as employee_role,
        d.name as depot_name
      FROM schedules s
      LEFT JOIN users u ON s.citizen_id = u.id::text
      LEFT JOIN personnel p ON s.employee_id = p.id
      LEFT JOIN depots d ON p.depot_id = d.id
      WHERE s.schedule_id = $1`,
      [id]
    );

    const updatedSchedule = rows[0];

    console.log(
      `✅ Schedule updated: ${id} -> status: ${
        updatedSchedule.status
      }, employee: ${updatedSchedule.employee_name || "none"}`
    );

    // Emit event to Socket.IO for real-time updates
    io.emit("schedule:updated", updatedSchedule);

    res.json({
      ok: true,
      data: updatedSchedule,
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
      `UPDATE schedules 
       SET status = 'cancelled', updated_at = NOW() 
       WHERE schedule_id = $1
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

// ==================== MASTER DATA - PERSONNEL API ====================
// Get all personnel
app.get("/api/manager/personnel", async (req, res) => {
  try {
    const { role, status, depot_id } = req.query;

    let query = `
      SELECT 
        p.id,
        p.name,
        p.role,
        p.phone,
        p.email,
        p.status,
        p.depot_id,
        p.hired_at,
        p.created_at,
        p.updated_at,
        d.name as depot_name
      FROM personnel p
      LEFT JOIN depots d ON p.depot_id = d.id
      WHERE 1=1
    `;
    const params = [];
    let paramIndex = 1;

    if (role) {
      query += ` AND p.role = $${paramIndex++}`;
      params.push(role);
    }

    if (status) {
      query += ` AND p.status = $${paramIndex++}`;
      params.push(status);
    }

    if (depot_id) {
      query += ` AND p.depot_id = $${paramIndex++}`;
      params.push(depot_id);
    }

    query += ` ORDER BY p.created_at DESC`;

    const { rows } = await db.query(query, params);

    res.json({ ok: true, data: rows });
  } catch (error) {
    console.error("[Personnel] Get error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Get personnel by ID
app.get("/api/manager/personnel/:id", async (req, res) => {
  try {
    const { id } = req.params;

    const { rows } = await db.query(
      `SELECT 
        p.id,
        p.name,
        p.role,
        p.phone,
        p.email,
        p.status,
        p.depot_id,
        p.hired_at,
        p.created_at,
        p.updated_at,
        d.name as depot_name
      FROM personnel p
      LEFT JOIN depots d ON p.depot_id = d.id
      WHERE p.id = $1`,
      [id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ ok: false, error: "Personnel not found" });
    }

    res.json({ ok: true, data: rows[0] });
  } catch (error) {
    console.error("[Personnel] Get by ID error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Create new personnel
app.post("/api/manager/personnel", async (req, res) => {
  try {
    const {
      name,
      role,
      phone,
      email,
      password, // New: password for user account
      status,
      depot_id,
      address, // New: address for user profile
    } = req.body;

    if (!name || !role || !phone || !email) {
      return res.status(400).json({
        ok: false,
        error: "Missing required fields: name, role, phone, email",
      });
    }

    // Validate role
    const validRoles = ["driver", "collector"];
    if (!validRoles.includes(role)) {
      return res.status(400).json({
        ok: false,
        error: `Invalid role. Must be one of: ${validRoles.join(", ")}`,
      });
    }

    // Check if user already exists with this phone or email
    const existingUser = await db.query(
      `SELECT id FROM users WHERE phone = $1 OR email = $2`,
      [phone, email]
    );

    if (existingUser.rows.length > 0) {
      return res.status(400).json({
        ok: false,
        error: "User with this phone or email already exists",
      });
    }

    const { v4: uuidv4 } = require("uuid");
    const bcrypt = require("bcrypt");

    // Hash password (default: "123456" if not provided)
    const defaultPassword = password || "123456";
    const passwordHash = await bcrypt.hash(defaultPassword, 10);

    // Start transaction
    try {
      await db.query("BEGIN");

      // 1. Create user account
      const userId = uuidv4();
      const userResult = await db.query(
        `INSERT INTO users (
          id, phone, email, password_hash, role, status, profile, created_at, updated_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW(), NOW())
        RETURNING id`,
        [
          userId,
          phone,
          email,
          passwordHash,
          "worker", // Always set role as "worker" for personnel
          status || "active",
          JSON.stringify({
            fullName: name,
            address: address || "",
            latitude: null,
            longitude: null,
            avatarUrl: null,
            isVerified: true,
          }),
        ]
      );

      // 2. Create personnel record
      const personnelId = uuidv4();
      const personnelResult = await db.query(
        `INSERT INTO personnel (
          id, name, role, phone, email, status, depot_id, hired_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())
        RETURNING *`,
        [
          personnelId,
          name,
          role,
          phone,
          email,
          status || "active",
          depot_id || null,
        ]
      );

      await db.query("COMMIT");

      console.log(
        `✅ Worker account created: User ID=${userId}, Personnel ID=${personnelId} (${name})`
      );

      res.status(201).json({
        ok: true,
        data: {
          ...personnelResult.rows[0],
          user_id: userId,
        },
        message: `Personnel created successfully. Login credentials - Email: ${email}, Password: ${defaultPassword}`,
      });
    } catch (error) {
      await db.query("ROLLBACK");
      throw error;
    }
  } catch (error) {
    console.error("[Personnel] Create error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Update personnel
app.put("/api/manager/personnel/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { name, role, phone, email, status, depot_id } = req.body;

    const updates = [];
    const params = [];
    let paramIndex = 1;

    if (name !== undefined) {
      updates.push(`name = $${paramIndex++}`);
      params.push(name);
    }

    if (role !== undefined) {
      updates.push(`role = $${paramIndex++}`);
      params.push(role);
    }

    if (phone !== undefined) {
      updates.push(`phone = $${paramIndex++}`);
      params.push(phone);
    }

    if (email !== undefined) {
      updates.push(`email = $${paramIndex++}`);
      params.push(email);
    }

    if (status !== undefined) {
      updates.push(`status = $${paramIndex++}`);
      params.push(status);
    }

    if (depot_id !== undefined) {
      updates.push(`depot_id = $${paramIndex++}`);
      params.push(depot_id);
    }

    if (updates.length === 0) {
      return res.status(400).json({ ok: false, error: "No fields to update" });
    }

    updates.push(`updated_at = NOW()`);
    params.push(id);

    const query = `UPDATE personnel SET ${updates.join(
      ", "
    )} WHERE id = $${paramIndex} RETURNING *`;
    const { rows } = await db.query(query, params);

    if (rows.length === 0) {
      return res.status(404).json({ ok: false, error: "Personnel not found" });
    }

    console.log(`✅ Personnel updated: ${id}`);

    res.json({
      ok: true,
      data: rows[0],
      message: "Personnel updated successfully",
    });
  } catch (error) {
    console.error("[Personnel] Update error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Delete personnel (soft delete by setting status to inactive)
app.delete("/api/manager/personnel/:id", async (req, res) => {
  try {
    const { id } = req.params;

    const { rows } = await db.query(
      `UPDATE personnel 
       SET status = 'inactive', updated_at = NOW() 
       WHERE id = $1 
       RETURNING *`,
      [id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ ok: false, error: "Personnel not found" });
    }

    console.log(`🗑️ Personnel deactivated: ${id}`);

    res.json({
      ok: true,
      message: "Personnel deactivated successfully",
    });
  } catch (error) {
    console.error("[Personnel] Delete error:", error);
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

    // TODO: Implement routes table and logic
    // For now, return empty route
    console.log(`🚛 Checking active route for employee: ${employee_id}`);

    res.json({
      ok: true,
      data: null, // No active route for now
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
// Login
app.post("/api/auth/login", async (req, res) => {
  try {
    const { phone, password } = req.body;

    if (!phone || !password) {
      return res.status(400).json({
        ok: false,
        error: "Phone and password are required",
      });
    }

    // Query user by phone
    const { rows } = await db.query(
      `SELECT id, phone, email, role, status, profile, created_at, updated_at
       FROM users WHERE phone = $1 AND status = 'active'`,
      [phone]
    );

    if (rows.length === 0) {
      return res.status(401).json({
        ok: false,
        error: "Invalid phone or password",
      });
    }

    const user = rows[0];

    // TODO: In production, verify password hash
    // For now, accept any password for demo (or check if password === '123456')
    if (password !== "123456") {
      return res.status(401).json({
        ok: false,
        error: "Invalid phone or password",
      });
    }

    // Update last login time
    await db.query("UPDATE users SET last_login_at = NOW() WHERE id = $1", [
      user.id,
    ]);

    console.log(`🔐 User logged in: ${user.phone} (${user.id})`);

    // Return user data (in production, also return JWT token)
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

// ==================== INCIDENT REPORTS API ====================

// Get all incident reports (with filters)
app.get("/api/incidents", async (req, res) => {
  try {
    const {
      reporter_id,
      report_category, // 'violation' or 'damage'
      type,
      status,
      priority,
      limit = 50,
      offset = 0,
    } = req.query;

    let query = "SELECT * FROM incidents WHERE 1=1";
    const params = [];
    let paramIndex = 1;

    if (reporter_id) {
      query += ` AND reporter_id = $${paramIndex++}`;
      params.push(reporter_id);
    }

    if (report_category) {
      query += ` AND report_category = $${paramIndex++}`;
      params.push(report_category);
    }

    if (type) {
      query += ` AND type = $${paramIndex++}`;
      params.push(type);
    }

    if (status) {
      query += ` AND status = $${paramIndex++}`;
      params.push(status);
    }

    if (priority) {
      query += ` AND priority = $${paramIndex++}`;
      params.push(priority);
    }

    query += ` ORDER BY created_at DESC LIMIT $${paramIndex++} OFFSET $${paramIndex}`;
    params.push(limit, offset);

    const { rows } = await db.query(query, params);

    res.json({
      ok: true,
      data: rows,
      total: rows.length,
    });
  } catch (error) {
    console.error("[Incidents] Get incidents error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Get incidents by user ID
app.get("/api/incidents/user/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    const { limit = 100, offset = 0 } = req.query;

    const { rows } = await db.query(
      `SELECT * FROM incidents 
       WHERE reporter_id = $1 
       ORDER BY created_at DESC 
       LIMIT $2 OFFSET $3`,
      [userId, limit, offset]
    );

    res.json({
      ok: true,
      data: rows,
      total: rows.length,
    });
  } catch (error) {
    console.error("[Incidents] Get user incidents error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Get incident by ID
app.get("/api/incidents/:id", async (req, res) => {
  try {
    const { id } = req.params;

    const { rows } = await db.query("SELECT * FROM incidents WHERE id = $1", [
      id,
    ]);

    if (rows.length === 0) {
      return res.status(404).json({ ok: false, error: "Incident not found" });
    }

    res.json({
      ok: true,
      data: rows[0],
    });
  } catch (error) {
    console.error("[Incidents] Get incident error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Create new incident report
app.post("/api/incidents", async (req, res) => {
  try {
    const {
      reporter_id,
      reporter_name,
      reporter_phone,
      report_category, // 'violation' or 'damage'
      type,
      description,
      latitude,
      longitude,
      location_address,
      image_urls = [], // Array of image URLs
      priority = "medium",
    } = req.body;

    // Validation
    if (!reporter_id || !report_category || !type || !description) {
      return res.status(400).json({
        ok: false,
        error:
          "Missing required fields: reporter_id, report_category, type, description",
      });
    }

    if (!["violation", "damage"].includes(report_category)) {
      return res.status(400).json({
        ok: false,
        error: "report_category must be 'violation' or 'damage'",
      });
    }

    // Validate that at least one image is provided
    if (!image_urls || image_urls.length === 0) {
      return res.status(400).json({
        ok: false,
        error: "At least one image is required for reporting",
      });
    }

    // Insert incident
    const { rows } = await db.query(
      `INSERT INTO incidents (
        reporter_id, reporter_name, reporter_phone, report_category, type,
        description, latitude, longitude, location_address, image_urls, priority, status
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, 'pending')
      RETURNING *`,
      [
        reporter_id,
        reporter_name,
        reporter_phone,
        report_category,
        type,
        description,
        latitude || null,
        longitude || null,
        location_address || null,
        image_urls,
        priority,
      ]
    );

    console.log(
      `📝 New incident report created: ${rows[0].id} (${report_category}/${type}) - ${image_urls.length} photos`
    );

    res.status(201).json({
      ok: true,
      data: rows[0],
      message: "Incident report submitted successfully",
    });
  } catch (error) {
    console.error("[Incidents] Create incident error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Update incident status
app.patch("/api/incidents/:id/status", async (req, res) => {
  try {
    const { id } = req.params;
    const { status, resolution_notes, assigned_to } = req.body;

    if (!status) {
      return res.status(400).json({ ok: false, error: "Status is required" });
    }

    const validStatuses = [
      "pending",
      "open",
      "in_progress",
      "resolved",
      "closed",
      "rejected",
    ];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        ok: false,
        error: `Invalid status. Must be one of: ${validStatuses.join(", ")}`,
      });
    }

    let query = `UPDATE incidents SET status = $1, updated_at = NOW()`;
    const params = [status];
    let paramIndex = 2;

    if (resolution_notes) {
      query += `, resolution_notes = $${paramIndex++}`;
      params.push(resolution_notes);
    }

    if (assigned_to) {
      query += `, assigned_to = $${paramIndex++}`;
      params.push(assigned_to);
    }

    if (status === "resolved" || status === "closed") {
      query += `, resolved_at = NOW()`;
    }

    query += ` WHERE id = $${paramIndex} RETURNING *`;
    params.push(id);

    const { rows } = await db.query(query, params);

    if (rows.length === 0) {
      return res.status(404).json({ ok: false, error: "Incident not found" });
    }

    res.json({
      ok: true,
      data: rows[0],
      message: "Incident status updated successfully",
    });
  } catch (error) {
    console.error("[Incidents] Update status error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Get incident statistics
app.get("/api/incidents/stats", async (req, res) => {
  try {
    const { reporter_id } = req.query;

    let whereClause = "";
    const params = [];

    if (reporter_id) {
      whereClause = "WHERE reporter_id = $1";
      params.push(reporter_id);
    }

    const { rows } = await db.query(
      `SELECT
        COUNT(*) as total_reports,
        COUNT(CASE WHEN report_category = 'violation' THEN 1 END) as total_violations,
        COUNT(CASE WHEN report_category = 'damage' THEN 1 END) as total_damages,
        COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending,
        COUNT(CASE WHEN status = 'in_progress' THEN 1 END) as in_progress,
        COUNT(CASE WHEN status = 'resolved' THEN 1 END) as resolved,
        COUNT(CASE WHEN status = 'closed' THEN 1 END) as closed
      FROM incidents
      ${whereClause}`,
      params
    );

    res.json({
      ok: true,
      data: rows[0],
    });
  } catch (error) {
    console.error("[Incidents] Get stats error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Delete incident (admin only)
app.delete("/api/incidents/:id", async (req, res) => {
  try {
    const { id } = req.params;

    const { rows } = await db.query(
      "DELETE FROM incidents WHERE id = $1 RETURNING *",
      [id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ ok: false, error: "Incident not found" });
    }

    res.json({
      ok: true,
      message: "Incident deleted successfully",
    });
  } catch (error) {
    console.error("[Incidents] Delete incident error:", error);
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
