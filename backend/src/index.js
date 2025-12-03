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
const ARIMA = require("arima");

// Load environment variables
dotenv.config();

const app = express();
const server = http.createServer(app);
const io = require("socket.io")(server, { cors: { origin: "*" } });
// In unified deployment (with Nginx), backend should use BACKEND_PORT (3000)
// Render's PORT (10000) is for Nginx only
const PORT = process.env.BACKEND_PORT || process.env.PORT || 3000;
// Performance middleware
app.use(compression());

// Realtime store (mock for dev)
const { store } = require("./realtime");

// Database Connection
const { Pool } = require("pg");

// Build DATABASE_URL from environment variables
let dbUrl = process.env.DATABASE_URL;

// If DATABASE_URL is not set, try to build it from individual DB_* variables
// This is useful for Render when using fromDatabase properties in render.yaml
if (!dbUrl && process.env.DB_HOST) {
  const dbHost = process.env.DB_HOST;
  const dbPort = process.env.DB_PORT || "5432";
  const dbUser = process.env.DB_USER || "ecocheck_user";
  const dbPassword = process.env.DB_PASSWORD || "";
  const dbName = process.env.DB_NAME || "ecocheck";
  
  dbUrl = `postgresql://${dbUser}:${dbPassword}@${dbHost}:${dbPort}/${dbName}`;
  console.log("🔧 Built DATABASE_URL from DB_* environment variables");
}

// Debug: Log database connection info (hide password)
if (dbUrl) {
  const maskedUrl = dbUrl.replace(/:([^:@]+)@/, ':****@'); // Hide password
  console.log("🔗 DATABASE_URL: " + maskedUrl);
} else {
  const isProduction = process.env.NODE_ENV === "production";
  if (isProduction) {
    console.error("❌ FATAL ERROR: DATABASE_URL is NOT set in production!");
    console.error("❌ Please set DATABASE_URL or DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME");
    console.error("❌ In Render: Link database service or add DATABASE_URL environment variable");
    process.exit(1); // Fail early in production - better than trying localhost
  } else {
    console.warn("⚠ WARNING: DATABASE_URL environment variable is NOT set!");
    console.warn("⚠ Using fallback localhost connection (development only)");
    dbUrl = "postgresql://ecocheck_user:ecocheck_pass@localhost:5432/ecocheck";
  }
}

const db = new Pool({
  connectionString: dbUrl,
  // Connection pool settings for better reliability
  max: 20, // Maximum number of clients in the pool
  idleTimeoutMillis: 30000, // Close idle clients after 30 seconds
  connectionTimeoutMillis: 10000, // Return error after 10 seconds if connection cannot be established
});

db.on("connect", () => console.log("🐘 Connected to PostgreSQL database"));
db.on("error", (err) => {
  console.error("❌ PostgreSQL connection error:", err.message);
  if (err.code === "ECONNREFUSED") {
    console.error("❌ Connection refused - PostgreSQL is not listening or connection string is wrong");
    console.error("❌ Current connection string:", dbUrl.replace(/:([^:@]+)@/, ':****@'));
    if (dbUrl.includes("localhost") || dbUrl.includes("127.0.0.1") || dbUrl.includes("::1")) {
      console.error("❌ ERROR: You are trying to connect to localhost!");
      console.error("❌ In Render, you must use the internal database hostname, not localhost");
      console.error("❌ Solution: Link database service or set DATABASE_URL with Render database hostname");
    }
  }
});

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

// --- Advanced VRP Utility Functions ---

// Lấy ma trận thời gian/khoảng cách từ OSRM (1 lần gọi duy nhất cho N điểm)
async function getOSRMMatrix(points) {
  if (points.length < 2) return null;
  try {
    // Format: lon,lat;lon,lat...
    const coordinates = points.map((p) => `${p.lon},${p.lat}`).join(";");
    const url = `https://router.project-osrm.org/table/v1/driving/${coordinates}?annotations=duration,distance`;

    // Sử dụng axios có sẵn trong project
    const axios = require("axios");
    const response = await axios.get(url, { timeout: 5000 }); // Timeout 5s

    if (response.data && response.data.code === "Ok") {
      return {
        durations: response.data.durations, // Giây
        distances: response.data.distances, // Mét
      };
    }
    return null;
  } catch (error) {
    console.warn(
      `[VRP] OSRM Matrix failed: ${error.message}. Falling back to Haversine.`
    );
    return null; // Trả về null để fallback sang Haversine
  }
}

// Tính tổng chi phí của một lộ trình cụ thể
function calculateRouteCost(
  routeIndices,
  matrix,
  points,
  weightTime = 0.7,
  weightDist = 0.3
) {
  let cost = 0;
  for (let i = 0; i < routeIndices.length - 1; i++) {
    const from = routeIndices[i];
    const to = routeIndices[i + 1];

    if (matrix) {
      // Dùng dữ liệu thực tế từ OSRM
      const time = matrix.durations[from][to];
      const dist = matrix.distances[from][to];
      cost += time * weightTime + dist * weightDist;
    } else {
      // Fallback: Dùng Haversine (chỉ có khoảng cách)
      const dist = getHaversineDistance(points[from], points[to]);
      cost += dist;
    }
  }
  return cost;
}

// OSRM Distance Cache to avoid redundant API calls
// Key format: "lon1,lat1|lon2,lat2" (sorted to ensure bidirectional cache)
const osrmDistanceCache = new Map();
const OSRM_CACHE_MAX_SIZE = 1000; // Limit cache size to prevent memory issues

function getCacheKey(point1, point2) {
  // Sort coordinates to ensure cache works bidirectionally
  const coords1 = `${point1.lon.toFixed(6)},${point1.lat.toFixed(6)}`;
  const coords2 = `${point2.lon.toFixed(6)},${point2.lat.toFixed(6)}`;
  return coords1 < coords2 ? `${coords1}|${coords2}` : `${coords2}|${coords1}`;
}

