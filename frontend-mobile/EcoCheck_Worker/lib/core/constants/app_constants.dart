/// App-wide Constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'EcoCheck Worker';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  // Storage Keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyUserData = 'user_data';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyLanguage = 'language';
  static const String keyThemeMode = 'theme_mode';
  static const String keyFirstLaunch = 'first_launch';
  static const String keyFCMToken = 'fcm_token';
  static const String keyNotificationsEnabled = 'notifications_enabled';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int phoneNumberLength = 10;
  static const int otpLength = 6;

  // Time Slots
  static const String timeSlotMorning = 'morning';
  static const String timeSlotAfternoon = 'afternoon';
  static const String timeSlotEvening = 'evening';

  static const List<String> timeSlots = [
    timeSlotMorning,
    timeSlotAfternoon,
    timeSlotEvening,
  ];

  static const Map<String, String> timeSlotRanges = {
    timeSlotMorning: '6:00 - 10:00',
    timeSlotAfternoon: '13:00 - 17:00',
    timeSlotEvening: '18:00 - 20:00',
  };

  // Waste Types
  static const String wasteTypeOrganic = 'organic';
  static const String wasteTypeRecyclable = 'recyclable';
  static const String wasteTypeHazardous = 'hazardous';
  static const String wasteTypeGeneral = 'general';
  static const String wasteTypeElectronic = 'electronic';

  static const List<String> wasteTypes = [
    wasteTypeOrganic,
    wasteTypeRecyclable,
    wasteTypeHazardous,
    wasteTypeGeneral,
    wasteTypeElectronic,
  ];

  // Schedule Status
  static const String statusPending = 'pending';
  static const String statusScheduled = 'scheduled'; // Đã lên lịch thành công
  static const String statusConfirmed =
      'confirmed'; // Legacy, use statusScheduled instead
  static const String statusAssigned = 'assigned';
  static const String statusInProgress = 'in_progress';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  static const List<String> scheduleStatuses = [
    statusPending,
    statusScheduled,
    statusConfirmed,
    statusAssigned,
    statusInProgress,
    statusCompleted,
    statusCancelled,
  ];

  // Route Status
  static const String routeStatusPending = 'pending';
  static const String routeStatusActive = 'active';
  static const String routeStatusCompleted = 'completed';

  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String apiDateFormat = 'yyyy-MM-dd';
  static const String apiDateTimeFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'";

  // Map Settings
  static const double defaultMapZoom = 15.0;
  static const double defaultMapBearing = 0.0;
  static const double defaultMapTilt = 0.0;
  static const double trackingUpdateInterval = 30.0; // seconds

  // Image Settings
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int imageQuality = 80;
  static const double maxImageWidth = 1920;
  static const double maxImageHeight = 1080;

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Debounce & Throttle
  static const Duration searchDebounce = Duration(milliseconds: 500);
  static const Duration buttonThrottle = Duration(milliseconds: 1000);

  // Network
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Cache
  static const Duration cacheExpiry = Duration(hours: 1);
  static const int maxCacheSize = 100;

  // Regular Expressions
  static final RegExp phoneRegex = RegExp(r'^0[0-9]{9}$');
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
  );

  // Error Messages
  static const String errorGeneric = 'Có lỗi xảy ra, vui lòng thử lại';
  static const String errorNetwork = 'Không có kết nối mạng';
  static const String errorServer = 'Lỗi máy chủ, vui lòng thử lại sau';
  static const String errorTimeout = 'Hết thời gian kết nối';
  static const String errorUnauthorized = 'Phiên đăng nhập hết hạn';

  // Support
  static const String supportEmail = 'support@ecocheck.vn';
  static const String supportPhone = '1900-xxxx';
  static const String websiteUrl = 'https://ecocheck.vn';
  static const String facebookUrl = 'https://facebook.com/ecocheck';
  static const String termsUrl = 'https://ecocheck.vn/terms';
  static const String privacyUrl = 'https://ecocheck.vn/privacy';
}
