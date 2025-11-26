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

app.get("/api/analytics/summary", (req, res) => {
  res.json({
    ok: true,
    routesActive: 12,
    collectionRate: 0.85,
    todayTons: 3.2,
  });
});

// Master data endpoints
app.get("/api/master/fleet", (req, res) => {
  const mockFleet = [
    {
      id: "V01",
      plate: "51A-123.45",
      type: "compactor",
      capacity: 3000,
      types: ["household"],
      status: "ready",
    },
    {
      id: "V02",
      plate: "51B-678.90",
      type: "mini-truck",
      capacity: 1200,
      types: ["recyclable"],
      status: "ready",
    },
    {
      id: "V03",
      plate: "51C-246.80",
      type: "electric-trike",
      capacity: 300,
      types: ["household", "recyclable"],
      status: "maintenance",
    },
  ];
  res.json({ ok: true, data: mockFleet });
});

app.post("/api/master/fleet", (req, res) => {
  res.json({ ok: true, data: { id: "V" + Date.now(), ...req.body } });
});

app.patch("/api/master/fleet/:id", (req, res) => {
  res.json({ ok: true, data: { id: req.params.id, ...req.body } });
});

app.delete("/api/master/fleet/:id", (req, res) => {
  res.json({ ok: true, message: "Vehicle deleted" });
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
app.post("/api/vrp/optimize", (req, res) => {
  const { vehicles = [], points = [] } = req.body;
  const routes = vehicles.map((v, idx) => ({
    vehicleId: v.id,
    distance: Math.round(8000 + Math.random() * 9000),
    eta: `${1 + idx}:2${idx}`,
    geojson: {
      type: "FeatureCollection",
      features: [
        {
          type: "Feature",
          geometry: {
            type: "LineString",
            coordinates: points
              .slice(idx, points.length)
              .map((p) => [p.lon, p.lat]),
          },
          properties: {},
        },
      ],
    },
    stops: points.map((p, i) => ({ id: p.id, seq: i + 1 })),
  }));
  res.json({ ok: true, data: { routes } });
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
       VALUES ($1, $2, $3, $4, $5)`,
      [
        newRouteId,
        vehicle_id,
        now,
        "in_progress",
        JSON.stringify({
          type: "incident_response",
          original_alert_id: alertId,
          original_route_id: alert.original_route_id,
          created_by: "dynamic_dispatch",
        }),
      ]
    );

    // 3. Add the incident point as a route stop
    const stopId = uuidv4();
    await db.query(
      `INSERT INTO route_stops (id, route_id, point_id, seq, status, planned_eta)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [stopId, newRouteId, alert.point_id, 1, "pending", now]
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
        alert_id: alertId,
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

  res.json({ ok: true, series, byType, data: series }); // Keep 'data' for backward compatibility
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

app.get("/api/exceptions", (req, res) => {
  const exceptions = Array.from({ length: 12 }).map((_, i) => ({
    id: `E${i + 1}`,
    time: new Date(Date.now() - i * 5e5).toLocaleString(),
    location: `10.${78 + i}, 106.${70 + i}`,
    type: ["oversize", "blocked", "other"][i % 3],
    status: ["pending", "approved", "rejected"][i % 3],
  }));
  res.json({ ok: true, data: exceptions });
});

app.post("/api/exceptions/:id/approve", (req, res) => {
  res.json({ ok: true, data: { message: "Approved" } });
});

app.post("/api/exceptions/:id/reject", (req, res) => {
  res.json({ ok: true, data: { message: "Rejected" } });
});

// ==================== SCHEDULE API ====================
// Get schedules (with optional filters)
app.get("/api/schedules", async (req, res) => {
  try {
    const { citizen_id, status, limit = 50, offset = 0 } = req.query;

    let query = "SELECT * FROM schedules WHERE 1=1";
    const params = [];
    let paramIndex = 1;

    if (citizen_id) {
      query += ` AND citizen_id = $${paramIndex}`;
      params.push(citizen_id);
      paramIndex++;
    }

    if (status) {
      query += ` AND status = $${paramIndex}`;
      params.push(status);
      paramIndex++;
    }

    query += ` ORDER BY created_at DESC LIMIT $${paramIndex} OFFSET $${
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
      `INSERT INTO schedules (
        citizen_id, scheduled_date, time_slot, waste_type, estimated_weight,
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
      `✅ Schedule created: ${rows[0].schedule_id} for citizen ${citizen_id} - Status: scheduled`
    );

    // Emit event to Socket.IO for real-time updates (for web manager & worker apps)
    io.emit("schedule:created", {
      schedule_id: rows[0].schedule_id,
      citizen_id: rows[0].citizen_id,
      scheduled_date: rows[0].scheduled_date,
      time_slot: rows[0].time_slot,
      waste_type: rows[0].waste_type,
      estimated_weight: rows[0].estimated_weight,
      latitude: rows[0].latitude,
      longitude: rows[0].longitude,
      address: rows[0].address,
      status: rows[0].status,
      created_at: rows[0].created_at,
    });

    console.log(
      `📡 Emitted schedule:created event for schedule ${rows[0].schedule_id}`
    );

    res.status(201).json({
      ok: true,
      data: rows[0],
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
    )} WHERE schedule_id = $${paramIndex} RETURNING *`;
    const { rows } = await db.query(query, params);

    if (rows.length === 0) {
      return res.status(404).json({ ok: false, error: "Schedule not found" });
    }

    console.log(
      `✅ Schedule updated: ${id} -> status: ${status || "unchanged"}`
    );

    res.json({
      ok: true,
      data: rows[0],
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
        description, geom, location_address, image_urls, priority, status, created_at, updated_at
      ) VALUES (
        $1, $2, $3, $4, $5, $6,
        ${
          latitude && longitude
            ? `ST_SetSRID(ST_MakePoint($7, $8), 4326)`
            : "NULL"
        },
        ${latitude && longitude ? "$9" : "$7"},
        ${latitude && longitude ? "$10" : "$8"},
        ${latitude && longitude ? "$11" : "$9"},
        'pending', NOW(), NOW()
      ) RETURNING *`,
      latitude && longitude
        ? [
            reporter_id,
            reporter_name,
            reporter_phone,
            report_category,
            type,
            description,
            longitude,
            latitude,
            location_address,
            image_urls,
            priority,
          ]
        : [
            reporter_id,
            reporter_name,
            reporter_phone,
            report_category,
            type,
            description,
            location_address,
            image_urls,
            priority,
          ]
    );

    console.log(
      `📝 New incident report created: ${rows[0].id} (${report_category})`
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
