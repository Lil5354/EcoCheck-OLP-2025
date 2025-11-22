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

app.get('/api/analytics/timeseries', (req, res) => {
  // Hourly series for 18:00-06:00
  const hours = [18,19,20,21,22,23,0,1,2,3,4,5,6];
  const series = hours.map(h => ({ hour: h, value: Math.round(40 + 30 * Math.sin((h/24)*Math.PI*2) + Math.random()*15) }));
  const byType = {
    household: Math.round(60 + Math.random()*20),
    recyclable: Math.round(25 + Math.random()*15),
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

    bulky: Math.round(8 + Math.random()*8)
  };
  res.json({ ok: true, hours, series, byType });
});

app.get('/api/analytics/summary', (req, res) => {
  res.json({ ok: true, routesActive: 12, collectionRate: 0.85, todayTons: 3.2 });
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
