/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * Weather Service - OpenWeatherMap API Integration
 * Provides weather forecast data for route optimization
 */

const axios = require('axios');

// OpenWeatherMap API configuration
const OPENWEATHER_API_KEY = process.env.OPENWEATHER_API_KEY || '';
const OPENWEATHER_BASE_URL = 'https://api.openweathermap.org/data/2.5';
const CACHE_DURATION = 30 * 60 * 1000; // 30 minutes

// In-memory cache for weather data
const weatherCache = new Map();

/**
 * Get cache key for coordinates
 */
function getCacheKey(lat, lon) {
  return `${lat.toFixed(2)},${lon.toFixed(2)}`;
}

/**
 * Get weather forecast for a location
 * @param {number} lat - Latitude
 * @param {number} lon - Longitude
 * @returns {Promise<Object>} Weather forecast data
 */
async function getForecast(lat, lon) {
  const cacheKey = getCacheKey(lat, lon);
  const cached = weatherCache.get(cacheKey);
  
  // Return cached data if still valid
  if (cached && Date.now() - cached.timestamp < CACHE_DURATION) {
    return cached.data;
  }

  try {
    if (!OPENWEATHER_API_KEY) {
      console.warn('[Weather] OpenWeatherMap API key not configured, returning mock data');
      return getMockForecast(lat, lon);
    }

    const url = `${OPENWEATHER_BASE_URL}/weather`;
    const response = await axios.get(url, {
      params: {
        lat,
        lon,
        appid: OPENWEATHER_API_KEY,
        units: 'metric',
        lang: 'vi'
      },
      timeout: 5000
    });

    const data = {
      temperature: response.data.main.temp,
      feelsLike: response.data.main.feels_like,
      humidity: response.data.main.humidity,
      pressure: response.data.main.pressure,
      weather: response.data.weather[0].main,
      description: response.data.weather[0].description,
      icon: response.data.weather[0].icon,
      windSpeed: response.data.wind?.speed || 0,
      windDirection: response.data.wind?.deg || 0,
      clouds: response.data.clouds?.all || 0,
      visibility: response.data.visibility || 10000,
      rain: response.data.rain?.['1h'] || 0,
      snow: response.data.snow?.['1h'] || 0,
      timestamp: new Date().toISOString()
    };

    // Cache the result
    weatherCache.set(cacheKey, {
      data,
      timestamp: Date.now()
    });

    return data;
  } catch (error) {
    console.error('[Weather] Error fetching forecast:', error.message);
    // Return mock data on error
    return getMockForecast(lat, lon);
  }
}

/**
 * Get weather data for multiple points (batch)
 * @param {Array} points - Array of {lat, lon} objects
 * @returns {Promise<Array>} Array of weather data for each point
 */
async function getWeatherForRoute(points) {
  if (!points || points.length === 0) {
    return [];
  }

  // Fetch weather for all points in parallel (with rate limiting)
  const weatherPromises = points.map((point, index) => {
    // Add small delay to avoid rate limiting
    return new Promise(resolve => {
      setTimeout(async () => {
        const weather = await getForecast(point.lat, point.lon);
        resolve({
          ...point,
          weather,
          weatherScore: calculateWeatherScore(weather)
        });
      }, index * 100); // 100ms delay between requests
    });
  });

  return Promise.all(weatherPromises);
}

/**
 * Calculate weather score (0-1) for route optimization
 * Lower score = better weather conditions
 * @param {Object} weather - Weather data
 * @returns {number} Weather score (0-1)
 */
function calculateWeatherScore(weather) {
  if (!weather) return 0.5; // Default neutral score

  let score = 0;

  // Rain penalty (0-0.4)
  if (weather.rain > 0) {
    score += Math.min(weather.rain / 10, 0.4); // Max 0.4 for heavy rain
  }

  // Snow penalty (0-0.3)
  if (weather.snow > 0) {
    score += Math.min(weather.snow / 5, 0.3);
  }

  // Wind penalty (0-0.2)
  if (weather.windSpeed > 10) {
    score += Math.min((weather.windSpeed - 10) / 20, 0.2);
  }

  // Cloud cover penalty (0-0.1)
  if (weather.clouds > 70) {
    score += (weather.clouds - 70) / 300; // Max 0.1
  }

  return Math.min(score, 1); // Cap at 1.0
}

/**
 * Get mock weather data for testing (when API key is not available)
 */
function getMockForecast(lat, lon) {
  // Simulate weather based on location (HCMC typically hot and humid)
  const hour = new Date().getHours();
  const isRaining = Math.random() < 0.2; // 20% chance of rain
  
  return {
    temperature: 28 + Math.random() * 5, // 28-33°C
    feelsLike: 30 + Math.random() * 5,
    humidity: 70 + Math.random() * 20, // 70-90%
    pressure: 1010 + Math.random() * 10,
    weather: isRaining ? 'Rain' : 'Clear',
    description: isRaining ? 'Mưa nhẹ' : 'Trời quang',
    icon: isRaining ? '10d' : '01d',
    windSpeed: 5 + Math.random() * 10, // 5-15 km/h
    windDirection: Math.random() * 360,
    clouds: isRaining ? 80 + Math.random() * 20 : 20 + Math.random() * 30,
    visibility: 10000,
    rain: isRaining ? Math.random() * 5 : 0,
    snow: 0,
    timestamp: new Date().toISOString()
  };
}

/**
 * Clear weather cache
 */
function clearCache() {
  weatherCache.clear();
}

module.exports = {
  getForecast,
  getWeatherForRoute,
  calculateWeatherScore,
  clearCache
};


