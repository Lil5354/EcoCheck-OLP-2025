/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * POI Service - OpenStreetMap Overpass API Integration
 * Provides Points of Interest (POI) data for route optimization
 */

const axios = require('axios');

// OpenStreetMap Overpass API configuration
const OVERPASS_API_URL = 'https://overpass-api.de/api/interpreter';
const CACHE_DURATION = 60 * 60 * 1000; // 1 hour (POI data changes slowly)

// Rate limiting configuration
const RATE_LIMIT_DELAY = 2000; // 2 seconds between requests (Overpass API recommends 1-2s)
const MAX_RETRIES = 3;
const RETRY_DELAY = 5000; // 5 seconds initial retry delay

// In-memory cache for POI data
const poiCache = new Map();

// Request queue for rate limiting
let lastRequestTime = 0;
let requestQueue = [];
let isProcessingQueue = false;

/**
 * Get cache key for coordinates and type
 */
function getCacheKey(lat, lon, type, radius) {
  return `${lat.toFixed(4)},${lon.toFixed(4)},${type},${radius}`;
}

/**
 * Calculate distance between two points (Haversine)
 */
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371e3; // Earth radius in meters
  const φ1 = lat1 * Math.PI / 180;
  const φ2 = lat2 * Math.PI / 180;
  const Δφ = (lat2 - lat1) * Math.PI / 180;
  const Δλ = (lon2 - lon1) * Math.PI / 180;

  const a = Math.sin(Δφ/2) * Math.sin(Δφ/2) +
          Math.cos(φ1) * Math.cos(φ2) *
          Math.sin(Δλ/2) * Math.sin(Δλ/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));

  return R * c; // Distance in meters
}

/**
 * Rate-limited request to Overpass API
 * @param {string} query - Overpass query string
 * @param {number} retries - Number of retries remaining
 * @returns {Promise<Object>} API response
 */
async function makeOverpassRequest(query, retries = MAX_RETRIES) {
  // Rate limiting: wait if last request was too recent
  const now = Date.now();
  const timeSinceLastRequest = now - lastRequestTime;
  if (timeSinceLastRequest < RATE_LIMIT_DELAY) {
    await new Promise(resolve => setTimeout(resolve, RATE_LIMIT_DELAY - timeSinceLastRequest));
  }

  try {
    lastRequestTime = Date.now();
    
    const response = await axios.post(OVERPASS_API_URL, query, {
      headers: {
        'Content-Type': 'text/plain',
        'User-Agent': 'EcoCheck-OLP/1.0' // Identify our app
      },
      timeout: 30000 // 30 seconds timeout
    });

    return response.data;
  } catch (error) {
    // Handle rate limiting (429) and timeout (504)
    if ((error.response?.status === 429 || error.response?.status === 504) && retries > 0) {
      const delay = RETRY_DELAY * (MAX_RETRIES - retries + 1); // Exponential backoff
      console.warn(`[POI] Rate limited (${error.response?.status}), retrying in ${delay}ms... (${retries} retries left)`);
      await new Promise(resolve => setTimeout(resolve, delay));
      return makeOverpassRequest(query, retries - 1);
    }
    
    // For other errors or no retries left, throw
    throw error;
  }
}

/**
 * Get nearby POIs from OpenStreetMap Overpass API
 * @param {number} lat - Latitude
 * @param {number} lon - Longitude
 * @param {number} radius - Search radius in meters (default: 500)
 * @param {string} type - POI type: gas_station, restaurant, hospital, school, parking, etc.
 * @returns {Promise<Array>} Array of POI objects
 */