// Get OSRM road distance between two points (with caching and retry logic)
async function getOSRMDistance(point1, point2, retries = 3) {
  try {
    // Check cache first
    const cacheKey = getCacheKey(point1, point2);
    if (osrmDistanceCache.has(cacheKey)) {
      return osrmDistanceCache.get(cacheKey);
    }

    const axios = require("axios");
    const coords = `${point1.lon},${point1.lat};${point2.lon},${point2.lat}`;
    const url = `https://router.project-osrm.org/route/v1/driving/${coords}?overview=false&alternatives=false&steps=false`;

    // Retry logic for better reliability
    let lastError = null;
    for (let attempt = 1; attempt <= retries; attempt++) {
      try {
        const response = await axios.get(url, {
          timeout: 10000, // 10 second timeout (increased for reliability)
          headers: {
            "User-Agent": "EcoCheck-Backend/1.0",
          },
        });

        if (
          response.data &&
          response.data.code === "Ok" &&
          response.data.routes &&
          response.data.routes.length > 0 &&
          response.data.routes[0].distance
        ) {
          const distance = response.data.routes[0].distance;

          // Cache the result (but limit cache size)
          if (osrmDistanceCache.size >= OSRM_CACHE_MAX_SIZE) {
            // Remove oldest entry (simple FIFO)
            const firstKey = osrmDistanceCache.keys().next().value;
            osrmDistanceCache.delete(firstKey);
          }
          osrmDistanceCache.set(cacheKey, distance);

          return distance;
        }
      } catch (error) {
        lastError = error;
        if (attempt < retries) {
          // Wait a bit before retry (exponential backoff)
          await new Promise((resolve) => setTimeout(resolve, attempt * 200));
          continue;
        }
      }
    }

    // If all retries failed, fall back to Haversine (but don't cache)
    console.warn(
      `[OSRM] Distance calculation failed after ${retries} attempts, using Haversine fallback: ${
        lastError?.message || "Unknown error"
      }`
    );
    return getHaversineDistance(point1, point2);
  } catch (error) {
    console.warn(
      `[OSRM] Distance calculation error: ${error.message}, using Haversine fallback`
    );
    return getHaversineDistance(point1, point2);
  }
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

// Realtime endpoints - Query from database
app.get("/api/rt/checkins", async (req, res) => {
  try {
    const n = Number(req.query.n || 30);

    // Query recent checkins from database (last 24 hours)
    const query = `
      SELECT 
        c.id,
        COALESCE(c.waste_type, 'household') as type,
        CASE 
          WHEN c.filling_level < 0.3 THEN 'low'
          WHEN c.filling_level < 0.7 THEN 'medium'
          ELSE 'high'
        END as level,
        CASE 
          WHEN c.waste_type = 'bulky' OR c.waste_type = 'hazardous' THEN true
          ELSE false
        END as incident,
        ST_Y(c.geom::geometry) as lat,
        ST_X(c.geom::geometry) as lon,
        EXTRACT(EPOCH FROM c.created_at) * 1000 as ts
      FROM checkins c
      WHERE c.created_at >= NOW() - INTERVAL '24 hours'
        AND c.geom IS NOT NULL
      ORDER BY c.created_at DESC
      LIMIT $1
    `;

    const { rows } = await db.query(query, [n]);

    // Transform to match frontend format
    const points = rows.map((row) => ({
      id: row.id,
      type: row.type === "ghost" ? "ghost" : row.type,
      level: row.level,
      incident: row.incident,
      lat: parseFloat(row.lat),
      lon: parseFloat(row.lon),
      ts: parseInt(row.ts),
    }));

    res.set("Cache-Control", "no-store").json({ ok: true, data: points });
  } catch (error) {
    console.error("[API] Error fetching realtime checkins:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Realtime endpoints (viewport + delta) - Query from database
app.get("/api/rt/points", async (req, res) => {
  try {
    const bbox = (req.query.bbox || "").split(",").map(parseFloat);
    const since = req.query.since
      ? new Date(Number(req.query.since))
      : undefined;

    let query = `
      SELECT 
        p.id,
        p.lon,
        p.lat,
        COALESCE(p.last_waste_type, 'household') as type,
        COALESCE(p.last_level, 0.5) as level,
        p.ghost,
        EXTRACT(EPOCH FROM COALESCE(p.last_checkin_at, NOW())) * 1000 as ts
      FROM (
        SELECT 
          id,
          ST_X(geom::geometry) as lon,
          ST_Y(geom::geometry) as lat,
          last_waste_type,
          last_level,
          ghost,
          last_checkin_at
        FROM points
        WHERE geom IS NOT NULL
    `;

    const params = [];
    let paramIndex = 1;

    // Apply bbox filter if provided
    if (bbox.length === 4) {
      const [minLng, minLat, maxLng, maxLat] = bbox;
      query += ` AND ST_X(geom::geometry) >= $${paramIndex++} 
                 AND ST_X(geom::geometry) <= $${paramIndex++}
                 AND ST_Y(geom::geometry) >= $${paramIndex++}
                 AND ST_Y(geom::geometry) <= $${paramIndex++}`;
      params.push(minLng, maxLng, minLat, maxLat);
    }

    // Apply since filter if provided
    if (since) {
      query += ` AND COALESCE(last_checkin_at, NOW()) >= $${paramIndex++}`;
      params.push(since);
    }

    query += ` ORDER BY COALESCE(last_checkin_at, NOW()) DESC LIMIT 1500
      ) p
    `;

    const { rows } = await db.query(query, params);

    // Transform to match frontend format
    const added = rows.map((row) => ({
      id: row.id,
      lon: parseFloat(row.lon),
      lat: parseFloat(row.lat),
      type: row.ghost ? "ghost" : row.type, // Set type to 'ghost' if ghost point
      level: parseFloat(row.level) || 0,
      ghost: row.ghost || false,
      ts: parseInt(row.ts),
    }));

    res.set("Cache-Control", "no-store").json({
      ok: true,
      serverTime: Date.now(),
      added,
      updated: [],
      removed: [],
    });
  } catch (error) {
    console.error("[API] Error fetching realtime points:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

app.get("/api/rt/vehicles", async (req, res) => {
  try {
    // Query latest vehicle tracking data for active vehicles
    // If no tracking data, fallback to depot location
    const query = `
      SELECT DISTINCT ON (v.id)
        v.id,
        COALESCE(ST_X(vt.geom::geometry), ST_X(d.geom::geometry)) as lon,
        COALESCE(ST_Y(vt.geom::geometry), ST_Y(d.geom::geometry)) as lat,
        COALESCE(vt.speed_kmh, 0) as speed,
        COALESCE(vt.heading, 0) as heading,
        EXTRACT(EPOCH FROM COALESCE(vt.recorded_at, NOW())) * 1000 as ts
      FROM vehicles v
      LEFT JOIN depots d ON v.depot_id = d.id
      LEFT JOIN LATERAL (
        SELECT geom, speed_kmh, heading, recorded_at
        FROM vehicle_tracking
        WHERE vehicle_id = v.id
          AND recorded_at >= NOW() - INTERVAL '1 hour'
        ORDER BY recorded_at DESC
        LIMIT 1
      ) vt ON true
      WHERE v.status IN ('available', 'in_use')
        AND (vt.geom IS NOT NULL OR d.geom IS NOT NULL)
      ORDER BY v.id, COALESCE(vt.recorded_at, '1970-01-01'::timestamptz) DESC NULLS LAST
    `;

    const { rows } = await db.query(query);

    // Transform to match frontend format
    const vehicles = rows.map((row) => {
      const lon = row.lon ? parseFloat(row.lon) : 106.7; // Default HCMC center
      const lat = row.lat ? parseFloat(row.lat) : 10.78;

      return {
        id: row.id,
        lon: lon,
        lat: lat,
        speed: parseFloat(row.speed) || 0,
        heading: parseFloat(row.heading) || 0,
        ts: parseInt(row.ts) || Date.now(),
      };
    });

    res
      .set("Cache-Control", "no-store")
      .json({ ok: true, data: vehicles, serverTime: Date.now() });
  } catch (error) {
    console.error("[API] Error fetching realtime vehicles:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Socket.IO for fleet broadcast - Query from database
io.on("connection", async (socket) => {
  try {
    // Query vehicles on connection
    const query = `
      SELECT DISTINCT ON (v.id)
        v.id,
        COALESCE(ST_X(vt.geom::geometry), ST_X(d.geom::geometry)) as lon,
        COALESCE(ST_Y(vt.geom::geometry), ST_Y(d.geom::geometry)) as lat,
        COALESCE(vt.speed_kmh, 0) as speed,
        COALESCE(vt.heading, 0) as heading,
        EXTRACT(EPOCH FROM COALESCE(vt.recorded_at, NOW())) * 1000 as ts
      FROM vehicles v
      LEFT JOIN depots d ON v.depot_id = d.id
      LEFT JOIN LATERAL (
        SELECT geom, speed_kmh, heading, recorded_at
        FROM vehicle_tracking
        WHERE vehicle_id = v.id
          AND recorded_at >= NOW() - INTERVAL '1 hour'
        ORDER BY recorded_at DESC
        LIMIT 1
      ) vt ON true
      WHERE v.status IN ('available', 'in_use')
        AND (vt.geom IS NOT NULL OR d.geom IS NOT NULL)
      ORDER BY v.id, COALESCE(vt.recorded_at, '1970-01-01'::timestamptz) DESC NULLS LAST
    `;

    const { rows } = await db.query(query);
    const vehicles = rows.map((row) => ({
      id: row.id,
      lon: parseFloat(row.lon) || 106.7,
      lat: parseFloat(row.lat) || 10.78,
      speed: parseFloat(row.speed) || 0,
      heading: parseFloat(row.heading) || 0,
      ts: parseInt(row.ts) || Date.now(),
    }));

    socket.emit("fleet:init", vehicles);
  } catch (error) {
    console.error("[Socket.IO] Error fetching vehicles on connection:", error);
    socket.emit("fleet:init", []);
  }
});

// Broadcast fleet updates every second
setInterval(async () => {
  try {
    const query = `
      SELECT DISTINCT ON (v.id)
        v.id,
        COALESCE(ST_X(vt.geom::geometry), ST_X(d.geom::geometry)) as lon,
        COALESCE(ST_Y(vt.geom::geometry), ST_Y(d.geom::geometry)) as lat,
        COALESCE(vt.speed_kmh, 0) as speed,
        COALESCE(vt.heading, 0) as heading,
        EXTRACT(EPOCH FROM COALESCE(vt.recorded_at, NOW())) * 1000 as ts
      FROM vehicles v
      LEFT JOIN depots d ON v.depot_id = d.id
      LEFT JOIN LATERAL (
        SELECT geom, speed_kmh, heading, recorded_at
        FROM vehicle_tracking
        WHERE vehicle_id = v.id
          AND recorded_at >= NOW() - INTERVAL '1 hour'
        ORDER BY recorded_at DESC
        LIMIT 1
      ) vt ON true
      WHERE v.status IN ('available', 'in_use')
        AND (vt.geom IS NOT NULL OR d.geom IS NOT NULL)
      ORDER BY v.id, COALESCE(vt.recorded_at, '1970-01-01'::timestamptz) DESC NULLS LAST
    `;

    const { rows } = await db.query(query);
    const vehicles = rows.map((row) => ({
      id: row.id,
      lon: parseFloat(row.lon) || 106.7,
      lat: parseFloat(row.lat) || 10.78,
      speed: parseFloat(row.speed) || 0,
      heading: parseFloat(row.heading) || 0,
      ts: parseInt(row.ts) || Date.now(),
    }));

    io.emit("fleet", vehicles);
  } catch (error) {
    console.error("[Socket.IO] Error broadcasting fleet:", error);
  }
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
    const { status, type, depot_id, district } = req.query;

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
        d.address as depot_address,
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

    // Filter by district (from depot address)
    if (district) {
      query += ` AND (
        d.address ~ $${paramIndex} OR
        d.address LIKE $${paramIndex + 1}
      )`;
      const districtPattern = district.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
      params.push(`.*${districtPattern}.*`, `%${district}%`);
      paramIndex += 2;
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

    // CRITICAL FIX: Validate and map status
    // Database constraint requires: 'available', 'in_use', 'maintenance', 'retired'
    let dbStatus = status || 'available';
    if (dbStatus === 'ready') {
      dbStatus = 'available';
    } else if (!['available', 'in_use', 'maintenance', 'retired'].includes(dbStatus)) {
      console.warn(`[Fleet] Invalid status "${dbStatus}", defaulting to 'available'`);
      dbStatus = 'available';
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
        dbStatus,
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
      // CRITICAL FIX: Map frontend status to database values
      // Database constraint requires: 'available', 'in_use', 'maintenance', 'retired'
      let dbStatus = status;
      if (status === 'ready') {
        dbStatus = 'available';
      } else if (!['available', 'in_use', 'maintenance', 'retired'].includes(status)) {
        // Invalid status, default to 'available'
        console.warn(`[Fleet] Invalid status "${status}", defaulting to 'available'`);
        dbStatus = 'available';
      }
      updates.push(`status = $${paramIndex++}`);
      params.push(dbStatus);
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
    const { status, district } = req.query;

    let query = `
      SELECT 
        id,
        name,
        CASE WHEN geom IS NOT NULL THEN ST_X(geom::geometry)::numeric ELSE NULL END as lon,
        CASE WHEN geom IS NOT NULL THEN ST_Y(geom::geometry)::numeric ELSE NULL END as lat,
        address,
        capacity_vehicles,
        opening_hours,
        status,
        meta,
        created_at,
        updated_at,
        CASE 
          WHEN address IS NOT NULL AND address ~ 'Quận\\s*\\d+' THEN 
            'Quận ' || COALESCE((regexp_match(address, 'Quận\\s*(\\d+)'))[1], '')
          WHEN address IS NOT NULL AND address ~ 'Q\\.?\\s*\\d+' THEN 
            'Quận ' || COALESCE((regexp_match(address, 'Q\\.?\\s*(\\d+)'))[1], '')
          WHEN address IS NOT NULL AND address ~ 'Bình Thạnh' THEN 'Bình Thạnh'
          WHEN address IS NOT NULL AND address ~ 'Tân Bình' THEN 'Tân Bình'
          WHEN address IS NOT NULL AND address ~ 'Tân Phú' THEN 'Tân Phú'
          WHEN address IS NOT NULL AND address ~ 'Phú Nhuận' THEN 'Phú Nhuận'
          WHEN address IS NOT NULL AND address ~ 'Gò Vấp' THEN 'Gò Vấp'
          WHEN address IS NOT NULL AND address ~ 'Bình Tân' THEN 'Bình Tân'
          WHEN address IS NOT NULL AND address ~ 'Thủ Đức' THEN 'Thủ Đức'
          ELSE NULL
        END as district
      FROM depots
      WHERE 1=1
    `;
    const params = [];
    let paramIndex = 1;

    if (status) {
      query += ` AND status = $${paramIndex++}`;
      params.push(status);
    }

    // Filter by district (from depot address)
    if (district) {
      query += ` AND (
        address ~ $${paramIndex} OR
        address LIKE $${paramIndex + 1}
      )`;
      const districtPattern = district.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
      params.push(`.*${districtPattern}.*`, `%${district}%`);
      paramIndex += 2;
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

    // Validate required fields
    if (!name || (typeof name === "string" && name.trim().length === 0)) {
      return res.status(400).json({
        ok: false,
        error: "Missing required field: name",
      });
    }

    // Validate coordinates - check for null, undefined, or invalid numbers
    if (
      lon === null ||
      lon === undefined ||
      lat === null ||
      lat === undefined
    ) {
      return res.status(400).json({
        ok: false,
        error:
          "Missing required fields: lon, lat. Please select a location on the map.",
      });
    }

    const lonNum = parseFloat(lon);
    const latNum = parseFloat(lat);

    if (isNaN(lonNum) || isNaN(latNum)) {
      return res.status(400).json({
        ok: false,
        error: "Invalid coordinates: lon and lat must be valid numbers",
      });
    }

    if (lonNum < -180 || lonNum > 180 || latNum < -90 || latNum > 90) {
      return res.status(400).json({
        ok: false,
        error:
          "Invalid coordinates: lon must be between -180 and 180, lat must be between -90 and 90",
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
        CASE WHEN geom IS NOT NULL THEN ST_X(geom::geometry)::numeric ELSE NULL END as lon,
        CASE WHEN geom IS NOT NULL THEN ST_Y(geom::geometry)::numeric ELSE NULL END as lat,
        address,
        capacity_vehicles,
        opening_hours,
        status,
        created_at,
        updated_at,
        CASE 
          WHEN address IS NOT NULL AND address ~ 'Quận\\s*\\d+' THEN 
            'Quận ' || COALESCE((regexp_match(address, 'Quận\\s*(\\d+)'))[1], '')
          WHEN address IS NOT NULL AND address ~ 'Q\\.?\\s*\\d+' THEN 
            'Quận ' || COALESCE((regexp_match(address, 'Q\\.?\\s*(\\d+)'))[1], '')
          WHEN address IS NOT NULL AND address ~ 'Bình Thạnh' THEN 'Bình Thạnh'
          WHEN address IS NOT NULL AND address ~ 'Tân Bình' THEN 'Tân Bình'
          WHEN address IS NOT NULL AND address ~ 'Tân Phú' THEN 'Tân Phú'
          WHEN address IS NOT NULL AND address ~ 'Phú Nhuận' THEN 'Phú Nhuận'
          WHEN address IS NOT NULL AND address ~ 'Gò Vấp' THEN 'Gò Vấp'
          WHEN address IS NOT NULL AND address ~ 'Bình Tân' THEN 'Bình Tân'
          WHEN address IS NOT NULL AND address ~ 'Thủ Đức' THEN 'Thủ Đức'
          ELSE NULL
        END as district`,
      [
        depotId,
        typeof name === "string" ? name.trim() : name,
        lonNum,
        latNum,
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
        CASE WHEN geom IS NOT NULL THEN ST_X(geom::geometry)::numeric ELSE NULL END as lon,
        CASE WHEN geom IS NOT NULL THEN ST_Y(geom::geometry)::numeric ELSE NULL END as lat,
        address,
        capacity_vehicles,
        opening_hours,
        status,
        created_at,
        updated_at,
        CASE 
          WHEN address IS NOT NULL AND address ~ 'Quận\\s*\\d+' THEN 
            'Quận ' || COALESCE((regexp_match(address, 'Quận\\s*(\\d+)'))[1], '')
          WHEN address IS NOT NULL AND address ~ 'Q\\.?\\s*\\d+' THEN 
            'Quận ' || COALESCE((regexp_match(address, 'Q\\.?\\s*(\\d+)'))[1], '')
          WHEN address IS NOT NULL AND address ~ 'Bình Thạnh' THEN 'Bình Thạnh'
          WHEN address IS NOT NULL AND address ~ 'Tân Bình' THEN 'Tân Bình'
          WHEN address IS NOT NULL AND address ~ 'Tân Phú' THEN 'Tân Phú'
          WHEN address IS NOT NULL AND address ~ 'Phú Nhuận' THEN 'Phú Nhuận'
          WHEN address IS NOT NULL AND address ~ 'Gò Vấp' THEN 'Gò Vấp'
          WHEN address IS NOT NULL AND address ~ 'Bình Tân' THEN 'Bình Tân'
          WHEN address IS NOT NULL AND address ~ 'Thủ Đức' THEN 'Thủ Đức'
          ELSE NULL
        END as district`;
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

// Helper function to extract district from address
function extractDistrict(address) {
  if (!address) return null;
  const match = address.match(/Quận\s*(\d+)|Q\.?\s*(\d+)/i);
  if (match) {
    return `Quận ${match[1] || match[2]}`;
  }
  const districts = [
    "Quận 1",
    "Quận 2",
    "Quận 3",
    "Quận 4",
    "Quận 5",
    "Quận 6",
    "Quận 7",
    "Quận 8",
    "Quận 9",
    "Quận 10",
    "Quận 11",
    "Quận 12",
    "Bình Thạnh",
    "Tân Bình",
    "Tân Phú",
    "Phú Nhuận",
    "Gò Vấp",
    "Bình Tân",
    "Thủ Đức",
  ];
  for (const dist of districts) {
    if (address.includes(dist)) return dist;
  }
  return null;
}

// Helper function to extract ward from address
function extractWard(address) {
  if (!address) return null;
  const match = address.match(/(Phường|Xã)\s*([\w\s\d]+)/i);
  if (match) {
    return `${match[1]} ${match[2]}`;
  }
  const wards = [
    "Phường Bến Nghé",
    "Phường Phạm Ngũ Lão",
    "Phường Thới An Đông",
    "Xã Phước Kiển",
    "Xã Phú Hữu",
  ];
  for (const ward of wards) {
    if (address.includes(ward)) return ward;
  }
  return null;
}

// Helper function to get vehicle current location
async function getVehicleCurrentLocation(vehicleId) {
  try {
    // Option 1: Get from GPS tracking (if available)
    const tracking = await db.query(
      `SELECT 
        ST_X(geom::geometry) as lon,
        ST_Y(geom::geometry) as lat,
        recorded_at 
       FROM vehicle_tracking 
       WHERE vehicle_id = $1 
       ORDER BY recorded_at DESC LIMIT 1`,
      [vehicleId]
    );

    if (
      tracking.rows.length > 0 &&
      tracking.rows[0].lon &&
      tracking.rows[0].lat
    ) {
      return {
        lon: parseFloat(tracking.rows[0].lon),
        lat: parseFloat(tracking.rows[0].lat),
      };
    }

    // Option 2: Get from depot of vehicle (fallback)
    const vehicle = await db.query(
      `SELECT 
        ST_X(d.geom::geometry) as lon,
        ST_Y(d.geom::geometry) as lat
       FROM vehicles v
       JOIN depots d ON v.depot_id = d.id
       WHERE v.id = $1`,
      [vehicleId]
    );

    if (vehicle.rows.length > 0 && vehicle.rows[0].lon && vehicle.rows[0].lat) {
      return {
        lon: parseFloat(vehicle.rows[0].lon),
        lat: parseFloat(vehicle.rows[0].lat),
      };
    }

    // Option 3: Default location (HCM center)
    return { lon: 106.7, lat: 10.78 };
  } catch (error) {
    console.warn(
      `[VRP] Error getting vehicle location for ${vehicleId}:`,
      error.message
    );
    // Fallback to default
    return { lon: 106.7, lat: 10.78 };
  }
}

// Helper function: Build distance graph for all points using OSRM for nearest neighbors
// This creates a more accurate graph using real road distances for optimization
async function buildDistanceGraph(
  points,
  useOSRMForNearest = true,
  nearestCount = 10
) {
  const graph = {};

  // First, build graph with Haversine distances (fast, approximate)
  for (let i = 0; i < points.length; i++) {
    const nodeId = `p${i}`;
    graph[nodeId] = {};
    for (let j = 0; j < points.length; j++) {
      if (i !== j) {
        const nodeId2 = `p${j}`;
        const dist = getHaversineDistance(
          { lat: points[i].lat, lon: points[i].lon },
          { lat: points[j].lat, lon: points[j].lon }
        );
        graph[nodeId][nodeId2] = dist;
      }
    }
  }

  // If OSRM is enabled, update distances for nearest neighbors with real road distances
  // OPTIMIZED: Use batch processing to avoid rate limiting and timeouts
  if (useOSRMForNearest && points.length > 1) {
    // Reduce nearestCount for large datasets to avoid too many API calls
    const actualNearestCount =
      points.length > 20 ? Math.min(5, nearestCount) : nearestCount;
    console.log(
      `[VRP] Building OSRM-enhanced distance graph (updating ${actualNearestCount} nearest neighbors per point, batch processing)...`
    );

    // Process points in batches to avoid overwhelming OSRM server
    const batchSize = 5; // Process 5 points at a time
    const delayBetweenBatches = 500; // 500ms delay between batches

    for (
      let batchStart = 0;
      batchStart < points.length;
      batchStart += batchSize
    ) {
      const batchEnd = Math.min(batchStart + batchSize, points.length);

      // Process batch of points
      for (let i = batchStart; i < batchEnd; i++) {
        const nodeId = `p${i}`;
        const point1 = points[i];

        // Get all distances from this point and sort by distance
        const distances = [];
        for (const neighborId in graph[nodeId]) {
          distances.push({
            neighborId,
            dist: graph[nodeId][neighborId],
            pointIndex: parseInt(neighborId.replace("p", "")),
          });
        }

        // Sort by Haversine distance and take nearest N
        distances.sort((a, b) => a.dist - b.dist);
        const nearest = distances.slice(
          0,
          Math.min(actualNearestCount, distances.length)
        );

        // Process OSRM requests sequentially (not parallel) to avoid rate limiting
        for (const { neighborId, pointIndex } of nearest) {
          const point2 = points[pointIndex];
          try {
            const osrmDist = await getOSRMDistance(point1, point2);
            if (osrmDist) {
              graph[nodeId][neighborId] = osrmDist;
              // Also update reverse direction (bidirectional graph)
              const reverseNodeId = neighborId;
              const reverseNeighborId = nodeId;
              if (graph[reverseNodeId]) {
                graph[reverseNodeId][reverseNeighborId] = osrmDist;
              }
            }
            // Small delay between requests to avoid rate limiting
            await new Promise((resolve) => setTimeout(resolve, 100));
          } catch (error) {
            // Keep Haversine distance if OSRM fails
            console.warn(
              `[VRP] OSRM distance failed for ${nodeId}->${neighborId}, keeping Haversine: ${error.message}`
            );
          }
        }
      }

      // Delay between batches
      if (batchEnd < points.length) {
        await new Promise((resolve) =>
          setTimeout(resolve, delayBetweenBatches)
        );
      }
    }

    console.log(`[VRP] OSRM-enhanced distance graph completed`);
  }

  return graph;
}

// Dijkstra algorithm to find shortest path between two points in graph
function dijkstraShortestPath(graph, startNode, endNode) {
  const distances = {};
  const previous = {};
  const unvisited = new Set();

  // Initialize distances
  for (const node in graph) {
    distances[node] = Infinity;
    unvisited.add(node);
  }
  distances[startNode] = 0;

  while (unvisited.size > 0) {
    // Find unvisited node with smallest distance
    let current = null;
    let minDist = Infinity;
    for (const node of unvisited) {
      if (distances[node] < minDist) {
        minDist = distances[node];
        current = node;
      }
    }

    if (current === null || current === endNode) break;
    unvisited.delete(current);

    // Update distances to neighbors
    if (graph[current]) {
      for (const neighbor in graph[current]) {
        if (!unvisited.has(neighbor)) continue;
        const alt = distances[current] + graph[current][neighbor];
        if (alt < distances[neighbor]) {
          distances[neighbor] = alt;
          previous[neighbor] = current;
        }
      }
    }
  }

  // Reconstruct path
  const path = [];
  let current = endNode;
  while (current !== undefined && distances[current] < Infinity) {
    path.unshift(current);
    current = previous[current];
    if (current === startNode) {
      path.unshift(current);
      break;
    }
  }

  return { path, distance: distances[endNode] };
}

// A* algorithm with Haversine heuristic
function aStarShortestPath(graph, startNode, endNode, points) {
  const openSet = new Set([startNode]);
  const closedSet = new Set();
  const gScore = { [startNode]: 0 };
  const fScore = {};
  const cameFrom = {};

  // Get point indices from node IDs
  const getPointIndex = (nodeId) => parseInt(nodeId.replace("p", ""));
  const startIdx = getPointIndex(startNode);
  const endIdx = getPointIndex(endNode);

  // Initialize fScore with heuristic (Haversine distance)
  fScore[startNode] = getHaversineDistance(
    { lat: points[startIdx].lat, lon: points[startIdx].lon },
    { lat: points[endIdx].lat, lon: points[endIdx].lon }
  );

  while (openSet.size > 0) {
    // Find node in openSet with lowest fScore
    let current = null;
    let minF = Infinity;
    for (const node of openSet) {
      if (fScore[node] < minF) {
        minF = fScore[node];
        current = node;
      }
    }

    if (current === endNode) {
      // Reconstruct path
      const path = [];
      let node = endNode;
      while (node !== undefined) {
        path.unshift(node);
        node = cameFrom[node];
      }
      return { path, distance: gScore[endNode] };
    }

    openSet.delete(current);
    closedSet.add(current);

    // Check neighbors
    if (graph[current]) {
      for (const neighbor in graph[current]) {
        if (closedSet.has(neighbor)) continue;

        const tentativeGScore = gScore[current] + graph[current][neighbor];

        if (!openSet.has(neighbor)) {
          openSet.add(neighbor);
        } else if (tentativeGScore >= (gScore[neighbor] || Infinity)) {
          continue;
        }

        cameFrom[neighbor] = current;
        gScore[neighbor] = tentativeGScore;

        // Calculate heuristic (Haversine distance to end)
        const neighborIdx = getPointIndex(neighbor);
        fScore[neighbor] =
          gScore[neighbor] +
          getHaversineDistance(
            { lat: points[neighborIdx].lat, lon: points[neighborIdx].lon },
            { lat: points[endIdx].lat, lon: points[endIdx].lon }
          );
      }
    }
  }

  return null; // No path found
}

// --- CORE ALGORITHMS: Hybrid CI-SA (Cheapest Insertion + Simulated Annealing) ---

// Giai đoạn 1: Cheapest Insertion (Xây dựng sườn lộ trình tốt ngay từ đầu)
function solveCheapestInsertion(points, matrix, startIdx, endIdx) {
  // Bắt đầu với lộ trình: Start -> End (hoặc chỉ Start nếu không có End)
  let currentRoute = [startIdx];
  if (endIdx !== startIdx) currentRoute.push(endIdx);

  // Danh sách các điểm chưa thăm (loại trừ start/end)
  let unvisited = new Set();
  for (let i = 0; i < points.length; i++) {
    if (i !== startIdx && i !== endIdx) unvisited.add(i);
  }

  // Vòng lặp chèn điểm
  while (unvisited.size > 0) {
    let bestPoint = -1;
    let bestInsertPos = -1;
    let minAddedCost = Infinity;

    // Duyệt qua từng điểm chưa thăm
    for (let pointIdx of unvisited) {
      // Nếu route chỉ có 1 điểm (Start), chèn vào cuối
      if (currentRoute.length === 1) {
        let addedCost = 0;
        const u = currentRoute[0];
        if (matrix) {
          const costUP =
            matrix.durations[u][pointIdx] * 0.7 +
            matrix.distances[u][pointIdx] * 0.3;
          addedCost = costUP;
        } else {
          addedCost = getHaversineDistance(points[u], points[pointIdx]);
        }

        if (addedCost < minAddedCost) {
          minAddedCost = addedCost;
          bestPoint = pointIdx;
          bestInsertPos = 1; // Chèn vào sau Start
        }
      } else {
        // Thử chèn vào giữa từng cặp điểm hiện có (u -> v)
        for (let i = 0; i < currentRoute.length - 1; i++) {
          const u = currentRoute[i];
          const v = currentRoute[i + 1];

          // Chi phí tăng thêm = (u->p + p->v) - (u->v)
          let addedCost = 0;
          if (matrix) {
            // Cost = 0.7*Time + 0.3*Dist
            const costUP =
              matrix.durations[u][pointIdx] * 0.7 +
              matrix.distances[u][pointIdx] * 0.3;
            const costPV =
              matrix.durations[pointIdx][v] * 0.7 +
              matrix.distances[pointIdx][v] * 0.3;
            const costUV =
              matrix.durations[u][v] * 0.7 + matrix.distances[u][v] * 0.3;
            addedCost = costUP + costPV - costUV;
          } else {
            const distUP = getHaversineDistance(points[u], points[pointIdx]);
            const distPV = getHaversineDistance(points[pointIdx], points[v]);
            const distUV = getHaversineDistance(points[u], points[v]);
            addedCost = distUP + distPV - distUV;
          }

          if (addedCost < minAddedCost) {
            minAddedCost = addedCost;
            bestPoint = pointIdx;
            bestInsertPos = i + 1; // Chèn vào sau u
          }
        }
      }
    }

    if (bestPoint !== -1) {
      currentRoute.splice(bestInsertPos, 0, bestPoint);
      unvisited.delete(bestPoint);
    } else {
      break; // Should not happen
    }
  }

  return currentRoute;
}

// Giai đoạn 2: Simulated Annealing (Tinh chỉnh để đạt tối ưu)
async function optimizeRouteHybrid(stops, startPoint, endPoint) {
  // 1. Chuẩn bị dữ liệu: Gộp tất cả điểm vào 1 mảng để lấy Matrix
  // Mapping: Index 0 = Start, 1..N = Stops, N+1 = End
  const allPoints = [startPoint, ...stops];
  if (endPoint) allPoints.push(endPoint);

  const startIdx = 0;
  const endIdx = endPoint ? allPoints.length - 1 : 0; // Nếu không có endpoint thì quay về start

  // 2. Lấy Matrix (QUAN TRỌNG)
  console.log(`[VRP] Calling OSRM Matrix for ${allPoints.length} points...`);
  const matrix = await getOSRMMatrix(allPoints);

  // 3. Chạy Phase 1: Cheapest Insertion
  // Kết quả trả về là mảng các index, ví dụ: [0, 5, 2, 3, 1, 6]
  let currentOrder = solveCheapestInsertion(
    allPoints,
    matrix,
    startIdx,
    endIdx
  );

  // Đảm bảo start và end luôn ở đúng vị trí sau Cheapest Insertion
  if (currentOrder[0] !== startIdx) {
    console.warn(
      `[VRP] Fixing start position after CI: expected ${startIdx}, got ${currentOrder[0]}`
    );
    currentOrder = [
      startIdx,
      ...currentOrder.filter((idx) => idx !== startIdx && idx !== endIdx),
    ];
    if (endPoint) currentOrder.push(endIdx);
  }
  if (endPoint && currentOrder[currentOrder.length - 1] !== endIdx) {
    console.warn(
      `[VRP] Fixing end position after CI: expected ${endIdx}, got ${
        currentOrder[currentOrder.length - 1]
      }`
    );
    currentOrder = currentOrder.filter((idx) => idx !== endIdx);
    currentOrder.push(endIdx);
  }

  // 4. Chạy Phase 2: Simulated Annealing
  // Cấu hình SA: Nóng nhanh, nguội từ từ
  let temp = 1000;
  const coolingRate = 0.99;
  const absoluteTemperature = 1;

  // Các điểm ở giữa (loại trừ start và end cố định)
  // Chúng ta chỉ hoán đổi vị trí các điểm ở giữa start và end
  let bestOrder = [...currentOrder];
  let currentCost = calculateRouteCost(currentOrder, matrix, allPoints);
  let bestCost = currentCost;

  while (temp > absoluteTemperature) {
    // Chỉ tráo đổi các điểm ở giữa (index từ 1 đến length-2)
    // Cần ít nhất 2 điểm ở giữa để có thể tráo đổi (Start + 2 stops + End = 4 điểm tối thiểu)
    // Hoặc nếu không có End, cần ít nhất 3 điểm (Start + 2 stops = 3 điểm tối thiểu)
    const minLengthForSwap = endPoint ? 4 : 3;
    if (currentOrder.length >= minLengthForSwap) {
      const newOrder = [...currentOrder];

      // Chọn 2 vị trí ngẫu nhiên ở giữa để tác động
      // Vị trí hợp lệ: 1 đến newOrder.length - 2 (nếu có end) hoặc newOrder.length - 1 (nếu không có end)
      const middleStart = 1;
      const middleEnd = endPoint ? newOrder.length - 2 : newOrder.length - 1;

      if (middleEnd > middleStart) {
        const pos1 =
          Math.floor(Math.random() * (middleEnd - middleStart + 1)) +
          middleStart;
        const pos2 =
          Math.floor(Math.random() * (middleEnd - middleStart + 1)) +
          middleStart;

        if (
          pos1 !== pos2 &&
          pos1 >= middleStart &&
          pos1 <= middleEnd &&
          pos2 >= middleStart &&
          pos2 <= middleEnd
        ) {
          const moveType = Math.random();

          if (moveType < 0.5) {
            // Move 1: Swap (Đổi chỗ)
            [newOrder[pos1], newOrder[pos2]] = [newOrder[pos2], newOrder[pos1]];
          } else {
            // Move 2: 2-Opt (Đảo ngược đoạn) - Mạnh mẽ hơn Swap
            const start = Math.min(pos1, pos2);
            const end = Math.max(pos1, pos2);
            // Đảm bảo không đảo ngược start hoặc end
            if (start >= middleStart && end <= middleEnd) {
              const segment = newOrder.slice(start, end + 1).reverse();
              newOrder.splice(start, segment.length, ...segment);
            } else {
              continue; // Skip invalid move
            }
          }

          // Đảm bảo start và end vẫn ở đúng vị trí sau khi swap
          if (
            newOrder[0] !== startIdx ||
            (endPoint && newOrder[newOrder.length - 1] !== endIdx)
          ) {
            continue; // Skip invalid moves
          }

          const newCost = calculateRouteCost(newOrder, matrix, allPoints);
          const delta = newCost - currentCost;

          // Chấp nhận nếu tốt hơn HOẶC xác suất ngẫu nhiên (Metropolis criterion)
          if (delta < 0 || Math.exp(-delta / temp) > Math.random()) {
            currentOrder = newOrder;
            currentCost = newCost;

            if (newCost < bestCost) {
              bestOrder = [...newOrder];
              bestCost = newCost;
            }
          }
        }
      }
    }
    temp *= coolingRate;
  }

  // Đảm bảo bestOrder luôn có start và end đúng vị trí trước khi trả về
  if (bestOrder[0] !== startIdx) {
    console.warn(
      `[VRP] Fixing start position in bestOrder: expected ${startIdx}, got ${bestOrder[0]}`
    );
    bestOrder = [
      startIdx,
      ...bestOrder.filter((idx) => idx !== startIdx && idx !== endIdx),
    ];
    if (endPoint) bestOrder.push(endIdx);
  }
  if (endPoint && bestOrder[bestOrder.length - 1] !== endIdx) {
    console.warn(
      `[VRP] Fixing end position in bestOrder: expected ${endIdx}, got ${
        bestOrder[bestOrder.length - 1]
      }`
    );
    bestOrder = bestOrder.filter((idx) => idx !== endIdx);
    bestOrder.push(endIdx);
  }

  const initialCost = calculateRouteCost(
    solveCheapestInsertion(allPoints, matrix, startIdx, endIdx),
    matrix,
    allPoints
  );
  console.log(
    `[VRP] Hybrid Optimization: Initial Cost=${Math.round(
      initialCost
    )} -> Optimized=${Math.round(bestCost)}`
  );

  // 5. Convert indices back to stop objects
  // Loại bỏ Start (index 0) và End (index cuối) để trả về danh sách stops đã sắp xếp
  const optimizedStopsIndices = bestOrder.slice(
    1,
    endPoint ? bestOrder.length - 1 : bestOrder.length
  );

  // Map lại về object gốc
  // Lưu ý: Stops gốc trong allPoints bắt đầu từ index 1
  return optimizedStopsIndices.map((idx) => allPoints[idx]);
}

// OPTIMIZED: Nearest Neighbor + 2-opt for fast and accurate route optimization
// This algorithm is much faster than Dijkstra and produces near-optimal results
// Step 1: Nearest Neighbor (simple, fast O(n²))
// Step 2: 2-opt local search (improves route quality)
async function optimizeRouteWith2Opt(stops, startPoint, endPoint) {
  if (stops.length === 0) return [];

  console.log(
    `[VRP] Optimizing ${stops.length} stops using Nearest Neighbor + 2-opt`
  );

  // Step 1: Nearest Neighbor - Build initial route starting from startPoint
  const ordered = [];
  const remaining = [...stops];
  let current = startPoint;

  // Visit all stops using simple nearest neighbor
  while (remaining.length > 0) {
    let nearest = null;
    let minDist = Infinity;
    let nearestIdx = -1;

    for (let i = 0; i < remaining.length; i++) {
      const dist = getHaversineDistance(
        { lat: current.lat, lon: current.lon },
        { lat: remaining[i].lat, lon: remaining[i].lon }
      );
      if (dist < minDist) {
        minDist = dist;
        nearest = remaining[i];
        nearestIdx = i;
      }
    }

    if (nearest) {
      ordered.push(nearest);
      remaining.splice(nearestIdx, 1);
      current = nearest;
    } else {
      break;
    }
  }

  // Step 2: 2-opt local search to improve route
  // This tries reversing segments of the route to find shorter paths
  let improved = true;
  let iterations = 0;
  const maxIterations = Math.min(100, stops.length * 2); // Limit iterations for performance

  // Helper function to calculate total route distance
  const calculateRouteDistance = (route) => {
    if (route.length === 0) return 0;

    let total = getHaversineDistance(startPoint, route[0]);
    for (let i = 0; i < route.length - 1; i++) {
      total += getHaversineDistance(route[i], route[i + 1]);
    }
    total += getHaversineDistance(route[route.length - 1], endPoint);
    return total;
  };

  while (improved && iterations < maxIterations) {
    improved = false;
    iterations++;

    // Try all possible 2-opt swaps
    for (let i = 0; i < ordered.length - 1; i++) {
      for (let j = i + 2; j < ordered.length; j++) {
        // Current route: start -> ... -> ordered[i] -> ordered[i+1] -> ... -> ordered[j] -> ordered[j+1] -> ... -> end
        // New route: start -> ... -> ordered[i] -> ordered[j] -> ... -> ordered[i+1] -> ordered[j+1] -> ... -> end
        // (reverse segment from i+1 to j)

        // Calculate current distance
        const currentDist = calculateRouteDistance(ordered);

        // Create new route by reversing segment i+1 to j
        const newOrder = [
          ...ordered.slice(0, i + 1),
          ...ordered.slice(i + 1, j + 1).reverse(),
          ...ordered.slice(j + 1),
        ];

        // Calculate new distance
        const newDist = calculateRouteDistance(newOrder);

        // If new route is better, accept it
        if (newDist < currentDist - 0.1) {
          // Small threshold to avoid floating point issues
          ordered.splice(0, ordered.length, ...newOrder);
          improved = true;
          break;
        }
      }
      if (improved) break;
    }
  }

  if (iterations > 1) {
    console.log(
      `[VRP] 2-opt optimization completed in ${iterations} iterations`
    );
  }

  // VALIDATION: Ensure route doesn't have duplicate points
  const seenIds = new Set();
  const uniqueOrdered = [];
  for (const stop of ordered) {
    const stopId = stop.id || `${stop.lat},${stop.lon}`;
    if (!seenIds.has(stopId)) {
      seenIds.add(stopId);
      uniqueOrdered.push(stop);
    } else {
      console.warn(
        `[VRP] Duplicate point detected in route: ${stopId}, skipping`
      );
    }
  }

  return uniqueOrdered;
}

// Helper function to optimize stop order using Hybrid CI-SA (Cheapest Insertion + Simulated Annealing)
// This algorithm provides the best balance between speed and optimality for VRP/TSP problems
async function optimizeStopOrder(stops, startPoint, endPoint) {
  if (stops.length === 0) return [];

  // Use Hybrid CI-SA algorithm for optimal routing
  // This replaces the old Nearest Neighbor + 2-opt approach
  return await optimizeRouteHybrid(stops, startPoint, endPoint);
}

// --- SMART CLUSTERING: Sweep Line Algorithm ---
// Phân cụm điểm theo góc từ depot (giống cách shipper thực tế làm)
// Đảm bảo các điểm gần nhau về mặt địa lý được gom vào cùng một cụm
function clusterPointsBySweepLine(points, depot, numClusters) {
  if (points.length === 0) return [];
  if (numClusters <= 0) numClusters = 1;
  if (numClusters >= points.length) {
    // Mỗi điểm là một cụm
    return points.map((p) => [p]);
  }

  // 1. Tính góc (bearing) của mỗi điểm từ depot
  const pointsWithAngle = points.map((point) => {
    const dx = point.lon - depot.lon;
    const dy = point.lat - depot.lat;

    // Tính góc từ depot đến điểm (0-360 độ, 0 = Bắc, 90 = Đông)
    let angle = Math.atan2(dx, dy) * (180 / Math.PI);
    if (angle < 0) angle += 360;

    // Tính khoảng cách từ depot
    const distance = getHaversineDistance(depot, point);

    return {
      point,
      angle,
      distance,
    };
  });

  // 2. Sắp xếp theo góc (từ Bắc quay theo chiều kim đồng hồ)
  pointsWithAngle.sort((a, b) => {
    if (Math.abs(a.angle - b.angle) < 0.1) {
      // Nếu góc gần nhau, ưu tiên điểm gần hơn
      return a.distance - b.distance;
    }
    return a.angle - b.angle;
  });

  // 3. Chia thành các cụm theo góc (sweep line)
  const clusters = [];
  const pointsPerCluster = Math.ceil(pointsWithAngle.length / numClusters);

  for (let i = 0; i < numClusters; i++) {
    const startIdx = i * pointsPerCluster;
    const endIdx = Math.min(
      startIdx + pointsPerCluster,
      pointsWithAngle.length
    );

    if (startIdx < pointsWithAngle.length) {
      const cluster = pointsWithAngle
        .slice(startIdx, endIdx)
        .map((item) => item.point);
      if (cluster.length > 0) {
        clusters.push(cluster);
      }
    }
  }

  return clusters;
}

// --- K-Means Clustering (Alternative - nếu muốn dùng) ---
// Hàm K-Means đơn giản không cần thư viện ngoài
function clusterPointsByKMeans(points, numClusters, maxIterations = 10) {
  if (points.length === 0) return [];
  if (numClusters <= 0) numClusters = 1;
  if (numClusters >= points.length) {
    return points.map((p) => [p]);
  }

  // Khởi tạo centroids ngẫu nhiên
  let centroids = [];
  for (let i = 0; i < numClusters; i++) {
    const randomPoint = points[Math.floor(Math.random() * points.length)];
    centroids.push({ lat: randomPoint.lat, lon: randomPoint.lon });
  }

  let clusters = [];

  for (let iter = 0; iter < maxIterations; iter++) {
    // Gán mỗi điểm vào cụm gần nhất
    clusters = Array(numClusters)
      .fill(null)
      .map(() => []);

    for (const point of points) {
      let minDist = Infinity;
      let nearestCluster = 0;

      for (let i = 0; i < centroids.length; i++) {
        const dist = getHaversineDistance(point, centroids[i]);
        if (dist < minDist) {
          minDist = dist;
          nearestCluster = i;
        }
      }

      clusters[nearestCluster].push(point);
    }

    // Cập nhật centroids
    let changed = false;
    for (let i = 0; i < centroids.length; i++) {
      if (clusters[i].length === 0) continue;

      const avgLat =
        clusters[i].reduce((sum, p) => sum + p.lat, 0) / clusters[i].length;
      const avgLon =
        clusters[i].reduce((sum, p) => sum + p.lon, 0) / clusters[i].length;

      const oldCentroid = centroids[i];
      centroids[i] = { lat: avgLat, lon: avgLon };

      if (getHaversineDistance(oldCentroid, centroids[i]) > 10) {
        changed = true;
      }
    }

    // Nếu centroids không thay đổi nhiều, dừng lại
    if (!changed && iter > 2) break;
  }

  // Loại bỏ cụm rỗng
  return clusters.filter((c) => c.length > 0);
}

// Helper function to find best dump for district
async function findBestDumpForDistrict(depot, points, dumps) {
  if (!dumps || dumps.length === 0) return null;

  // Filter active dumps with valid coordinates
  const activeDumps = dumps.filter((d) => {
    const hasValidCoords =
      d.lat &&
      d.lon &&
      typeof d.lat === "number" &&
      typeof d.lon === "number" &&
      !isNaN(d.lat) &&
      !isNaN(d.lon);
    const isActive = d.status === "active" || !d.status;

    // Also ensure dump is NOT at the same location as depot
    let isDifferentFromDepot = true;
    if (depot && depot.lat && depot.lon && hasValidCoords) {
      const dist = getHaversineDistance(
        { lat: depot.lat, lon: depot.lon },
        { lat: d.lat, lon: d.lon }
      );
      isDifferentFromDepot = dist > 100; // At least 100m away from depot
    }

    return hasValidCoords && isActive && isDifferentFromDepot;
  });

  if (activeDumps.length === 0) {
    console.warn(
      `[VRP] No valid dumps found (with coords and different from depot)`
    );
    return null;
  }

  // Strategy: Find dump closest to the last stop (after visiting all points)
  // This ensures efficient end-of-route disposal
  let targetPoint = depot;

  if (points && points.length > 0) {
    // Use the farthest point from depot as target
    let maxDist = 0;
    for (const point of points) {
      if (!point.lat || !point.lon) continue;
      const dist = getHaversineDistance(
        { lat: depot.lat, lon: depot.lon },
        { lat: point.lat, lon: point.lon }
      );
      if (dist > maxDist) {
        maxDist = dist;
        targetPoint = point;
      }
    }
  }

  // Find dump nearest to target point (farthest point from depot)
  let nearestDump = null;
  let minDistance = Infinity;

  for (const dump of activeDumps) {
    if (!dump.lat || !dump.lon) continue;

    const distance = getHaversineDistance(
      { lat: targetPoint.lat, lon: targetPoint.lon },
      { lat: dump.lat, lon: dump.lon }
    );

    if (distance < minDistance) {
      minDistance = distance;
      nearestDump = dump;
    }
  }

  if (nearestDump) {
    console.log(
      `[VRP] Selected dump: ${nearestDump.name} at [${nearestDump.lon}, ${
        nearestDump.lat
      }], distance from target: ${Math.round(minDistance)}m`
    );
  }

  return nearestDump || activeDumps[0];
}

// Helper function to get route from OSRM (Open Source Routing Machine)
// IMPORTANT: Use segment-by-segment routing to ensure route passes through ALL waypoints
// OSRM route API with multiple waypoints may optimize route but skip intermediate stops
async function getOSRMRoute(waypoints) {
  try {
    if (!waypoints || waypoints.length < 2) {
      console.warn("[OSRM] Invalid waypoints: need at least 2 points");
      return null;
    }

    // Validate waypoints format: [lon, lat]
    for (const wp of waypoints) {
      if (
        !Array.isArray(wp) ||
        wp.length !== 2 ||
        typeof wp[0] !== "number" ||
        typeof wp[1] !== "number" ||
        wp[0] < -180 ||
        wp[0] > 180 ||
        wp[1] < -90 ||
        wp[1] > 90
      ) {
        console.warn(`[OSRM] Invalid waypoint format: ${JSON.stringify(wp)}`);
        return null;
      }
    }

    const axios = require("axios");

    // Remove duplicate consecutive waypoints (e.g., if dump = depot)
    const uniqueWaypoints = [];
    for (let i = 0; i < waypoints.length; i++) {
      const current = waypoints[i];
      const previous = uniqueWaypoints[uniqueWaypoints.length - 1];

      // Only add if different from previous waypoint (at least 10m apart, ~0.0001 degrees)
      // Use smaller threshold to ensure all stops are included
      if (
        !previous ||
        Math.abs(current[0] - previous[0]) > 0.0001 ||
        Math.abs(current[1] - previous[1]) > 0.0001
      ) {
        uniqueWaypoints.push(current);
      } else {
        console.warn(
          `[OSRM] Skipping duplicate waypoint ${i}: [${current[0].toFixed(
            4
          )}, ${current[1].toFixed(4)}] (same as previous - within 10m)`
        );
      }
    }

    if (uniqueWaypoints.length < 2) {
      console.warn(
        `[OSRM] Not enough unique waypoints (${uniqueWaypoints.length}), need at least 2`
      );
      return null;
    }

    // Skip single request - always use segment-by-segment for guaranteed waypoint inclusion

    // ALWAYS use segment-by-segment routing to ensure route passes through ALL waypoints
    // OSRM route API with multiple waypoints may optimize but skip intermediate stops
    console.log(
      `[OSRM] Using segment-by-segment routing to ensure route passes through all ${uniqueWaypoints.length} waypoints`
    );
    let totalDistance = 0;
    let totalDuration = 0;
    const allCoordinates = [];

    // Use uniqueWaypoints
    const fallbackWaypoints = uniqueWaypoints;

    for (let i = 0; i < fallbackWaypoints.length - 1; i++) {
      const start = fallbackWaypoints[i];
      const end = fallbackWaypoints[i + 1];

      const segmentCoords = `${start[0]},${start[1]};${end[0]},${end[1]}`;
      const segmentUrl = `https://router.project-osrm.org/route/v1/driving/${segmentCoords}?overview=full&geometries=geojson&alternatives=false&steps=false`;

      try {
        const segmentResponse = await axios.get(segmentUrl, {
          timeout: 10000,
          headers: {
            "User-Agent": "EcoCheck-Backend/1.0",
          },
        });

        if (
          segmentResponse.data &&
          segmentResponse.data.code === "Ok" &&
          segmentResponse.data.routes &&
          segmentResponse.data.routes.length > 0
        ) {
          const segmentRoute = segmentResponse.data.routes[0];
          if (
            segmentRoute.distance &&
            segmentRoute.duration &&
            segmentRoute.geometry
          ) {
            const segmentCoords = segmentRoute.geometry.coordinates;

            // CRITICAL FIX: Ensure smooth connection between segments
            if (i === 0) {
              // First segment: add all coordinates
              allCoordinates.push(...segmentCoords);
            } else {
              // Subsequent segments: ensure connection
              const lastCoord = allCoordinates[allCoordinates.length - 1];
              const firstCoord = segmentCoords[0];

              // Check if segments are connected (within 1m tolerance ~0.00001 degrees)
              const isConnected =
                Math.abs(lastCoord[0] - firstCoord[0]) < 0.00001 &&
                Math.abs(lastCoord[1] - firstCoord[1]) < 0.00001;

              if (isConnected) {
                // Connected: skip first coordinate to avoid duplicate
                allCoordinates.push(...segmentCoords.slice(1));
              } else {
                // NOT connected: create a smooth bridge line between segments
                // This ensures the route is continuous from START to END
                const gap = Math.sqrt(
                  Math.pow(lastCoord[0] - firstCoord[0], 2) +
                    Math.pow(lastCoord[1] - firstCoord[1], 2)
                );

                if (gap > 0.0001) {
                  // Only bridge if gap is significant (>10m)
                  console.log(
                    `[OSRM] Segment ${i}->${i + 1} gap detected (${Math.round(
                      gap * 111000
                    )}m), creating bridge`
                  );
                  // Create intermediate points for smooth connection (linear interpolation)
                  const bridgePoints = 3; // Number of intermediate points
                  for (let b = 1; b <= bridgePoints; b++) {
                    const t = b / (bridgePoints + 1);
                    const bridgeLon =
                      lastCoord[0] + (firstCoord[0] - lastCoord[0]) * t;
                    const bridgeLat =
                      lastCoord[1] + (firstCoord[1] - lastCoord[1]) * t;
                    allCoordinates.push([bridgeLon, bridgeLat]);
                  }
                }
                // Then add all segment coordinates
                allCoordinates.push(...segmentCoords);
              }
            }

            totalDistance += segmentRoute.distance;
            totalDuration += segmentRoute.duration;
          } else {
            // Invalid response data - log error but don't use straight line fallback
            console.error(
              `[OSRM] Segment ${i}->${
                i + 1
              } returned invalid data (missing distance/duration/geometry)`
            );
            throw new Error(
              `OSRM route segment ${i}->${i + 1} has invalid response data`
            );
          }
        } else {
          // OSRM returned error code
          const errorCode = segmentResponse.data?.code || "Unknown";
          const errorMessage =
            segmentResponse.data?.message || "No error message";
          console.error(
            `[OSRM] Segment ${i}->${
              i + 1
            } returned error code: ${errorCode}, message: ${errorMessage}`
          );
          throw new Error(
            `OSRM route segment ${i}->${
              i + 1
            } failed: ${errorCode} - ${errorMessage}`
          );
        }
      } catch (error) {
        // Retry logic for transient errors (timeout, network issues)
        const maxRetries = 3;
        let lastError = error;
        let retryCount = 0;

        while (retryCount < maxRetries) {
          try {
            console.log(
              `[OSRM] Segment ${i}->${i + 1} retry attempt ${
                retryCount + 1
              }/${maxRetries}...`
            );
            await new Promise((resolve) =>
              setTimeout(resolve, (retryCount + 1) * 500)
            ); // Exponential backoff

            const retryResponse = await axios.get(segmentUrl, {
              timeout: 10000, // Longer timeout for retry
              headers: {
                "User-Agent": "EcoCheck-Backend/1.0",
              },
            });

            if (
              retryResponse.data &&
              retryResponse.data.code === "Ok" &&
              retryResponse.data.routes &&
              retryResponse.data.routes.length > 0 &&
              retryResponse.data.routes[0].distance &&
              retryResponse.data.routes[0].duration &&
              retryResponse.data.routes[0].geometry
            ) {
              // Retry succeeded!
              const segmentRoute = retryResponse.data.routes[0];
              const segmentCoords = segmentRoute.geometry.coordinates;

              if (i === 0) {
                allCoordinates.push(...segmentCoords);
              } else {
                const lastCoord = allCoordinates[allCoordinates.length - 1];
                const firstCoord = segmentCoords[0];
                const isConnected =
                  Math.abs(lastCoord[0] - firstCoord[0]) < 0.00001 &&
                  Math.abs(lastCoord[1] - firstCoord[1]) < 0.00001;

                if (isConnected) {
                  allCoordinates.push(...segmentCoords.slice(1));
                } else {
                  // NOT connected: create a smooth bridge line between segments
                  const gap = Math.sqrt(
                    Math.pow(lastCoord[0] - firstCoord[0], 2) +
                      Math.pow(lastCoord[1] - firstCoord[1], 2)
                  );

                  if (gap > 0.0001) {
                    // Only bridge if gap is significant (>10m)
                    console.log(
                      `[OSRM] Segment ${i}->${
                        i + 1
                      } gap detected after retry (${Math.round(
                        gap * 111000
                      )}m), creating bridge`
                    );
                    // Create intermediate points for smooth connection
                    const bridgePoints = 3;
                    for (let b = 1; b <= bridgePoints; b++) {
                      const t = b / (bridgePoints + 1);
                      const bridgeLon =
                        lastCoord[0] + (firstCoord[0] - lastCoord[0]) * t;
                      const bridgeLat =
                        lastCoord[1] + (firstCoord[1] - lastCoord[1]) * t;
                      allCoordinates.push([bridgeLon, bridgeLat]);
                    }
                  }
                  allCoordinates.push(...segmentCoords);
                }
              }

              totalDistance += segmentRoute.distance;
              totalDuration += segmentRoute.duration;
              console.log(`[OSRM] Segment ${i}->${i + 1} retry succeeded ✅`);
              lastError = null; // Clear error to indicate success
              break; // Exit retry loop
            }
          } catch (retryError) {
            lastError = retryError;
            retryCount++;
          }
        }

        // If all retries failed, throw error instead of using straight line
        if (lastError) {
          console.error(
            `[OSRM] Segment ${i}->${
              i + 1
            } failed after ${maxRetries} retries: ${lastError.message}`
          );
          throw new Error(
            `OSRM route segment ${i}->${
              i + 1
            } failed after ${maxRetries} retries: ${lastError.message}`
          );
        }
      }
    }

    // Combine all segments into one route
    if (allCoordinates.length > 0) {
      console.log(
        `[OSRM] Fallback route created: ${Math.round(totalDistance)}m, ${
          allCoordinates.length
        } coordinates`
      );
      return {
        geometry: {
          type: "LineString",
          coordinates: allCoordinates,
        },
        distance: Math.round(totalDistance),
        duration: Math.round(totalDuration),
      };
    } else {
      console.warn("[OSRM] No valid route created");
      return null;
    }
  } catch (error) {
    console.warn(`[OSRM] Route calculation failed: ${error.message}`);
    if (error.response) {
      console.warn(
        `[OSRM] Response status: ${error.response.status}, data:`,
        error.response.data
      );
    }
    return null;
  }
}

// ==================== VRP OPTIMIZATION API ====================

// GET /api/vrp/districts - Get available districts (from depots, similar to depot management)
app.get("/api/vrp/districts", async (req, res) => {
  try {
    const { date } = req.query;
    const scheduledDate = date || new Date().toISOString().split("T")[0];

    // Get districts from depots AND count actual schedules for each district
    const { rows } = await db.query(
      `
      WITH depot_districts AS (
        SELECT DISTINCT
          CASE 
            WHEN d.address IS NOT NULL AND d.address ~ 'Quận\\s*\\d+' THEN 
              'Quận ' || COALESCE((regexp_match(d.address, 'Quận\\s*(\\d+)'))[1], '')
            WHEN d.address IS NOT NULL AND d.address ~ 'Q\\.?\\s*\\d+' THEN 
              'Quận ' || COALESCE((regexp_match(d.address, 'Q\\.?\\s*(\\d+)'))[1], '')
            WHEN d.address IS NOT NULL AND d.address ~ 'Bình Thạnh' THEN 'Bình Thạnh'
            WHEN d.address IS NOT NULL AND d.address ~ 'Tân Bình' THEN 'Tân Bình'
            WHEN d.address IS NOT NULL AND d.address ~ 'Tân Phú' THEN 'Tân Phú'
            WHEN d.address IS NOT NULL AND d.address ~ 'Phú Nhuận' THEN 'Phú Nhuận'
            WHEN d.address IS NOT NULL AND d.address ~ 'Gò Vấp' THEN 'Gò Vấp'
            WHEN d.address IS NOT NULL AND d.address ~ 'Bình Tân' THEN 'Bình Tân'
            WHEN d.address IS NOT NULL AND d.address ~ 'Thủ Đức' THEN 'Thủ Đức'
            ELSE NULL
          END as district
        FROM depots d
        WHERE d.address IS NOT NULL
          AND d.status = 'active'
      ),
      schedule_counts AS (
      SELECT 
        dd.district,
          COUNT(DISTINCT s.schedule_id)::integer as schedule_count
        FROM depot_districts dd
        LEFT JOIN schedules s ON (
          s.scheduled_date::date = $1::date
            -- Don't filter by status - count all schedules
            AND (
              -- Match by address if available
              (s.address IS NOT NULL AND (
              s.address LIKE '%' || dd.district || '%'
              OR (dd.district ~ '^Quận\\s*\\d+$' 
                  AND s.address ~ ('Quận\\s*' || SUBSTRING(dd.district FROM 'Quận\\s*(\\d+)')))
              ))
              -- OR match by location (join with points/user_addresses)
              OR (s.location IS NOT NULL AND EXISTS (
                SELECT 1 FROM points p
                JOIN user_addresses ua ON p.address_id = ua.id
                WHERE ST_DWithin(s.location, p.geom, 0.01)
                  AND (
                    ua.address_text LIKE '%' || dd.district || '%'
                    OR (dd.district ~ '^Quận\\s*\\d+$' 
                        AND ua.address_text ~ ('Quận\\s*' || SUBSTRING(dd.district FROM 'Quận\\s*(\\d+)')))
                  )
              ))
            )
      )
      WHERE dd.district IS NOT NULL
      GROUP BY dd.district
      ),
      -- Add fallback: count all schedules for the date if no district match
      all_schedules_count AS (
        SELECT COUNT(*)::integer as total FROM schedules WHERE scheduled_date::date = $1::date
      )
      SELECT 
        sc.district,
        COALESCE(sc.schedule_count, 0) as schedule_count,
        COALESCE(sc.schedule_count, 0) as point_count
      FROM schedule_counts sc
      WHERE sc.schedule_count > 0
      UNION ALL
      -- If no districts have schedules, show all districts with total count
      SELECT 
        dd.district,
        COALESCE(asc_count.total, 0) as schedule_count,
        COALESCE(asc_count.total, 0) as point_count
      FROM depot_districts dd
      CROSS JOIN all_schedules_count asc_count
      WHERE NOT EXISTS (SELECT 1 FROM schedule_counts sc WHERE sc.schedule_count > 0)
        AND dd.district IS NOT NULL
      ORDER BY district
    `,
      [scheduledDate]
    );

    res.json({ ok: true, data: rows });
  } catch (error) {
    console.error("[VRP] Get districts error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// VRP optimization endpoint
app.post("/api/vrp/optimize", async (req, res) => {
  try {
    const {
      vehicles = [],
      points = [],
      depot,
      dump,
      timeWindow,
      dumps: dumpsList,
    } = req.body;

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

    // If dump is not provided, we'll select best dump per route after optimization
    // NOTE: Dump selection is done per route based on last stop (after optimization)
    // This ensures dump is closest to the actual last collection point
    let globalSelectedDump = dump;
    if (!globalSelectedDump && dumpsList && dumpsList.length > 0) {
      // Pre-select a dump for initial clustering (will be refined per route later)
      globalSelectedDump = await findBestDumpForDistrict(depot, points, dumpsList);
      console.log(`[VRP] Pre-selected dump for clustering: ${globalSelectedDump?.name || "None"}`);
    } else if (!globalSelectedDump) {
      console.warn(
        `[VRP] No dump provided - routes will end at last stop (no dump destination)`
      );
    }

    // SMART VRP algorithm với Clustering: Phân cụm trước, sau đó tối ưu từng cụm
    // Logic: All points -> Clustering (Sweep Line) -> Mỗi cụm -> Tối ưu với Hybrid CI-SA
    // Điều này giúp tránh việc xe phải băng qua đường nhiều lần

    // CRITICAL FIX: Ensure defaultVehicleCapacity is always a number
    const defaultVehicleCapacity = parseFloat(
      vehicles[0]?.capacity || vehicles[0]?.capacity_kg || 5000
    );

    // 1. SMART CLUSTERING: Phân cụm điểm theo góc từ depot (Sweep Line)
    // Số cụm = Số xe (hoặc có thể điều chỉnh)
    const numClusters = vehicles.length;
    console.log(
      `[VRP] Clustering ${points.length} points into ${numClusters} zones using Sweep Line algorithm...`
    );

    let clusteredPoints = [];
    try {
      // Sử dụng Sweep Line để phân cụm (phù hợp với bài toán VRP)
      clusteredPoints = clusterPointsBySweepLine(points, depot, numClusters);
      console.log(
        `[VRP] Clustering completed: ${clusteredPoints.length} clusters created`
      );
      clusteredPoints.forEach((cluster, idx) => {
        console.log(`[VRP] Cluster ${idx + 1}: ${cluster.length} points`);
      });
    } catch (error) {
      console.warn(
        `[VRP] Sweep Line clustering failed: ${error.message}, falling back to K-Means`
      );
      try {
        clusteredPoints = clusterPointsByKMeans(points, numClusters);
        console.log(
          `[VRP] K-Means clustering completed: ${clusteredPoints.length} clusters`
        );
      } catch (e2) {
        console.warn(
          `[VRP] K-Means also failed: ${e2.message}, using simple distance-based grouping`
        );
        // Fallback: Chia đều theo khoảng cách
        const sortedPoints = [...points].sort((a, b) => {
          const distA = getHaversineDistance(depot, a);
          const distB = getHaversineDistance(depot, b);
          return distA - distB;
        });
        const chunkSize = Math.ceil(sortedPoints.length / numClusters);
        for (let i = 0; i < sortedPoints.length; i += chunkSize) {
          clusteredPoints.push(sortedPoints.slice(i, i + chunkSize));
        }
      }
    }

    const routes = [];
    let routeIndex = 0; // Route A, B, C, ...

    // 2. XỬ LÝ TỪNG CỤM: Mỗi cụm được gán cho một xe và tối ưu riêng biệt
    // Điều này đảm bảo xe không phải băng qua đường nhiều lần
    for (
      let clusterIdx = 0;
      clusterIdx < clusteredPoints.length;
      clusterIdx++
    ) {
      const cluster = clusteredPoints[clusterIdx];

      if (cluster.length === 0) {
        console.log(`[VRP] Cluster ${clusterIdx + 1} is empty, skipping`);
        continue;
      }

      // Gán xe cho cụm này (round-robin nếu có nhiều cụm hơn xe)
      const vehicle = vehicles[clusterIdx % vehicles.length];
      if (!vehicle || !vehicle.id) {
        console.error(`[VRP] Invalid vehicle for cluster ${clusterIdx + 1}`);
        continue;
      }

      const vehicleCapacity = parseFloat(
        vehicle.capacity || vehicle.capacity_kg || defaultVehicleCapacity
      );

      // Nếu cụm quá lớn, chia nhỏ theo capacity
      let remainingPoints = [...cluster];
      let subRouteIndex = 0;

      while (remainingPoints.length > 0) {
        // Tạo route mới cho phần cụm này
        const route = {
          vehicleId: vehicle.id,
          vehiclePlate: vehicle.plate,
          stops: [],
          currentLoad: 0,
          currentLocation: depot,
          clusterIndex: clusterIdx,
        };

        // Thêm điểm vào route theo capacity (trong cùng cụm)
        const unassignedInCluster = remainingPoints.map((p) => ({
          ...p,
          assigned: false,
        }));
        let pointsAdded = 0;

        while (unassignedInCluster.some((p) => !p.assigned)) {
          const availablePoints = unassignedInCluster.filter(
            (p) => !p.assigned
          );
          if (availablePoints.length === 0) break;

          // Tìm điểm gần nhất từ vị trí hiện tại (trong cụm)
          let nearestPoint = null;
          let minDistance = Infinity;
          let nearestIdx = -1;

          for (let i = 0; i < unassignedInCluster.length; i++) {
            const point = unassignedInCluster[i];
            if (point.assigned) continue;

            const distance = getHaversineDistance(route.currentLocation, point);
            if (distance < minDistance) {
              minDistance = distance;
              nearestPoint = point;
              nearestIdx = i;
            }
          }

          if (!nearestPoint) break;

          // Kiểm tra capacity
          const demand = parseFloat(nearestPoint.demand) || 0;
          const currentLoad = parseFloat(route.currentLoad) || 0;
          const totalLoad = currentLoad + demand;

          if (
            totalLoad <= vehicleCapacity ||
            demand === 0 ||
            !nearestPoint.demand
          ) {
            route.stops.push(nearestPoint);
            route.currentLoad = totalLoad;
            route.currentLocation = nearestPoint;
            unassignedInCluster[nearestIdx].assigned = true;
            pointsAdded++;
          } else {
            // Không thể thêm điểm này, dừng route này
            break;
          }
        }

        // Chỉ thêm route nếu có ít nhất 1 điểm
        if (route.stops.length > 0) {
          routes.push(route);
          routeIndex++;

          // Cập nhật remainingPoints (loại bỏ các điểm đã được gán)
          remainingPoints = unassignedInCluster
            .filter((p) => !p.assigned)
            .map((p) => {
              const { assigned, ...point } = p;
              return point;
            });

          console.log(
            `[VRP] Created Route ${String.fromCharCode(
              65 + routeIndex - 1
            )} from Cluster ${clusterIdx + 1} (${vehicle.plate}): ${
              route.stops.length
            } points, ${Math.round(route.currentLoad)}kg`
          );
        } else {
          break; // Không thể tạo route nào nữa từ cụm này
        }
      }
    }

    console.log(
      `[VRP] Total routes created: ${routes.length} from ${points.length} points`
    );

    // 4. Optimize and process each route
    for (let routeIdx = 0; routeIdx < routes.length; routeIdx++) {
      const route = routes[routeIdx];
      const vehicle =
        vehicles.find((v) => v.id === route.vehicleId) ||
        vehicles[routeIdx % vehicles.length];

      // Get vehicle current location (or use depot as fallback)
      let vehicleStartLocation = depot;
      try {
        const currentLoc = await getVehicleCurrentLocation(vehicle.id);
        if (currentLoc && currentLoc.lon && currentLoc.lat) {
          vehicleStartLocation = currentLoc;
          console.log(
            `[VRP] Vehicle ${vehicle.id} current location: ${currentLoc.lon}, ${currentLoc.lat}`
          );
        }
      } catch (error) {
        console.warn(
          `[VRP] Could not get current location for vehicle ${vehicle.id}, using depot`
        );
      }

      // POI display is now handled by frontend (like POI.jsx does)
      // No need to fetch POIs in backend anymore

      // 4. Optimize stop order using Hybrid CI-SA (Cheapest Insertion + Simulated Annealing)
      // OSRM will be used later for route drawing (getOSRMRoute) which gives actual road paths
      if (route.stops.length > 0) {
        route.stops = await optimizeStopOrder(
          route.stops,
          vehicleStartLocation,
          globalSelectedDump || vehicleStartLocation
        );
        console.log(
          `[VRP] Vehicle ${vehicle.id}: Optimized ${route.stops.length} stops using Hybrid CI-SA`
        );
      }
      
      // CRITICAL FIX: Select best dump for THIS route based on LAST stop (after optimization)
      // This ensures dump is closest to the actual last collection point in the route
      let selectedDump = globalSelectedDump;
      if (dumpsList && dumpsList.length > 0 && route.stops.length > 0) {
        // Find last stop in optimized route
        const lastStop = route.stops[route.stops.length - 1];
        if (lastStop && lastStop.lat && lastStop.lon) {
          // Find dump closest to last stop
          let nearestDump = null;
          let minDistance = Infinity;
          
          for (const dump of dumpsList) {
            if (!dump.lat || !dump.lon || (dump.status && dump.status !== 'active')) continue;
            
            const distance = getHaversineDistance(
              { lat: lastStop.lat, lon: lastStop.lon },
              { lat: dump.lat, lon: dump.lon }
            );
            
            if (distance < minDistance) {
              minDistance = distance;
              nearestDump = dump;
            }
          }
          
          if (nearestDump) {
            selectedDump = nearestDump;
            console.log(
              `[VRP] Vehicle ${vehicle.id}: Selected dump "${nearestDump.name}" closest to last stop (${Math.round(minDistance)}m away)`
            );
          }
        }
      }

      // Build waypoints: vehicle current location -> optimized stops -> dump
      // IMPORTANT: Keep the optimized order - Route will go through ALL waypoints in order
      const waypoints = [];

      // 1. Start point (depot or vehicle current location)
      if (
        vehicleStartLocation &&
        vehicleStartLocation.lon &&
        vehicleStartLocation.lat
      ) {
        waypoints.push([vehicleStartLocation.lon, vehicleStartLocation.lat]);
        console.log(
          `[VRP] Vehicle ${vehicle.id}: Start point: ${vehicleStartLocation.lon}, ${vehicleStartLocation.lat}`
        );
      }

      // 2. All stops (in optimized order)
      route.stops.forEach((p, idx) => {
        if (p.lon && p.lat) {
          waypoints.push([p.lon, p.lat]);
          console.log(
            `[VRP] Vehicle ${vehicle.id}: Stop ${idx + 1}: ${p.lon}, ${p.lat}`
          );
        } else {
          console.warn(
            `[VRP] Vehicle ${vehicle.id}: Stop ${idx + 1} missing coordinates`
          );
        }
      });

      // 3. End point (dump) - ALWAYS add to ensure route has clear END point
      // Route must go: START -> stops -> END
      if (selectedDump && selectedDump.lon && selectedDump.lat) {
        const dumpCoords = [
          parseFloat(selectedDump.lon),
          parseFloat(selectedDump.lat),
        ];
        const startCoords = waypoints[0];

        // Check if dump is same as start point (within 10m tolerance)
        const isSameAsStart =
          Math.abs(dumpCoords[0] - startCoords[0]) < 0.0001 &&
          Math.abs(dumpCoords[1] - startCoords[1]) < 0.0001;

        if (isSameAsStart) {
          console.warn(
            `[VRP] Vehicle ${vehicle.id}: Dump is same as start point, but still adding to ensure route has END point`
          );
          // Still add dump to ensure route has clear END point
          // OSRM will handle the route correctly even if start and end are close
        }

        // ALWAYS add dump as END point to ensure route completeness
        waypoints.push(dumpCoords);
        console.log(
          `[VRP] Vehicle ${vehicle.id}: End point (dump): ${
            selectedDump.name || "Dump"
          } at [${dumpCoords[0]}, ${dumpCoords[1]}]`
        );
      } else {
        // If no dump provided, use last stop as END point
        if (waypoints.length > 1) {
          const lastStop = waypoints[waypoints.length - 1];
          console.log(
            `[VRP] Vehicle ${vehicle.id}: No dump provided, route will end at last stop: [${lastStop[0]}, ${lastStop[1]}]`
          );
        }
      }

      // VALIDATION: Ensure route is valid (START → END, no duplicates, no dead ends)
      const validationErrors = [];

      // 1. Validate START point exists
      if (!waypoints || waypoints.length === 0) {
        validationErrors.push("No waypoints defined");
      } else {
        const startPoint = waypoints[0];
        if (!startPoint || startPoint.length !== 2) {
          validationErrors.push("Invalid START point");
        } else if (
          startPoint[0] === vehicleStartLocation.lon &&
          startPoint[1] === vehicleStartLocation.lat
        ) {
          // START point matches vehicle location - OK
        } else {
          validationErrors.push(
            `START point [${startPoint[0]}, ${startPoint[1]}] does not match vehicle location [${vehicleStartLocation.lon}, ${vehicleStartLocation.lat}]`
          );
        }
      }

      // 2. Validate END point exists (if dump is provided)
      if (selectedDump && selectedDump.lon && selectedDump.lat) {
        const endPoint = waypoints[waypoints.length - 1];
        if (!endPoint || endPoint.length !== 2) {
          validationErrors.push("Invalid END point");
        } else {
          const dumpCoords = [
            parseFloat(selectedDump.lon),
            parseFloat(selectedDump.lat),
          ];
          const isSameAsEnd =
            Math.abs(endPoint[0] - dumpCoords[0]) < 0.0001 &&
            Math.abs(endPoint[1] - dumpCoords[1]) < 0.0001;
          if (!isSameAsEnd) {
            validationErrors.push(
              `END point [${endPoint[0]}, ${endPoint[1]}] does not match dump location [${dumpCoords[0]}, ${dumpCoords[1]}]`
            );
          }
        }
      }

      // 3. Validate no duplicate consecutive waypoints
      const duplicateWaypoints = [];
      for (let i = 0; i < waypoints.length - 1; i++) {
        const wp1 = waypoints[i];
        const wp2 = waypoints[i + 1];
        const dist = Math.abs(wp1[0] - wp2[0]) + Math.abs(wp1[1] - wp2[1]);
        if (dist < 0.0001) {
          // Less than ~10m apart
          duplicateWaypoints.push(`Waypoints ${i} and ${i + 1} are duplicates`);
        }
      }
      if (duplicateWaypoints.length > 0) {
        validationErrors.push(
          `Duplicate waypoints detected: ${duplicateWaypoints.join(", ")}`
        );
      }

      // 4. Validate no duplicate stops (non-consecutive duplicates)
      const stopIds = new Set();
      for (const stop of route.stops) {
        const stopId = stop.id || `${stop.lat},${stop.lon}`;
        if (stopIds.has(stopId)) {
          validationErrors.push(`Duplicate stop detected: ${stopId}`);
        }
        stopIds.add(stopId);
      }

      // 5. Validate waypoints count matches expected (START + stops + END)
      const expectedWaypoints = 1 + route.stops.length + (selectedDump ? 1 : 0);
      if (waypoints.length !== expectedWaypoints) {
        validationErrors.push(
          `Waypoints count mismatch: expected ${expectedWaypoints} (START + ${
            route.stops.length
          } stops + ${selectedDump ? "1" : "0"} END), got ${waypoints.length}`
        );
      }

      // Log validation results
      if (validationErrors.length > 0) {
        console.warn(
          `[VRP] Vehicle ${vehicle.id}: Route validation warnings:`,
          validationErrors
        );
      } else {
        console.log(`[VRP] Vehicle ${vehicle.id}: Route validation passed ✅`);
      }

      // Validate waypoints minimum
      if (waypoints.length < 2) {
        console.warn(
          `[VRP] Vehicle ${vehicle.id}: Not enough waypoints (${waypoints.length}), skipping route`
        );
        continue;
      }

      console.log(
        `[VRP] Vehicle ${vehicle.id}: Total waypoints: ${
          waypoints.length
        } (1 START + ${route.stops.length} stops + ${
          selectedDump ? "1" : "0"
        } END)`
      );
      console.log(
        `[VRP] Vehicle ${vehicle.id}: Waypoints order:`,
        waypoints
          .map((wp) => `[${wp[0].toFixed(4)},${wp[1].toFixed(4)}]`)
          .join(" -> ")
      );

      // Get route from OSRM (road network routing)
      let routeGeometry = null;
      let totalDistance = 0;
      let totalDuration = 0;

      try {
        const osrmRoute = await getOSRMRoute(waypoints);
        if (
          osrmRoute &&
          osrmRoute.distance > 0 &&
          osrmRoute.duration > 0 &&
          osrmRoute.geometry
        ) {
          routeGeometry = osrmRoute.geometry;
          totalDistance = Math.round(osrmRoute.distance);
          totalDuration = Math.round(osrmRoute.duration);
          const coordCount = osrmRoute.geometry.coordinates?.length || 0;
          console.log(
            `[VRP] Vehicle ${vehicle.id}: OSRM route - ${totalDistance}m, ${totalDuration}s, ${coordCount} coordinates`
          );
          console.log(
            `[VRP] Vehicle ${vehicle.id}: Route geometry type: ${routeGeometry.type}, coordinates: ${coordCount}`
          );
        } else {
          // OSRM returned null or invalid data - don't use fallback
          console.error(
            `[VRP] OSRM failed or returned invalid data for vehicle ${vehicle.id} - route will have no geometry`
          );
          routeGeometry = null; // Don't create fallback geometry - route will be marked as incomplete
        }
      } catch (error) {
        console.warn(
          `[VRP] Route calculation error for vehicle ${vehicle.id}:`,
          error.message
        );
        // Don't use fallback - log error and route will have no geometry
        console.error(
          `[VRP] Route calculation failed for vehicle ${vehicle.id} - route will have no geometry. Error: ${error.message}`
        );
        routeGeometry = null;
        // Route will still be included but without geometry - frontend should handle this gracefully
      }

      // Ensure distance and duration are valid numbers
      if (!totalDistance || totalDistance <= 0) {
        console.warn(
          `[VRP] Invalid distance for vehicle ${vehicle.id}, setting default`
        );
        totalDistance = 1000; // Default 1km
      }
      if (!totalDuration || totalDuration <= 0 || isNaN(totalDuration)) {
        console.warn(
          `[VRP] Invalid duration for vehicle ${vehicle.id}, calculating from distance`
        );
        totalDuration = Math.round(totalDistance / 8.33); // Recalculate from distance
      }

      // Estimate ETA from duration (in seconds)
      const hours = Math.floor(totalDuration / 3600);
      const minutes = Math.round((totalDuration % 3600) / 60);
      const eta = `${hours}:${minutes.toString().padStart(2, "0")}`;

      // Final validation before updating route
      if (totalDistance <= 0 || isNaN(totalDistance)) {
        console.error(
          `[VRP] Invalid distance ${totalDistance} for vehicle ${vehicle.id}, skipping route`
        );
        // Remove this route from routes array
        routes.splice(routeIdx, 1);
        routeIdx--; // Adjust index after removal
        continue;
      }

      // CRITICAL FIX: Ensure route geometry ALWAYS includes depot and dump
      // Handle ALL cases: routeGeometry null, empty, or valid
      const depotCoords = vehicleStartLocation ? [vehicleStartLocation.lon, vehicleStartLocation.lat] : null;
      const dumpCoords = selectedDump ? [selectedDump.lon, selectedDump.lat] : null;
      
      // Check if routeGeometry is valid (has coordinates)
      const hasValidGeometry = routeGeometry && 
                               routeGeometry.coordinates && 
                               Array.isArray(routeGeometry.coordinates) &&
                               routeGeometry.coordinates.length > 0;
      
      if (hasValidGeometry) {
        // Case 1: OSRM returned valid route - ensure depot and dump are included
        console.log(`[VRP] Vehicle ${vehicle.id}: OSRM returned valid route with ${routeGeometry.coordinates.length} coordinates`);
        
        const newCoordinates = [];
        
        // 1. ALWAYS start with depot
        if (depotCoords) {
          newCoordinates.push(depotCoords);
          console.log(`[VRP] Route starts at depot: [${depotCoords[0]}, ${depotCoords[1]}]`);
        }
        
        // 2. Add route geometry coordinates (skip first if it's same as depot)
        const firstRouteCoord = routeGeometry.coordinates[0];
        if (depotCoords && firstRouteCoord) {
          const distToDepot = Math.sqrt(
            Math.pow(firstRouteCoord[0] - depotCoords[0], 2) + 
            Math.pow(firstRouteCoord[1] - depotCoords[1], 2)
          ) * 111000;
          
          if (distToDepot < 50) {
            // Route already starts at depot, skip first coordinate to avoid duplicate
            newCoordinates.push(...routeGeometry.coordinates.slice(1));
          } else {
            // Route doesn't start at depot, add all coordinates
            newCoordinates.push(...routeGeometry.coordinates);
          }
        } else {
          // No depot, add all route coordinates
          newCoordinates.push(...routeGeometry.coordinates);
        }
        
        // 3. ALWAYS end with dump
        if (dumpCoords) {
          const lastCoord = newCoordinates[newCoordinates.length - 1];
          const distToDump = Math.sqrt(
            Math.pow(lastCoord[0] - dumpCoords[0], 2) + 
            Math.pow(lastCoord[1] - dumpCoords[1], 2)
          ) * 111000;
          
          if (distToDump > 50) {
            // Route doesn't end at dump, add dump as final point
            newCoordinates.push(dumpCoords);
            console.log(`[VRP] Route ends at dump: [${dumpCoords[0]}, ${dumpCoords[1]}]`);
          } else {
            console.log(`[VRP] Route already ends at dump`);
          }
        }
        
        // Update routeGeometry with new coordinates
        routeGeometry = {
          ...routeGeometry,
          coordinates: newCoordinates
        };
        
        console.log(`[VRP] Route geometry updated: ${newCoordinates.length} coordinates (START + route + END)`);
      } else if (waypoints.length >= 2) {
        // Case 2: OSRM failed or returned empty/invalid geometry - create fallback from waypoints
        // waypoints already includes depot (first) and dump (last if exists)
        console.warn(`[VRP] Vehicle ${vehicle.id}: OSRM failed or returned empty geometry, creating fallback from ${waypoints.length} waypoints`);
        console.log(`[VRP] Fallback waypoints:`, waypoints.map(wp => `[${wp[0].toFixed(4)}, ${wp[1].toFixed(4)}]`).join(' -> '));
        
        routeGeometry = {
          type: "LineString",
          coordinates: waypoints // waypoints already includes depot and dump
        };
        
        console.log(`[VRP] Fallback route created with ${waypoints.length} waypoints (includes START and END)`);
      } else {
        // Case 3: No waypoints - cannot create route
        console.error(`[VRP] Vehicle ${vehicle.id}: Cannot create route - no valid geometry and insufficient waypoints (${waypoints.length})`);
        routeGeometry = null;
      }

      // Update route object with optimized data (don't push new, update existing)
      route.distance = totalDistance; // in meters
      route.eta = eta; // format: "H:MM"
      
      // Ensure routeGeometry is valid before creating geojson
      // If routeGeometry is still null, use waypoints as final fallback
      const finalGeometry = routeGeometry || (waypoints.length >= 2 ? {
        type: "LineString",
        coordinates: waypoints
      } : null);
      
      if (!finalGeometry || !finalGeometry.coordinates || finalGeometry.coordinates.length < 2) {
        console.error(`[VRP] Vehicle ${vehicle.id}: Cannot create route geojson - invalid geometry`);
        // Still create route object but mark as incomplete
        route.geojson = {
          type: "FeatureCollection",
          features: []
        };
      } else {
        route.geojson = {
          type: "FeatureCollection",
          features: [
            {
              type: "Feature",
              geometry: finalGeometry,
              properties: {
                vehicleId: vehicle.id,
                vehiclePlate: vehicle.plate,
                distance: totalDistance,
                duration: totalDuration,
              },
            },
          ],
        };
        console.log(`[VRP] Vehicle ${vehicle.id}: Route geojson created with ${finalGeometry.coordinates.length} coordinates`);
      }
      route.stops = route.stops.map((p, idx) => ({
        id: p.id,
        seq: idx + 1,
        lat: p.lat,
        lon: p.lon,
        demand: p.demand || 0,
      }));
      // CRITICAL FIX: route.depot must match vehicleStartLocation used in route geometry
      // Use vehicleStartLocation (actual start point) instead of depot (original depot)
      // This ensures START marker matches the actual route start point
      route.depot =
        vehicleStartLocation &&
        vehicleStartLocation.lat &&
        vehicleStartLocation.lon
          ? {
              id: depot?.id || vehicleStartLocation.id || "unknown",
              name: depot?.name || vehicleStartLocation.name || "Start Point",
              lat: parseFloat(vehicleStartLocation.lat),
              lon: parseFloat(vehicleStartLocation.lon),
            }
          : depot && depot.lat && depot.lon
          ? {
              id: depot.id,
              name: depot.name || "Depot",
              lat: parseFloat(depot.lat),
              lon: parseFloat(depot.lon),
            }
          : null;
      
      console.log(`[VRP] Vehicle ${vehicle.id}: route.depot set to:`, {
        lat: route.depot?.lat,
        lon: route.depot?.lon,
        name: route.depot?.name,
        matchesVehicleStart: route.depot?.lat === vehicleStartLocation?.lat && route.depot?.lon === vehicleStartLocation?.lon
      });
      route.dump =
        selectedDump && selectedDump.lat && selectedDump.lon
          ? {
              id: selectedDump.id,
              name: selectedDump.name || "Dump",
              lat: parseFloat(selectedDump.lat),
              lon: parseFloat(selectedDump.lon),
            }
          : null;
      route.depot_id = depot?.id || null;
      route.dump_id = selectedDump?.id || null;
    }

    // Filter out any invalid routes (should not happen, but safety check)
    const validRoutes = routes.filter(
      (r) => r && r.stops && r.stops.length > 0 && r.distance > 0
    );

    if (validRoutes.length === 0 && routes.length > 0) {
      console.warn("[VRP] All routes were invalid after optimization");
    }

    console.log(
      `✅ VRP optimization completed: ${validRoutes.length} valid routes from ${routes.length} total routes, ${vehicles.length} vehicles`
    );

    const finalRoutes = validRoutes.length > 0 ? validRoutes : routes;

    res.json({
      ok: true,
      data: { routes: finalRoutes },
    });
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

      // Create route (with optional driver_id if provided)
      await db.query(
        `INSERT INTO routes (id, vehicle_id, driver_id, depot_id, dump_id, start_at, status, planned_distance_km, meta)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
        [
          routeId,
          routeData.vehicleId,
          routeData.driver_id || null, // Optional driver assignment
          routeData.depot_id || null,
          routeData.dump_id || null,
          now,
          routeData.driver_id ? "assigned" : "planned", // If driver assigned, status = assigned, else planned
          routeData.distance
            ? parseFloat((routeData.distance / 1000).toFixed(2))
            : null, // Convert meters to km
          JSON.stringify({
            optimized: true,
            distance: routeData.distance,
            eta: routeData.eta,
            geojson: routeData.geojson,
            vehiclePlate: routeData.vehiclePlate,
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
        driver_id: routeData.driver_id || null,
        depot_id: routeData.depot_id || null,
        dump_id: routeData.dump_id || null,
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

// Assign employee to route
app.post("/api/vrp/assign-route", async (req, res) => {
  try {
    const { route_id, driver_id, collector_id } = req.body;

    if (!route_id) {
      return res.status(400).json({
        ok: false,
        error: "route_id is required",
      });
    }

    if (!driver_id) {
      return res.status(400).json({
        ok: false,
        error: "driver_id is required",
      });
    }

    // Update route with driver assignment
    const { rows } = await db.query(
      `UPDATE routes 
       SET driver_id = $1, status = 'assigned', updated_at = NOW()
       WHERE id = $2
       RETURNING id, vehicle_id, driver_id, depot_id, dump_id, status, planned_distance_km`,
      [driver_id, route_id]
    );

    if (rows.length === 0) {
      return res.status(404).json({
        ok: false,
        error: "Route not found",
      });
    }

    console.log(`✅ Assigned driver ${driver_id} to route ${route_id}`);

    res.json({
      ok: true,
      data: rows[0],
      message: "Route assigned successfully",
    });
  } catch (error) {
    console.error("[VRP] Assign route error:", error);
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
    // FIX: Parse alertId to integer (alert_id is SERIAL/INTEGER in database)
    const alertIdInt = parseInt(alertId, 10);
    if (isNaN(alertIdInt)) {
      return res.status(400).json({
        ok: false,
        error: "Invalid alert ID format. Expected integer.",
      });
    }

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
       WHERE a.alert_id = $1 AND p.geom IS NOT NULL`,
      [alertIdInt]
    );

    if (alertResult.rows.length === 0) {
      return res.status(404).json({
        ok: false,
        error:
          "Alert not found, point not found, or point has no location data",
      });
    }
    const alertData = alertResult.rows[0];

    // 2. Get all currently active vehicles from database
    const vehiclesQuery = `
      SELECT DISTINCT ON (v.id)
        v.id,
        COALESCE(ST_X(vt.geom::geometry), ST_X(d.geom::geometry)) as lon,
        COALESCE(ST_Y(vt.geom::geometry), ST_Y(d.geom::geometry)) as lat
      FROM vehicles v
      LEFT JOIN depots d ON v.depot_id = d.id
      LEFT JOIN LATERAL (
        SELECT geom, recorded_at
        FROM vehicle_tracking
        WHERE vehicle_id = v.id
          AND recorded_at >= NOW() - INTERVAL '1 hour'
        ORDER BY recorded_at DESC
        LIMIT 1
      ) vt ON true
      WHERE v.status IN ('available', 'in_use')
        AND (vt.geom IS NOT NULL OR d.geom IS NOT NULL)
      ORDER BY v.id, COALESCE(vt.recorded_at, '1970-01-01'::timestamptz) DESC NULLS LAST
    `;

    const vehiclesResult = await db.query(vehiclesQuery);
    const activeVehicles = vehiclesResult.rows.map((row) => ({
      id: row.id,
      lat: parseFloat(row.lat) || 10.78,
      lon: parseFloat(row.lon) || 106.7,
    }));

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
    console.error(
      `[Dispatch] Error processing dispatch for alert ${alertId}:`,
      err
    );
    console.error(`[Dispatch] Error details:`, {
      message: err.message,
      stack: err.stack,
      alertId: alertId,
    });
    res.status(500).json({
      ok: false,
      error: err.message || "Failed to process dispatch request",
    });
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

// Simple Linear Regression helper for time series forecasting
function simpleLinearRegression(x, y) {
  const n = x.length;
  if (n < 2) return null;

  const sumX = x.reduce((a, b) => a + b, 0);
  const sumY = y.reduce((a, b) => a + b, 0);
  const sumXY = x.reduce((sum, xi, i) => sum + xi * y[i], 0);
  const sumXX = x.reduce((sum, xi) => sum + xi * xi, 0);

  const slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
  const intercept = (sumY - slope * sumX) / n;

  return { slope, intercept, predict: (xValue) => slope * xValue + intercept };
}

app.get("/api/analytics/predict", async (req, res) => {
  try {
    const days = Number(req.query.days || 7);
    const point_id = req.query.point_id || null;
    const waste_type = req.query.waste_type || null;
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Get historical data (60 days for better trend analysis)
    let query = `
      SELECT 
        DATE(completed_at) as day,
        COALESCE(SUM(actual_weight), 0) / 1000.0 as total_tons
      FROM schedules
      WHERE completed_at >= NOW() - INTERVAL '60 days'
        AND status = 'completed'
    `;
    const params = [];
    let paramIndex = 1;

    if (point_id) {
      query += ` AND point_id = $${paramIndex++}`;
      params.push(point_id);
    }

    if (waste_type) {
      query += ` AND waste_type = $${paramIndex++}`;
      params.push(waste_type);
    }

    query += ` GROUP BY day ORDER BY day ASC`;

    const historyData = await db.query(query, params);

    // Get actual data for past N days (for display)
    let actualQuery = `
      SELECT 
        DATE(completed_at) as day,
        COALESCE(SUM(actual_weight), 0) / 1000.0 as total_tons
      FROM schedules
      WHERE completed_at >= NOW() - INTERVAL '1 day' * $${paramIndex++}
        AND status = 'completed'
    `;

    if (point_id) {
      actualQuery += ` AND point_id = $${paramIndex++}`;
      params.push(point_id);
    }

    if (waste_type) {
      actualQuery += ` AND waste_type = $${paramIndex++}`;
      params.push(waste_type);
    }

    actualQuery += ` GROUP BY day ORDER BY day ASC`;

    const actualData = await db.query(actualQuery, [
      days,
      ...params.slice(
        params.length - (point_id ? 1 : 0) - (waste_type ? 1 : 0)
      ),
    ]);

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

    // Use ARIMA AI model if we have enough historical data
    let forecast = [];
    let modelInfo = { model: "simple_average", reason: "insufficient_data" };

    if (historyData.rows.length >= 14) {
      // Prepare time series data for ARIMA
      const Y = historyData.rows.map((row) => parseFloat(row.total_tons) || 0);

      try {
        // Initialize ARIMA model with auto parameter selection
        const arima = new ARIMA({
          auto: true, // Auto-select best (p,d,q) parameters
          method: 0, // Maximum likelihood estimation
          optimizer: 6, // Use Nelder-Mead optimizer
          verbose: false, // Disable verbose output
        });

        // Train ARIMA model on historical data
        arima.train(Y);

        // Predict future values
        const [predictions, errors] = arima.predict(days);

        if (
          predictions &&
          predictions.length > 0 &&
          !predictions.some((v) => isNaN(v) || !isFinite(v))
        ) {
          // Generate forecast using ARIMA predictions
          for (let i = 0; i < days; i++) {
            const dayDate = new Date(today.getTime() + i * 86400000);
            const dateStr = dayDate.toISOString().slice(0, 10);

            // Get predicted value (ensure it's valid)
            let predictedValue =
              predictions[i] || predictions[predictions.length - 1];

            // Ensure non-negative values and reasonable range
            const forecastValue = Math.max(0, Math.min(predictedValue, 1000)); // Cap at 1000 tons

            forecast.push({
              d: dateStr,
              v: parseFloat(forecastValue.toFixed(1)),
            });
          }

          // Calculate model metrics
          const avgError =
            errors && errors.length > 0
              ? errors.reduce((sum, e) => sum + Math.abs(e), 0) / errors.length
              : null;

          modelInfo = {
            model: "arima",
            training_days: historyData.rows.length,
            forecast_days: days,
            avg_error: avgError ? parseFloat(avgError.toFixed(4)) : null,
            parameters: arima.params || "auto-selected",
          };
        } else {
          throw new Error("ARIMA predictions invalid");
        }
      } catch (arimaError) {
        console.warn(
          "[Analytics] ARIMA failed, falling back to linear regression:",
          arimaError.message
        );

        // Fallback to Linear Regression if ARIMA fails
        const startDate = new Date(historyData.rows[0].day);
        startDate.setHours(0, 0, 0, 0);

        const X = historyData.rows.map((row) => {
          const rowDate = new Date(row.day);
          rowDate.setHours(0, 0, 0, 0);
          return Math.floor((rowDate - startDate) / (1000 * 60 * 60 * 24));
        });

        const regression = simpleLinearRegression(X, Y);

        if (
          regression &&
          !isNaN(regression.slope) &&
          !isNaN(regression.intercept)
        ) {
          const lastX = X[X.length - 1];

          for (let i = 0; i < days; i++) {
            const dayDate = new Date(today.getTime() + i * 86400000);
            const dateStr = dayDate.toISOString().slice(0, 10);
            const futureX = lastX + 1 + i;
            const predictedValue = regression.predict(futureX);
            const forecastValue = Math.max(0, Math.min(predictedValue, 1000));

            forecast.push({
              d: dateStr,
              v: parseFloat(forecastValue.toFixed(1)),
            });
          }

          modelInfo = {
            model: "linear_regression",
            reason: "arima_fallback",
            training_days: historyData.rows.length,
            slope: parseFloat(regression.slope.toFixed(4)),
            intercept: parseFloat(regression.intercept.toFixed(2)),
          };
        } else {
          // Final fallback to simple average
          const avgWeight =
            Y.reduce((sum, val) => sum + val, 0) / Y.length || 50;
          const lastValue = Y[Y.length - 1] || avgWeight;

          for (let i = 0; i < days; i++) {
            const dayDate = new Date(today.getTime() + i * 86400000);
            const dateStr = dayDate.toISOString().slice(0, 10);
            const forecastValue = lastValue * (1 + i * 0.01);
            forecast.push({
              d: dateStr,
              v: parseFloat(forecastValue.toFixed(1)),
            });
          }
          modelInfo = {
            model: "simple_average",
            reason: "arima_and_regression_failed",
          };
        }
      }
    } else if (historyData.rows.length >= 7) {
      // Not enough data for ARIMA (need 14+ days), use Linear Regression
      const startDate = new Date(historyData.rows[0].day);
      startDate.setHours(0, 0, 0, 0);

      const X = historyData.rows.map((row) => {
        const rowDate = new Date(row.day);
        rowDate.setHours(0, 0, 0, 0);
        return Math.floor((rowDate - startDate) / (1000 * 60 * 60 * 24));
      });
      const Y = historyData.rows.map((row) => parseFloat(row.total_tons) || 0);

      const regression = simpleLinearRegression(X, Y);

      if (
        regression &&
        !isNaN(regression.slope) &&
        !isNaN(regression.intercept)
      ) {
        const lastX = X[X.length - 1];

        for (let i = 0; i < days; i++) {
          const dayDate = new Date(today.getTime() + i * 86400000);
          const dateStr = dayDate.toISOString().slice(0, 10);
          const futureX = lastX + 1 + i;
          const predictedValue = regression.predict(futureX);
          const forecastValue = Math.max(0, Math.min(predictedValue, 1000));

          forecast.push({
            d: dateStr,
            v: parseFloat(forecastValue.toFixed(1)),
          });
        }

        modelInfo = {
          model: "linear_regression",
          reason: "insufficient_data_for_arima",
          training_days: historyData.rows.length,
          slope: parseFloat(regression.slope.toFixed(4)),
          intercept: parseFloat(regression.intercept.toFixed(2)),
        };
      } else {
        // Fallback to simple average
        const avgWeight = Y.reduce((sum, val) => sum + val, 0) / Y.length || 50;
        for (let i = 0; i < days; i++) {
          const dayDate = new Date(today.getTime() + i * 86400000);
          const dateStr = dayDate.toISOString().slice(0, 10);
          const forecastValue = avgWeight * (1 + (i * 0.02) / days);
          forecast.push({
            d: dateStr,
            v: parseFloat(forecastValue.toFixed(1)),
          });
        }
        modelInfo = {
          model: "simple_average",
          reason: "regression_failed",
          data_points: historyData.rows.length,
        };
      }
    } else {
      // Not enough data, use simple average with growth
      const avgWeight =
        actual.reduce((sum, d) => sum + parseFloat(d.v), 0) / actual.length ||
        50;
      for (let i = 0; i < days; i++) {
        const dayDate = new Date(today.getTime() + i * 86400000);
        const dateStr = dayDate.toISOString().slice(0, 10);
        const forecastValue = avgWeight * (1 + (i * 0.02) / days);
        forecast.push({
          d: dateStr,
          v: parseFloat(forecastValue.toFixed(1)),
        });
      }
      modelInfo = {
        model: "simple_average",
        reason: "insufficient_data",
        data_points: historyData.rows.length,
      };
    }

    res.json({
      ok: true,
      data: { actual, forecast },
      model_info: modelInfo,
    });
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

  try {
    // Get active routes from database and in-memory store
    const activeRoutesFromStore = store.getActiveRoutes();

    // Also get active routes from database
    const routesResult = await db.query(
      `SELECT r.id as route_id, r.vehicle_id, r.status
       FROM routes r
       WHERE r.status IN ('in_progress', 'assigned')
       ORDER BY r.start_at DESC`
    );

    // Combine routes from store and database
    const allActiveRoutes = new Map();
    activeRoutesFromStore.forEach((route) => {
      allActiveRoutes.set(route.route_id, route);
    });
    routesResult.rows.forEach((row) => {
      if (!allActiveRoutes.has(row.route_id)) {
        allActiveRoutes.set(row.route_id, {
          route_id: row.route_id,
          vehicle_id: row.vehicle_id,
          status: row.status,
          points: new Map(), // Will be populated from route_stops
        });
      }
    });

    for (const route of allActiveRoutes.values()) {
      if (route.status !== "inprogress" && route.status !== "in_progress")
        continue;

      // Get vehicle location from database
      const vehicleResult = await db.query(
        `SELECT DISTINCT ON (v.id)
          v.id,
          COALESCE(ST_Y(vt.geom::geometry), ST_Y(d.geom::geometry)) as lat,
          COALESCE(ST_X(vt.geom::geometry), ST_X(d.geom::geometry)) as lon
        FROM vehicles v
        LEFT JOIN depots d ON v.depot_id = d.id
        LEFT JOIN LATERAL (
          SELECT geom, recorded_at
          FROM vehicle_tracking
          WHERE vehicle_id = v.id
            AND recorded_at >= NOW() - INTERVAL '1 hour'
          ORDER BY recorded_at DESC
          LIMIT 1
        ) vt ON true
        WHERE v.id = $1
        ORDER BY v.id, COALESCE(vt.recorded_at, '1970-01-01'::timestamptz) DESC NULLS LAST`,
        [route.vehicle_id]
      );

      if (vehicleResult.rows.length === 0) continue;
      const vehicle = {
        lat: parseFloat(vehicleResult.rows[0].lat) || 10.78,
        lon: parseFloat(vehicleResult.rows[0].lon) || 106.7,
      };

      // Get route points from database if not in store
      if (!route.points || route.points.size === 0) {
        const stopsResult = await db.query(
          `SELECT rs.point_id, rs.status, 
                  ST_Y(p.geom::geometry) as lat,
                  ST_X(p.geom::geometry) as lon
           FROM route_stops rs
           JOIN points p ON rs.point_id = p.id
           WHERE rs.route_id = $1 AND rs.status != 'completed'
           ORDER BY rs.seq`,
          [route.route_id]
        );

        route.points = new Map();
        stopsResult.rows.forEach((row) => {
          route.points.set(row.point_id, {
            point_id: row.point_id,
            lat: parseFloat(row.lat),
            lon: parseFloat(row.lon),
            checked: row.status === "completed",
          });
        });
      }

      for (const point of route.points.values()) {
        if (point.checked) continue;

        const distance = getHaversineDistance(
          { lat: vehicle.lat, lon: vehicle.lon },
          { lat: point.lat, lon: point.lon }
        );

        // Basic check: if vehicle is far past the point, it's likely missed.
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
              const routeIdForInsert =
                typeof route.route_id === "string" &&
                /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/.test(
                  route.route_id
                )
                  ? route.route_id
                  : null;
              await db.query(
                `INSERT INTO alerts (alert_type, point_id, vehicle_id, route_id, severity, status, details)
               VALUES ($1, $2, $3, $4, $5, $6, $7)`,
                [
                  "missed_point",
                  point.point_id,
                  route.vehicle_id,
                  routeIdForInsert,
                  "critical",
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
  } catch (err) {
    console.error("Error in missed point detection cron:", err);
  }
});

// --- Testing Endpoints (CN7) ---
// Start a mock route so the cron can detect missed points
app.post("/api/test/start-route", async (req, res) => {
  try {
    const { route_id, vehicle_id = "V01" } = req.body || {};
    const testRouteId = route_id || require("uuid").v4();

    // Get first 5 points from database
    const pointsResult = await db.query(
      `SELECT id as point_id, 
              ST_Y(geom::geometry) as lat,
              ST_X(geom::geometry) as lon
       FROM points
       WHERE geom IS NOT NULL AND ghost = false
       ORDER BY last_checkin_at DESC NULLS LAST, created_at DESC
       LIMIT 5`
    );

    if (pointsResult.rows.length === 0) {
      return res
        .status(500)
        .json({ ok: false, error: "No points available in database" });
    }

    const points = pointsResult.rows.map((row) => ({
      point_id: row.point_id,
      lat: parseFloat(row.lat),
      lon: parseFloat(row.lon),
    }));

    store.startRoute(testRouteId, vehicle_id, points);
    return res.json({
      ok: true,
      message: `Test route ${testRouteId} started for vehicle ${vehicle_id}`,
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
      district,
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
        d.name as depot_name,
        COALESCE(s.longitude, ST_X(s.location::geometry)) as longitude,
        COALESCE(s.latitude, ST_Y(s.location::geometry)) as latitude,
        s.address as location_address
      FROM schedules s
      LEFT JOIN users u ON s.citizen_id = u.id::text OR s.citizen_id = u.phone
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
      // Use date casting to handle timezone properly
      query += ` AND s.scheduled_date::date = $${paramIndex}::date`;
      params.push(scheduled_date);
      paramIndex++;
    }

    // Filter by district (extract from schedules.address or location via points/user_addresses)
    if (district) {
      query += ` AND (
        -- Match by address if available
        (s.address IS NOT NULL AND (
        s.address ~ $${paramIndex} OR
        s.address LIKE $${paramIndex + 1}
        ))
        -- OR match by location (join with points/user_addresses)
        OR (s.location IS NOT NULL AND EXISTS (
          SELECT 1 FROM points p
          JOIN user_addresses ua ON p.address_id = ua.id
          WHERE ST_DWithin(s.location, p.geom, 0.01)
            AND (
              ua.address_text ~ $${paramIndex} OR
              ua.address_text LIKE $${paramIndex + 1}
            )
        ))
      )`;
      // Use regex pattern for exact district match
      const districtPattern = district.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
      params.push(`.*${districtPattern}.*`, `%${district}%`);
      paramIndex += 2;
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

    console.log(`[Schedule] Update request for schedule_id: ${id}`, {
      status,
      employee_id,
      actual_weight,
      notes,
    });

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
      // Auto-update status to 'assigned' if employee is assigned and status is not explicitly set
      if (!status) {
        updates.push(`status = 'assigned'`);
      }
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
    
    console.log(`[Schedule] Executing query:`, query);
    console.log(`[Schedule] With params:`, params);
    
    const { rows: updateRows } = await db.query(query, params);

    if (updateRows.length === 0) {
      console.log(`[Schedule] Schedule not found: ${id}`);
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
    const { role, status, depot_id, district } = req.query;

    let query = `
      SELECT 
        p.id,
        p.name,
        p.role,
        p.phone,
        p.email,
        p.status,
        p.depot_id,
        p.meta,
        p.hired_at,
        p.created_at,
        p.updated_at,
        d.name as depot_name,
        d.address as depot_address
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

    // Filter by district (from depot address)
    if (district) {
      query += ` AND (
        d.address ~ $${paramIndex} OR
        d.address LIKE $${paramIndex + 1}
      )`;
      const districtPattern = district.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
      params.push(`.*${districtPattern}.*`, `%${district}%`);
      paramIndex += 2;
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
        p.meta,
        p.hired_at,
        p.created_at,
        p.updated_at,
        d.name as depot_name,
        d.address as depot_address
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
      meta = {}, // New: meta for operating_area and group
    } = req.body;

    if (!name || !phone || !email) {
      return res.status(400).json({
        ok: false,
        error: "Missing required fields: name, phone, email",
      });
    }

    // Set default role to "collector" if not provided
    const personnelRole = role || "collector";

    // Validate role
    const validRoles = ["driver", "collector"];
    if (!validRoles.includes(personnelRole)) {
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
          id, name, role, phone, email, status, depot_id, meta, hired_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
        RETURNING *`,
        [
          personnelId,
          name,
          personnelRole, // Use default "collector" if not provided
          phone,
          email,
          status || "active",
          depot_id || null,
          JSON.stringify(meta || {}), // Store meta (operating_area, group)
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
    const { name, role, phone, email, status, depot_id, meta } = req.body;

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

    if (meta !== undefined) {
      updates.push(`meta = $${paramIndex++}`);
      params.push(JSON.stringify(meta));
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

// ==================== GROUPS MANAGEMENT API ====================

// GET /api/groups - Get all groups
app.get("/api/groups", async (req, res) => {
  try {
    const { status, depot_id, vehicle_id, operating_area } = req.query;

    let query = `
      SELECT 
        g.id,
        g.name,
        g.code,
        g.description,
        g.vehicle_id,
        g.route_id,
        g.depot_id,
        g.operating_area,
        g.status,
        g.meta,
        g.created_at,
        g.updated_at,
        v.plate as vehicle_plate,
        v.type as vehicle_type,
        d.name as depot_name,
        COUNT(DISTINCT gm.personnel_id) FILTER (WHERE gm.status = 'active') as member_count
      FROM groups g
      LEFT JOIN vehicles v ON g.vehicle_id = v.id
      LEFT JOIN depots d ON g.depot_id = d.id
      LEFT JOIN group_members gm ON g.id = gm.group_id
      WHERE 1=1
    `;

    const params = [];
    let paramIndex = 1;

    if (status) {
      query += ` AND g.status = $${paramIndex++}`;
      params.push(status);
    }

    if (depot_id) {
      query += ` AND g.depot_id = $${paramIndex++}`;
      params.push(depot_id);
    }

    if (vehicle_id) {
      query += ` AND g.vehicle_id = $${paramIndex++}`;
      params.push(vehicle_id);
    }

    if (operating_area) {
      query += ` AND g.operating_area = $${paramIndex++}`;
      params.push(operating_area);
    }

    query += ` GROUP BY g.id, v.plate, v.type, d.name ORDER BY g.created_at DESC`;

    const { rows } = await db.query(query, params);

    res.json({ ok: true, data: rows });
  } catch (error) {
    console.error("[Groups] Get error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// GET /api/groups/:id - Get group details
app.get("/api/groups/:id", async (req, res) => {
  try {
    const { id } = req.params;

    // Get group info
    const groupQuery = `
      SELECT 
        g.*,
        v.plate as vehicle_plate,
        v.type as vehicle_type,
        d.name as depot_name
      FROM groups g
      LEFT JOIN vehicles v ON g.vehicle_id = v.id
      LEFT JOIN depots d ON g.depot_id = d.id
      WHERE g.id = $1
    `;
    const { rows: groupRows } = await db.query(groupQuery, [id]);

    if (groupRows.length === 0) {
      return res.status(404).json({ ok: false, error: "Group not found" });
    }

    // Get members
    const membersQuery = `
      SELECT 
        gm.*,
        p.name as personnel_name,
        p.phone as personnel_phone,
        p.email as personnel_email
      FROM group_members gm
      JOIN personnel p ON gm.personnel_id = p.id
      WHERE gm.group_id = $1 AND gm.status = 'active'
      ORDER BY gm.role_in_group DESC, gm.joined_at ASC
    `;
    const { rows: memberRows } = await db.query(membersQuery, [id]);

    // Get stats
    const statsQuery = `
      SELECT 
        COUNT(*) as total_checkins,
        SUM(collected_weight_kg) as total_weight_kg,
        SUM(CASE WHEN waste_type = 'household' THEN collected_weight_kg ELSE 0 END) as household_weight_kg,
        SUM(CASE WHEN waste_type = 'recyclable' THEN collected_weight_kg ELSE 0 END) as recyclable_weight_kg,
        SUM(CASE WHEN waste_type = 'bulky' THEN collected_weight_kg ELSE 0 END) as bulky_weight_kg
      FROM group_checkins
      WHERE group_id = $1
    `;
    const { rows: statsRows } = await db.query(statsQuery, [id]);

    res.json({
      ok: true,
      data: {
        ...groupRows[0],
        members: memberRows,
        stats: statsRows[0] || {
          total_checkins: 0,
          total_weight_kg: 0,
          household_weight_kg: 0,
          recyclable_weight_kg: 0,
          bulky_weight_kg: 0,
        },
      },
    });
  } catch (error) {
    console.error("[Groups] Get detail error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// POST /api/groups - Create new group
app.post("/api/groups", async (req, res) => {
  try {
    const {
      name,
      code,
      description,
      vehicle_id,
      depot_id,
      operating_area,
      member_ids = [],
      leader_id,
    } = req.body;

    if (!name) {
      return res.status(400).json({
        ok: false,
        error: "Group name is required",
      });
    }

    const { v4: uuidv4 } = require("uuid");
    const groupId = uuidv4();

    // Create group
    const { rows: groupRows } = await db.query(
      `INSERT INTO groups (
        id, name, code, description, vehicle_id, depot_id, operating_area, status
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, 'active')
      RETURNING *`,
      [
        groupId,
        name,
        code || null,
        description || null,
        vehicle_id || null,
        depot_id || null,
        operating_area || null,
      ]
    );

    // Add members
    if (member_ids.length > 0) {
      for (const personnelId of member_ids) {
        const memberId = uuidv4();
        const role = personnelId === leader_id ? "leader" : "member";
        await db.query(
          `INSERT INTO group_members (id, group_id, personnel_id, role_in_group, status)
           VALUES ($1, $2, $3, $4, 'active')`,
          [memberId, groupId, personnelId, role]
        );
      }
    }

    console.log(`✅ Group created: ${groupId} (${name})`);

    res.status(201).json({
      ok: true,
      data: groupRows[0],
      message: "Group created successfully",
    });
  } catch (error) {
    console.error("[Groups] Create error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// POST /api/groups/run-migration - Run migration 015 (temporary endpoint)
app.post("/api/groups/run-migration", async (req, res) => {
  try {
    console.log("[Migration] Starting migration 015: Create Groups Tables");

    // Create groups table
    await db.query(`
      CREATE TABLE IF NOT EXISTS groups (
        id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
        name text NOT NULL,
        code text UNIQUE,
        description text,
        vehicle_id text REFERENCES vehicles(id) ON DELETE SET NULL,
        route_id uuid REFERENCES routes(id) ON DELETE SET NULL,
        depot_id uuid REFERENCES depots(id) ON DELETE SET NULL,
        operating_area text,
        status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'archived')),
        meta jsonb DEFAULT '{}',
        created_at timestamptz DEFAULT now(),
        updated_at timestamptz DEFAULT now()
      );
    `);

    // Create group_members table
    await db.query(`
      CREATE TABLE IF NOT EXISTS group_members (
        id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
        group_id uuid NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
        personnel_id uuid NOT NULL REFERENCES personnel(id) ON DELETE CASCADE,
        role_in_group text DEFAULT 'member' CHECK (role_in_group IN ('leader', 'member')),
        joined_at timestamptz DEFAULT now(),
        left_at timestamptz,
        status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive'))
      );
    `);

    // Create unique constraint with WHERE clause separately
    await db.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS group_members_unique_active 
      ON group_members(group_id, personnel_id) 
      WHERE status = 'active';
    `);

    // Create group_checkins table
    await db.query(`
      CREATE TABLE IF NOT EXISTS group_checkins (
        id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
        group_id uuid NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
        route_id uuid REFERENCES routes(id) ON DELETE SET NULL,
        route_stop_id uuid REFERENCES route_stops(id) ON DELETE SET NULL,
        checked_by uuid NOT NULL REFERENCES personnel(id) ON DELETE SET NULL,
        waste_type text NOT NULL CHECK (waste_type IN ('household', 'recyclable', 'bulky')),
        collected_weight_kg numeric(10,2) NOT NULL DEFAULT 0,
        quantity_bags int DEFAULT 0,
        notes text,
        photo_urls text[],
        geom geography(Point,4326),
        checked_at timestamptz DEFAULT now(),
        created_at timestamptz DEFAULT now()
      );
    `);

    // Create indexes
    await db.query(
      `CREATE INDEX IF NOT EXISTS groups_status_idx ON groups(status);`
    );
    await db.query(
      `CREATE INDEX IF NOT EXISTS groups_route_idx ON groups(route_id) WHERE route_id IS NOT NULL;`
    );
    await db.query(
      `CREATE INDEX IF NOT EXISTS groups_vehicle_idx ON groups(vehicle_id) WHERE vehicle_id IS NOT NULL;`
    );
    await db.query(
      `CREATE INDEX IF NOT EXISTS groups_depot_idx ON groups(depot_id) WHERE depot_id IS NOT NULL;`
    );
    await db.query(
      `CREATE INDEX IF NOT EXISTS groups_code_idx ON groups(code) WHERE code IS NOT NULL;`
    );
    await db.query(
      `CREATE INDEX IF NOT EXISTS group_members_group_idx ON group_members(group_id);`
    );
    await db.query(
      `CREATE INDEX IF NOT EXISTS group_members_personnel_idx ON group_members(personnel_id);`
    );
    await db.query(
      `CREATE INDEX IF NOT EXISTS group_members_active_idx ON group_members(group_id, personnel_id) WHERE status = 'active';`
    );
    await db.query(
      `CREATE INDEX IF NOT EXISTS group_checkins_group_idx ON group_checkins(group_id);`
    );
    await db.query(
      `CREATE INDEX IF NOT EXISTS group_checkins_route_idx ON group_checkins(route_id);`
    );
    await db.query(
      `CREATE INDEX IF NOT EXISTS group_checkins_checked_at_idx ON group_checkins(checked_at DESC);`
    );

    console.log("[Migration] Migration 015 completed successfully");

    res.json({
      ok: true,
      message: "Migration 015 completed successfully - Groups tables created",
    });
  } catch (error) {
    console.error("[Migration] Error:", error);
    res.status(500).json({
      ok: false,
      error: error.message || "Migration failed",
    });
  }
});

// POST /api/groups/auto-create - Tự động tạo nhóm từ nhân viên
app.post("/api/groups/auto-create", async (req, res) => {
  try {
    const client = await db.connect();

    try {
      await client.query("BEGIN");

      // Helper function để extract operating area
      const extractOperatingArea = (person) => {
        if (person.operating_area) return person.operating_area;
        if (person.depot_address) {
          // Extract từ address (giống logic frontend)
          const quanMatch = person.depot_address.match(/Quận\s*(\d+)/i);
          if (quanMatch) {
            return `Quận ${quanMatch[1]}`;
          }
          if (person.depot_address.match(/Bình Thạnh/i)) return "Bình Thạnh";
          if (person.depot_address.match(/Bình Tân/i)) return "Bình Tân";
          if (person.depot_address.match(/Tân Bình/i)) return "Tân Bình";
          if (person.depot_address.match(/Tân Phú/i)) return "Tân Phú";
          if (person.depot_address.match(/Phú Nhuận/i)) return "Phú Nhuận";
          if (person.depot_address.match(/Gò Vấp/i)) return "Gò Vấp";
          if (person.depot_address.match(/Thủ Đức/i)) return "Thủ Đức";
        }
        return null;
      };

      // Helper function để generate prefix
      const getGroupPrefix = (operatingArea) => {
        if (!operatingArea) return "GRP";

        const prefixMap = {
          "Bình Thạnh": "A",
          "Bình Tân": "B",
          "Tân Bình": "T",
          "Tân Phú": "TP",
          "Phú Nhuận": "PN",
          "Gò Vấp": "GV",
          "Thủ Đức": "TD",
        };

        const quanMatch = operatingArea.match(/Quận\s*(\d+)/);
        if (quanMatch) {
          return `Q${quanMatch[1]}`;
        }

        return (
          prefixMap[operatingArea] ||
          operatingArea.substring(0, 2).toUpperCase()
        );
      };

      // Lấy tất cả nhân viên active
      const personnelResult = await client.query(`
        SELECT 
          p.id,
          p.name,
          p.depot_id,
          p.meta->>'operating_area' as operating_area,
          d.address as depot_address
        FROM personnel p
        LEFT JOIN depots d ON p.depot_id = d.id
        WHERE p.status = 'active'
        ORDER BY p.meta->>'operating_area', p.depot_id, p.name
      `);

      const allPersonnel = personnelResult.rows;

      // Group personnel theo operating_area và depot_id
      const groupsMap = new Map();

      for (const person of allPersonnel) {
        const operatingArea = extractOperatingArea(person);
        if (!operatingArea) continue; // Skip nếu không có khu vực

        const key = `${operatingArea}|${person.depot_id || "null"}`;

        if (!groupsMap.has(key)) {
          groupsMap.set(key, {
            operating_area: operatingArea,
            depot_id: person.depot_id,
            personnel: [],
          });
        }

        groupsMap.get(key).personnel.push(person);
      }

      // Tạo groups
      let createdCount = 0;
      const groupsByArea = new Map(); // Track số thứ tự theo khu vực

      for (const [key, groupData] of groupsMap) {
        if (groupData.personnel.length === 0) continue;

        const prefix = getGroupPrefix(groupData.operating_area);

        // Get next number cho khu vực này
        const areaKey = groupData.operating_area;
        if (!groupsByArea.has(areaKey)) {
          // Check existing groups
          const existingResult = await client.query(
            `
            SELECT name FROM groups 
            WHERE operating_area = $1 AND status = 'active'
            ORDER BY name DESC
          `,
            [areaKey]
          );

          const existingNums = existingResult.rows
            .map((r) => {
              // Extract number from name (A01, B02, Q101, etc.)
              const match = r.name?.match(/(\d+)$/);
              return match ? parseInt(match[1]) : 0;
            })
            .filter((n) => !isNaN(n) && n > 0)
            .sort((a, b) => b - a);

          const nextNum = existingNums.length > 0 ? existingNums[0] + 1 : 1;
          groupsByArea.set(areaKey, nextNum);
        } else {
          groupsByArea.set(areaKey, groupsByArea.get(areaKey) + 1);
        }

        const groupNum = groupsByArea.get(areaKey).toString().padStart(2, "0");
        const groupName = `${prefix}${groupNum}`;
        const today = new Date().toISOString().split("T")[0].replace(/-/g, "");
        const groupCode = `GRP-${prefix}-${groupNum}-${today}`;

        const { v4: uuidv4 } = require("uuid");
        const groupId = uuidv4();

        // Create group
        const groupResult = await client.query(
          `
          INSERT INTO groups (id, name, code, operating_area, depot_id, status, description)
          VALUES ($1, $2, $3, $4, $5, 'active', $6)
          RETURNING id
        `,
          [
            groupId,
            groupName,
            groupCode,
            groupData.operating_area,
            groupData.depot_id,
            `Nhóm tự động tạo từ ${groupData.personnel.length} nhân viên tại ${groupData.operating_area}`,
          ]
        );

        // Add members
        const leaderId = groupData.personnel[0].id; // First person as leader

        for (let i = 0; i < groupData.personnel.length; i++) {
          const person = groupData.personnel[i];
          const memberId = uuidv4();
          await client.query(
            `
            INSERT INTO group_members (id, group_id, personnel_id, role_in_group, status)
            VALUES ($1, $2, $3, $4, 'active')
          `,
            [memberId, groupId, person.id, i === 0 ? "leader" : "member"]
          );
        }

        createdCount++;
        console.log(
          `✅ Auto-created group: ${groupName} (${groupCode}) with ${groupData.personnel.length} members`
        );
      }

      await client.query("COMMIT");

      res.json({
        ok: true,
        message: `Đã tạo ${createdCount} nhóm tự động`,
        data: { created: createdCount },
      });
    } catch (error) {
      await client.query("ROLLBACK");
      throw error;
    } finally {
      client.release();
    }
  } catch (error) {
    console.error("[Groups] Auto-create error:", error);
    res.status(500).json({
      ok: false,
      error: error.message || "Tạo nhóm tự động thất bại",
    });
  }
});

// PUT /api/groups/:id - Update group
app.put("/api/groups/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const {
      name,
      code,
      description,
      vehicle_id,
      depot_id,
      operating_area,
      status,
    } = req.body;

    const updates = [];
    const params = [];
    let paramIndex = 1;

    if (name !== undefined) {
      updates.push(`name = $${paramIndex++}`);
      params.push(name);
    }

    if (code !== undefined) {
      updates.push(`code = $${paramIndex++}`);
      params.push(code);
    }

    if (description !== undefined) {
      updates.push(`description = $${paramIndex++}`);
      params.push(description);
    }

    if (vehicle_id !== undefined) {
      updates.push(`vehicle_id = $${paramIndex++}`);
      params.push(vehicle_id || null);
    }

    if (depot_id !== undefined) {
      updates.push(`depot_id = $${paramIndex++}`);
      params.push(depot_id || null);
    }

    if (operating_area !== undefined) {
      updates.push(`operating_area = $${paramIndex++}`);
      params.push(operating_area || null);
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

    const { rows } = await db.query(
      `UPDATE groups SET ${updates.join(
        ", "
      )} WHERE id = $${paramIndex} RETURNING *`,
      params
    );

    if (rows.length === 0) {
      return res.status(404).json({ ok: false, error: "Group not found" });
    }

    console.log(`✅ Group updated: ${id}`);

    res.json({
      ok: true,
      data: rows[0],
      message: "Group updated successfully",
    });
  } catch (error) {
    console.error("[Groups] Update error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// DELETE /api/groups/:id - Delete/Deactivate group
app.delete("/api/groups/:id", async (req, res) => {
  try {
    const { id } = req.params;

    const { rows } = await db.query(
      `UPDATE groups SET status = 'inactive', updated_at = NOW() WHERE id = $1 RETURNING *`,
      [id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ ok: false, error: "Group not found" });
    }

    // Deactivate all members
    await db.query(
      `UPDATE group_members SET status = 'inactive', left_at = NOW() WHERE group_id = $1 AND status = 'active'`,
      [id]
    );

    console.log(`🗑️ Group deactivated: ${id}`);

    res.json({
      ok: true,
      message: "Group deactivated successfully",
    });
  } catch (error) {
    console.error("[Groups] Delete error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// POST /api/groups/:id/members - Add member to group
app.post("/api/groups/:id/members", async (req, res) => {
  try {
    const { id } = req.params;
    const { personnel_id, role_in_group = "member" } = req.body;

    if (!personnel_id) {
      return res.status(400).json({
        ok: false,
        error: "personnel_id is required",
      });
    }

    // Check if personnel is already in an active group
    const { rows: existingRows } = await db.query(
      `SELECT * FROM group_members WHERE personnel_id = $1 AND status = 'active'`,
      [personnel_id]
    );

    if (existingRows.length > 0) {
      return res.status(400).json({
        ok: false,
        error: "Personnel is already in an active group",
      });
    }

    const { v4: uuidv4 } = require("uuid");
    const memberId = uuidv4();

    const { rows } = await db.query(
      `INSERT INTO group_members (id, group_id, personnel_id, role_in_group, status)
       VALUES ($1, $2, $3, $4, 'active')
       RETURNING *`,
      [memberId, id, personnel_id, role_in_group]
    );

    console.log(`✅ Added member ${personnel_id} to group ${id}`);

    res.status(201).json({
      ok: true,
      data: rows[0],
      message: "Member added successfully",
    });
  } catch (error) {
    console.error("[Groups] Add member error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// DELETE /api/groups/:id/members/:personnel_id - Remove member from group
app.delete("/api/groups/:id/members/:personnel_id", async (req, res) => {
  try {
    const { id, personnel_id } = req.params;

    const { rows } = await db.query(
      `UPDATE group_members 
       SET status = 'inactive', left_at = NOW() 
       WHERE group_id = $1 AND personnel_id = $2 AND status = 'active'
       RETURNING *`,
      [id, personnel_id]
    );

    if (rows.length === 0) {
      return res
        .status(404)
        .json({ ok: false, error: "Member not found in group" });
    }

    console.log(`🗑️ Removed member ${personnel_id} from group ${id}`);

    res.json({
      ok: true,
      message: "Member removed successfully",
    });
  } catch (error) {
    console.error("[Groups] Remove member error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// POST /api/groups/:id/checkins - Create check-in
app.post("/api/groups/:id/checkins", async (req, res) => {
  try {
    const { id } = req.params;
    const {
      route_id,
      route_stop_id,
      checked_by,
      waste_type,
      collected_weight_kg,
      quantity_bags,
      notes,
      photo_urls,
      lon,
      lat,
    } = req.body;

    if (!checked_by || !waste_type || !collected_weight_kg) {
      return res.status(400).json({
        ok: false,
        error: "checked_by, waste_type, and collected_weight_kg are required",
      });
    }

    const { v4: uuidv4 } = require("uuid");
    const checkinId = uuidv4();

    let geomClause = "";
    let geomValue = "";
    const params = [
      checkinId,
      id,
      route_id || null,
      route_stop_id || null,
      checked_by,
      waste_type,
      collected_weight_kg,
      quantity_bags || 0,
      notes || null,
      photo_urls || [],
    ];
    let paramIndex = params.length + 1;

    if (lon !== undefined && lat !== undefined) {
      geomClause = `, geom`;
      geomValue = `, ST_SetSRID(ST_MakePoint($${paramIndex}, $${
        paramIndex + 1
      }), 4326)`;
      params.push(lon, lat);
    }

    const query = `
      INSERT INTO group_checkins (
        id, group_id, route_id, route_stop_id, checked_by, waste_type,
        collected_weight_kg, quantity_bags, notes, photo_urls${geomClause}
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10${geomValue})
      RETURNING *
    `;

    const { rows } = await db.query(query, params);

    console.log(`✅ Check-in created: ${checkinId} for group ${id}`);

    res.status(201).json({
      ok: true,
      data: rows[0],
      message: "Check-in created successfully",
    });
  } catch (error) {
    console.error("[Groups] Create check-in error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// GET /api/groups/:id/checkins - Get check-ins for group
app.get("/api/groups/:id/checkins", async (req, res) => {
  try {
    const { id } = req.params;
    const { route_id, start_date, end_date } = req.query;

    let query = `
      SELECT 
        gc.*,
        p.name as checked_by_name,
        r.id as route_id_display
      FROM group_checkins gc
      LEFT JOIN personnel p ON gc.checked_by = p.id
      LEFT JOIN routes r ON gc.route_id = r.id
      WHERE gc.group_id = $1
    `;

    const params = [id];
    let paramIndex = 2;

    if (route_id) {
      query += ` AND gc.route_id = $${paramIndex++}`;
      params.push(route_id);
    }

    if (start_date) {
      query += ` AND gc.checked_at >= $${paramIndex++}`;
      params.push(start_date);
    }

    if (end_date) {
      query += ` AND gc.checked_at <= $${paramIndex++}`;
      params.push(end_date);
    }

    query += ` ORDER BY gc.checked_at DESC`;

    const { rows } = await db.query(query, params);

    res.json({ ok: true, data: rows });
  } catch (error) {
    console.error("[Groups] Get check-ins error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// GET /api/groups/:id/stats - Get group statistics
app.get("/api/groups/:id/stats", async (req, res) => {
  try {
    const { id } = req.params;
    const { start_date, end_date } = req.query;

    let query = `
      SELECT 
        COUNT(*) as total_checkins,
        SUM(collected_weight_kg) as total_weight_kg,
        SUM(CASE WHEN waste_type = 'household' THEN collected_weight_kg ELSE 0 END) as household_weight_kg,
        SUM(CASE WHEN waste_type = 'recyclable' THEN collected_weight_kg ELSE 0 END) as recyclable_weight_kg,
        SUM(CASE WHEN waste_type = 'bulky' THEN collected_weight_kg ELSE 0 END) as bulky_weight_kg,
        COUNT(DISTINCT route_id) as total_routes,
        COUNT(DISTINCT checked_by) as total_checkers
      FROM group_checkins
      WHERE group_id = $1
    `;

    const params = [id];
    let paramIndex = 2;

    if (start_date) {
      query += ` AND checked_at >= $${paramIndex++}`;
      params.push(start_date);
    }

    if (end_date) {
      query += ` AND checked_at <= $${paramIndex++}`;
      params.push(end_date);
    }

    const { rows } = await db.query(query, params);

    res.json({ ok: true, data: rows[0] || {} });
  } catch (error) {
    console.error("[Groups] Get stats error:", error);
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

/**
 * POST /api/auth/worker/login
 * Worker login - authenticate personnel from database
 */
app.post("/api/auth/worker/login", async (req, res) => {
  try {
    const { phone, password } = req.body;

    if (!phone || !password) {
      return res.status(400).json({
        ok: false,
        error: "Phone and password are required",
      });
    }

    // Query personnel by phone
    const { rows } = await db.query(
      `SELECT 
        p.*,
        d.name as depot_name,
        ST_Y(d.geom::geometry) as depot_lat,
        ST_X(d.geom::geometry) as depot_lon
       FROM personnel p
       LEFT JOIN depots d ON p.depot_id = d.id
       WHERE p.phone = $1 AND p.status = 'active'`,
      [phone]
    );

    if (rows.length === 0) {
      return res.status(401).json({
        ok: false,
        error: "Invalid phone or password",
      });
    }

    const personnel = rows[0];

    // TODO: In production, verify password hash
    // For now, accept '123456' or 'worker123' for demo
    if (password !== "123456" && password !== "worker123") {
      return res.status(401).json({
        ok: false,
        error: "Invalid phone or password",
      });
    }

    // Get group information if assigned
    const groupResult = await db.query(
      `SELECT 
        g.*,
        gm.role_in_group,
        v.plate as vehicle_plate,
        v.type as vehicle_type,
        v.capacity_kg as vehicle_capacity
       FROM group_members gm
       JOIN groups g ON gm.group_id = g.id
       LEFT JOIN vehicles v ON g.vehicle_id = v.id
       WHERE gm.personnel_id = $1 
         AND gm.status = 'active'
         AND g.status = 'active'
       LIMIT 1`,
      [personnel.id]
    );

    const group = groupResult.rows.length > 0 ? groupResult.rows[0] : null;

    console.log(`🔐 Worker logged in: ${personnel.name} (${personnel.phone})`);

    // Return worker data with group info
    res.json({
      ok: true,
      data: {
        id: personnel.id,
        phone: personnel.phone,
        email: personnel.email || "",
        role: "worker", // Set role as 'worker' for mobile app
        personnelRole: personnel.role, // driver, collector, etc.
        fullName: personnel.name,
        depotId: personnel.depot_id,
        depotName: personnel.depot_name || "",
        depotLocation:
          personnel.depot_lat && personnel.depot_lon
            ? {
                latitude: personnel.depot_lat,
                longitude: personnel.depot_lon,
              }
            : null,
        groupId: group?.id || null,
        groupName: group?.name || null,
        groupCode: group?.code || null,
        roleInGroup: group?.role_in_group || null,
        operatingArea: group?.operating_area || null,
        vehicleId: group?.vehicle_id || null,
        vehiclePlate: group?.vehicle_plate || null,
        vehicleType: group?.vehicle_type || null,
        skills: personnel.meta?.skills || [],
        experience: personnel.meta?.experience_years || 0,
        license: personnel.meta?.license || null,
        isVerified: true,
        isActive: personnel.status === "active",
        createdAt: personnel.created_at,
        updatedAt: personnel.updated_at,
      },
      message: "Login successful",
    });
  } catch (error) {
    console.error("[Auth] Worker login error:", error);
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

// ==================== GAMIFICATION ANALYTICS API ====================

// Get gamification overview statistics
app.get("/api/gamification/analytics/overview", async (req, res) => {
  try {
    // Total users with points
    const totalUsersQuery = await db.query(
      `SELECT COUNT(*) as count FROM user_points WHERE points > 0`
    );
    const totalUsers = parseInt(totalUsersQuery.rows[0]?.count || 0);

    // Points distributed today
    const todayPointsQuery = await db.query(
      `SELECT COALESCE(SUM(points), 0) as total
       FROM point_transactions
       WHERE DATE(created_at) = CURRENT_DATE
       AND type IN ('earn', 'bonus', 'adjustment')
       AND points > 0`
    );
    const pointsToday = parseInt(todayPointsQuery.rows[0]?.total || 0);

    // Points distributed this month
    const monthPointsQuery = await db.query(
      `SELECT COALESCE(SUM(points), 0) as total
       FROM point_transactions
       WHERE DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE)
       AND type IN ('earn', 'bonus', 'adjustment')
       AND points > 0`
    );
    const pointsMonth = parseInt(monthPointsQuery.rows[0]?.total || 0);

    // Badges unlocked
    const badgesQuery = await db.query(
      `SELECT COUNT(DISTINCT badge_id) as count FROM user_badges`
    );
    const badgesUnlocked = parseInt(badgesQuery.rows[0]?.count || 0);

    // Top 5 users
    const topUsersQuery = await db.query(
      `SELECT 
        u.id as user_id,
        u.profile->>'name' as user_name,
        up.points,
        up.level,
        up.total_checkins
       FROM user_points up
       JOIN users u ON u.id = up.user_id
       WHERE u.status = 'active' AND up.points > 0
       ORDER BY up.points DESC
       LIMIT 5`
    );

    const topUsers = topUsersQuery.rows.map((row) => {
      let rankTier = "Người mới";
      if (row.level >= 10) rankTier = "Huyền thoại";
      else if (row.level >= 7) rankTier = "Chuyên gia";
      else if (row.level >= 5) rankTier = "Chiến binh xanh";
      else if (row.level >= 3) rankTier = "Người tích cực";

      return {
        userId: row.user_id,
        userName: row.user_name || "User",
        points: parseInt(row.points || 0),
        level: parseInt(row.level || 1),
        rankTier: rankTier,
        totalCheckins: parseInt(row.total_checkins || 0),
      };
    });

    res.json({
      ok: true,
      data: {
        totalUsers,
        pointsDistributed: {
          today: pointsToday,
          month: pointsMonth,
        },
        badgesUnlocked,
        topUsers,
      },
    });
  } catch (error) {
    console.error("[Gamification Analytics] Overview error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Get gamification trends
app.get("/api/gamification/analytics/trends", async (req, res) => {
  try {
    const { period = "7d" } = req.query;
    
    // Calculate date range based on period
    let days = 7;
    if (period === "30d") days = 30;
    else if (period === "90d") days = 90;
    else if (period === "365d") days = 365;

    // Points trend - daily aggregation
    const pointsTrendQuery = await db.query(
      `SELECT 
        DATE(created_at) as date,
        COALESCE(SUM(points), 0) as points,
        COUNT(*) as transactions
       FROM point_transactions
       WHERE created_at >= CURRENT_DATE - INTERVAL '${days} days'
       AND type IN ('earn', 'bonus', 'adjustment')
       AND points > 0
       GROUP BY DATE(created_at)
       ORDER BY date ASC`
    );

    const pointsTrend = pointsTrendQuery.rows.map((row) => ({
      date: row.date.toISOString().split("T")[0],
      points: parseInt(row.points || 0),
      transactions: parseInt(row.transactions || 0),
    }));

    // Check-ins trend - daily aggregation
    const checkinsTrendQuery = await db.query(
      `SELECT 
        DATE(created_at) as date,
        COUNT(*) as checkins
       FROM checkins
       WHERE created_at >= CURRENT_DATE - INTERVAL '${days} days'
       GROUP BY DATE(created_at)
       ORDER BY date ASC`
    );

    const checkinsTrend = checkinsTrendQuery.rows.map((row) => ({
      date: row.date.toISOString().split("T")[0],
      checkins: parseInt(row.checkins || 0),
    }));

    res.json({
      ok: true,
      data: {
        pointsTrend,
        checkinsTrend,
      },
    });
  } catch (error) {
    console.error("[Gamification Analytics] Trends error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Get gamification distribution
app.get("/api/gamification/analytics/distribution", async (req, res) => {
  try {
    const { type = "rank_tier" } = req.query;

    if (type === "rank_tier") {
      // Distribution by rank tier
      const distributionQuery = await db.query(
        `WITH tier_data AS (
          SELECT 
            CASE 
              WHEN level >= 10 THEN 'Huyền thoại'
              WHEN level >= 7 THEN 'Chuyên gia'
              WHEN level >= 5 THEN 'Chiến binh xanh'
              WHEN level >= 3 THEN 'Người tích cực'
              ELSE 'Người mới'
            END as tier
          FROM user_points
        )
        SELECT 
          tier,
          COUNT(*) as count
         FROM tier_data
         GROUP BY tier
         ORDER BY 
           CASE tier
             WHEN 'Huyền thoại' THEN 1
             WHEN 'Chuyên gia' THEN 2
             WHEN 'Chiến binh xanh' THEN 3
             WHEN 'Người tích cực' THEN 4
             WHEN 'Người mới' THEN 5
           END`
      );

      const distribution = distributionQuery.rows.map((row) => ({
        tier: row.tier || row.rank_tier,
        count: parseInt(row.count || 0),
      }));

      const total = distribution.reduce((sum, item) => sum + item.count, 0);

      res.json({
        ok: true,
        data: {
          type: "rank_tier",
          distribution,
          total,
        },
      });
    } else if (type === "level") {
      // Distribution by level
      const distributionQuery = await db.query(
        `SELECT level, COUNT(*) as count
         FROM user_points
         GROUP BY level
         ORDER BY level ASC`
      );

      const distribution = distributionQuery.rows.map((row) => ({
        level: parseInt(row.level || 1),
        count: parseInt(row.count || 0),
      }));

      const total = distribution.reduce((sum, item) => sum + item.count, 0);

      res.json({
        ok: true,
        data: {
          type: "level",
          distribution,
          total,
        },
      });
    } else {
      res.status(400).json({
        ok: false,
        error: "Invalid distribution type. Use 'rank_tier' or 'level'",
      });
    }
  } catch (error) {
    console.error("[Gamification Analytics] Distribution error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// ==================== GAMIFICATION POINTS API ====================

// Get point transactions history
app.get("/api/gamification/points/transactions", async (req, res) => {
  try {
    const { user_id, type, limit = 50, offset = 0 } = req.query;
    
    let query = `
      SELECT 
        pt.id,
        pt.user_id,
        u.profile->>'name' as user_name,
        u.profile->>'email' as user_email,
        pt.points,
        pt.type,
        pt.reason,
        pt.reference_id,
        pt.reference_type,
        pt.created_at
      FROM point_transactions pt
      JOIN users u ON u.id = pt.user_id
      WHERE 1=1
    `;
    const params = [];
    let paramIndex = 1;

    if (user_id) {
      query += ` AND pt.user_id = $${paramIndex++}`;
      params.push(user_id);
    }

    if (type) {
      query += ` AND pt.type = $${paramIndex++}`;
      params.push(type);
    }

    query += ` ORDER BY pt.created_at DESC LIMIT $${paramIndex++} OFFSET $${paramIndex++}`;
    params.push(parseInt(limit), parseInt(offset));

    const { rows } = await db.query(query, params);

    // Get total count
    let countQuery = `
      SELECT COUNT(*) as total
      FROM point_transactions pt
      WHERE 1=1
    `;
    const countParams = [];
    let countParamIndex = 1;

    if (user_id) {
      countQuery += ` AND pt.user_id = $${countParamIndex++}`;
      countParams.push(user_id);
    }

    if (type) {
      countQuery += ` AND pt.type = $${countParamIndex++}`;
      countParams.push(type);
    }

    const countResult = await db.query(countQuery, countParams);
    const total = parseInt(countResult.rows[0]?.total || 0);

    // Map snake_case to camelCase for frontend
    const mappedRows = rows.map(row => ({
      id: row.id,
      userId: row.user_id,
      userName: row.user_name || 'N/A',
      userEmail: row.user_email || '',
      points: parseInt(row.points || 0),
      transactionType: row.type,
      reason: row.reason || '',
      referenceId: row.reference_id,
      referenceType: row.reference_type,
      createdAt: row.created_at ? new Date(row.created_at).toISOString() : null,
    }));

    res.json({
      ok: true,
      data: mappedRows,
      total,
      limit: parseInt(limit),
      offset: parseInt(offset),
    });
  } catch (error) {
    console.error("[Gamification] Get transactions error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Adjust points (add or subtract)
app.post("/api/gamification/points/adjust", async (req, res) => {
  try {
    const { user_id, points, reason } = req.body;

    if (!user_id || points === undefined) {
      return res.status(400).json({
        ok: false,
        error: "user_id and points are required",
      });
    }

    // Find user_id if input is name/email instead of UUID
    let actualUserId = user_id;
    const isUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(user_id);
    
    if (!isUUID) {
      // Try to find user by name or email
      const userQuery = await db.query(
        `SELECT id FROM users 
         WHERE profile->>'name' ILIKE $1 
            OR profile->>'email' ILIKE $1 
            OR phone = $1
         LIMIT 1`,
        [`%${user_id}%`]
      );
      
      if (userQuery.rows.length === 0) {
        return res.status(404).json({
          ok: false,
          error: `Không tìm thấy user với ID/tên/email: ${user_id}`,
        });
      }
      
      actualUserId = userQuery.rows[0].id;
    }

    const transactionType = points > 0 ? "adjustment" : "penalty";

    // Add points transaction
    await db.query(
      `INSERT INTO point_transactions (user_id, points, type, reason)
       VALUES ($1, $2, $3, $4)`,
      [actualUserId, points, transactionType, reason || "Points adjustment"]
    );

    // Update user points and recalculate level
    const { rows } = await db.query(
      `UPDATE user_points
       SET points = GREATEST(0, points + $1),
           level = calculate_level_from_points(GREATEST(0, points + $1)),
           updated_at = NOW()
       WHERE user_id = $2
       RETURNING points, level`,
      [points, actualUserId]
    );

    let finalPoints = rows[0]?.points || 0;
    let finalLevel = rows[0]?.level || 1;

    if (rows.length === 0) {
      // Create user_points entry if doesn't exist
      const newPoints = GREATEST(0, points);
      const insertResult = await db.query(
        `INSERT INTO user_points (user_id, points, level)
         VALUES ($1, $2, calculate_level_from_points($2))
         ON CONFLICT (user_id) DO UPDATE
         SET points = GREATEST(0, user_points.points + $3),
             level = calculate_level_from_points(GREATEST(0, user_points.points + $3)),
             updated_at = NOW()
         RETURNING points, level`,
        [actualUserId, newPoints, points]
      );
      if (insertResult.rows.length > 0) {
        finalPoints = insertResult.rows[0].points;
        finalLevel = insertResult.rows[0].level;
      }
    }

    // Check and unlock badges after points adjustment
    await db.query('SELECT check_and_unlock_badges($1)', [actualUserId]);

    console.log(`📊 Points adjusted: ${points > 0 ? '+' : ''}${points} points for user ${actualUserId}`);

    res.json({
      ok: true,
      data: {
        totalPoints: finalPoints,
        level: finalLevel,
        pointsAdjusted: points,
      },
      message: "Points adjusted successfully",
    });
  } catch (error) {
    console.error("[Gamification] Adjust points error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Get points rules
app.get("/api/gamification/points/rules", async (req, res) => {
  try {
    const rules = {
      earn: {
        checkin: {
          base: 10,
          description: "Mỗi lần check-in",
        },
        recyclable: {
          base: 15,
          description: "Check-in rác tái chế",
        },
        bulky: {
          base: 20,
          description: "Check-in rác cồng kềnh",
        },
        streak: {
          base: 5,
          description: "Điểm thưởng streak (mỗi ngày liên tiếp)",
        },
      },
      bonus: {
        first_checkin: {
          points: 50,
          description: "Check-in đầu tiên",
        },
        weekly_goal: {
          points: 100,
          description: "Hoàn thành mục tiêu tuần",
        },
        monthly_goal: {
          points: 500,
          description: "Hoàn thành mục tiêu tháng",
        },
      },
      level_thresholds: [
        { level: 1, points: 0 },
        { level: 2, points: 100 },
        { level: 3, points: 300 },
        { level: 4, points: 600 },
        { level: 5, points: 1000 },
        { level: 6, points: 1500 },
        { level: 7, points: 2200 },
        { level: 8, points: 3000 },
        { level: 9, points: 4000 },
        { level: 10, points: 5000 },
      ],
    };

    res.json({
      ok: true,
      data: rules,
    });
  } catch (error) {
    console.error("[Gamification] Get rules error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// ==================== GAMIFICATION BADGES API ====================

// Create badge
app.post("/api/gamification/badges", async (req, res) => {
  try {
    const { code, name, description, icon_url, criteria, points_reward, rarity } = req.body;

    if (!code || !name || !criteria) {
      return res.status(400).json({
        ok: false,
        error: "code, name, and criteria are required",
      });
    }

    const { rows } = await db.query(
      `INSERT INTO badges (code, name, description, icon_url, criteria, points_reward, rarity, active)
       VALUES ($1, $2, $3, $4, $5, $6, $7, true)
       RETURNING *`,
      [
        code,
        name,
        description || null,
        icon_url || null,
        JSON.stringify(criteria),
        points_reward || 0,
        rarity || "common",
      ]
    );

    console.log(`🏆 Badge created: ${code} (${name})`);

    res.status(201).json({
      ok: true,
      data: rows[0],
      message: "Badge created successfully",
    });
  } catch (error) {
    console.error("[Gamification] Create badge error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Update badge
app.patch("/api/gamification/badges/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description, icon_url, criteria, points_reward, rarity, active } = req.body;

    const updates = [];
    const params = [];
    let paramIndex = 1;

    if (name !== undefined) {
      updates.push(`name = $${paramIndex++}`);
      params.push(name);
    }
    if (description !== undefined) {
      updates.push(`description = $${paramIndex++}`);
      params.push(description);
    }
    if (icon_url !== undefined) {
      updates.push(`icon_url = $${paramIndex++}`);
      params.push(icon_url);
    }
    if (criteria !== undefined) {
      updates.push(`criteria = $${paramIndex++}`);
      params.push(JSON.stringify(criteria));
    }
    if (points_reward !== undefined) {
      updates.push(`points_reward = $${paramIndex++}`);
      params.push(points_reward);
    }
    if (rarity !== undefined) {
      updates.push(`rarity = $${paramIndex++}`);
      params.push(rarity);
    }
    if (active !== undefined) {
      updates.push(`active = $${paramIndex++}`);
      params.push(active);
    }

    if (updates.length === 0) {
      return res.status(400).json({
        ok: false,
        error: "No fields to update",
      });
    }

    params.push(id);
    const { rows } = await db.query(
      `UPDATE badges
       SET ${updates.join(", ")}
       WHERE id = $${paramIndex}
       RETURNING *`,
      params
    );

    if (rows.length === 0) {
      return res.status(404).json({
        ok: false,
        error: "Badge not found",
      });
    }

    console.log(`🏆 Badge updated: ${id}`);

    res.json({
      ok: true,
      data: rows[0],
      message: "Badge updated successfully",
    });
  } catch (error) {
    console.error("[Gamification] Update badge error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Delete badge
app.delete("/api/gamification/badges/:id", async (req, res) => {
  try {
    const { id } = req.params;

    const { rows } = await db.query(
      `UPDATE badges SET active = false WHERE id = $1 RETURNING *`,
      [id]
    );

    if (rows.length === 0) {
      return res.status(404).json({
        ok: false,
        error: "Badge not found",
      });
    }

    console.log(`🏆 Badge deactivated: ${id}`);

    res.json({
      ok: true,
      message: "Badge deactivated successfully",
    });
  } catch (error) {
    console.error("[Gamification] Delete badge error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Assign badge to user
app.post("/api/gamification/badges/assign", async (req, res) => {
  try {
    const { user_id, badge_id, reason } = req.body;

    if (!user_id || !badge_id) {
      return res.status(400).json({
        ok: false,
        error: "user_id and badge_id are required",
      });
    }

    // Check if badge exists and is active
    const badgeCheck = await db.query(
      `SELECT id, points_reward FROM badges WHERE id = $1 AND active = true`,
      [badge_id]
    );

    if (badgeCheck.rows.length === 0) {
      return res.status(404).json({
        ok: false,
        error: "Badge not found or inactive",
      });
    }

    // Check if user already has this badge
    const existing = await db.query(
      `SELECT id FROM user_badges WHERE user_id = $1 AND badge_id = $2`,
      [user_id, badge_id]
    );

    if (existing.rows.length > 0) {
      return res.status(409).json({
        ok: false,
        error: "User already has this badge",
      });
    }

    // Assign badge
    await db.query(
      `INSERT INTO user_badges (user_id, badge_id, earned_at)
       VALUES ($1, $2, NOW())`,
      [user_id, badge_id]
    );

    // Award points if badge has points reward
    const pointsReward = badgeCheck.rows[0].points_reward;
    if (pointsReward > 0) {
      await db.query(
        `INSERT INTO point_transactions (user_id, points, type, reason, reference_id, reference_type)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [user_id, pointsReward, "bonus", reason || "Badge reward", badge_id, "badge"]
      );

      await db.query(
        `UPDATE user_points
         SET points = points + $1,
             level = calculate_level_from_points(points + $1),
             updated_at = NOW()
         WHERE user_id = $2`,
        [pointsReward, user_id]
      );
    }

    console.log(`🏆 Badge assigned: ${badge_id} to user ${user_id}`);

    res.json({
      ok: true,
      message: "Badge assigned successfully",
      data: {
        badgeId: badge_id,
        pointsAwarded: pointsReward,
      },
    });
  } catch (error) {
    console.error("[Gamification] Assign badge error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Get badge analytics
app.get("/api/gamification/badges/analytics", async (req, res) => {
  try {
    // Total badges
    const totalBadgesQuery = await db.query(
      `SELECT COUNT(*) as total FROM badges WHERE active = true`
    );
    const totalBadges = parseInt(totalBadgesQuery.rows[0]?.total || 0);

    // Total badges unlocked (distinct badge types)
    const unlockedBadgesQuery = await db.query(
      `SELECT COUNT(DISTINCT badge_id) as total FROM user_badges`
    );
    const unlockedBadges = parseInt(unlockedBadgesQuery.rows[0]?.total || 0);

    // Users with badges
    const usersWithBadgesQuery = await db.query(
      `SELECT COUNT(DISTINCT user_id) as total FROM user_badges`
    );
    const usersWithBadges = parseInt(usersWithBadgesQuery.rows[0]?.total || 0);

    // Total unlocks (all badge unlocks)
    const totalUnlocksQuery = await db.query(
      `SELECT COUNT(*) as total FROM user_badges`
    );
    const totalUnlocks = parseInt(totalUnlocksQuery.rows[0]?.total || 0);

    // Badges by rarity
    const rarityQuery = await db.query(
      `SELECT rarity, COUNT(*) as count
       FROM badges
       WHERE active = true
       GROUP BY rarity`
    );
    const byRarity = rarityQuery.rows.reduce((acc, row) => {
      acc[row.rarity] = parseInt(row.count || 0);
      return acc;
    }, {});

    // Most unlocked badges
    const popularQuery = await db.query(
      `SELECT 
        b.id,
        b.name,
        b.rarity,
        COUNT(ub.id) as unlock_count
       FROM badges b
       LEFT JOIN user_badges ub ON b.id = ub.badge_id
       WHERE b.active = true
       GROUP BY b.id, b.name, b.rarity
       ORDER BY unlock_count DESC
       LIMIT 10`
    );
    const mostPopular = popularQuery.rows.map((row) => ({
      id: row.id,
      name: row.name,
      rarity: row.rarity,
      unlockCount: parseInt(row.unlock_count || 0),
    }));

    res.json({
      ok: true,
      data: {
        statistics: {
          totalBadges,
          unlockedBadges,
          usersWithBadges,
          totalUnlocks,
        },
        byRarity,
        mostPopular,
      },
    });
  } catch (error) {
    console.error("[Gamification] Get badge analytics error:", error);
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
      `INSERT INTO point_transactions (user_id, points, type, reason)
       VALUES ($1, $2, $3, $4)`,
      [userId, points, "bonus", reason || "Reward claimed"]
    );

    // Update user points and recalculate level
    const { rows } = await db.query(
      `UPDATE user_points
       SET points = points + $1,
           level = calculate_level_from_points(points + $1),
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

// ==================== AIR QUALITY API ====================
const airQualityService = require('./services/airquality');

// Get air quality data for a location
app.get("/api/air-quality", async (req, res) => {
  try {
    const { lat, lon } = req.query;
    
    if (!lat || !lon) {
      return res.status(400).json({
        ok: false,
        error: "lat and lon query parameters are required"
      });
    }

    const latNum = parseFloat(lat);
    const lonNum = parseFloat(lon);

    if (isNaN(latNum) || isNaN(lonNum)) {
      return res.status(400).json({
        ok: false,
        error: "Invalid lat or lon values"
      });
    }

    const aqiData = await airQualityService.getAirQuality(latNum, lonNum);
    
    res.json({
      ok: true,
      data: aqiData
    });
  } catch (error) {
    console.error("[Air Quality] Get error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// ==================== POI (Points of Interest) API ====================
const poiService = require('./services/poi');

// Get POIs near a location (alias for /api/poi/nearby)
app.get("/api/poi", async (req, res) => {
  try {
    const { lat, lon, type, radius = 500 } = req.query;
    
    if (!lat || !lon) {
      return res.status(400).json({
        ok: false,
        error: "lat and lon query parameters are required"
      });
    }

    const latNum = parseFloat(lat);
    const lonNum = parseFloat(lon);
    const radiusNum = parseInt(radius);

    if (isNaN(latNum) || isNaN(lonNum)) {
      return res.status(400).json({
        ok: false,
        error: "Invalid lat or lon values"
      });
    }

    const pois = await poiService.getNearbyPOI(latNum, lonNum, radiusNum, type);
    
    res.json({
      ok: true,
      data: pois
    });
  } catch (error) {
    console.error("[POI] Get error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Get POIs near a location (frontend uses this endpoint)
app.get("/api/poi/nearby", async (req, res) => {
  try {
    const { lat, lon, type, radius = 500 } = req.query;
    
    if (!lat || !lon) {
      return res.status(400).json({
        ok: false,
        error: "lat and lon query parameters are required"
      });
    }

    const latNum = parseFloat(lat);
    const lonNum = parseFloat(lon);
    const radiusNum = parseInt(radius);

    if (isNaN(latNum) || isNaN(lonNum)) {
      return res.status(400).json({
        ok: false,
        error: "Invalid lat or lon values"
      });
    }

    const pois = await poiService.getNearbyPOI(latNum, lonNum, radiusNum, type);
    
    res.json({
      ok: true,
      data: pois
    });
  } catch (error) {
    console.error("[POI] Get nearby error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// ==================== SENSOR ALERTS API ====================
const sensorsService = require('./services/sensors');

// Get containers that need collection (fill level > threshold)
app.get("/api/sensors/alerts", async (req, res) => {
  try {
    const { threshold = 80 } = req.query;
    const thresholdNum = parseInt(threshold);

    if (isNaN(thresholdNum) || thresholdNum < 0 || thresholdNum > 100) {
      return res.status(400).json({
        ok: false,
        error: "Invalid threshold value (must be 0-100)"
      });
    }

    const containers = await sensorsService.getContainersNeedingCollection(thresholdNum);
    
    res.json({
      ok: true,
      data: containers
    });
  } catch (error) {
    console.error("[Sensors] Get alerts error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Get sensor data for a specific container
app.get("/api/sensors/container/:containerId", async (req, res) => {
  try {
    const { containerId } = req.params;
    
    const sensorData = await sensorsService.getContainerLevel(containerId);
    
    if (!sensorData) {
      return res.status(404).json({
        ok: false,
        error: "Container not found"
      });
    }

    res.json({
      ok: true,
      data: sensorData
    });
  } catch (error) {
    console.error("[Sensors] Get container error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Get container level (alias for frontend compatibility)
app.get("/api/sensors/:containerId/level", async (req, res) => {
  try {
    const { containerId } = req.params;
    
    const sensorData = await sensorsService.getContainerLevel(containerId);
    
    if (!sensorData) {
      return res.status(404).json({
        ok: false,
        error: "Container not found"
      });
    }

    res.json({
      ok: true,
      data: {
        containerId: sensorData.containerId || containerId,
        fillLevel: sensorData.fillLevel || 0,
        level: sensorData.level || 0,
        timestamp: sensorData.timestamp || new Date().toISOString(),
      }
    });
  } catch (error) {
    console.error("[Sensors] Get level error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Get observations for a container
app.get("/api/sensors/container/:containerId/observations", async (req, res) => {
  try {
    const { containerId } = req.params;
    const { limit = 100 } = req.query;
    
    const observations = await sensorsService.getContainerObservations(containerId, parseInt(limit));
    
    res.json({
      ok: true,
      data: observations
    });
  } catch (error) {
    console.error("[Sensors] Get observations error:", error);
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
      limit = 1000,
      offset = 0,
    } = req.query;

    // Join with personnel to get reporter name and phone
    let query = `
      SELECT 
        i.*,
        p.name as personnel_name,
        p.phone as personnel_phone,
        p.role as personnel_role,
        assigned_p.name as assigned_personnel_name
      FROM incidents i
      LEFT JOIN personnel p ON i.reporter_id = p.id
      LEFT JOIN personnel assigned_p ON i.assigned_to = assigned_p.id
      WHERE 1=1
    `;
    const params = [];
    let paramIndex = 1;

    if (reporter_id) {
      query += ` AND i.reporter_id = $${paramIndex++}`;
      params.push(reporter_id);
    }

    if (report_category) {
      query += ` AND i.report_category = $${paramIndex++}`;
      params.push(report_category);
    }

    if (type) {
      query += ` AND i.type = $${paramIndex++}`;
      params.push(type);
    }

    if (status) {
      query += ` AND i.status = $${paramIndex++}`;
      params.push(status);
    }

    if (priority) {
      query += ` AND i.priority = $${paramIndex++}`;
      params.push(priority);
    }

    query += ` ORDER BY i.created_at DESC LIMIT $${paramIndex++} OFFSET $${paramIndex}`;
    params.push(parseInt(limit), parseInt(offset));

    const { rows } = await db.query(query, params);

    // Enrich data with reporter info
    const enrichedRows = rows.map((row) => {
      // Use personnel info if available, otherwise use incident reporter info
      const reporterName = row.personnel_name || row.reporter_name || null;
      const reporterPhone = row.personnel_phone || row.reporter_phone || null;

      return {
        ...row,
        reporter_name: reporterName,
        reporter_phone: reporterPhone,
        is_worker: !!row.personnel_name, // Flag to identify if reporter is a worker
      };
    });

    res.json({
      ok: true,
      data: enrichedRows,
      total: enrichedRows.length,
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

    // Join with personnel to get reporter and assigned personnel info
    const { rows } = await db.query(
      `SELECT 
        i.*,
        p.name as personnel_name,
        p.phone as personnel_phone,
        p.role as personnel_role,
        assigned_p.name as assigned_personnel_name,
        assigned_p.phone as assigned_personnel_phone
      FROM incidents i
      LEFT JOIN personnel p ON i.reporter_id = p.id
      LEFT JOIN personnel assigned_p ON i.assigned_to = assigned_p.id
      WHERE i.id = $1`,
      [id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ ok: false, error: "Incident not found" });
    }

    const row = rows[0];
    // Enrich data
    const enrichedData = {
      ...row,
      reporter_name: row.personnel_name || row.reporter_name || null,
      reporter_phone: row.personnel_phone || row.reporter_phone || null,
      is_worker: !!row.personnel_name,
      assigned_personnel_name: row.assigned_personnel_name || null,
    };

    res.json({
      ok: true,
      data: enrichedData,
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

// Update full incident (admin only)
app.put("/api/incidents/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const {
      report_category,
      type,
      description,
      latitude,
      longitude,
      location_address,
      image_urls,
      priority,
      status,
      assigned_to,
      resolution_notes,
    } = req.body;

    // Build update query dynamically
    const updates = [];
    const params = [];
    let paramIndex = 1;

    if (report_category !== undefined) {
      if (!["violation", "damage"].includes(report_category)) {
        return res.status(400).json({
          ok: false,
          error: "report_category must be 'violation' or 'damage'",
        });
      }
      updates.push(`report_category = $${paramIndex++}`);
      params.push(report_category);
    }

    if (type !== undefined) {
      updates.push(`type = $${paramIndex++}`);
      params.push(type);
    }

    if (description !== undefined) {
      updates.push(`description = $${paramIndex++}`);
      params.push(description);
    }

    if (latitude !== undefined) {
      updates.push(`latitude = $${paramIndex++}`);
      params.push(latitude);
    }

    if (longitude !== undefined) {
      updates.push(`longitude = $${paramIndex++}`);
      params.push(longitude);
    }

    if (location_address !== undefined) {
      updates.push(`location_address = $${paramIndex++}`);
      params.push(location_address);
    }

    if (image_urls !== undefined) {
      updates.push(`image_urls = $${paramIndex++}`);
      params.push(image_urls);
    }

    if (priority !== undefined) {
      const validPriorities = ["low", "medium", "high", "urgent"];
      if (!validPriorities.includes(priority)) {
        return res.status(400).json({
          ok: false,
          error: `Invalid priority. Must be one of: ${validPriorities.join(", ")}`,
        });
      }
      updates.push(`priority = $${paramIndex++}`);
      params.push(priority);
    }

    if (status !== undefined) {
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
      updates.push(`status = $${paramIndex++}`);
      params.push(status);

      // Set resolved_at if status changes to resolved/closed
      if (status === "resolved" || status === "closed") {
        updates.push(`resolved_at = NOW()`);
      }
    }

    if (assigned_to !== undefined) {
      updates.push(`assigned_to = $${paramIndex++}`);
      params.push(assigned_to || null);
    }

    if (resolution_notes !== undefined) {
      updates.push(`resolution_notes = $${paramIndex++}`);
      params.push(resolution_notes);
    }

    if (updates.length === 0) {
      return res.status(400).json({
        ok: false,
        error: "No fields to update",
      });
    }

    updates.push(`updated_at = NOW()`);
    params.push(id);

    const query = `UPDATE incidents 
                   SET ${updates.join(", ")} 
                   WHERE id = $${paramIndex} 
                   RETURNING *`;

    const { rows } = await db.query(query, params);

    if (rows.length === 0) {
      return res.status(404).json({ ok: false, error: "Incident not found" });
    }

    res.json({
      ok: true,
      data: rows[0],
      message: "Incident updated successfully",
    });
  } catch (error) {
    console.error("[Incidents] Update incident error:", error);
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

// ============================================================================
// WORKER APP APIS
// ============================================================================

/**
 * GET /api/worker/profile/:id
 * Get worker profile with group and vehicle information
 */
app.get("/api/worker/profile/:id", async (req, res) => {
  try {
    const { id } = req.params;

    const result = await db.query(
      `
      SELECT 
        p.*,
        d.name as depot_name,
        d.geom as depot_location,
        -- Group information
        g.id as group_id,
        g.name as group_name,
        g.code as group_code,
        g.operating_area,
        g.vehicle_id,
        gm.role_in_group,
        -- Vehicle information
        v.plate as vehicle_plate,
        v.type as vehicle_type,
        v.capacity_kg as vehicle_capacity,
        v.status as vehicle_status
      FROM personnel p
      LEFT JOIN depots d ON p.depot_id = d.id
      LEFT JOIN group_members gm ON p.id = gm.personnel_id AND gm.status = 'active'
      LEFT JOIN groups g ON gm.group_id = g.id AND g.status = 'active'
      LEFT JOIN vehicles v ON g.vehicle_id = v.id
      WHERE p.id = $1
    `,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ ok: false, error: "Personnel not found" });
    }

    res.json({ ok: true, data: result.rows[0] });
  } catch (error) {
    console.error("[Worker] Get profile error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

/**
 * GET /api/worker/group/:personnelId
 * Get worker's current group with all members
 */
app.get("/api/worker/group/:personnelId", async (req, res) => {
  try {
    const { personnelId } = req.params;

    // Get group info
    const groupResult = await db.query(
      `
      SELECT 
        g.*,
        v.plate as vehicle_plate,
        v.type as vehicle_type,
        v.capacity_kg as vehicle_capacity,
        d.name as depot_name
      FROM groups g
      JOIN group_members gm ON g.id = gm.group_id
      LEFT JOIN vehicles v ON g.vehicle_id = v.id
      LEFT JOIN depots d ON g.depot_id = d.id
      WHERE gm.personnel_id = $1 
        AND gm.status = 'active'
        AND g.status = 'active'
      LIMIT 1
    `,
      [personnelId]
    );

    if (groupResult.rows.length === 0) {
      return res.json({ ok: true, data: null, message: "No active group" });
    }

    const group = groupResult.rows[0];

    // Get all members
    const membersResult = await db.query(
      `
      SELECT 
        p.id,
        p.name,
        p.role,
        p.phone,
        p.email,
        gm.role_in_group,
        gm.joined_at
      FROM group_members gm
      JOIN personnel p ON gm.personnel_id = p.id
      WHERE gm.group_id = $1 AND gm.status = 'active'
      ORDER BY 
        CASE gm.role_in_group WHEN 'leader' THEN 1 ELSE 2 END,
        p.name
    `,
      [group.id]
    );

    group.members = membersResult.rows;

    res.json({ ok: true, data: group });
  } catch (error) {
    console.error("[Worker] Get group error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

/**
 * GET /api/worker/schedule/:personnelId
 * Get worker's schedule for today or specified date
 */
app.get("/api/worker/schedule/:personnelId", async (req, res) => {
  try {
    const { personnelId } = req.params;
    const { date } = req.query;
    const targetDate = date || new Date().toISOString().split("T")[0];

    const result = await db.query(
      `
      SELECT 
        s.*,
        p.name as point_name,
        p.address,
        ST_Y(p.geom::geometry) as lat,
        ST_X(p.geom::geometry) as lon,
        u.phone as citizen_phone,
        ua.label as citizen_address_label
      FROM schedules s
      JOIN points p ON s.point_id = p.id
      LEFT JOIN user_addresses ua ON s.citizen_address_id = ua.id
      LEFT JOIN users u ON ua.user_id = u.id
      WHERE s.assigned_to = $1
        AND DATE(s.scheduled_date) = $2
      ORDER BY s.scheduled_time
    `,
      [personnelId, targetDate]
    );

    res.json({ ok: true, data: result.rows });
  } catch (error) {
    console.error("[Worker] Get schedule error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

/**
 * GET /api/worker/route/:routeId
 * Get route details with stops for worker
 */
app.get("/api/worker/route/:routeId", async (req, res) => {
  try {
    const { routeId } = req.params;

    // Get route info
    const routeResult = await db.query(
      `
      SELECT 
        r.*,
        v.plate as vehicle_plate,
        v.type as vehicle_type,
        d1.name as depot_name,
        d2.name as dump_name
      FROM routes r
      LEFT JOIN vehicles v ON r.vehicle_id = v.id
      LEFT JOIN depots d1 ON r.depot_id = d1.id
      LEFT JOIN dumps d2 ON r.dump_id = d2.id
      WHERE r.id = $1
    `,
      [routeId]
    );

    if (routeResult.rows.length === 0) {
      return res.status(404).json({ ok: false, error: "Route not found" });
    }

    const route = routeResult.rows[0];

    // Get route stops
    const stopsResult = await db.query(
      `
      SELECT 
        rs.*,
        p.name as point_name,
        p.address,
        p.waste_type,
        ST_Y(p.geom::geometry) as lat,
        ST_X(p.geom::geometry) as lon
      FROM route_stops rs
      JOIN points p ON rs.point_id = p.id
      WHERE rs.route_id = $1
      ORDER BY rs.stop_order
    `,
      [routeId]
    );

    route.stops = stopsResult.rows;

    res.json({ ok: true, data: route });
  } catch (error) {
    console.error("[Worker] Get route error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

/**
 * POST /api/worker/checkin
 * Worker check-in at a point (group checkin)
 */
app.post("/api/worker/checkin", async (req, res) => {
  try {
    const {
      group_id,
      route_id,
      route_stop_id,
      checked_by,
      point_id,
      waste_type,
      collected_weight_kg,
      quantity_bags,
      notes,
      photo_urls,
      lat,
      lon,
    } = req.body;

    const result = await db.query(
      `
      INSERT INTO group_checkins (
        group_id, route_id, route_stop_id, checked_by, 
        waste_type, collected_weight_kg, quantity_bags,
        notes, photo_urls, geom
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, ST_GeogFromText($10))
      RETURNING *
    `,
      [
        group_id,
        route_id,
        route_stop_id,
        checked_by,
        waste_type,
        collected_weight_kg || 0,
        quantity_bags || 0,
        notes,
        photo_urls || [],
        lat && lon ? `POINT(${lon} ${lat})` : null,
      ]
    );

    // Update route stop status if provided
    if (route_stop_id) {
      await db.query(
        `
        UPDATE route_stops 
        SET status = 'completed', 
            completed_at = NOW(),
            actual_weight_kg = $1
        WHERE id = $2
      `,
        [collected_weight_kg, route_stop_id]
      );
    }

    // Emit real-time update via Socket.IO
    io.emit("checkin:created", result.rows[0]);

    res.json({
      ok: true,
      data: result.rows[0],
      message: "Check-in recorded successfully",
    });
  } catch (error) {
    console.error("[Worker] Check-in error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

/**
 * GET /api/worker/checkins/:groupId
 * Get check-in history for a group
 */
app.get("/api/worker/checkins/:groupId", async (req, res) => {
  try {
    const { groupId } = req.params;
    const { date, limit = 50 } = req.query;

    let query = `
      SELECT 
        gc.*,
        p.name as personnel_name,
        ST_Y(gc.geom::geometry) as lat,
        ST_X(gc.geom::geometry) as lon
      FROM group_checkins gc
      JOIN personnel p ON gc.checked_by = p.id
      WHERE gc.group_id = $1
    `;

    const params = [groupId];

    if (date) {
      query += ` AND DATE(gc.checked_at) = $2`;
      params.push(date);
    }

    query += ` ORDER BY gc.checked_at DESC LIMIT $${params.length + 1}`;
    params.push(limit);

    const result = await db.query(query, params);

    res.json({ ok: true, data: result.rows });
  } catch (error) {
    console.error("[Worker] Get checkins error:", error);
    res.status(500).json({ ok: false, error: error.message });
  }
});

/**
 * GET /api/worker/stats/:personnelId
 * Get worker statistics
 */
app.get("/api/worker/stats/:personnelId", async (req, res) => {
  try {
    const { personnelId } = req.params;
    const { period = "30" } = req.query; // days

    const stats = await db.query(
      `
      SELECT 
        COUNT(DISTINCT gc.id) as total_checkins,
        COALESCE(SUM(gc.collected_weight_kg), 0) as total_weight_kg,
        COALESCE(SUM(gc.quantity_bags), 0) as total_bags,
        COUNT(DISTINCT DATE(gc.checked_at)) as days_worked,
        COUNT(DISTINCT gc.route_id) as routes_completed
      FROM group_checkins gc
      JOIN group_members gm ON gc.group_id = gm.group_id
      WHERE gm.personnel_id = $1
        AND gm.status = 'active'
        AND gc.checked_at >= NOW() - INTERVAL '${period} days'
    `,
      [personnelId]
    );

    res.json({ ok: true, data: stats.rows[0] });
  } catch (error) {
    console.error("[Worker] Get stats error:", error);
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
server.listen(PORT, "0.0.0.0", () => {
  console.log(`🚀 EcoCheck Backend started on port ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV || "development"}`);
});

// Handle EADDRINUSE error gracefully
server.on("error", (err) => {
  if (err.code === "EADDRINUSE") {
    console.error(
      `❌ Port ${PORT} is already in use. Please wait a few seconds and try again.`
    );
    console.error(
      `   Or kill the process using: netstat -ano | findstr :${PORT}`
    );
    process.exit(1);
  } else {
    throw err;
  }
});

module.exports = app;
