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
const CACHE_DURATION = 60 * 60 * 1000; // 1 hour (AQI changes slowly)

// Get API key from environment variable
const OPENAQ_API_KEY = process.env.AIRQUALITY_API_KEY;

// Fixed OpenAQ station IDs for Ho Chi Minh City
// Using fixed stations instead of radius search because Vietnam has limited stations
const HCMC_FIXED_STATIONS = [
  { id: 7440, name: 'US Diplomatic Post: Ho Chi Minh City' },
  { id: 3276359, name: 'CMT8' }
];

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
/**
 * Get health recommendation based on AQI category
 * @param {string} category - AQI category
 * @returns {string} Health recommendation in Vietnamese
 */
function getHealthRecommendation(category) {
  // Normalize category to lowercase for comparison
  const normalizedCategory = (category || '').toLowerCase().trim();
  
  switch (normalizedCategory) {
    case 'good':
      return 'Chất lượng không khí tốt. Mọi người có thể hoạt động ngoài trời bình thường.';
    case 'moderate':
      return 'Chất lượng không khí ở mức chấp nhận được. Những người nhạy cảm nên hạn chế hoạt động ngoài trời.';
    case 'unhealthy for sensitive groups':
    case 'unhealthyforsensitivegroups':
      return 'Nhóm nhạy cảm (trẻ em, người già, người mắc bệnh hô hấp) nên hạn chế hoạt động ngoài trời. Người khỏe mạnh có thể hoạt động bình thường.';
    case 'unhealthy':
      return 'Mọi người nên hạn chế hoạt động ngoài trời. Nhóm nhạy cảm nên tránh hoàn toàn. Đeo khẩu trang khi ra ngoài.';
    case 'very unhealthy':
    case 'veryunhealthy':
      return 'CẢNH BÁO: Chất lượng không khí rất kém. Mọi người nên tránh hoạt động ngoài trời. Đóng cửa sổ và sử dụng máy lọc không khí.';
    case 'hazardous':
      return 'CẢNH BÁO NGUY HIỂM: Chất lượng không khí cực kỳ nguy hiểm. Ở trong nhà, đóng tất cả cửa sổ. Chỉ ra ngoài khi thực sự cần thiết và đeo khẩu trang N95.';
    default:
      // Default recommendation for any unknown category
      return 'Chất lượng không khí ở mức chấp nhận được. Những người nhạy cảm nên hạn chế hoạt động ngoài trời.';
  }
}

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

  const healthRecommendation = getHealthRecommendation(category);

  return { aqi, category, color, pm25, healthRecommendation };
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

  // Check if API key is available
  if (!OPENAQ_API_KEY) {
    console.warn('[AirQuality] ⚠️ No OpenAQ API key found. Please set AIRQUALITY_API_KEY in .env file.');
    return getMockAirQuality(lat, lon);
  }

  try {
    // Use fixed stations for HCMC instead of radius search
    // Vietnam has limited OpenAQ stations, so using fixed stations is more reliable
    let aqiData;
    
    // Try each fixed station until we find valid PM2.5 data
    for (const station of HCMC_FIXED_STATIONS) {
      try {
        // Get latest measurements for this fixed station
        const measurementsUrl = `${OPENAQ_BASE_URL}/locations/${station.id}/latest`;
        const measurementsRes = await axios.get(measurementsUrl, {
          headers: {
            'X-API-Key': OPENAQ_API_KEY
          },
          timeout: 5000
        });
        
        // OpenAQ v3 response structure: { results: [{ value, datetime, sensorsId, locationsId, ... }] }
        // Each result is a single measurement, not grouped by parameter
        if (measurementsRes.data && measurementsRes.data.results && measurementsRes.data.results.length > 0) {
          // Get location info to find which sensors measure PM2.5 and PM10
          const locationUrl = `${OPENAQ_BASE_URL}/locations/${station.id}`;
          const locationRes = await axios.get(locationUrl, {
            headers: {
              'X-API-Key': OPENAQ_API_KEY
            },
            timeout: 5000
          });
          
          const location = locationRes.data?.results?.[0];
          if (!location || !location.sensors) continue;
          
          // Find PM2.5 and PM10 sensor IDs
          const pm25Sensor = location.sensors.find(s => s.parameter?.name === 'pm25');
          const pm10Sensor = location.sensors.find(s => s.parameter?.name === 'pm10');
          
          if (!pm25Sensor) continue;
          
          // Find PM2.5 measurement value from results
          const pm25Measurement = measurementsRes.data.results.find(m => m.sensorsId === pm25Sensor.id);
          const pm10Measurement = pm10Sensor ? measurementsRes.data.results.find(m => m.sensorsId === pm10Sensor.id) : null;
          
          // Check if PM2.5 value is valid (not null, not undefined, and not invalid marker like -999)
          if (pm25Measurement && 
              pm25Measurement.value !== null && 
              pm25Measurement.value !== undefined &&
              pm25Measurement.value > 0 && // Valid PM2.5 should be positive
              pm25Measurement.value < 1000) { // Sanity check: PM2.5 shouldn't exceed 1000
            const pm25 = pm25Measurement.value;
            const pm10 = (pm10Measurement && pm10Measurement.value > 0 && pm10Measurement.value < 1000) 
              ? pm10Measurement.value 
              : null;
            
            aqiData = calculateAQI(pm25);
            aqiData.pm10 = pm10 || pm25 * 1.5; // Fallback to estimated PM10 if not available
            aqiData.location = station.name;
            aqiData.distance = 0; // Fixed station, no distance calculation
            aqiData.lastUpdated = pm25Measurement.datetime?.local || pm25Measurement.datetime?.utc || new Date().toISOString();
            aqiData.source = 'OpenAQ'; // Mark as real data from OpenAQ
            aqiData.stationId = station.id;
            // healthRecommendation is already included in calculateAQI result
            // Add health recommendation if not already present
            if (!aqiData.healthRecommendation) {
              aqiData.healthRecommendation = getHealthRecommendation(aqiData.category);
            }
            
            console.log(`[AirQuality] ✅ Found data from OpenAQ station ${station.id} (${station.name}): PM2.5: ${pm25.toFixed(1)} μg/m³`);
            break; // Use the first station with valid PM2.5 data
          } else if (pm25Measurement) {
            console.warn(`[AirQuality] ⚠️ Station ${station.id} has invalid PM2.5 value: ${pm25Measurement.value}`);
          }
        }
      } catch (err) {
        // Skip this station if we can't get measurements
        console.warn(`[AirQuality] ⚠️ Could not get data from station ${station.id}: ${err.message}`);
        continue;
      }
    }

    // If no data found from fixed stations, use mock data
    if (!aqiData) {
      console.warn(`[AirQuality] ⚠️ No OpenAQ data found from fixed stations. Using mock data.`);
      aqiData = getMockAirQuality(lat, lon);
      aqiData.source = 'Mock'; // Mark as mock data
    }
    
    // Ensure healthRecommendation is always present
    if (!aqiData.healthRecommendation || aqiData.healthRecommendation.trim() === '') {
      aqiData.healthRecommendation = getHealthRecommendation(aqiData.category);
      console.log(`[AirQuality] ✅ Added healthRecommendation: ${aqiData.healthRecommendation.substring(0, 50)}...`);
    }

    // Cache the result
    aqiCache.set(cacheKey, {
      data: aqiData,
      timestamp: Date.now()
    });

    return aqiData;
  } catch (error) {
    // Handle specific error cases
    if (error.response) {
      if (error.response.status === 401 || error.response.status === 403) {
        console.error('[AirQuality] ❌ API Key authentication failed. Please check your API key.');
      } else if (error.response.status === 429) {
        console.error('[AirQuality] ⚠️ Rate limit exceeded. Using cached or mock data.');
      } else {
        console.error(`[AirQuality] ❌ API Error (${error.response.status}):`, error.response.data || error.message);
      }
    } else {
      console.error('[AirQuality] ❌ Error fetching data:', error.message);
    }
    // Return mock data on error
    const mockData = getMockAirQuality(lat, lon);
    // Ensure healthRecommendation is present
    if (!mockData.healthRecommendation || mockData.healthRecommendation.trim() === '') {
      mockData.healthRecommendation = getHealthRecommendation(mockData.category);
    }
    return mockData;
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
    distance: 0,
    source: 'Mock', // Mark as mock data
    healthRecommendation: aqiData.healthRecommendation || getHealthRecommendation(aqiData.category)
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


