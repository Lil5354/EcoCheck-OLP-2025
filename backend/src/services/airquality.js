/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * Air Quality Service - OpenAQ API Integration
 * Provides air quality data for health monitoring
 */

const axios = require('axios');

// OpenAQ API configuration
const OPENAQ_BASE_URL = 'https://api.openaq.org/v3';
const OPENAQ_API_KEY = process.env.OPENAQ_API_KEY || process.env.AIRQUALITY_API_KEY || '';
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
async function getAirQuality(lat, lon, maxRadius = 25000) {
  // Check if API key is configured
  if (!OPENAQ_API_KEY) {
    console.error('[AirQuality] OpenAQ API key not configured. Please set OPENAQ_API_KEY or AIRQUALITY_API_KEY in environment variables.');
    throw new Error('OpenAQ API key chưa được cấu hình. Vui lòng thêm OPENAQ_API_KEY vào file .env');
  }

  const cacheKey = getCacheKey(lat, lon);
  const cached = aqiCache.get(cacheKey);
  
  // Return cached data if still valid
  if (cached && Date.now() - cached.timestamp < CACHE_DURATION) {
    console.log(`[AirQuality] Using cached data for ${lat}, ${lon}`);
    return cached.data;
  }

  // Progressive radius search: 5km, 10km, 20km, 25km (OpenAQ v3 max is 25000m)
  // Limit maxRadius to 25000m for OpenAQ v3 API
  const effectiveMaxRadius = Math.min(maxRadius, 25000);
  const radiusSteps = [5000, 10000, 20000, effectiveMaxRadius];
  const maxRetries = 2; // Reduced retries to avoid rate limiting
  
  // Prepare headers with API key
  const headers = {
    'X-API-Key': OPENAQ_API_KEY
  };
  
  // Rate limiting: Add delay between requests to avoid 429 errors
  const RATE_LIMIT_DELAY = 2000; // 2 seconds between requests
  
  // Use /locations endpoint with progressive radius
  for (const radius of radiusSteps) {
    // Add delay between different radius attempts to avoid rate limiting
    if (radius !== radiusSteps[0]) {
      await new Promise(resolve => setTimeout(resolve, RATE_LIMIT_DELAY));
    }
    
    for (let attempt = 0; attempt < maxRetries; attempt++) {
      // Add delay between retry attempts
      if (attempt > 0) {
        await new Promise(resolve => setTimeout(resolve, RATE_LIMIT_DELAY * (attempt + 1)));
      }
      
      try {
        // OpenAQ API v3: Get latest measurements near location
        const url = `${OPENAQ_BASE_URL}/locations`;
        
        // Use coordinates as string format "lat,lon" (standard OpenAQ v3 format)
        const params = {
          coordinates: `${lat},${lon}`,
          radius: radius,
          limit: 5 // Reduced limit to minimize requests
        };
        
        const response = await axios.get(url, {
          params: params,
          headers: headers,
          timeout: 10000
        });

        // OpenAQ v3 response structure: { results: [...], meta: {...} }
        const locations = response.data.results || response.data.data || [];
        
        if (locations.length > 0) {
          // Try locations one by one, but stop at first success to minimize requests
          for (let i = 0; i < Math.min(locations.length, 3); i++) {
            const location = locations[i];
            
            // Add delay between measurement requests to avoid rate limiting
            if (i > 0) {
              await new Promise(resolve => setTimeout(resolve, RATE_LIMIT_DELAY));
            }
            
            try {
              // OpenAQ v3: Get latest measurements for location
              const measurementsUrl = `${OPENAQ_BASE_URL}/locations/${location.id}/latest`;
              const measurementsRes = await axios.get(measurementsUrl, { 
                headers: headers,
                timeout: 10000 
              });
              
              // OpenAQ v3 response structure: { results: [...], meta: {...} }
              const measurementsData = measurementsRes.data.results || measurementsRes.data.data || [];
              
              if (measurementsData.length > 0) {
                const latest = measurementsData[0];
                // OpenAQ v3: measurements is an array of objects with parameter and value
                const measurements = latest.measurements || [];
                const pm25Measurement = measurements.find(m => m.parameter === 'pm25');
                const pm10Measurement = measurements.find(m => m.parameter === 'pm10');
                
                const pm25 = pm25Measurement?.value;
                const pm10 = pm10Measurement?.value;
                
                if (pm25) {
                  const aqiData = calculateAQI(pm25);
                  aqiData.pm10 = pm10;
                  aqiData.location = location.name || location.locationName || 'Unknown';
                  aqiData.distance = location.distance || 0;
                  aqiData.source = 'openaq';
                  aqiData.stationId = location.id;
                  aqiData.lastUpdated = new Date().toISOString();
                  
                  // Cache the result
                  aqiCache.set(cacheKey, {
                    data: aqiData,
                    timestamp: Date.now()
                  });
                  
                  console.log(`[AirQuality] ✅ Found data from OpenAQ v3 at ${aqiData.location} (${radius}m radius)`);
                  console.log(`  - PM2.5: ${pm25} μg/m³, AQI: ${aqiData.aqi}`);
                  return aqiData;
                }
              }
            } catch (measurementError) {
              const errorStatus = measurementError.response?.status;
              const errorMsg = measurementError.message;
              
              // Handle rate limiting (429) with longer backoff
              if (errorStatus === 429) {
                console.warn(`[AirQuality] Rate limited (429) for location ${location.id}, waiting longer...`);
                // Wait longer for rate limit (30-60 seconds)
                await new Promise(resolve => setTimeout(resolve, 30000 + Math.random() * 30000));
                // Skip this location and try next
                continue;
              }
              
              // For other errors, continue to next location
              console.warn(`[AirQuality] Failed to get measurements for location ${location.id}:`, errorMsg);
              continue;
            }
          }
        }
      } catch (error) {
        const errorMsg = error.response?.data?.message || error.response?.data?.detail || error.message;
        const statusCode = error.response?.status;
        const errorData = error.response?.data;
        
        // Handle rate limiting (429) with longer backoff
        if (statusCode === 429) {
          const waitTime = 30000 + Math.random() * 30000; // 30-60 seconds
          console.warn(`[AirQuality] Rate limited (429) at radius ${radius}m, waiting ${Math.round(waitTime/1000)}s...`);
          await new Promise(resolve => setTimeout(resolve, waitTime));
          
          if (attempt < maxRetries - 1) {
            continue; // Retry after waiting
          }
        } else if (statusCode === 422) {
          console.warn(`[AirQuality] Attempt ${attempt + 1} failed at radius ${radius}m: Request failed with status code 422`);
          if (errorData) {
            console.warn(`[AirQuality] Error details:`, JSON.stringify(errorData, null, 2));
          }
        } else if (statusCode === 401) {
          console.error(`[AirQuality] ❌ Unauthorized - Invalid API key. Please check OPENAQ_API_KEY.`);
          throw new Error('OpenAQ API key không hợp lệ. Vui lòng kiểm tra lại OPENAQ_API_KEY trong file .env');
        } else if (statusCode === 500) {
          console.warn(`[AirQuality] Attempt ${attempt + 1} failed at radius ${radius}m: Server error (500)`);
          // Wait longer for server errors
          if (attempt < maxRetries - 1) {
            await new Promise(resolve => setTimeout(resolve, 5000 * (attempt + 1)));
            continue;
          }
        } else {
          console.warn(`[AirQuality] Attempt ${attempt + 1} failed at radius ${radius}m:`, errorMsg);
        }
        
        if (attempt < maxRetries - 1 && statusCode !== 429) {
          // Wait before retry (exponential backoff)
          await new Promise(resolve => setTimeout(resolve, 2000 * (attempt + 1)));
          continue;
        }
      }
    }
  }

  // If no data found after all attempts, throw error instead of using mock data
  console.error(`[AirQuality] ❌ No OpenAQ data found after all attempts for ${lat}, ${lon}`);
  console.error(`  - Tried radius: ${radiusSteps.join(', ')}m`);
  console.error(`  - Total attempts: ${radiusSteps.length * maxRetries}`);
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


