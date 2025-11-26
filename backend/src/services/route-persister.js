/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * Route Persister Service
 * Saves optimized routes to database
 */

const { v4: uuidv4 } = require("uuid");

class RoutePersister {
  constructor(db) {
    this.db = db;
  }

  /**
   * Save optimized routes to database
   * @param {Array} optimizedRoutes - Routes from VRP optimizer
   * @param {Object} params - {scheduled_date, depot_id, dump_id}
   * @returns {Promise<Array>} Created route IDs
   */
  async saveRoutes(optimizedRoutes, params) {
    const { scheduled_date, depot_id, dump_id } = params;
    const routeIds = [];

    for (const route of optimizedRoutes) {
      const routeId = uuidv4();

      try {
        // 1. Create route in database
        await this.db.query(
          `
          INSERT INTO routes (
            id, vehicle_id, depot_id, dump_id,
            driver_id, collector_id, start_at,
            planned_distance_km, planned_duration_min,
            status, optimization_score, meta,
            created_at, updated_at
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, NOW(), NOW())
        `,
          [
            routeId,
            route.vehicle_id,
            depot_id,
            dump_id,
            route.driver_id || null,
            route.collector_id || null,
            scheduled_date,
            route.total_distance_km,
            route.total_duration_min,
            "planned",
            route.optimization_score || 0.8,
            JSON.stringify({
              optimization_date: new Date().toISOString(),
              total_stops: route.stops.length,
            }),
          ]
        );

        // 2. Create route_stops
        for (const stop of route.stops) {
          const stopId = uuidv4();
          
          // Get point_id from collection_schedule (if it has a point)
          // For now, we'll link directly to the schedule
          // In future, we can create/use points table entries
          
          // Parse estimated_arrival time
          const [arrivalHour, arrivalMin] = stop.estimated_arrival.split(":").map(Number);
          const arrivalTime = new Date(scheduled_date);
          arrivalTime.setHours(arrivalHour, arrivalMin, 0, 0);

          await this.db.query(
            `
            INSERT INTO route_stops (
              id, route_id, point_id, seq,
              planned_eta, status, meta,
              created_at, updated_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW(), NOW())
          `,
            [
              stopId,
              routeId,
              stop.schedule_id, // Using schedule_id as point_id for now
              stop.seq,
              arrivalTime,
              "pending",
              JSON.stringify({
                schedule_id: stop.schedule_id,
                estimated_departure: stop.estimated_departure,
              }),
            ]
          );

          // 3. Update collection_schedules to link with route
          await this.db.query(
            `
            UPDATE collection_schedules
            SET route_id = $1, 
                status = CASE 
                  WHEN status = 'scheduled' THEN 'assigned'
                  ELSE status
                END,
                updated_at = NOW()
            WHERE id = $2
          `,
            [routeId, stop.schedule_id]
          );
        }

        routeIds.push(routeId);
        console.log(
          `✅ Created route ${routeId} with ${route.stops.length} stops`
        );
      } catch (error) {
        console.error(`❌ Error saving route ${routeId}:`, error);
        throw error;
      }
    }

    return routeIds;
  }

  /**
   * Get route details with stops
   */
  async getRouteDetails(routeId) {
    const routeQuery = await this.db.query(
      `
      SELECT 
        r.*,
        d.name as depot_name,
        ST_Y(d.geom::geometry) as depot_latitude,
        ST_X(d.geom::geometry) as depot_longitude,
        dump.name as dump_name,
        ST_Y(dump.geom::geometry) as dump_latitude,
        ST_X(dump.geom::geometry) as dump_longitude,
        v.plate_number as vehicle_plate
      FROM routes r
      LEFT JOIN depots d ON r.depot_id = d.id
      LEFT JOIN dumps dump ON r.dump_id = dump.id
      LEFT JOIN vehicles v ON r.vehicle_id = v.id
      WHERE r.id = $1
    `,
      [routeId]
    );

    if (routeQuery.rows.length === 0) {
      return null;
    }

    const route = routeQuery.rows[0];

    const stopsQuery = await this.db.query(
      `
      SELECT 
        rs.*,
        cs.address,
        cs.latitude,
        cs.longitude,
        cs.waste_type,
        cs.estimated_weight_kg,
        cs.citizen_id,
        u.profile->>'name' as citizen_name
      FROM route_stops rs
      LEFT JOIN collection_schedules cs ON rs.point_id = cs.id
      LEFT JOIN users u ON cs.citizen_id = u.id
      WHERE rs.route_id = $1
      ORDER BY rs.seq ASC
    `,
      [routeId]
    );

    route.stops = stopsQuery.rows;
    return route;
  }
}

module.exports = RoutePersister;

