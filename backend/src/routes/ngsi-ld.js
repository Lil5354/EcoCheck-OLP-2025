/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck Backend - NGSI-LD API Routes
 * Implements NGSI-LD v1.6.1 specification
 */

const express = require('express');
const router = express.Router();
const { toNGSILD, fromNGSILD, validateNGSILD, CONTEXT_URL } = require('../ngsi-ld-adapter');

module.exports = (db) => {
  // ============================================================================
  // NGSI-LD Entities API
  // ============================================================================

  /**
   * GET /ngsi-ld/v1/entities
   * Query entities with NGSI-LD filters
   */
  router.get('/entities', async (req, res) => {
    try {
      const { 
        type, 
        id, 
        idPattern,
        attrs,
        q,
        georel,
        geometry,
        coordinates,
        geoproperty,
        limit = 20,
        offset = 0
      } = req.query;

      // Build SQL query based on NGSI-LD parameters
      let query = '';
      let params = [];
      let paramIndex = 1;
      const entities = [];

      // Determine entity type and table
      const entityTypes = type ? type.split(',') : [];
      
      // Query each entity type
      const tableMap = {
        'Vehicle': 'vehicles',
        'Worker': 'personnel',
        'Depot': 'depots',
        'Dump': 'dumps',
        'Route': 'routes',
        'WastePoint': 'points',
        'Alert': 'alerts',
        'CheckIn': 'checkins'
      };

      if (entityTypes.length === 0) {
        // Query all entity types if no type specified
        entityTypes.push(...Object.keys(tableMap));
      }

      for (const entityType of entityTypes) {
        const tableName = tableMap[entityType];
        if (!tableName) continue;

        query = `SELECT * FROM ${tableName} WHERE 1=1`;
        params = [];
        paramIndex = 1;

        // Filter by ID
        if (id) {
          const ids = id.split(',').map(i => i.replace(/^urn:ngsi-ld:\w+:/, ''));
          query += ` AND id = ANY($${paramIndex++})`;
          params.push(ids);
        }

        // Filter by ID pattern (regex)
        if (idPattern) {
          const pattern = idPattern.replace(/^urn:ngsi-ld:\w+:/, '');
          query += ` AND id ~ $${paramIndex++}`;
          params.push(pattern);
        }

        // Add geo-query if specified
        if (georel && geometry && coordinates) {
          const geoprop = geoproperty || 'location';
          // Parse coordinates based on geometry type
          if (geometry === 'Point') {
            const [lon, lat] = coordinates.split(',').map(parseFloat);
            const [relation, distance] = georel.split(';');
            
            if (relation === 'near' && distance) {
              const maxDist = parseInt(distance.replace('maxDistance==', ''));
              query += ` AND ST_DWithin(geom::geography, ST_SetSRID(ST_MakePoint($${paramIndex}, $${paramIndex + 1}), 4326)::geography, $${paramIndex + 2})`;
              params.push(lon, lat, maxDist);
              paramIndex += 3;
            }
          }
        }

        // Apply limit and offset
        query += ` ORDER BY created_at DESC LIMIT $${paramIndex++} OFFSET $${paramIndex++}`;
        params.push(parseInt(limit), parseInt(offset));

        // Execute query
        const { rows } = await db.query(query, params);

        // Convert to NGSI-LD format
        for (const row of rows) {
          // Add lat/lon from PostGIS geometry if available
          if (row.geom) {
            const geoQuery = await db.query(
              'SELECT ST_X($1::geometry) as lon, ST_Y($1::geometry) as lat',
              [row.geom]
            );
            if (geoQuery.rows.length > 0) {
              row.lon = geoQuery.rows[0].lon;
              row.lat = geoQuery.rows[0].lat;
            }
          }

          const entity = toNGSILD(entityType, row, { includeContext: false });
          entities.push(entity);
        }
      }

      // Set Link header with context
      res.setHeader('Link', `<${CONTEXT_URL}>; rel="http://www.w3.org/ns/json-ld#context"; type="application/ld+json"`);
      res.json(entities);
    } catch (error) {
      console.error('[NGSI-LD] Query entities error:', error);
      res.status(500).json({
        type: 'https://uri.etsi.org/ngsi-ld/errors/InternalError',
        title: 'Internal Server Error',
        detail: error.message
      });
    }
  });

  /**
   * GET /ngsi-ld/v1/entities/:id
   * Retrieve specific entity by ID
   */
  router.get('/entities/:id', async (req, res) => {
    try {
      const entityId = req.params.id;
      const { attrs } = req.query;

      // Extract entity type and ID from URN
      const match = entityId.match(/^urn:ngsi-ld:(\w+):(.+)$/);
      if (!match) {
        return res.status(400).json({
          type: 'https://uri.etsi.org/ngsi-ld/errors/BadRequestData',
          title: 'Invalid Entity ID',
          detail: 'Entity ID must be in format: urn:ngsi-ld:EntityType:id'
        });
      }

      const [, entityType, id] = match;
      
      // Map entity type to table
      const tableMap = {
        'Vehicle': 'vehicles',
        'Worker': 'personnel',
        'Depot': 'depots',
        'Dump': 'dumps',
        'Route': 'routes',
        'WastePoint': 'points',
        'Alert': 'alerts',
        'CheckIn': 'checkins'
      };

      const tableName = tableMap[entityType];
      if (!tableName) {
        return res.status(404).json({
          type: 'https://uri.etsi.org/ngsi-ld/errors/ResourceNotFound',
          title: 'Entity Not Found',
          detail: `Unknown entity type: ${entityType}`
        });
      }

      // Query database
      const { rows } = await db.query(`SELECT * FROM ${tableName} WHERE id = $1`, [id]);
      
      if (rows.length === 0) {
        return res.status(404).json({
          type: 'https://uri.etsi.org/ngsi-ld/errors/ResourceNotFound',
          title: 'Entity Not Found',
          detail: `Entity with id ${entityId} not found`
        });
      }

      const row = rows[0];

      // Add lat/lon from PostGIS geometry
      if (row.geom) {
        const geoQuery = await db.query(
          'SELECT ST_X($1::geometry) as lon, ST_Y($1::geometry) as lat',
          [row.geom]
        );
        if (geoQuery.rows.length > 0) {
          row.lon = geoQuery.rows[0].lon;
          row.lat = geoQuery.rows[0].lat;
        }
      }

      // Convert to NGSI-LD
      const entity = toNGSILD(entityType, row, { includeContext: false });

      // Filter attributes if specified
      if (attrs) {
        const attrList = attrs.split(',');
        const filtered = { id: entity.id, type: entity.type };
        for (const attr of attrList) {
          if (entity[attr]) {
            filtered[attr] = entity[attr];
          }
        }
        res.setHeader('Link', `<${CONTEXT_URL}>; rel="http://www.w3.org/ns/json-ld#context"; type="application/ld+json"`);
        return res.json(filtered);
      }

      res.setHeader('Link', `<${CONTEXT_URL}>; rel="http://www.w3.org/ns/json-ld#context"; type="application/ld+json"`);
      res.json(entity);
    } catch (error) {
      console.error('[NGSI-LD] Get entity error:', error);
      res.status(500).json({
        type: 'https://uri.etsi.org/ngsi-ld/errors/InternalError',
        title: 'Internal Server Error',
        detail: error.message
      });
    }
  });

  /**
   * POST /ngsi-ld/v1/entities
   * Create new entity
   */
  router.post('/entities', async (req, res) => {
    try {
      const entity = req.body;

      // Validate NGSI-LD format
      const validation = validateNGSILD(entity);
      if (!validation.valid) {
        return res.status(400).json({
          type: 'https://uri.etsi.org/ngsi-ld/errors/BadRequestData',
          title: 'Invalid NGSI-LD Entity',
          detail: validation.errors.join(', ')
        });
      }

      // Extract entity type and ID
      const match = entity.id.match(/^urn:ngsi-ld:(\w+):(.+)$/);
      if (!match) {
        return res.status(400).json({
          type: 'https://uri.etsi.org/ngsi-ld/errors/BadRequestData',
          title: 'Invalid Entity ID',
          detail: 'Entity ID must be in format: urn:ngsi-ld:EntityType:id'
        });
      }

      const [, entityType, id] = match;

      // Convert from NGSI-LD to database format
      const data = fromNGSILD(entity);
      data.id = id;

      // Map entity type to table and insert
      const tableMap = {
        'Vehicle': 'vehicles',
        'Worker': 'personnel',
        'Depot': 'depots',
        'Dump': 'dumps',
        'Route': 'routes',
        'WastePoint': 'points',
        'Alert': 'alerts',
        'CheckIn': 'checkins'
      };

      const tableName = tableMap[entityType];
      if (!tableName) {
        return res.status(400).json({
          type: 'https://uri.etsi.org/ngsi-ld/errors/BadRequestData',
          title: 'Unknown Entity Type',
          detail: `Entity type ${entityType} is not supported`
        });
      }

      // Build INSERT query dynamically
      const columns = Object.keys(data).filter(k => data[k] !== undefined);
      const values = columns.map(k => data[k]);
      const placeholders = columns.map((_, i) => `$${i + 1}`);

      // Handle geometry column
      let geomIndex = -1;
      if (data.lat !== undefined && data.lon !== undefined) {
        columns.push('geom');
        geomIndex = columns.length;
        placeholders.push(`ST_SetSRID(ST_MakePoint($${values.length + 1}, $${values.length + 2}), 4326)::geography`);
        values.push(data.lon, data.lat);
      }

      const insertQuery = `
        INSERT INTO ${tableName} (${columns.join(', ')})
        VALUES (${placeholders.join(', ')})
        RETURNING id
      `;

      await db.query(insertQuery, values);

      res.status(201)
        .setHeader('Location', `/ngsi-ld/v1/entities/${entity.id}`)
        .json({ created: true });
    } catch (error) {
      console.error('[NGSI-LD] Create entity error:', error);
      
      if (error.code === '23505') {
        // Unique constraint violation
        return res.status(409).json({
          type: 'https://uri.etsi.org/ngsi-ld/errors/AlreadyExists',
          title: 'Entity Already Exists',
          detail: 'An entity with this ID already exists'
        });
      }

      res.status(500).json({
        type: 'https://uri.etsi.org/ngsi-ld/errors/InternalError',
        title: 'Internal Server Error',
        detail: error.message
      });
    }
  });

  /**
   * PATCH /ngsi-ld/v1/entities/:id/attrs
   * Update entity attributes
   */
  router.patch('/entities/:id/attrs', async (req, res) => {
    try {
      const entityId = req.params.id;
      const attrs = req.body;

      // Extract entity type and ID
      const match = entityId.match(/^urn:ngsi-ld:(\w+):(.+)$/);
      if (!match) {
        return res.status(400).json({
          type: 'https://uri.etsi.org/ngsi-ld/errors/BadRequestData',
          title: 'Invalid Entity ID'
        });
      }

      const [, entityType, id] = match;

      // Map entity type to table
      const tableMap = {
        'Vehicle': 'vehicles',
        'Worker': 'personnel',
        'Depot': 'depots',
        'Dump': 'dumps',
        'Route': 'routes',
        'WastePoint': 'points',
        'Alert': 'alerts'
      };

      const tableName = tableMap[entityType];
      if (!tableName) {
        return res.status(404).json({
          type: 'https://uri.etsi.org/ngsi-ld/errors/ResourceNotFound',
          title: 'Entity Not Found'
        });
      }

      // Convert NGSI-LD attributes to database columns
      const updates = [];
      const values = [];
      let paramIndex = 1;

      for (const [key, value] of Object.entries(attrs)) {
        if (value.type === 'Property') {
          updates.push(`${key} = $${paramIndex++}`);
          values.push(value.value);
        }
        // Handle more attribute types as needed
      }

      if (updates.length === 0) {
        return res.status(400).json({
          type: 'https://uri.etsi.org/ngsi-ld/errors/BadRequestData',
          title: 'No Valid Attributes',
          detail: 'No valid attributes to update'
        });
      }

      // Add updated_at timestamp
      updates.push(`updated_at = NOW()`);

      // Build UPDATE query
      values.push(id);
      const updateQuery = `
        UPDATE ${tableName}
        SET ${updates.join(', ')}
        WHERE id = $${paramIndex}
      `;

      const result = await db.query(updateQuery, values);

      if (result.rowCount === 0) {
        return res.status(404).json({
          type: 'https://uri.etsi.org/ngsi-ld/errors/ResourceNotFound',
          title: 'Entity Not Found'
        });
      }

      res.status(204).send();
    } catch (error) {
      console.error('[NGSI-LD] Update entity error:', error);
      res.status(500).json({
        type: 'https://uri.etsi.org/ngsi-ld/errors/InternalError',
        title: 'Internal Server Error',
        detail: error.message
      });
    }
  });

  /**
   * DELETE /ngsi-ld/v1/entities/:id
   * Delete entity
   */
  router.delete('/entities/:id', async (req, res) => {
    try {
      const entityId = req.params.id;

      // Extract entity type and ID
      const match = entityId.match(/^urn:ngsi-ld:(\w+):(.+)$/);
      if (!match) {
        return res.status(400).json({
          type: 'https://uri.etsi.org/ngsi-ld/errors/BadRequestData',
          title: 'Invalid Entity ID'
        });
      }

      const [, entityType, id] = match;

      // Map entity type to table
      const tableMap = {
        'Vehicle': 'vehicles',
        'Worker': 'personnel',
        'Depot': 'depots',
        'Dump': 'dumps',
        'Route': 'routes',
        'WastePoint': 'points',
        'Alert': 'alerts'
      };

      const tableName = tableMap[entityType];
      if (!tableName) {
        return res.status(404).json({
          type: 'https://uri.etsi.org/ngsi-ld/errors/ResourceNotFound',
          title: 'Entity Not Found'
        });
      }

      const result = await db.query(`DELETE FROM ${tableName} WHERE id = $1`, [id]);

      if (result.rowCount === 0) {
        return res.status(404).json({
          type: 'https://uri.etsi.org/ngsi-ld/errors/ResourceNotFound',
          title: 'Entity Not Found'
        });
      }

      res.status(204).send();
    } catch (error) {
      console.error('[NGSI-LD] Delete entity error:', error);
      res.status(500).json({
        type: 'https://uri.etsi.org/ngsi-ld/errors/InternalError',
        title: 'Internal Server Error',
        detail: error.message
      });
    }
  });

  return router;
};