async function getNearbyPOI(lat, lon, radius = 500, type = 'gas_station') {
  const cacheKey = getCacheKey(lat, lon, type, radius);
  const cached = poiCache.get(cacheKey);
  
  // Return cached data if still valid
  if (cached && Date.now() - cached.timestamp < CACHE_DURATION) {
    return cached.data;
  }

  try {
    // Overpass API query
    // Query both nodes and ways with the specified amenity type
    // For gas_station, also search for "fuel" tag
    let queryConditions = '';
    if (type === 'gas_station') {
      queryConditions = `
        node["amenity"~"^(gas_station|fuel)$"](around:${radius},${lat},${lon});
        way["amenity"~"^(gas_station|fuel)$"](around:${radius},${lat},${lon});
        relation["amenity"~"^(gas_station|fuel)$"](around:${radius},${lat},${lon});
        node["amenity"="fuel"](around:${radius},${lat},${lon});
        way["amenity"="fuel"](around:${radius},${lat},${lon});
        relation["amenity"="fuel"](around:${radius},${lat},${lon});
      `;
    } else {
      queryConditions = `
        node["amenity"="${type}"](around:${radius},${lat},${lon});
        way["amenity"="${type}"](around:${radius},${lat},${lon});
        relation["amenity"="${type}"](around:${radius},${lat},${lon});
      `;
    }
    
    const query = `
      [out:json][timeout:25];
      (
        ${queryConditions}
      );
      out center;
    `;

    const data = await makeOverpassRequest(query);

    if (!data || !data.elements) {
      console.warn('[POI] Invalid response from Overpass API');
      return [];
    }

    const pois = data.elements
      .map(element => {
        // Get coordinates
        let poiLat, poiLon;
        if (element.type === 'node') {
          poiLat = element.lat;
          poiLon = element.lon;
        } else if (element.center) {
          poiLat = element.center.lat;
          poiLon = element.center.lon;
        } else {
          return null; // Skip if no coordinates
        }

        // Calculate distance
        const distance = calculateDistance(lat, lon, poiLat, poiLon);

        return {
          id: `${element.type}_${element.id}`,
          osmId: element.id,
          osmType: element.type,
          name: element.tags?.name || element.tags?.['name:vi'] || 'Unnamed',
          type: element.tags?.amenity || type,
          category: element.tags?.amenity,
          lat: poiLat,
          lon: poiLon,
          distance: Math.round(distance), // meters
          tags: element.tags || {},
          address: element.tags?.['addr:full'] || element.tags?.['addr:street'] || null
        };
      })
      .filter(poi => poi !== null) // Remove null entries
      .sort((a, b) => a.distance - b.distance); // Sort by distance

    // Cache the result
    poiCache.set(cacheKey, {
      data: pois,
      timestamp: Date.now()
    });

    return pois;
  } catch (error) {
    console.error('[POI] Error fetching POI data:', error.message);
    // Return empty array on error (don't use mock data)
    return [];
  }
}

/**
 * Get multiple POI types for a location
 * @param {number} lat - Latitude
 * @param {number} lon - Longitude
 * @param {number} radius - Search radius in meters
 * @param {Array} types - Array of POI types to search
 * @returns {Promise<Object>} Object with POI arrays by type
 */
async function getMultiplePOITypes(lat, lon, radius = 500, types = ['gas_station', 'restaurant', 'parking']) {
  const results = {};
  
  // Fetch all types in parallel
  const promises = types.map(type => 
    getNearbyPOI(lat, lon, radius, type).then(pois => ({ type, pois }))
  );

  const resultsArray = await Promise.all(promises);
  
  resultsArray.forEach(({ type, pois }) => {
    results[type] = pois;
  });

  return results;
}

/**
 * Get POIs along a route (optimized batch query)
 * @param {Array} points - Array of {lat, lon} objects
 * @param {string} type - POI type
 * @param {number} radius - Search radius for each point
 * @returns {Promise<Array>} Array of POIs near the route
 */
