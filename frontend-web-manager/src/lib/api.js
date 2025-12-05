/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck Frontend API Client
 * Centralized API utility for making backend requests
 */

const API_BASE = "/api";

// Generic fetch wrapper
async function request(endpoint, options = {}) {
  let url = `${API_BASE}${endpoint}`;
  const config = {
    headers: {
      "Content-Type": "application/json",
      ...options.headers,
    },
    ...options,
  };

  // Convert params object to query string for GET requests
  if (options.method === "GET" && options.params) {
    const searchParams = new URLSearchParams();
    Object.entries(options.params).forEach(([key, value]) => {
      if (value !== undefined && value !== null) {
        searchParams.append(key, value);
      }
    });
    const queryString = searchParams.toString();
    if (queryString) {
      url = `${url}?${queryString}`;
    }
    delete config.params;
  }

  try {
    const response = await fetch(url, config);
    let data;
    const contentType = response.headers.get("content-type");

    if (contentType && contentType.includes("application/json")) {
      data = await response.json();
    } else {
      data = await response.text();
    }

    // Backend returns {ok: true, data: [...]}, unwrap it
    let unwrappedData = data;
    let isOk = response.ok;
    let error = null;

    if (typeof data === "object" && data !== null) {
      // If backend response has {ok: true/false, data: ..., error: ...} structure
      if ("ok" in data) {
        isOk = data.ok && response.ok; // Both HTTP status and backend ok must be true
        unwrappedData = data.data !== undefined ? data.data : data;
        error = data.error || (isOk ? null : data.message || "Request failed");
      }
    }

    if (!isOk && !error) {
      error = data.error || data.message || "Request failed";
    }

    return {
      ok: isOk,
      status: response.status,
      data: unwrappedData,
      error: error,
    };
  } catch (error) {
    console.error(`API request failed: ${endpoint}`, error);
    return {
      ok: false,
      status: 0,
      data: null,
      error: error.message || "Network error",
    };
  }
}

