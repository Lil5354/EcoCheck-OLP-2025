/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * VRP Optimizer Service
 * Implements Nearest Neighbor + 2-opt improvement algorithm
 * for Vehicle Routing Problem with Time Windows
 */

const { v4: uuidv4 } = require("uuid");
const DistanceCalculator = require("./distance-calculator");

class VRPOptimizer {
  constructor(db) {
    this.db = db;
    this.distanceCalculator = new DistanceCalculator(db);
  }

  /**
   * Main optimization function
   * @param {Object} params - Optimization parameters
   * @returns {Promise<Object>} Optimized routes
   */
  async optimize(params) {
    const {
      scheduled_date,
      depot_id,
      dump_id,
      vehicles = [],
      constraints = {},
    } = params;

    console.log(`🚀 Starting VRP optimization for date: ${scheduled_date}`);

    // 1. Load data
    const schedules = await this.loadSchedules(scheduled_date);
    const depot = await this.loadDepot(depot_id);
    const dump = await this.loadDump(dump_id);
    const vehicleDetails = await this.loadVehicles(vehicles);

    if (schedules.length === 0) {
      return {
        routes: [],
        unassigned_schedules: [],
        statistics: {
          total_routes: 0,
          total_distance_km: 0,
          total_duration_min: 0,
          utilization_rate: 0,
        },
      };
    }

    // 2. Build distance matrix
    const allPoints = [
      { id: "depot", latitude: depot.latitude, longitude: depot.longitude },
      ...schedules.map((s) => ({
        id: s.id,
        latitude: s.latitude,
        longitude: s.longitude,
        schedule: s,
      })),
      { id: "dump", latitude: dump.latitude, longitude: dump.longitude },
    ];

    console.log(`📊 Building distance matrix for ${allPoints.length} points...`);
    const distanceMatrix = await this.distanceCalculator.buildDistanceMatrix(
      allPoints
    );

    // 3. Nearest Neighbor algorithm
    console.log(`🔍 Running Nearest Neighbor algorithm...`);
    const initialRoutes = this.nearestNeighbor(
      schedules,
      vehicleDetails,
      depot,
      dump,
      distanceMatrix,
      constraints
    );

    // 4. 2-opt improvement
    console.log(`⚡ Running 2-opt improvement...`);
    const improvedRoutes = this.twoOptImprovement(
      initialRoutes,
      distanceMatrix
    );

    // 5. Cross-route optimization
    console.log(`🔄 Running cross-route optimization...`);
    const finalRoutes = this.crossRouteOptimization(
      improvedRoutes,
      distanceMatrix,
      constraints
    );

    // 6. Calculate scores and statistics
    const result = this.calculateResults(finalRoutes, schedules);

    console.log(
      `✅ Optimization complete: ${result.routes.length} routes, ${result.statistics.total_distance_km.toFixed(2)} km`
    );

    return result;
  }

  /**
   * Load collection schedules for a specific date
   */
  async loadSchedules(scheduled_date) {
    const query = `
      SELECT 
        cs.id,
        cs.citizen_id,
        cs.scheduled_date,
        cs.time_slot,
        cs.waste_type,
        cs.estimated_weight_kg,
        cs.latitude,
        cs.longitude,
        cs.address,
        cs.status,
        cs.priority,
        cs.employee_id,
        cs.route_id
      FROM collection_schedules cs
      WHERE cs.scheduled_date = $1
        AND cs.status IN ('scheduled', 'assigned')
        AND cs.route_id IS NULL
        AND cs.latitude IS NOT NULL
        AND cs.longitude IS NOT NULL
      ORDER BY cs.priority DESC, cs.created_at ASC
    `;

    const result = await this.db.query(query, [scheduled_date]);
    return result.rows;
  }

  /**
   * Load depot information
   */
  async loadDepot(depot_id) {
    const query = `
      SELECT 
        id,
        name,
        ST_Y(geom::geometry) as latitude,
        ST_X(geom::geometry) as longitude,
        address
      FROM depots
      WHERE id = $1
    `;

    const result = await this.db.query(query, [depot_id]);
    if (result.rows.length === 0) {
      throw new Error(`Depot ${depot_id} not found`);
    }
    return result.rows[0];
  }

