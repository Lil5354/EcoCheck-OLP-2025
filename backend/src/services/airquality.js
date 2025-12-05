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
 * Get air quality data for a location with retry and progressive radius
 * Always tries to get data from OpenAQ, never uses mock data
 * @param {number} lat - Latitude
 * @param {number} lon - Longitude
 * @param {number} maxRadius - Maximum search radius in meters (default: 50000)
 * @returns {Promise<Object>} Air quality data
 */
async function getAirQuality(lat, lon, maxRadius = 50000) {
  const cacheKey = getCacheKey(lat, lon);
  const cached = aqiCache.get(cacheKey);
  
  // Return cached data if still valid
  if (cached && Date.now() - cached.timestamp < CACHE_DURATION) {
    return cached.data;
  }

  // Progressive radius search: 5km, 10km, 20km, 50km
  const radiusSteps = [5000, 10000, 20000, maxRadius];
  const maxRetries = 3;
  
  for (const radius of radiusSteps) {
    for (let attempt = 0; attempt < maxRetries; attempt++) {
      try {
        // OpenAQ API: Get latest measurements near location
        const url = `${OPENAQ_BASE_URL}/locations`;
        const response = await axios.get(url, {
          params: {
            coordinates: `${lat},${lon}`,
            radius: radius,
            limit: 10, // Tăng từ 1 lên 10 để tìm nhiều trạm
            order_by: 'distance'
          },
          timeout: 10000 // Tăng timeout từ 5000 lên 10000ms
        });

        if (response.data.results && response.data.results.length > 0) {
          // Thử tất cả locations để tìm location có dữ liệu PM2.5
          for (const location of response.data.results) {
            try {
              const measurementsUrl = `${OPENAQ_BASE_URL}/locations/${location.id}/latest`;
              const measurementsRes = await axios.get(measurementsUrl, { 
                timeout: 10000 
              });
              
              if (measurementsRes.data.results && measurementsRes.data.results.length > 0) {
                const latest = measurementsRes.data.results[0].measurements;
                const pm25 = latest.find(m => m.parameter === 'pm25')?.value;
                const pm10 = latest.find(m => m.parameter === 'pm10')?.value;
                
                if (pm25) {
                  const aqiData = calculateAQI(pm25);
                  aqiData.pm10 = pm10;
                  aqiData.location = location.name;
                  aqiData.distance = location.distance || 0;
                  
                  // Cache the result
                  aqiCache.set(cacheKey, {
                    data: aqiData,
                    timestamp: Date.now()
                  });
                  
                  console.log(`[AirQuality] Found data from OpenAQ at ${location.name} (${radius}m radius)`);
                  return aqiData;
                }
              }
            } catch (measurementError) {
              // Continue to next location
              continue;
            }
          }
        }
      } catch (error) {
        console.warn(`[AirQuality] Attempt ${attempt + 1} failed at radius ${radius}m:`, error.message);
        if (attempt < maxRetries - 1) {
          // Wait before retry (exponential backoff)
          await new Promise(resolve => setTimeout(resolve, 1000 * (attempt + 1)));
          continue;
        }
      }
    }
  }

  // If no data found after all attempts, throw error instead of using mock data
  console.error(`[AirQuality] No OpenAQ data found after all attempts for ${lat}, ${lon}`);
  throw new Error('Không thể lấy dữ liệu chất lượng không khí từ OpenAQ. Vui lòng thử lại sau.');
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


