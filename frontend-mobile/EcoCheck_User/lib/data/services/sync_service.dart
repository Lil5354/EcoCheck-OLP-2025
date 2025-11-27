import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/ecocheck_repository.dart';
import '../models/user_model.dart';
import '../models/auth_token_model.dart';

/// Sync Service - Đồng bộ dữ liệu user giữa app và backend
class SyncService {
  final EcoCheckRepository _repository;
  final SharedPreferences _prefs;

  // Keys for SharedPreferences
  static const String _keyAuthToken = 'auth_token';
  static const String _keyUserData = 'user_data';
  static const String _keyDeviceInfo = 'device_info';
  static const String _keyUserSettings = 'user_settings';
  static const String _keyLastSync = 'last_sync_timestamp';
  static const String _keyUserId = 'user_id';

  // Sync interval (30 minutes)
  static const Duration _syncInterval = Duration(minutes: 30);

  Timer? _syncTimer;
  bool _isSyncing = false;

  SyncService({
    required EcoCheckRepository repository,
    required SharedPreferences prefs,
  }) : _repository = repository,
       _prefs = prefs;

  // ==================== Auth Token Management ====================

  /// Save auth token
  Future<void> saveAuthToken(AuthTokenModel token) async {
    await _prefs.setString(_keyAuthToken, jsonEncode(token.toJson()));
    print('🔐 [SYNC] Auth token saved');
  }

  /// Get auth token
  AuthTokenModel? getAuthToken() {
    final tokenJson = _prefs.getString(_keyAuthToken);
    if (tokenJson == null) return null;

    try {
      final tokenData = jsonDecode(tokenJson) as Map<String, dynamic>;
      return AuthTokenModel.fromJson(tokenData);
    } catch (e) {
      print('⚠️ [SYNC] Error parsing auth token: $e');
      return null;
    }
  }

  /// Clear auth token
  Future<void> clearAuthToken() async {
    await _prefs.remove(_keyAuthToken);
    print('🔐 [SYNC] Auth token cleared');
  }

  /// Check if token is valid
  bool isTokenValid() {
    final token = getAuthToken();
    return token != null && !token.isExpired;
  }

  /// Check if token needs refresh
  bool shouldRefreshToken() {
    final token = getAuthToken();
    return token != null && token.willExpireSoon;
  }

  // ==================== User Data Management ====================

  /// Save user data to local storage
  Future<void> saveUserData(UserModel user) async {
    await _prefs.setString(_keyUserData, jsonEncode(user.toJson()));
    await _prefs.setString(_keyUserId, user.id);
    print('👤 [SYNC] User data saved locally: ${user.fullName}');
  }

  /// Get user data from local storage
  UserModel? getCachedUserData() {
    final userJson = _prefs.getString(_keyUserData);
    if (userJson == null) return null;

    try {
      final userData = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(userData);
    } catch (e) {
      print('⚠️ [SYNC] Error parsing user data: $e');
      return null;
    }
  }

  /// Get cached user ID
  String? getCachedUserId() {
    return _prefs.getString(_keyUserId);
  }

  /// Sync user data from backend
  Future<UserModel?> syncUserData({bool force = false}) async {
    if (_isSyncing && !force) {
      print('⏳ [SYNC] Already syncing, skipping...');
      return null;
    }

    _isSyncing = true;

    try {
      final userId = getCachedUserId();
      if (userId == null) {
        print('⚠️ [SYNC] No user ID found, cannot sync');
        return null;
      }

      print('🔄 [SYNC] Syncing user data for: $userId');

      // Fetch fresh data from backend
      final user = await _repository.getCurrentUser(userId);

      // Save to local storage
      await saveUserData(user);
      await _updateLastSyncTime();

      print('✅ [SYNC] User data synced successfully');
      return user;
    } catch (e) {
      print('❌ [SYNC] Error syncing user data: $e');

      // Return cached data if sync fails
      return getCachedUserData();
    } finally {
      _isSyncing = false;
    }
  }

  // ==================== Device Management ====================