  /**
   * Load dump information
   */
  async loadDump(dump_id) {
    const query = `
      SELECT 
        id,
        name,
        ST_Y(geom::geometry) as latitude,
        ST_X(geom::geometry) as longitude,
        address
      FROM dumps
      WHERE id = $1
    `;

    const result = await this.db.query(query, [dump_id]);
    if (result.rows.length === 0) {
      throw new Error(`Dump ${dump_id} not found`);
    }
    return result.rows[0];
  }

  /**
   * Load vehicle details
   */
  async loadVehicles(vehicleIds) {
    if (vehicleIds.length === 0) return [];

    const query = `
      SELECT 
        v.id,
        v.plate,
        v.capacity_kg,
        v.type,
        v.depot_id
      FROM vehicles v
      WHERE v.id = ANY($1::text[])
    `;

    const result = await this.db.query(query, [vehicleIds]);
    return result.rows;
  }

  /**
   * Nearest Neighbor algorithm
   */
  nearestNeighbor(schedules, vehicles, depot, dump, distanceMatrix, constraints) {
    const routes = [];
    const assignedScheduleIds = new Set();
    const maxRouteDuration = constraints.max_route_duration_min || 480; // 8 hours default
    const maxStopsPerRoute = constraints.max_stops_per_route || 20;
    const avgSpeedKmh = 30; // Average speed in km/h for urban areas

    for (const vehicle of vehicles) {
      const route = {
        vehicle_id: vehicle.id,
        driver_id: null, // Will be assigned later
        collector_id: null, // Will be assigned later
        stops: [],
        current_location: "depot",
        current_weight: 0,
        current_time_min: 0, // Start from depot at time 0
        total_distance_km: 0,
      };

      let remainingCapacity = vehicle.capacity_kg || 5000;
      let currentPoint = "depot";

      // Find nearest unassigned schedule
      while (route.stops.length < maxStopsPerRoute) {
        let nearestSchedule = null;
        let nearestDistance = Infinity;
        let nearestIndex = -1;

        for (let i = 0; i < schedules.length; i++) {
          const schedule = schedules[i];
          if (assignedScheduleIds.has(schedule.id)) continue;

          // Check capacity constraint
          if (schedule.estimated_weight_kg > remainingCapacity) continue;

          // Check time window (simplified: check if can reach within time slot)
          const distance = distanceMatrix[currentPoint]?.[schedule.id] || Infinity;
          const travelTimeMin = (distance / avgSpeedKmh) * 60;
          const arrivalTimeMin = route.current_time_min + travelTimeMin;

          // Parse time slot (e.g., "18:00-20:00")
          const [startTime, endTime] = this.parseTimeSlot(schedule.time_slot);
          const arrivalHour = Math.floor(arrivalTimeMin / 60);
          const arrivalMin = arrivalTimeMin % 60;

          // Check if arrival time is within time window (with buffer)
          if (arrivalHour < startTime || arrivalHour > endTime) {
            // Can still assign if close enough (within 1 hour buffer)
            if (arrivalHour < startTime - 1 || arrivalHour > endTime + 1) {
              continue;
            }
          }

          // Check route duration constraint
          const estimatedReturnToDump = arrivalTimeMin + 15 + // 15 min collection time
            (distanceMatrix[schedule.id]?.["dump"] || 0) / avgSpeedKmh * 60;
          if (estimatedReturnToDump > maxRouteDuration) continue;

          if (distance < nearestDistance) {
            nearestDistance = distance;
            nearestSchedule = schedule;
            nearestIndex = i;
          }
        }

        if (!nearestSchedule) break; // No more feasible schedules

        // Add to route
        const travelTimeMin = (nearestDistance / avgSpeedKmh) * 60;
        const collectionTimeMin = 15; // 15 minutes per stop
        const estimatedArrival = route.current_time_min + travelTimeMin;
        const estimatedDeparture = estimatedArrival + collectionTimeMin;

        route.stops.push({
          schedule_id: nearestSchedule.id,
          schedule: nearestSchedule,
          seq: route.stops.length + 1,
          estimated_arrival_min: estimatedArrival,
          estimated_departure_min: estimatedDeparture,
          distance_from_previous_km: nearestDistance,
        });

        route.total_distance_km += nearestDistance;
        route.current_time_min = estimatedDeparture;
        route.current_weight += nearestSchedule.estimated_weight_kg;
        remainingCapacity -= nearestSchedule.estimated_weight_kg;
        currentPoint = nearestSchedule.id;
        assignedScheduleIds.add(nearestSchedule.id);
      }

      // Add return to dump
      const returnDistance = distanceMatrix[currentPoint]?.["dump"] || 0;
      route.total_distance_km += returnDistance;
      route.total_duration_min = route.current_time_min + (returnDistance / avgSpeedKmh) * 60;

      if (route.stops.length > 0) {
        routes.push(route);
      }
    }

    return routes;
  }

