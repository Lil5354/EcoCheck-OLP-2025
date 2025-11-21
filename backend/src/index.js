/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck Backend - FIWARE-based Environmental Monitoring System
 * Main application entry point
 */

const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const cron = require('node-cron');

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

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

// Start server
app.listen(PORT, () => {
  console.log(`🚀 EcoCheck Backend started on port ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
});

module.exports = app;
