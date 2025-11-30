/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck Backend - Realtime Store
 * Lightweight realtime route management store
 * Note: Points and vehicles are now queried directly from database
 * This store only manages active route state for check-in tracking
 */

class RealtimeStore {
  constructor() {
    // Only store active routes for check-in tracking
    // Points and vehicles are queried from database via API endpoints
    this.activeRoutes = new Map(); // route_id -> { route_id, vehicle_id, status, points: Map<point_id, {checked, ...}> }
    this.serverTime = Date.now();
  }

  // --- Route Management for CN7 ---

  startRoute(routeId, vehicleId, points = []) {
    if (this.activeRoutes.has(routeId)) {
      console.warn(`[Store] Route ${routeId} is already active.`);
      return;
    }
    const routePoints = new Map();
    // Assuming points is an array of objects with at least a point_id
    points.forEach((p) =>
      routePoints.set(p.point_id, { ...p, checked: false, checkin_time: null })
    );

    this.activeRoutes.set(routeId, {
      route_id: routeId,
      vehicle_id: vehicleId,
      status: "inprogress", // inprogress, completed
      started_at: Date.now(),
      points: routePoints,
    });
    console.log(
      `[Store] Route ${routeId} started for vehicle ${vehicleId} with ${points.length} points.`
    );
  }

  recordCheckin(routeId, pointId, imageUrl) {
    const route = this.activeRoutes.get(routeId);
    if (!route || route.status === "completed") {
      // This could be a "Late Check-in"
      console.warn(
        `[Store] Received check-in for inactive/completed route ${routeId}`
      );
      return { status: "late_checkin" };
    }

    const point = route.points.get(pointId);
    if (point) {
      if (point.checked) {
        console.warn(
          `[Store] Duplicate check-in for point ${pointId} on route ${routeId}`
        );
        return { status: "duplicate" };
      }
      point.checked = true;
      point.checkin_time = Date.now();
      point.image_url = imageUrl;
      console.log(
        `[Store] Check-in recorded for point ${pointId} on route ${routeId} with image: ${imageUrl}`
      );
      return { status: "ok" };
    } else {
      console.warn(`[Store] Point ${pointId} not found on route ${routeId}`);
      return { status: "point_not_found" };
    }
  }

  completeRoute(routeId) {
    const route = this.activeRoutes.get(routeId);
    if (route) {
      route.status = "completed";
      route.completed_at = Date.now();
      console.log(`[Store] Route ${routeId} completed.`);
    }
  }

  getActiveRoutes() {
    return Array.from(this.activeRoutes.values());
  }

  getRoute(routeId) {
    return this.activeRoutes.get(routeId);
  }
}

const store = new RealtimeStore();

module.exports = { store };
