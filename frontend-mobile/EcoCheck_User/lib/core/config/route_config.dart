/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck User
 */
/// Route Names
class AppRoutes {
  AppRoutes._();

  // Root
  static const String splash = '/';
  static const String onboarding = '/onboarding';

  // Auth
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyOtp = '/verify-otp';

  // Main
  static const String home = '/home';
  static const String main = '/main';

  // Schedule
  static const String schedules = '/schedules';
  static const String createSchedule = '/schedules/create';
  static const String scheduleDetail = '/schedules/:id';
  static const String editSchedule = '/schedules/:id/edit';

  // Tracking
  static const String liveTracking = '/tracking';
  static const String trackSchedule = '/tracking/:scheduleId';

  // Statistics
  static const String statistics = '/statistics';
  static const String achievements = '/statistics/achievements';
  static const String leaderboard = '/statistics/leaderboard';

  // Notifications
  static const String notifications = '/notifications';
  static const String notificationDetail = '/notifications/:id';

  // Profile
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String settings = '/settings';
  static const String about = '/about';
  static const String help = '/help';
  static const String feedback = '/feedback';

  /// Generate route path with parameters
  static String scheduleDetailPath(String id) => '/schedules/$id';
  static String editSchedulePath(String id) => '/schedules/$id/edit';
  static String trackSchedulePath(String id) => '/tracking/$id';
  static String notificationDetailPath(String id) => '/notifications/$id';
}
