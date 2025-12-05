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
  const maxRetries = 3;
  
  // Prepare headers with API key
  const headers = {
    'X-API-Key': OPENAQ_API_KEY
  };
  
  // First, try using /v3/latest endpoint directly with coordinates
  // This is often more reliable than /v3/locations
  try {
    const latestUrl = `${OPENAQ_BASE_URL}/latest`;
    const latestParams = {
      coordinates: `${lat},${lon}`,
      radius: effectiveMaxRadius,
      limit: 50,
      parameter: 'pm25' // Filter for PM2.5
    };
    
    const latestResponse = await axios.get(latestUrl, {
      params: latestParams,
      headers: headers,
      timeout: 10000
    });
    
    const latestData = latestResponse.data.results || latestResponse.data.data || [];
    
    if (latestData.length > 0) {
      // Find the closest measurement with PM2.5
      for (const result of latestData) {
        if (result.measurements && result.measurements.length > 0) {
          const pm25Measurement = result.measurements.find(m => m.parameter === 'pm25');
          if (pm25Measurement) {
            const pm25 = pm25Measurement.value;
            const pm10Measurement = result.measurements.find(m => m.parameter === 'pm10');
            const pm10 = pm10Measurement?.value;
            
            const aqiData = calculateAQI(pm25);
            aqiData.pm10 = pm10;
            aqiData.location = result.location?.name || result.name || 'Unknown';
            aqiData.distance = result.distance || 0;
            aqiData.source = 'openaq';
            aqiData.stationId = result.location?.id || result.id;
            aqiData.lastUpdated = new Date().toISOString();
            
            // Cache the result
            aqiCache.set(cacheKey, {
              data: aqiData,
              timestamp: Date.now()
            });
            
            console.log(`[AirQuality] ✅ Found data from OpenAQ v3 /latest endpoint at ${aqiData.location}`);
            console.log(`  - PM2.5: ${pm25} μg/m³, AQI: ${aqiData.aqi}`);
            return aqiData;
          }
        }
      }
    }
  } catch (latestError) {
    // If /latest endpoint fails, continue with /locations endpoint
    console.warn(`[AirQuality] /latest endpoint failed, trying /locations:`, latestError.message);
  }
  
  // Fallback to /locations endpoint with progressive radius
  for (const radius of radiusSteps) {
    for (let attempt = 0; attempt < maxRetries; attempt++) {
      try {
        // OpenAQ API v3: Get latest measurements near location
        // Try different parameter formats for OpenAQ v3
        const url = `${OPENAQ_BASE_URL}/locations`;
        
        // OpenAQ v3 API: Try coordinates as string format "lat,lon"
        // If this fails with 422, it might need different format
        let params;
        
        // First attempt: coordinates as string (most common format)
        if (attempt === 0) {
          params = {
            coordinates: `${lat},${lon}`,
            radius: radius,
            limit: 10
          };
        } 
        // Second attempt: try with separate lat/lon parameters
        else if (attempt === 1) {
          params = {
            lat: lat,
            lon: lon,
            radius: radius,
            limit: 10
          };
        }
        // Third attempt: try coordinates as array format
        else {
          params = {
            coordinates: [lat, lon].join(','),
            radius: radius,
            limit: 10
          };
        }
        
        const response = await axios.get(url, {
          params: params,
          headers: headers,
          timeout: 10000
        });

        // OpenAQ v3 response structure: { results: [...], meta: {...} }
        const locations = response.data.results || response.data.data || [];
        
        if (locations.length > 0) {
          // Thử tất cả locations để tìm location có dữ liệu PM2.5
          for (const location of locations) {
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
              // Continue to next location
              console.warn(`[AirQuality] Failed to get measurements for location ${location.id}:`, measurementError.message);
              continue;
            }
          }
        }
      } catch (error) {
        const errorMsg = error.response?.data?.message || error.message;
        const statusCode = error.response?.status;
        const errorData = error.response?.data;
        
        // Log detailed error for debugging
        if (statusCode === 422) {
          console.warn(`[AirQuality] Attempt ${attempt + 1} failed at radius ${radius}m: Request failed with status code 422`);
          if (errorData) {
            console.warn(`[AirQuality] Error details:`, JSON.stringify(errorData, null, 2));
          }
          // Log the request parameters for debugging
          console.warn(`[AirQuality] Request params:`, JSON.stringify(params));
        } else if (statusCode === 401) {
          console.error(`[AirQuality] ❌ Unauthorized - Invalid API key. Please check OPENAQ_API_KEY.`);
          throw new Error('OpenAQ API key không hợp lệ. Vui lòng kiểm tra lại OPENAQ_API_KEY trong file .env');
        } else {
          console.warn(`[AirQuality] Attempt ${attempt + 1} failed at radius ${radius}m:`, errorMsg);
          if (errorData) {
            console.warn(`[AirQuality] Error response:`, JSON.stringify(errorData, null, 2).substring(0, 500));
          }
        }
        
        if (attempt < maxRetries - 1) {
          // Wait before retry (exponential backoff)
          await new Promise(resolve => setTimeout(resolve, 1000 * (attempt + 1)));
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