async function getPOIsAlongRoute(points, type = 'gas_station', radius = 300) {
  if (!points || points.length === 0) {
    return [];
  }

  // Strategy: Use a single batch query instead of multiple individual queries
  // This reduces API calls significantly
  
  try {
    // Create a bounding box that covers all points
    const lats = points.map(p => p.lat);
    const lons = points.map(p => p.lon);
    const minLat = Math.min(...lats);
    const maxLat = Math.max(...lats);
    const minLon = Math.min(...lons);
    const maxLon = Math.max(...lons);
    
    // Expand bounding box by radius (in degrees, approximate)
    const latExpansion = radius / 111000; // ~111km per degree
    const lonExpansion = radius / (111000 * Math.cos((minLat + maxLat) / 2 * Math.PI / 180));
    
    const bbox = [
      minLat - latExpansion,
      minLon - lonExpansion,
      maxLat + latExpansion,
      maxLon + lonExpansion
    ];

    // Single batch query for all POIs in the bounding box
    // For gas_station, also search for "fuel" tag
    let queryConditions = '';
    if (type === 'gas_station') {
      // Search for both amenity=gas_station and amenity=fuel
      queryConditions = `
        node["amenity"~"^(gas_station|fuel)$"](${bbox[0]},${bbox[1]},${bbox[2]},${bbox[3]});
        way["amenity"~"^(gas_station|fuel)$"](${bbox[0]},${bbox[1]},${bbox[2]},${bbox[3]});
        relation["amenity"~"^(gas_station|fuel)$"](${bbox[0]},${bbox[1]},${bbox[2]},${bbox[3]});
        node["amenity"="fuel"](${bbox[0]},${bbox[1]},${bbox[2]},${bbox[3]});
        way["amenity"="fuel"](${bbox[0]},${bbox[1]},${bbox[2]},${bbox[3]});
        relation["amenity"="fuel"](${bbox[0]},${bbox[1]},${bbox[2]},${bbox[3]});
      `;
    } else {
      queryConditions = `
        node["amenity"="${type}"](${bbox[0]},${bbox[1]},${bbox[2]},${bbox[3]});
        way["amenity"="${type}"](${bbox[0]},${bbox[1]},${bbox[2]},${bbox[3]});
        relation["amenity"="${type}"](${bbox[0]},${bbox[1]},${bbox[2]},${bbox[3]});
      `;
    }
    
    const query = `
      [out:json][timeout:25];
      (
        ${queryConditions}
      );
      out center;
    `;

    const data = await makeOverpassRequest(query);

    if (!data || !data.elements) {
      return [];
    }

    // Filter POIs that are within radius of any route point
    const allPois = data.elements
      .map(element => {
        let poiLat, poiLon;
        if (element.type === 'node') {
          poiLat = element.lat;
          poiLon = element.lon;
        } else if (element.center) {
          poiLat = element.center.lat;
          poiLon = element.center.lon;
        } else {
          return null;
        }

        // Find minimum distance to any route point
        let minDistance = Infinity;
        let nearestPoint = null;
        for (const point of points) {
          const distance = calculateDistance(point.lat, point.lon, poiLat, poiLon);
          if (distance < minDistance) {
            minDistance = distance;
            nearestPoint = point;
          }
        }

        // Only include if within radius
        if (minDistance > radius) {
          return null;
        }

        return {
          id: `${element.type}_${element.id}`,
          osmId: element.id,
          osmType: element.type,
          name: element.tags?.name || element.tags?.['name:vi'] || 'Unnamed',
          type: element.tags?.amenity || type,
          category: element.tags?.amenity,
          lat: poiLat,
          lon: poiLon,
          distance: Math.round(minDistance),
          tags: element.tags || {},
          address: element.tags?.['addr:full'] || element.tags?.['addr:street'] || null
        };
      })
      .filter(poi => poi !== null);

    // Deduplicate by ID
    const uniquePois = new Map();
    allPois.forEach(poi => {
      if (!uniquePois.has(poi.id)) {
        uniquePois.set(poi.id, poi);
      }
    });

    return Array.from(uniquePois.values()).sort((a, b) => a.distance - b.distance);
  } catch (error) {
    console.error('[POI] Error fetching POIs along route:', error.message);
    return [];
  }
}

/**
 * Clear POI cache
 */
function clearCache() {
  poiCache.clear();
}

module.exports = {
  getNearbyPOI,
  getMultiplePOITypes,
  getPOIsAlongRoute,
  clearCache
};

