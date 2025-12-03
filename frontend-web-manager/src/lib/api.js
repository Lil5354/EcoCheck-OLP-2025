/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 * 
 * EcoCheck Frontend API Client
 * Centralized API utility for making backend requests
 */

const API_BASE = '/api';

// Generic fetch wrapper
async function request(endpoint, options = {}) {
  let url = `${API_BASE}${endpoint}`;
  const config = {
    headers: {
      'Content-Type': 'application/json',
      ...options.headers,
    },
    ...options,
  };

  // Convert params object to query string for GET requests
  if (options.method === 'GET' && options.params) {
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
    const contentType = response.headers.get('content-type');
    
    if (contentType && contentType.includes('application/json')) {
      data = await response.json();
    } else {
      data = await response.text();
    }

    return {
      ok: response.ok,
      status: response.status,
      data: data,
      error: response.ok ? null : (data.error || data.message || 'Request failed'),
    };
  } catch (error) {
    console.error(`API request failed: ${endpoint}`, error);
    return {
      ok: false,
      status: 0,
      data: null,
      error: error.message || 'Network error',
    };
  }
}

// API client object
const api = {
  // Alerts & Dispatch
  getAlerts: (params) => request('/alerts', { method: 'GET', params }),
  dispatchAlert: (alertId) => request(`/alerts/${alertId}/dispatch`, { method: 'POST' }),
  assignVehicleToAlert: (alertId, vehicleId) => 
    request(`/alerts/${alertId}/assign`, { 
      method: 'POST', 
      body: JSON.stringify({ vehicle_id: vehicleId }) 
    }),

  // Personnel
  getPersonnel: (params) => request('/manager/personnel', { method: 'GET', params }),
  deletePersonnel: (id) => request(`/manager/personnel/${id}`, { method: 'DELETE' }),

  // Fleet
  getFleet: (params) => request('/master/fleet', { method: 'GET', params }),

  // Schedules
  getSchedules: (params) => request('/schedules', { method: 'GET', params }),
  deleteSchedule: (id) => request(`/schedules/${id}`, { method: 'DELETE' }),

  // Depots & Dumps
  getDepots: (params) => request('/master/depots', { method: 'GET', params }),
  getDumps: (params) => request('/master/dumps', { method: 'GET', params }),

  // Groups
  getGroups: (params) => request('/groups', { method: 'GET', params }),
  getGroup: (id) => request(`/groups/${id}`, { method: 'GET' }),
  deleteGroup: (id) => request(`/groups/${id}`, { method: 'DELETE' }),

  // Districts (for Route Optimization)
  getDistricts: (date) => request('/vrp/districts', { method: 'GET', params: { date } }),

  // Route Assignment
  assignRoute: (routeId, employeeId) => 
    request('/vrp/assign-route', { 
      method: 'POST', 
      body: JSON.stringify({ route_id: routeId, employee_id: employeeId }) 
    }),

  // Sensors & Air Quality
  getSensorAlerts: (threshold) => 
    request('/sensors/alerts', { method: 'GET', params: { threshold } }),
  getContainerLevel: (containerId) => 
    request(`/sensors/${containerId}/level`, { method: 'GET' }),
  getContainerSensors: (containerId) => 
    request(`/sensors/container/${containerId}`, { method: 'GET' }),
  getSensorObservations: (containerId, limit = 50) => 
    request(`/sensors/container/${containerId}/observations`, { 
      method: 'GET', 
      params: { limit } 
    }),
  getAirQuality: (lat, lon) => 
    request('/air-quality', { method: 'GET', params: { lat, lon } }),

  // POI (Points of Interest)
  getNearbyPOI: (lat, lon, radius, poiType) => 
    request('/poi/nearby', { 
      method: 'GET', 
      params: { lat, lon, radius, type: poiType } 
    }),

  // Incidents & Exceptions
  getIncidents: (params) => request('/incidents', { method: 'GET', params }),
  getExceptions: (params) => request('/exceptions', { method: 'GET', params }),

  // Analytics
  getSummary: () => request('/analytics/summary', { method: 'GET' }),
  getTimeseries: (params) => request('/analytics/timeseries', { method: 'GET', params }),

  // Gamification
  getGamificationOverview: () => request('/gamification/analytics/overview', { method: 'GET' }),
  getGamificationTrends: (period) => 
    request('/gamification/analytics/trends', { method: 'GET', params: { period } }),
  getGamificationDistribution: (type) => 
    request('/gamification/analytics/distribution', { method: 'GET', params: { type } }),
  getLeaderboard: (params) => request('/gamification/leaderboard', { method: 'GET', params }),
  getBadges: () => request('/gamification/badges', { method: 'GET' }),
  getBadgeAnalytics: () => request('/gamification/badges/analytics', { method: 'GET' }),
  deleteBadge: (id) => request(`/gamification/badges/${id}`, { method: 'DELETE' }),
  getPointTransactions: (params) => 
    request('/gamification/points/transactions', { method: 'GET', params }),
  getPointsRules: () => request('/gamification/points/rules', { method: 'GET' }),
};

export default api;