  /**
   * 2-opt improvement algorithm
   */
  twoOptImprovement(routes, distanceMatrix) {
    const improvedRoutes = [];

    for (const route of routes) {
      if (route.stops.length < 3) {
        improvedRoutes.push(route);
        continue;
      }

      let improved = true;
      let bestRoute = { ...route };
      let iterations = 0;
      const maxIterations = 100;

      while (improved && iterations < maxIterations) {
        improved = false;
        iterations++;

        for (let i = 0; i < bestRoute.stops.length - 1; i++) {
          for (let j = i + 2; j < bestRoute.stops.length; j++) {
            // Try swapping edges (i, i+1) and (j, j+1)
            const newRoute = this.twoOptSwap(bestRoute, i, j, distanceMatrix);
            if (newRoute.total_distance_km < bestRoute.total_distance_km) {
              bestRoute = newRoute;
              improved = true;
              break;
            }
          }
          if (improved) break;
        }
      }

      improvedRoutes.push(bestRoute);
    }

    return improvedRoutes;
  }

  /**
   * Perform 2-opt swap
   */
  twoOptSwap(route, i, j, distanceMatrix) {
    const newStops = [
      ...route.stops.slice(0, i),
      ...route.stops.slice(i, j + 1).reverse(),
      ...route.stops.slice(j + 1),
    ];

    // Recalculate distances and times
    let totalDistance = 0;
    let currentTime = 0;
    const avgSpeedKmh = 30;

    // Distance from depot to first stop
    const firstStop = newStops[0];
    const depotDistance = distanceMatrix["depot"]?.[firstStop.schedule_id] || 0;
    totalDistance += depotDistance;
    currentTime += (depotDistance / avgSpeedKmh) * 60;

    for (let k = 0; k < newStops.length; k++) {
      const stop = newStops[k];
      const arrivalTime = currentTime;
      const departureTime = arrivalTime + 15; // 15 min collection

      stop.estimated_arrival_min = arrivalTime;
      stop.estimated_departure_min = departureTime;

      if (k < newStops.length - 1) {
        const nextStop = newStops[k + 1];
        const distance = distanceMatrix[stop.schedule_id]?.[nextStop.schedule_id] || 0;
        stop.distance_from_previous_km = distance;
        totalDistance += distance;
        currentTime = departureTime + (distance / avgSpeedKmh) * 60;
      }
    }

    // Distance from last stop to dump
    const lastStop = newStops[newStops.length - 1];
    const dumpDistance = distanceMatrix[lastStop.schedule_id]?.["dump"] || 0;
    totalDistance += dumpDistance;

    return {
      ...route,
      stops: newStops,
      total_distance_km: totalDistance,
      total_duration_min: currentTime + (dumpDistance / avgSpeedKmh) * 60,
    };
  }

