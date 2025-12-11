/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck Worker - API Configuration and Endpoints
 */

import 'dart:io';
import 'package:flutter/foundation.dart';

/// API Configuration and Endpoints
class ApiConstants {
  ApiConstants._();

  // Base URL - Render Production
  static const String baseUrl = 'https://ecocheck-olp-2025.onrender.com';

  // Development Base URL - Platform specific
  static String get devBaseUrl {
    if (kDebugMode) {
      // Android emulator uses 10.0.2.2 to access host machine
      if (!kIsWeb && Platform.isAndroid) {
        return 'http://10.0.2.2:3000';
      }
      // iOS simulator and macOS can use localhost
      // iOS Simulator CAN access localhost of Mac
      return 'http://localhost:3000';
    }
    return baseUrl;
  }

  // API Version
  static const String apiVersion = 'v1';
  static const String apiPrefix = '/api';

  // Timeout
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Auth Endpoints
  static const String login =
      '$apiPrefix/auth/worker/login'; // Worker login endpoint
  static const String register = '$apiPrefix/auth/register';
  static const String verifyOtp = '$apiPrefix/auth/verify-otp';
  static const String refreshToken = '$apiPrefix/auth/refresh-token';
  static const String logout = '$apiPrefix/auth/logout';
  static const String forgotPassword = '$apiPrefix/auth/forgot-password';
  static const String resetPassword = '$apiPrefix/auth/reset-password';

  // User Endpoints
  static const String profile = '$apiPrefix/users/profile';
  static const String updateProfile = '$apiPrefix/users/profile';
  static const String uploadAvatar = '$apiPrefix/users/avatar';

  // Schedule Endpoints (Worker specific)
  static const String schedules = '$apiPrefix/schedules';
  static const String assignedSchedules = '$apiPrefix/schedules/assigned';
  static String scheduleDetail(String id) => '$apiPrefix/schedules/$id';
  static String updateSchedule(String id) => '$apiPrefix/schedules/$id';
  static String completeSchedule(String id) =>
      '$apiPrefix/schedules/$id/complete';

  // Route Endpoints (Worker specific)
  static const String routes = '$apiPrefix/routes';
  static const String workerRoutes =
      '$apiPrefix/worker/routes'; // New worker-specific routes endpoint
  static const String activeRoute = '$apiPrefix/routes/active';
  static String routeDetail(String id) => '$apiPrefix/routes/$id';
  static String workerRouteDetail(String id) =>
      '$apiPrefix/worker/routes/$id'; // New worker route detail
  static String startRoute(String id) => '$apiPrefix/routes/$id/start';
  static String startWorkerRoute(String id) =>
      '$apiPrefix/worker/routes/$id/start'; // New worker route start
  static String completeRoute(String id) => '$apiPrefix/routes/$id/complete';
  static String completeWorkerRoute(String id) =>
      '$apiPrefix/worker/routes/$id/complete'; // New worker route complete
  static String skipRouteStop(String stopId) =>
      '$apiPrefix/worker/route-stops/$stopId/skip'; // Skip route stop
  static String completeRouteStop(String stopId) =>
      '$apiPrefix/worker/route-stops/$stopId/complete'; // Complete route stop

  // Collection Endpoints (Worker specific)
  static const String collections = '$apiPrefix/collections';
  static String recordCollection(String scheduleId) =>
      '$apiPrefix/collections/$scheduleId/record';

  // Tracking Endpoints
  static const String trackRoute = '$apiPrefix/tracking/route';
  static String trackSchedule(String scheduleId) =>
      '$apiPrefix/tracking/schedule/$scheduleId';
  static const String updateLocation = '$apiPrefix/tracking/location';

  // Notification Endpoints
  static const String notifications = '$apiPrefix/notifications';
  static String markNotificationRead(String id) =>
      '$apiPrefix/notifications/$id/read';
  static const String markAllRead = '$apiPrefix/notifications/mark-all-read';
  static const String subscribeFCM = '$apiPrefix/notifications/subscribe';

  // Statistics Endpoints (Worker specific)
  static const String workerStats = '$apiPrefix/worker/statistics';
  static const String monthlyStats = '$apiPrefix/worker/statistics/monthly';

  // File Upload
  static const String uploadFile = '$apiPrefix/upload';
  static const String uploadImage = '$apiPrefix/upload/image';

  // WebSocket
  static const String wsBaseUrl = 'wss://ecocheck-olp-2025.onrender.com';
  static const String wsTracking = '/tracking';

  // OpenStreetMap Tiles (100% Open Source)
  static const String osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String osmAttribution = '© OpenStreetMap contributors';
  
  // Alternative OSM Tile Servers (for redundancy)
  static const String osmHotTileUrl = 'https://tile-a.openstreetmap.fr/hot/{z}/{x}/{y}.png';
  static const String cartoLightTileUrl = 'https://cartodb-basemaps-a.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png';

  /// Get full URL
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  // Alias methods for backward compatibility
  static String getUrl(String endpoint) => getFullUrl(endpoint);
  static String get loginEndpoint => login;
  static String get activeRouteEndpoint => activeRoute;
  static String startRouteEndpoint(String id) => startWorkerRoute(id);
  static String completeRouteEndpoint(String id) => completeWorkerRoute(id);
  static String updateScheduleEndpoint(String id) => updateSchedule(id);
  static String get assignedSchedulesEndpoint => assignedSchedules;

  /// Headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> authHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };
}
