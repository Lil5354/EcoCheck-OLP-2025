/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * Distance Calculator Service
 * Uses PostGIS for accurate geographic distance calculations
 */

class DistanceCalculator {
  constructor(db) {
    this.db = db;
    this.cache = new Map(); // Cache for distance matrix
  }

  /**
   * Calculate distance between two points using PostGIS
   * @param {Object} point1 - {latitude, longitude}
   * @param {Object} point2 - {latitude, longitude}
   * @returns {Promise<number>} Distance in kilometers
   */
  async calculateDistance(point1, point2) {
    const cacheKey = `${point1.latitude},${point1.longitude}-${point2.latitude},${point2.longitude}`;
    if (this.cache.has(cacheKey)) {
      return this.cache.get(cacheKey);
    }

    try {
      const query = `
        SELECT ST_Distance(
          ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
          ST_SetSRID(ST_MakePoint($3, $4), 4326)::geography
        ) / 1000.0 as distance_km
      `;

      const result = await this.db.query(query, [
        point1.longitude,
        point1.latitude,
        point2.longitude,
        point2.latitude,
      ]);

      const distance = parseFloat(result.rows[0].distance_km);
      this.cache.set(cacheKey, distance);
      return distance;
    } catch (error) {
      console.error("[DistanceCalculator] Error calculating distance:", error);
      // Fallback to Haversine if PostGIS fails
      return this.haversineDistance(point1, point2);
    }
  }

  /**
   * Build distance matrix for multiple points
   * @param {Array} points - Array of {id, latitude, longitude}
   * @returns {Promise<Object>} Distance matrix {fromId: {toId: distance}}
   */
  async buildDistanceMatrix(points) {
    const matrix = {};
    const cacheKey = `matrix-${points.map(p => p.id).join('-')}`;

    // Initialize matrix
    for (const point1 of points) {
      matrix[point1.id] = {};
      for (const point2 of points) {
        if (point1.id === point2.id) {
          matrix[point1.id][point2.id] = 0;
        } else {
          matrix[point1.id][point2.id] = null; // Will be calculated
        }
      }
    }

    // Calculate distances pairwise using PostGIS
    try {
      for (let i = 0; i < points.length; i++) {
        for (let j = i + 1; j < points.length; j++) {
          const distance = await this.calculateDistance(
            { latitude: points[i].latitude, longitude: points[i].longitude },
            { latitude: points[j].latitude, longitude: points[j].longitude }
          );
          matrix[points[i].id][points[j].id] = distance;
          matrix[points[j].id][points[i].id] = distance; // Symmetric
        }
      }
    } catch (error) {
      console.error("[DistanceCalculator] Error building matrix:", error);
      // Fallback to Haversine
      for (let i = 0; i < points.length; i++) {
        for (let j = i + 1; j < points.length; j++) {
          const distance = this.haversineDistance(
            { latitude: points[i].latitude, longitude: points[i].longitude },
            { latitude: points[j].latitude, longitude: points[j].longitude }
          );
          matrix[points[i].id][points[j].id] = distance;
          matrix[points[j].id][points[i].id] = distance;
        }
      }
    }

    return matrix;
  }

  /**
   * Haversine distance calculation (fallback)
   * @param {Object} point1 - {latitude, longitude}
   * @param {Object} point2 - {latitude, longitude}
   * @returns {number} Distance in kilometers
   */
  haversineDistance(point1, point2) {
    const toRad = (x) => (x * Math.PI) / 180;
    const R = 6371; // Earth radius in km

    const dLat = toRad(point2.latitude - point1.latitude);
    const dLon = toRad(point2.longitude - point1.longitude);
    const lat1 = toRad(point1.latitude);
    const lat2 = toRad(point2.latitude);

    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.sin(dLon / 2) * Math.sin(dLon / 2) * Math.cos(lat1) * Math.cos(lat2);

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  /**
   * Clear cache
   */
  clearCache() {
    this.cache.clear();
  }
}

module.exports = DistanceCalculator;

