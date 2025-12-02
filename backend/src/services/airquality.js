/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * Air Quality Service - OpenAQ API Integration
 * Provides air quality data for health monitoring
 */

const axios = require('axios');

// OpenAQ API configuration
const OPENAQ_BASE_URL = 'https://api.openaq.org/v2';
const CACHE_DURATION = 60 * 60 * 1000; // 1 hour (AQI changes slowly)

// In-memory cache for air quality data
const aqiCache = new Map();

/**
 * Get cache key for coordinates
 */
function getCacheKey(lat, lon) {
  return `${lat.toFixed(2)},${lon.toFixed(2)}`;
}

/**
 * Calculate AQI from PM2.5 concentration
 * @param {number} pm25 - PM2.5 concentration (μg/m³)
 * @returns {Object} AQI data
 */
function calculateAQI(pm25) {
  // US EPA AQI calculation for PM2.5
  let aqi, category, color;
  
  if (pm25 <= 12) {
    aqi = Math.round((50 / 12) * pm25);
    category = 'Good';
    color = 'green';
  } else if (pm25 <= 35.4) {
    aqi = Math.round(((100 - 51) / (35.4 - 12)) * (pm25 - 12) + 51);
    category = 'Moderate';
    color = 'yellow';
  } else if (pm25 <= 55.4) {
    aqi = Math.round(((150 - 101) / (55.4 - 35.4)) * (pm25 - 35.4) + 101);
    category = 'Unhealthy for Sensitive Groups';
    color = 'orange';
  } else if (pm25 <= 150.4) {
    aqi = Math.round(((200 - 151) / (150.4 - 55.4)) * (pm25 - 55.4) + 151);
    category = 'Unhealthy';
    color = 'red';
  } else if (pm25 <= 250.4) {
    aqi = Math.round(((300 - 201) / (250.4 - 150.4)) * (pm25 - 150.4) + 201);
    category = 'Very Unhealthy';
    color = 'purple';
  } else {
    aqi = Math.round(((500 - 301) / (500 - 250.4)) * (pm25 - 250.4) + 301);
    category = 'Hazardous';
    color = 'maroon';
  }

  return { aqi, category, color, pm25 };
}

/**
 * Get air quality data for a location
 * @param {number} lat - Latitude
 * @param {number} lon - Longitude
 * @param {number} radius - Search radius in meters (default: 5000)
 * @returns {Promise<Object>} Air quality data
 */
async function getAirQuality(lat, lon, radius = 5000) {
  const cacheKey = getCacheKey(lat, lon);
  const cached = aqiCache.get(cacheKey);
  
  // Return cached data if still valid
  if (cached && Date.now() - cached.timestamp < CACHE_DURATION) {
    return cached.data;
  }

  try {
    // OpenAQ API: Get latest measurements near location
    const url = `${OPENAQ_BASE_URL}/locations`;
    const response = await axios.get(url, {
      params: {
        coordinates: `${lat},${lon}`,
        radius: radius,
        limit: 1,
        order_by: 'distance'
      },
      timeout: 5000
    });

    let aqiData;
    
    if (response.data.results && response.data.results.length > 0) {
      const location = response.data.results[0];
      
      // Get latest measurements
      const measurementsUrl = `${OPENAQ_BASE_URL}/locations/${location.id}/latest`;
      const measurementsRes = await axios.get(measurementsUrl, { timeout: 5000 });
      
      if (measurementsRes.data.results && measurementsRes.data.results.length > 0) {
        const latest = measurementsRes.data.results[0].measurements;
        const pm25 = latest.find(m => m.parameter === 'pm25')?.value;
        const pm10 = latest.find(m => m.parameter === 'pm10')?.value;
        
        if (pm25) {
          aqiData = calculateAQI(pm25);
          aqiData.pm10 = pm10;
          aqiData.location = location.name;
          aqiData.distance = location.distance || 0;
        }
      }
    }

    // If no data found, use mock data
    if (!aqiData) {
      aqiData = getMockAirQuality(lat, lon);
    }

    // Cache the result
    aqiCache.set(cacheKey, {
      data: aqiData,
      timestamp: Date.now()
    });

    return aqiData;
  } catch (error) {
    console.error('[AirQuality] Error fetching data:', error.message);
    // Return mock data on error
    return getMockAirQuality(lat, lon);
  }
}

/**
 * Get air quality for multiple points (batch)
 * @param {Array} points - Array of {lat, lon} objects
 * @returns {Promise<Array>} Array of air quality data
 */
async function getAirQualityForRoute(points) {
  if (!points || points.length === 0) {
    return [];
  }

  const aqiPromises = points.map((point, index) => {
    return new Promise(resolve => {
      setTimeout(async () => {
        const aqi = await getAirQuality(point.lat, point.lon);
        resolve({
          ...point,
          airQuality: aqi
        });
      }, index * 200); // 200ms delay to avoid rate limiting
    });
  });

  return Promise.all(aqiPromises);
}

/**
 * Get mock air quality data for testing
 */
function getMockAirQuality(lat, lon) {
  // HCMC typically has moderate to unhealthy air quality
  const pm25 = 30 + Math.random() * 40; // 30-70 μg/m³
  const aqiData = calculateAQI(pm25);
  
  return {
    ...aqiData,
    pm10: pm25 * 1.5,
    location: 'Hồ Chí Minh',
    distance: 0
  };
}

/**
 * Clear air quality cache
 */
function clearCache() {
  aqiCache.clear();
}

module.exports = {
  getAirQuality,
  getAirQualityForRoute,
  calculateAQI,
  clearCache
};


