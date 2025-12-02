/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * Smart Container Sensors Service - SOSA/SSN Ontology
 * Manages IoT sensors for waste containers
 */

const { Pool } = require('pg');

// Database connection for sensors service
const db = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://ecocheck_user:ecocheck_pass@localhost:5432/ecocheck'
});

/**
 * Get sensor data for a container
 * @param {string} containerId - Container/WasteContainer ID
 * @returns {Promise<Object>} Sensor data with current fill level
 */
async function getContainerLevel(containerId) {
  try {
    // Query sensor observations from database
    // Assuming we have a sensors table or observations table
    const query = `
      SELECT 
        s.id as sensor_id,
        s.container_id,
        s.sensor_type,
        o.observed_property,
        o.result_value,
        o.result_time,
        o.unit
      FROM sensors s
      LEFT JOIN LATERAL (
        SELECT 
          observed_property,
          result_value,
          result_time,
          unit
        FROM observations
        WHERE sensor_id = s.id
        ORDER BY result_time DESC
        LIMIT 1
      ) o ON true
      WHERE s.container_id = $1
      AND s.sensor_type = 'fill_level'
      ORDER BY o.result_time DESC NULLS LAST
      LIMIT 1
    `;

    const { rows } = await db.query(query, [containerId]);
    
    if (rows.length === 0) {
      // If no sensor exists, try to get data from points table (last_level)
      const pointQuery = `
        SELECT 
          id,
          last_level,
          last_checkin_at
        FROM points
        WHERE id::text = $1
        LIMIT 1
      `;
      const pointRows = await db.query(pointQuery, [containerId]);
      
      if (pointRows.rows.length > 0 && pointRows.rows[0].last_level !== null) {
        // Use data from points table
        return {
          containerId,
          fillLevel: parseFloat(pointRows.rows[0].last_level) * 100, // Convert 0-1 to 0-100%
          unit: 'percent',
          timestamp: pointRows.rows[0].last_checkin_at || new Date().toISOString(),
          sensorId: null,
          source: 'points_table'
        };
      }
      
      // No data available - return null values
      return {
        containerId,
        fillLevel: null,
        unit: 'percent',
        timestamp: new Date().toISOString(),
        sensorId: null,
        source: null
      };
    }

    const row = rows[0];
    return {
      containerId,
      sensorId: row.sensor_id,
      fillLevel: parseFloat(row.result_value) || 0,
      unit: row.unit || 'percent',
      timestamp: row.result_time || new Date().toISOString(),
      observedProperty: row.observed_property || 'fillLevel'
    };
  } catch (error) {
    console.error('[Sensors] Error getting container level:', error.message);
    // Return error response instead of mock data
    throw error;
  }
}

/**
 * Create observation from sensor
 * @param {string} sensorId - Sensor ID
 * @param {Object} observation - Observation data
 * @returns {Promise<Object>} Created observation
 */
async function createObservation(sensorId, observation) {
  try {
    const {
      observedProperty = 'fillLevel',
      resultValue,
      resultTime = new Date().toISOString(),
      unit = 'percent',
      featureOfInterest = null
    } = observation;

    // Insert observation into database
    const query = `
      INSERT INTO observations (
        sensor_id,
        observed_property,
        result_value,
        result_time,
        unit,
        feature_of_interest
      ) VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *
    `;

    const { rows } = await db.query(query, [
      sensorId,
      observedProperty,
      resultValue,
      resultTime,
      unit,
      featureOfInterest
    ]);

    return {
      id: rows[0].id,
      sensorId,
      observedProperty,
      resultValue: parseFloat(rows[0].result_value),
      resultTime: rows[0].result_time,
      unit: rows[0].unit
    };
  } catch (error) {
    console.error('[Sensors] Error creating observation:', error.message);
    throw error;
  }
}

/**
 * Get containers that need collection (fill level > threshold)
 * @param {number} threshold - Fill level threshold (default: 80)
 * @returns {Promise<Array>} List of containers needing collection
 */
async function getContainersNeedingCollection(threshold = 80) {
  try {
    const query = `
      SELECT DISTINCT ON (s.container_id)
        s.container_id,
        s.id as sensor_id,
        o.result_value as fill_level,
        o.result_time,
        ST_X(wc.geom::geometry) as lon,
        ST_Y(wc.geom::geometry) as lat,
        wc.last_level,
        wc.last_waste_type
      FROM sensors s
      LEFT JOIN LATERAL (
        SELECT result_value, result_time
        FROM observations
        WHERE sensor_id = s.id
        ORDER BY result_time DESC
        LIMIT 1
      ) o ON true
      LEFT JOIN points wc ON s.container_id = wc.id::text
      WHERE s.sensor_type = 'fill_level'
      AND o.result_value > $1
      ORDER BY s.container_id, o.result_time DESC
    `;

    const { rows } = await db.query(query, [threshold]);
    
    return rows.map(row => ({
      containerId: row.container_id,
      sensorId: row.sensor_id,
      fillLevel: parseFloat(row.fill_level) || 0,
      timestamp: row.result_time,
      name: `Container ${row.container_id.substring(0, 8)}`, // Generate name from ID
      lat: parseFloat(row.lat),
      lon: parseFloat(row.lon),
      lastLevel: row.last_level ? parseFloat(row.last_level) : null,
      lastWasteType: row.last_waste_type
    }));
  } catch (error) {
    console.error('[Sensors] Error getting containers needing collection:', error.message);
    // Return empty array on error (table might not exist yet)
    return [];
  }
}

/**
 * Get all sensors for a container
 * @param {string} containerId - Container ID
 * @returns {Promise<Array>} List of sensors
 */
async function getContainerSensors(containerId) {
  try {
    const query = `
      SELECT 
        id,
        container_id,
        sensor_type,
        name,
        unit,
        created_at
      FROM sensors
      WHERE container_id = $1
      ORDER BY created_at DESC
    `;

    const { rows } = await db.query(query, [containerId]);
    return rows;
  } catch (error) {
    console.error('[Sensors] Error getting container sensors:', error.message);
    return [];
  }
}

/**
 * Get observations for a sensor
 * @param {string} sensorId - Sensor ID
 * @param {number} limit - Number of observations to return
 * @returns {Promise<Array>} List of observations
 */
async function getSensorObservations(sensorId, limit = 100) {
  try {
    const query = `
      SELECT 
        id,
        sensor_id,
        observed_property,
        result_value,
        result_time,
        unit
      FROM observations
      WHERE sensor_id = $1
      ORDER BY result_time DESC
      LIMIT $2
    `;

    const { rows } = await db.query(query, [sensorId, limit]);
    return rows.map(row => ({
      id: row.id,
      sensorId: row.sensor_id,
      observedProperty: row.observed_property,
      resultValue: parseFloat(row.result_value),
      resultTime: row.result_time,
      unit: row.unit
    }));
  } catch (error) {
    console.error('[Sensors] Error getting sensor observations:', error.message);
    return [];
  }
}

module.exports = {
  getContainerLevel,
  createObservation,
  getContainersNeedingCollection,
  getContainerSensors,
  getSensorObservations
};

