#!/usr/bin/env node
/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * NGSI-LD Seed Data Loader
 * Loads all NGSI-LD entities from seeds directory into EcoCheck API
 */

const fs = require('fs');
const path = require('path');
const axios = require('axios');

const API_URL = process.env.API_URL || 'http://localhost:3000';
const NGSI_LD_ENDPOINT = `${API_URL}/ngsi-ld/v1/entities`;
const SEED_DIR = path.join(__dirname, '..', 'seeds', 'ngsi-ld', 'cn14');

// Color output
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

async function loadEntity(filePath) {
  const fileName = path.basename(filePath);
  try {
    const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    
    await axios.post(NGSI_LD_ENDPOINT, data, {
      headers: {
        'Content-Type': 'application/ld+json',
        'Accept': 'application/json'
      }
    });
    
    log(`✅ Loaded ${fileName}`, 'green');
    return { success: true, file: fileName };
  } catch (error) {
    if (error.response?.status === 409) {
      log(`⚠️  ${fileName} already exists, skipping`, 'yellow');
      return { success: true, file: fileName, skipped: true };
    }
    
    const errorMsg = error.response?.data?.detail || error.message;
    log(`❌ Failed to load ${fileName}: ${errorMsg}`, 'red');
    return { success: false, file: fileName, error: errorMsg };
  }
}

async function loadAllSeeds() {
  log('🚀 EcoCheck NGSI-LD Seed Data Loader', 'blue');
  log(`📂 Loading from: ${SEED_DIR}`, 'blue');
  log(`🌐 API endpoint: ${NGSI_LD_ENDPOINT}`, 'blue');
  log('');

  if (!fs.existsSync(SEED_DIR)) {
    log(`❌ Seed directory not found: ${SEED_DIR}`, 'red');
    process.exit(1);
  }

  const files = fs.readdirSync(SEED_DIR)
    .filter(f => f.endsWith('.jsonld'))
    .sort();

  if (files.length === 0) {
    log('⚠️  No .jsonld files found in seed directory', 'yellow');
    process.exit(0);
  }

  log(`📦 Found ${files.length} entity files\n`, 'blue');

  const results = [];
  
  // Load entities by type in order to respect relationships
  const entityOrder = [
    'depot',      // Load depots first (no dependencies)
    'dump',       // Load dumps (no dependencies)
    'vehicle',    // Vehicles depend on depots
    'worker',     // Workers depend on depots
    'wastepoint', // Points can be standalone
    'route',      // Routes depend on vehicles, depots, dumps
    'schedule',   // Schedules depend on vehicles, depots
    'alert',      // Alerts depend on points, routes
    'checkin'     // Check-ins depend on points
  ];

  for (const prefix of entityOrder) {
    const matchingFiles = files.filter(f => f.startsWith(prefix));
    
    if (matchingFiles.length > 0) {
      log(`\n📋 Loading ${prefix} entities (${matchingFiles.length} files)...`, 'blue');
      
      for (const file of matchingFiles) {
        const filePath = path.join(SEED_DIR, file);
        const result = await loadEntity(filePath);
        results.push(result);
        
        // Small delay to avoid overwhelming the API
        await new Promise(resolve => setTimeout(resolve, 100));
      }
    }
  }

  // Summary
  log('\n' + '='.repeat(60), 'blue');
  log('📊 Summary', 'blue');
  log('='.repeat(60), 'blue');
  
  const successful = results.filter(r => r.success && !r.skipped).length;
  const skipped = results.filter(r => r.skipped).length;
  const failed = results.filter(r => !r.success).length;
  
  log(`✅ Successfully loaded: ${successful}`, 'green');
  if (skipped > 0) {
    log(`⚠️  Skipped (already exists): ${skipped}`, 'yellow');
  }
  if (failed > 0) {
    log(`❌ Failed: ${failed}`, 'red');
    log('\nFailed files:', 'red');
    results.filter(r => !r.success).forEach(r => {
      log(`  - ${r.file}: ${r.error}`, 'red');
    });
  }
  
  log('');
  log(`🎉 Seed data loading completed!`, 'green');
  
  if (failed > 0) {
    process.exit(1);
  }
}

// Run the loader
loadAllSeeds().catch(error => {
  log(`\n❌ Unexpected error: ${error.message}`, 'red');
  console.error(error);
  process.exit(1);
});
