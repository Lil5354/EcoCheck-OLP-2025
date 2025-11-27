import 'package:equatable/equatable.dart';

/// Auth Token Model - For JWT authentication
class AuthTokenModel extends Equatable {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String tokenType;

  const AuthTokenModel({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    this.tokenType = 'Bearer',
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get willExpireSoon {
    final fiveMinutesFromNow = DateTime.now().add(const Duration(minutes: 5));
    return expiresAt.isBefore(fiveMinutesFromNow);
  }

  factory AuthTokenModel.fromJson(Map<String, dynamic> json) {
    return AuthTokenModel(
      accessToken:
          json['access_token']?.toString() ??
          json['accessToken']?.toString() ??
          '',
      refreshToken:
          json['refresh_token']?.toString() ??
          json['refreshToken']?.toString() ??
          '',
      expiresAt: json['expires_at'] != null || json['expiresAt'] != null
          ? DateTime.parse(
              json['expires_at']?.toString() ??
                  json['expiresAt']?.toString() ??
                  DateTime.now()
                      .add(const Duration(hours: 24))
                      .toIso8601String(),
            )
          : DateTime.now().add(const Duration(hours: 24)),
      tokenType:
          json['token_type']?.toString() ??
          json['tokenType']?.toString() ??
          'Bearer',
    );
  }

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_at': expiresAt.toIso8601String(),
    'token_type': tokenType,
  };

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresAt, tokenType];
}

/// Device Info Model - For multi-device support
class DeviceInfoModel extends Equatable {
  final String deviceId;
  final String deviceName;
  final String platform; // ios, android, web, macos, windows, linux
  final String appVersion;
  final DateTime lastActiveAt;
  final String? fcmToken;

  const DeviceInfoModel({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.appVersion,
    required this.lastActiveAt,
    this.fcmToken,
  });

  factory DeviceInfoModel.fromJson(Map<String, dynamic> json) {
    return DeviceInfoModel(
      deviceId:
          json['device_id']?.toString() ?? json['deviceId']?.toString() ?? '',
      deviceName:
          json['device_name']?.toString() ??
          json['deviceName']?.toString() ??
          'Unknown Device',
      platform: json['platform']?.toString() ?? 'unknown',
      appVersion:
          json['app_version']?.toString() ??
          json['appVersion']?.toString() ??
          '1.0.0',
      lastActiveAt:
          json['last_active_at'] != null || json['lastActiveAt'] != null
          ? DateTime.parse(
              json['last_active_at']?.toString() ??
                  json['lastActiveAt']?.toString() ??
                  DateTime.now().toIso8601String(),
            )
          : DateTime.now(),
      fcmToken: json['fcm_token']?.toString() ?? json['fcmToken']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'device_id': deviceId,
    'device_name': deviceName,
    'platform': platform,
    'app_version': appVersion,
    'last_active_at': lastActiveAt.toIso8601String(),
    if (fcmToken != null) 'fcm_token': fcmToken,
  };

  @override
  List<Object?> get props => [
    deviceId,
    deviceName,
    platform,
    appVersion,
    lastActiveAt,
    fcmToken,
  ];
}

/// User Settings Model - Synced across devices
class UserSettingsModel extends Equatable {
  final bool notificationsEnabled;
  final bool locationTrackingEnabled;
  final String language; // vi, en
  final String theme; // light, dark, system
  final bool soundEnabled;
  final bool vibrationEnabled;
  final Map<String, dynamic> customSettings;

  const UserSettingsModel({
    this.notificationsEnabled = true,
    this.locationTrackingEnabled = true,
    this.language = 'vi',
    this.theme = 'system',
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.customSettings = const {},
  });

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      notificationsEnabled:
          json['notifications_enabled'] ?? json['notificationsEnabled'] ?? true,
      locationTrackingEnabled:
          json['location_tracking_enabled'] ??
          json['locationTrackingEnabled'] ??
          true,
      language: json['language']?.toString() ?? 'vi',
      theme: json['theme']?.toString() ?? 'system',
      soundEnabled: json['sound_enabled'] ?? json['soundEnabled'] ?? true,
      vibrationEnabled:
          json['vibration_enabled'] ?? json['vibrationEnabled'] ?? true,
      customSettings: json['custom_settings'] ?? json['customSettings'] ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'notifications_enabled': notificationsEnabled,
    'location_tracking_enabled': locationTrackingEnabled,
    'language': language,
    'theme': theme,
    'sound_enabled': soundEnabled,
    'vibration_enabled': vibrationEnabled,
    'custom_settings': customSettings,
  };

  UserSettingsModel copyWith({
    bool? notificationsEnabled,
    bool? locationTrackingEnabled,
    String? language,
    String? theme,
    bool? soundEnabled,
    bool? vibrationEnabled,
    Map<String, dynamic>? customSettings,
  }) {
    return UserSettingsModel(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      locationTrackingEnabled:
          locationTrackingEnabled ?? this.locationTrackingEnabled,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      customSettings: customSettings ?? this.customSettings,
    );
  }

  @override
  List<Object?> get props => [
    notificationsEnabled,
    locationTrackingEnabled,
    language,
    theme,
    soundEnabled,
    vibrationEnabled,
    customSettings,
  ];
}
