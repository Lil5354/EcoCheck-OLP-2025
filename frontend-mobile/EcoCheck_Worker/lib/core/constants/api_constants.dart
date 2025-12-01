import 'dart:io';
import 'package:flutter/foundation.dart';

/// API Configuration and Endpoints
class ApiConstants {
  ApiConstants._();

  // Base URL - Railway Production
  static const String baseUrl =
      'https://ecocheck-olp-2025-production.up.railway.app';

  // Development Base URL - Platform specific
  static String get devBaseUrl {
    if (kDebugMode) {
      // Android emulator uses 10.0.2.2 to access host machine
      if (!kIsWeb && Platform.isAndroid) {
        return 'http://10.0.2.2:3000';
      }
      // iOS simulator and macOS can use localhost
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
  static const String activeRoute = '$apiPrefix/routes/active';
  static String routeDetail(String id) => '$apiPrefix/routes/$id';
  static String startRoute(String id) => '$apiPrefix/routes/$id/start';
  static String completeRoute(String id) => '$apiPrefix/routes/$id/complete';

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
  static const String wsBaseUrl = 'wss://ecocheck-olp-2025-production.up.railway.app';
  static const String wsTracking = '/tracking';

  // Google Maps API
  static const String googleMapsApiKey =
      'YOUR_GOOGLE_MAPS_API_KEY'; // TODO: Add key

  /// Get full URL
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

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