  /**
   * Cross-route optimization
   */
  crossRouteOptimization(routes, distanceMatrix, constraints) {
    if (routes.length < 2) return routes;

    let improved = true;
    let iterations = 0;
    const maxIterations = 50;
    let currentRoutes = [...routes];

    while (improved && iterations < maxIterations) {
      improved = false;
      iterations++;

      for (let i = 0; i < currentRoutes.length; i++) {
        for (let j = i + 1; j < currentRoutes.length; j++) {
          const route1 = currentRoutes[i];
          const route2 = currentRoutes[j];

          // Try moving a stop from route1 to route2
          for (let k = 0; k < route1.stops.length; k++) {
            const stop = route1.stops[k];
            const newRoute2 = this.insertStopInRoute(route2, stop, distanceMatrix, constraints);
            const newRoute1 = {
              ...route1,
              stops: route1.stops.filter((_, idx) => idx !== k),
            };

            // Recalculate route1
            const recalculatedRoute1 = this.recalculateRoute(newRoute1, distanceMatrix);

            if (newRoute2 && recalculatedRoute1) {
              const oldTotal = route1.total_distance_km + route2.total_distance_km;
              const newTotal = recalculatedRoute1.total_distance_km + newRoute2.total_distance_km;

              if (newTotal < oldTotal) {
                currentRoutes[i] = recalculatedRoute1;
                currentRoutes[j] = newRoute2;
                improved = true;
                break;
              }
            }
          }
          if (improved) break;
        }
        if (improved) break;
      }
    }

    return currentRoutes;
  }

  /**
   * Insert stop into route at optimal position
   */
  insertStopInRoute(route, stop, distanceMatrix, constraints) {
    // Find best insertion position
    let bestPosition = -1;
    let bestIncrease = Infinity;

    for (let i = 0; i <= route.stops.length; i++) {
      let distanceIncrease = 0;

      if (i === 0) {
        // Insert at beginning
        const depotDistance = distanceMatrix["depot"]?.[stop.schedule_id] || 0;
        const toFirstStop = distanceMatrix[stop.schedule_id]?.[route.stops[0]?.schedule_id] || 0;
        const originalDistance = distanceMatrix["depot"]?.[route.stops[0]?.schedule_id] || 0;
        distanceIncrease = depotDistance + toFirstStop - originalDistance;
      } else if (i === route.stops.length) {
        // Insert at end
        const lastStop = route.stops[route.stops.length - 1];
        const fromLastStop = distanceMatrix[lastStop.schedule_id]?.[stop.schedule_id] || 0;
        const toDump = distanceMatrix[stop.schedule_id]?.["dump"] || 0;
        const originalToDump = distanceMatrix[lastStop.schedule_id]?.["dump"] || 0;
        distanceIncrease = fromLastStop + toDump - originalToDump;
      } else {
        // Insert in middle
        const prevStop = route.stops[i - 1];
        const nextStop = route.stops[i];
        const fromPrev = distanceMatrix[prevStop.schedule_id]?.[stop.schedule_id] || 0;
        const toNext = distanceMatrix[stop.schedule_id]?.[nextStop.schedule_id] || 0;
        const originalDistance = distanceMatrix[prevStop.schedule_id]?.[nextStop.schedule_id] || 0;
        distanceIncrease = fromPrev + toNext - originalDistance;
      }

      if (distanceIncrease < bestIncrease) {
        bestIncrease = distanceIncrease;
        bestPosition = i;
      }
    }

    if (bestPosition === -1) return null;

    // Insert stop
    const newStops = [...route.stops];
    newStops.splice(bestPosition, 0, stop);

    // Recalculate route
    return this.recalculateRoute({ ...route, stops: newStops }, distanceMatrix);
  }

  /**
   * Recalculate route distances and times
   */
  recalculateRoute(route, distanceMatrix) {
    if (route.stops.length === 0) return null;

    let totalDistance = 0;
    let currentTime = 0;
    const avgSpeedKmh = 30;

    // Distance from depot to first stop
    const firstStop = route.stops[0];
    const depotDistance = distanceMatrix["depot"]?.[firstStop.schedule_id] || 0;
    totalDistance += depotDistance;
    currentTime += (depotDistance / avgSpeedKmh) * 60;

    for (let i = 0; i < route.stops.length; i++) {
      const stop = route.stops[i];
      stop.seq = i + 1;
      stop.estimated_arrival_min = currentTime;
      stop.estimated_departure_min = currentTime + 15; // 15 min collection

      if (i < route.stops.length - 1) {
        const nextStop = route.stops[i + 1];
        const distance = distanceMatrix[stop.schedule_id]?.[nextStop.schedule_id] || 0;
        stop.distance_from_previous_km = distance;
        totalDistance += distance;
        currentTime = stop.estimated_departure_min + (distance / avgSpeedKmh) * 60;
      }
    }

    // Distance from last stop to dump
    const lastStop = route.stops[route.stops.length - 1];
    const dumpDistance = distanceMatrix[lastStop.schedule_id]?.["dump"] || 0;
    totalDistance += dumpDistance;

    return {
      ...route,
      total_distance_km: totalDistance,
      total_duration_min: currentTime + (dumpDistance / avgSpeedKmh) * 60,
    };
  }