  /// Save device info
  Future<void> saveDeviceInfo(DeviceInfoModel device) async {
    await _prefs.setString(_keyDeviceInfo, jsonEncode(device.toJson()));
    print('📱 [SYNC] Device info saved: ${device.deviceName}');
  }

  /// Get device info
  DeviceInfoModel? getDeviceInfo() {
    final deviceJson = _prefs.getString(_keyDeviceInfo);
    if (deviceJson == null) return null;

    try {
      final deviceData = jsonDecode(deviceJson) as Map<String, dynamic>;
      return DeviceInfoModel.fromJson(deviceData);
    } catch (e) {
      print('⚠️ [SYNC] Error parsing device info: $e');
      return null;
    }
  }

  // ==================== User Settings Management ====================

  /// Save user settings
  Future<void> saveUserSettings(UserSettingsModel settings) async {
    await _prefs.setString(_keyUserSettings, jsonEncode(settings.toJson()));
    print('⚙️ [SYNC] User settings saved');
  }

  /// Get user settings
  UserSettingsModel getUserSettings() {
    final settingsJson = _prefs.getString(_keyUserSettings);
    if (settingsJson == null) return const UserSettingsModel();

    try {
      final settingsData = jsonDecode(settingsJson) as Map<String, dynamic>;
      return UserSettingsModel.fromJson(settingsData);
    } catch (e) {
      print('⚠️ [SYNC] Error parsing settings: $e');
      return const UserSettingsModel();
    }
  }

  // ==================== Automatic Sync ====================

  /// Start automatic sync
  void startAutoSync() {
    stopAutoSync(); // Stop existing timer if any

    _syncTimer = Timer.periodic(_syncInterval, (timer) {
      print('⏰ [SYNC] Auto-sync triggered');
      syncUserData();
    });

    print(
      '🔄 [SYNC] Auto-sync started (interval: ${_syncInterval.inMinutes}m)',
    );
  }

  /// Stop automatic sync
  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    print('⏹️ [SYNC] Auto-sync stopped');
  }

  /// Check if should sync based on last sync time
  bool shouldSync() {
    final lastSyncStr = _prefs.getString(_keyLastSync);
    if (lastSyncStr == null) return true;

    try {
      final lastSync = DateTime.parse(lastSyncStr);
      final nextSync = lastSync.add(_syncInterval);
      return DateTime.now().isAfter(nextSync);
    } catch (e) {
      return true;
    }
  }

  /// Update last sync timestamp
  Future<void> _updateLastSyncTime() async {
    await _prefs.setString(_keyLastSync, DateTime.now().toIso8601String());
  }

  /// Get last sync time
  DateTime? getLastSyncTime() {
    final lastSyncStr = _prefs.getString(_keyLastSync);
    if (lastSyncStr == null) return null;

    try {
      return DateTime.parse(lastSyncStr);
    } catch (e) {
      return null;
    }
  }

  // ==================== Clear All Data ====================

  /// Clear all synced data (for logout)
  Future<void> clearAllData() async {
    await Future.wait([
      _prefs.remove(_keyAuthToken),
      _prefs.remove(_keyUserData),
      _prefs.remove(_keyDeviceInfo),
      _prefs.remove(_keyUserSettings),
      _prefs.remove(_keyLastSync),
      _prefs.remove(_keyUserId),
    ]);

    stopAutoSync();
    print('🗑️ [SYNC] All synced data cleared');
  }

  // ==================== Helper Methods ====================

  /// Check if user is logged in (has valid token and user data)
  bool isLoggedIn() {
    return isTokenValid() && getCachedUserId() != null;
  }

  /// Get sync status info
  Map<String, dynamic> getSyncStatus() {
    return {
      'is_logged_in': isLoggedIn(),
      'token_valid': isTokenValid(),
      'should_refresh': shouldRefreshToken(),
      'last_sync': getLastSyncTime()?.toIso8601String(),
      'should_sync': shouldSync(),
      'user_id': getCachedUserId(),
    };
  }

  /// Dispose resources
  void dispose() {
    stopAutoSync();
  }
}
