/*
 * Test OpenAQ API v3 with API key
 */

const axios = require('axios');
require('dotenv').config();

const OPENAQ_BASE_URL = 'https://api.openaq.org/v3';
const OPENAQ_API_KEY = process.env.OPENAQ_API_KEY || process.env.AIRQUALITY_API_KEY || '';

async function testOpenAQV3WithKey() {
  console.log('🔍 Testing OpenAQ API v3 with API key...\n');

  if (!OPENAQ_API_KEY) {
    console.log('❌ OPENAQ_API_KEY not found in environment variables');
    console.log('Please set OPENAQ_API_KEY or AIRQUALITY_API_KEY in .env file');
    return;
  }

  console.log(`✅ API Key found: ${OPENAQ_API_KEY.substring(0, 10)}...\n`);

  const testLat = 10.78;
  const testLon = 106.70;

  const headers = {
    'X-API-Key': OPENAQ_API_KEY
  };

  // Test v3 API with coordinates
  console.log('Test 1: OpenAQ API v3 - /v3/locations with coordinates...');
  try {
    const response = await axios.get(`${OPENAQ_BASE_URL}/locations`, {
      params: {
        coordinates: `${testLat},${testLon}`,
        radius: 25000, // OpenAQ v3 max radius is 25000m
        limit: 10
      },
      headers: headers,
      timeout: 10000
    });
    console.log('✅ v3 API accessible');
    console.log('Status:', response.status);
    console.log('Response structure:', Object.keys(response.data));
    
    const locations = response.data.data || response.data.results || [];
    console.log('Results count:', locations.length);
    
    if (locations.length > 0) {
      const firstLoc = locations[0];
      console.log('\nFirst location:');
      console.log('  - ID:', firstLoc.id);
      console.log('  - Name:', firstLoc.name || firstLoc.locationName);
      console.log('  - Distance:', firstLoc.distance, 'm');
      console.log('  - Coordinates:', firstLoc.coordinates);
      
      // Try to get measurements
      console.log('\n  Getting latest measurements...');
      try {
        const measurementsRes = await axios.get(`${OPENAQ_BASE_URL}/locations/${firstLoc.id}/latest`, {
          headers: headers,
          timeout: 10000
        });
        console.log('  ✅ Measurements retrieved');
        
        const measurementsData = measurementsRes.data.data || measurementsRes.data.results || [];
        if (measurementsData.length > 0) {
          const latest = measurementsData[0];
          const measurements = latest.measurements || [];
          console.log('  Measurements count:', measurements.length);
          
          measurements.forEach(m => {
            console.log(`    - ${m.parameter}: ${m.value} ${m.unit || ''}`);
          });
          
          const pm25 = measurements.find(m => m.parameter === 'pm25');
          if (pm25) {
            console.log(`\n  ✅ PM2.5 found: ${pm25.value} ${pm25.unit || 'μg/m³'}`);
          } else {
            console.log('  ⚠️ No PM2.5 data in measurements');
          }
        }
      } catch (measurementError) {
        console.log('  ❌ Failed to get measurements:', measurementError.message);
        if (measurementError.response) {
          console.log('  Status:', measurementError.response.status);
          console.log('  Response:', JSON.stringify(measurementError.response.data, null, 2).substring(0, 500));
        }
      }
    } else {
      console.log('⚠️ No locations found');
    }
  } catch (error) {
    console.log('❌ v3 API failed:', error.message);
    if (error.response) {
      console.log('Status:', error.response.status);
      console.log('Response:', JSON.stringify(error.response.data, null, 2).substring(0, 500));
    }
  }
}

testOpenAQV3WithKey().catch(console.error);