  /**
   * Parse time slot string (e.g., "18:00-20:00")
   */
  parseTimeSlot(timeSlot) {
    if (!timeSlot || typeof timeSlot !== 'string') {
      return [0, 23]; // Default: all day
    }
    const parts = timeSlot.split("-");
    if (parts.length !== 2) {
      return [0, 23]; // Default: all day
    }
    const startHour = parseInt(parts[0].split(":")[0], 10) || 0;
    const endHour = parseInt(parts[1].split(":")[0], 10) || 23;
    return [startHour, endHour];
  }

  /**
   * Calculate optimization results and statistics
   */
  calculateResults(routes, allSchedules) {
    const assignedScheduleIds = new Set();
    routes.forEach((route) => {
      route.stops.forEach((stop) => {
        assignedScheduleIds.add(stop.schedule_id);
      });
    });

    const unassignedSchedules = allSchedules.filter(
      (s) => !assignedScheduleIds.has(s.id)
    );

    const totalDistance = routes.reduce(
      (sum, r) => sum + r.total_distance_km,
      0
    );
    const totalDuration = routes.reduce(
      (sum, r) => sum + r.total_duration_min,
      0
    );

    // Calculate optimization score (0-1, higher is better)
    // Based on: distance efficiency, route utilization, time window compliance
    const avgDistancePerStop =
      routes.length > 0
        ? totalDistance /
          routes.reduce((sum, r) => sum + r.stops.length, 0)
        : 0;
    const utilizationRate =
      allSchedules.length > 0
        ? assignedScheduleIds.size / allSchedules.length
        : 0;

    // Calculate optimization score (0-1, higher is better)
    // Normalize distance per stop (assume 0-20 km per stop is reasonable range)
    const normalizedDistanceEfficiency = Math.max(0, Math.min(1, 1 - avgDistancePerStop / 20));
    
    const optimizationScore = Math.min(
      0.3 * normalizedDistanceEfficiency + // Distance efficiency (normalized)
        0.4 * utilizationRate + // Utilization rate
        0.3 * (routes.length > 0 ? 1 : 0), // Route creation success
      1.0
    );

    // Add optimization score to each route
    routes.forEach((route) => {
      route.optimization_score = optimizationScore;
    });

    return {
      routes: routes.map((r) => ({
        vehicle_id: r.vehicle_id,
        driver_id: r.driver_id,
        collector_id: r.collector_id,
        stops: r.stops.map((s) => ({
          schedule_id: s.schedule_id,
          seq: s.seq,
          estimated_arrival: this.minutesToTimeString(
            s.estimated_arrival_min
          ),
          estimated_departure: this.minutesToTimeString(
            s.estimated_departure_min
          ),
        })),
        total_distance_km: parseFloat(r.total_distance_km.toFixed(2)),
        total_duration_min: Math.round(r.total_duration_min),
        optimization_score: parseFloat(optimizationScore.toFixed(2)),
      })),
      unassigned_schedules: unassignedSchedules.map((s) => ({
        id: s.id,
        address: s.address,
        reason: "No feasible route found",
      })),
      statistics: {
        total_routes: routes.length,
        total_distance_km: parseFloat(totalDistance.toFixed(2)),
        total_duration_min: Math.round(totalDuration),
        utilization_rate: parseFloat(utilizationRate.toFixed(2)),
        optimization_score: parseFloat(optimizationScore.toFixed(2)),
      },
    };
  }

  /**
   * Convert minutes to time string (HH:MM)
   */
  minutesToTimeString(minutes) {
    const hours = Math.floor(minutes / 60);
    const mins = Math.floor(minutes % 60);
    return `${String(hours).padStart(2, "0")}:${String(mins).padStart(2, "0")}`;
  }
}

module.exports = VRPOptimizer;