// API client object
const api = {
  // Alerts & Dispatch
  getAlerts: (params) => request("/alerts", { method: "GET", params }),
  dispatchAlert: (alertId) =>
    request(`/alerts/${alertId}/dispatch`, { method: "POST" }),
  assignVehicleToAlert: (alertId, vehicleId) =>
    request(`/alerts/${alertId}/assign`, {
      method: "POST",
      body: JSON.stringify({ vehicle_id: vehicleId }),
    }),

  // Personnel
  getPersonnel: (params) =>
    request("/manager/personnel", { method: "GET", params }),
  createPersonnel: (data) =>
    request("/manager/personnel", {
      method: "POST",
      body: JSON.stringify(data),
    }),
  updatePersonnel: (id, data) =>
    request(`/manager/personnel/${id}`, {
      method: "PUT",
      body: JSON.stringify(data),
    }),
  deletePersonnel: (id) =>
    request(`/manager/personnel/${id}`, { method: "DELETE" }),

  // Fleet
  getFleet: (params) => request("/master/fleet", { method: "GET", params }),
  createVehicle: (data) =>
    request("/master/fleet", {
      method: "POST",
      body: JSON.stringify(data),
    }),
  updateVehicle: (id, data) =>
    request(`/master/fleet/${id}`, {
      method: "PATCH",
      body: JSON.stringify(data),
    }),
  deleteVehicle: (id) => request(`/master/fleet/${id}`, { method: "DELETE" }),

  // Schedules
  getSchedules: (params) => request("/schedules", { method: "GET", params }),
  updateSchedule: (id, data) =>
    request(`/schedules/${id}`, {
      method: "PATCH",
      body: JSON.stringify(data),
    }),
  deleteSchedule: (id) => request(`/schedules/${id}`, { method: "DELETE" }),

  // Depots & Dumps
  getDepots: (params) => request("/master/depots", { method: "GET", params }),
  createDepot: (data) =>
    request("/master/depots", {
      method: "POST",
      body: JSON.stringify(data),
    }),
  updateDepot: (id, data) =>
    request(`/master/depots/${id}`, {
      method: "PATCH",
      body: JSON.stringify(data),
    }),
  getDumps: (params) => request("/master/dumps", { method: "GET", params }),

  // Groups
  getGroups: (params) => request("/groups", { method: "GET", params }),
  getGroup: (id) => request(`/groups/${id}`, { method: "GET" }),
  createGroup: (data) =>
    request("/groups", {
      method: "POST",
      body: JSON.stringify(data),
    }),
  updateGroup: (id, data) =>
    request(`/groups/${id}`, {
      method: "PUT",
      body: JSON.stringify(data),
    }),
  autoCreateGroups: () =>
    request("/groups/auto-create", {
      method: "POST",
    }),
  deleteGroup: (id) => request(`/groups/${id}`, { method: "DELETE" }),

  // Districts (for Route Optimization)
  getDistricts: (date) =>
    request("/vrp/districts", { method: "GET", params: { date } }),

  // Route Optimization
  optimizeVRP: (payload) =>
    request("/vrp/optimize", {
      method: "POST",
      body: JSON.stringify(payload),
    }),
  saveRoutes: (payload) =>
    request("/vrp/save-routes", {
      method: "POST",
      body: JSON.stringify(payload),
    }),
  sendRoutes: (payload) =>
    request("/dispatch/send-routes", {
      method: "POST",
      body: JSON.stringify(payload),
    }),

  // Route Assignment
  assignRoute: (routeId, employeeId) =>
    request("/vrp/assign-route", {
      method: "POST",
      body: JSON.stringify({ route_id: routeId, driver_id: employeeId }),
    }),

  // Sensors & Air Quality
  getSensorAlerts: (threshold) =>
    request("/sensors/alerts", { method: "GET", params: { threshold } }),
  getContainerLevel: (containerId) =>
    request(`/sensors/${containerId}/level`, { method: "GET" }),
  getContainerSensors: (containerId) =>
    request(`/sensors/container/${containerId}`, { method: "GET" }),
  getSensorObservations: (containerId, limit = 50) =>
    request(`/sensors/container/${containerId}/observations`, {
      method: "GET",
      params: { limit },
    }),
  getAirQuality: (lat, lon) =>
    request("/air-quality", { method: "GET", params: { lat, lon } }),

  // POI (Points of Interest)
  getNearbyPOI: (lat, lon, radius, poiType) =>
    request("/poi/nearby", {
      method: "GET",
      params: { lat, lon, radius, type: poiType },
    }),

  // Incidents & Exceptions
  getIncidents: (params) => request("/incidents", { method: "GET", params }),
  getIncident: (id) => request(`/incidents/${id}`, { method: "GET" }),
  createIncident: (data) =>
    request("/incidents", {
      method: "POST",
      body: JSON.stringify(data),
    }),
  updateIncidentStatus: (id, data) =>
    request(`/incidents/${id}/status`, {
      method: "PATCH",
      body: JSON.stringify(data),
    }),
  updateIncident: (id, data) =>
    request(`/incidents/${id}`, {
      method: "PUT",
      body: JSON.stringify(data),
    }),
  deleteIncident: (id) => request(`/incidents/${id}`, { method: "DELETE" }),
  getExceptions: (params) => request("/exceptions", { method: "GET", params }),

  // Analytics
  getSummary: () => request("/analytics/summary", { method: "GET" }),
  getTimeseries: (params) =>
    request("/analytics/timeseries", { method: "GET", params }),
  predict: (params) =>
    request("/analytics/predict", {
      method: "GET",
      params,
    }),

  // Gamification
  getGamificationOverview: () =>
    request("/gamification/analytics/overview", { method: "GET" }),
  getGamificationTrends: (period) =>
    request("/gamification/analytics/trends", {
      method: "GET",
      params: { period },
    }),
  getGamificationDistribution: (type) =>
    request("/gamification/analytics/distribution", {
      method: "GET",
      params: { type },
    }),
  getLeaderboard: (params) =>
    request("/gamification/leaderboard", { method: "GET", params }),
  getBadges: () => request("/gamification/badges", { method: "GET" }),
  getBadgeAnalytics: () =>
    request("/gamification/badges/analytics", { method: "GET" }),
  createBadge: (data) =>
    request("/gamification/badges", {
      method: "POST",
      body: JSON.stringify(data),
    }),
  updateBadge: (id, data) =>
    request(`/gamification/badges/${id}`, {
      method: "PATCH",
      body: JSON.stringify(data),
    }),
  deleteBadge: (id) =>
    request(`/gamification/badges/${id}`, { method: "DELETE" }),
  uploadImage: async (file) => {
    const formData = new FormData();
    formData.append("image", file);
    
    try {
      const response = await fetch(`${API_BASE}/upload`, {
        method: "POST",
        body: formData,
      });
      
      const data = await response.json();
      
      if (response.ok && data.success && data.url) {
        return {
          ok: true,
          data: { url: data.url },
        };
      } else {
        return {
          ok: false,
          error: data.error || "Upload failed",
        };
      }
    } catch (error) {
      return {
        ok: false,
        error: error.message || "Network error",
      };
    }
  },
  getPointTransactions: (params) =>
    request("/gamification/points/transactions", { method: "GET", params }),
  getPointsRules: () =>
    request("/gamification/points/rules", { method: "GET" }),
  adjustPoints: (userId, points, reason) =>
    request("/gamification/points/adjust", {
      method: "POST",
      body: JSON.stringify({ user_id: userId, points, reason }),
    }),
};

export default api;
