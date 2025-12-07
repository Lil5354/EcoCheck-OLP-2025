/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck User - API Configuration and Endpoints
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
  static const String login = '$apiPrefix/auth/login';
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

  // Schedule Endpoints
  static const String schedules = '$apiPrefix/schedules';
  static String scheduleDetail(String id) => '$apiPrefix/schedules/$id';
  static String updateSchedule(String id) => '$apiPrefix/schedules/$id';
  static String deleteSchedule(String id) => '$apiPrefix/schedules/$id';

  // Tracking Endpoints
  static const String trackRoute = '$apiPrefix/tracking/route';
  static String trackSchedule(String scheduleId) =>
      '$apiPrefix/tracking/schedule/$scheduleId';

  // Notification Endpoints
  static const String notifications = '$apiPrefix/notifications';
  static String markNotificationRead(String id) =>
      '$apiPrefix/notifications/$id/read';
  static const String markAllRead = '$apiPrefix/notifications/mark-all-read';
  static const String subscribeFCM = '$apiPrefix/notifications/subscribe';

  // Statistics Endpoints
  static const String personalStats = '$apiPrefix/citizen/statistics';
  static const String monthlyStats = '$apiPrefix/citizen/statistics/monthly';
  static const String leaderboard = '$apiPrefix/citizen/leaderboard';

  // Feedback Endpoints
  static const String feedback = '$apiPrefix/citizen/feedback';

  // File Upload
  static const String uploadFile = '$apiPrefix/upload';
  static const String uploadImage = '$apiPrefix/upload/image';

  // WebSocket
  static const String wsBaseUrl = 'wss://ecocheck-olp-2025.onrender.com';
  static const String wsTracking = '/tracking';

  // Google Maps API
  static const String googleMapsApiKey =
      'YOUR_GOOGLE_MAPS_API_KEY'; // TODO: Add key

  // Firebase
  static const String firebaseProjectId = 'eco-check-vn'; // TODO: Update

  /// Get full URL
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  // Alias methods for backward compatibility
  static String get loginUrl => login;
  static String get registerUrl => register;
  static String get profileUrl => profile;
  static String get schedulesUrl => schedules;

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
