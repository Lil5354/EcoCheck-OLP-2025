/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck User
 */

import '../models/api_models.dart';
import '../models/gamification_model.dart';
import '../models/schedule_model.dart';
import '../models/user_model.dart';
import '../models/statistics_model.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';

/// EcoCheck API Repository
class EcoCheckRepository {
  final ApiClient _apiClient;

  EcoCheckRepository(this._apiClient);

  // ==================== Authentication ====================

  /// Login with phone and password
  Future<UserModel> login({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.apiPrefix}/auth/login',
        data: {'phone': phone, 'password': password},
      );

      final data = response.data as Map<String, dynamic>;
      if (data['ok'] == true) {
        return UserModel.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw ApiException(message: data['error'] ?? 'Login failed');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Register new user
  Future<UserModel> register({
    required String phone,
    required String password,
    String? email,
    String? fullName,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.apiPrefix}/auth/register',
        data: {
          'phone': phone,
          'password': password,
          if (email != null) 'email': email,
          if (fullName != null) 'fullName': fullName,
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (data['ok'] == true) {
        return UserModel.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw ApiException(message: data['error'] ?? 'Registration failed');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get current user profile
  Future<UserModel> getCurrentUser(String userId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.apiPrefix}/auth/me',
        queryParameters: {'user_id': userId},
      );

      final data = response.data as Map<String, dynamic>;
      if (data['ok'] == true) {
        return UserModel.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw ApiException(message: data['error'] ?? 'Failed to get user');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Health & Status ====================

  /// Check backend health
  Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await _apiClient.get('/health');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get API status
  Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await _apiClient.get(ApiConstants.apiPrefix + '/status');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Alerts ====================

  /// Get all alerts
  Future<List<Alert>> getAlerts() async {
    try {
      final response = await _apiClient.get(ApiConstants.apiPrefix + '/alerts');

      final apiResponse = ApiResponse<List<Alert>>.fromJson(
        response.data as Map<String, dynamic>,
        (data) {
          if (data is List) {
            return data
                .map((item) => Alert.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          return <Alert>[];
        },
      );

      return apiResponse.data ?? [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Dispatch vehicle for alert
  Future<List<Vehicle>> dispatchAlert(String alertId) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.apiPrefix}/alerts/$alertId/dispatch',
      );

      final apiResponse = ApiResponse<List<Vehicle>>.fromJson(
        response.data as Map<String, dynamic>,
        (data) {
          if (data is List) {
            return data
                .map((item) => Vehicle.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          return <Vehicle>[];
        },
      );

      return apiResponse.data ?? [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Assign vehicle to alert
  Future<Map<String, dynamic>> assignVehicleToAlert(
    String alertId,
    String vehicleId,
  ) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.apiPrefix}/alerts/$alertId/assign',
        data: {'vehicle_id': vehicleId},
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Real-time Data ====================

  /// Get check-in points
  Future<List<CheckinPoint>> getCheckins({int count = 30}) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.apiPrefix}/rt/checkins',
        queryParameters: {'n': count},
      );

      final apiResponse = ApiResponse<List<CheckinPoint>>.fromJson(
        response.data as Map<String, dynamic>,
        (data) {
          if (data is List) {
            return data
                .map(
                  (item) => CheckinPoint.fromJson(item as Map<String, dynamic>),
                )
                .toList();
          }
          return <CheckinPoint>[];
        },
      );

      return apiResponse.data ?? [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get real-time points
  Future<Map<String, dynamic>> getRealTimePoints({
    List<double>? bbox,
    int? since,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (bbox != null && bbox.length == 4) {
        queryParams['bbox'] = bbox.join(',');
      }
      if (since != null) {
        queryParams['since'] = since;
      }

      final response = await _apiClient.get(
        '${ApiConstants.apiPrefix}/rt/points',
        queryParameters: queryParams,
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get real-time vehicles
  Future<List<Vehicle>> getRealTimeVehicles() async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.apiPrefix}/rt/vehicles',
      );

      final apiResponse = ApiResponse<List<Vehicle>>.fromJson(
        response.data as Map<String, dynamic>,
        (data) {
          if (data is List) {
            return data
                .map((item) => Vehicle.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          return <Vehicle>[];
        },
      );

      return apiResponse.data ?? [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Post check-in
  Future<CheckinResponse> postCheckin(CheckinRequest request) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.apiPrefix}/rt/checkin',
        data: request.toJson(),
      );

      return CheckinResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Fleet Management ====================

  /// Get fleet vehicles
  Future<List<Vehicle>> getFleet() async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.apiPrefix}/master/fleet',
      );

      final apiResponse = ApiResponse<List<Vehicle>>.fromJson(
        response.data as Map<String, dynamic>,
        (data) {
          if (data is List) {
            return data
                .map((item) => Vehicle.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          return <Vehicle>[];
        },
      );

      return apiResponse.data ?? [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Create new vehicle
  Future<Vehicle> createVehicle(Map<String, dynamic> vehicleData) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.apiPrefix}/master/fleet',
        data: vehicleData,
      );

      final apiResponse = ApiResponse<Vehicle>.fromJson(
        response.data as Map<String, dynamic>,
        (data) => Vehicle.fromJson(data as Map<String, dynamic>),
      );

      return apiResponse.data!;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Collection Points ====================

  /// Get collection points
  Future<List<CollectionPoint>> getCollectionPoints() async {
    try {
      final response = await _apiClient.get('${ApiConstants.apiPrefix}/points');

      final apiResponse = ApiResponse<List<CollectionPoint>>.fromJson(
        response.data as Map<String, dynamic>,
        (data) {
          if (data is List) {
            return data
                .map(
                  (item) =>
                      CollectionPoint.fromJson(item as Map<String, dynamic>),
                )
                .toList();
          }
          return <CollectionPoint>[];
        },
      );

      return apiResponse.data ?? [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Analytics ====================

  /// Get analytics summary
  Future<AnalyticsSummary> getAnalyticsSummary() async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.apiPrefix}/analytics/summary',
      );

      final apiResponse = ApiResponse<AnalyticsSummary>.fromJson(
        response.data as Map<String, dynamic>,
        (data) => AnalyticsSummary.fromJson(data as Map<String, dynamic>),
      );

      return apiResponse.data!;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get time series data
  Future<Map<String, dynamic>> getTimeSeries() async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.apiPrefix}/analytics/timeseries',
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get predictions
  Future<Map<String, dynamic>> getPredictions({int days = 7}) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.apiPrefix}/analytics/predict',
        queryParameters: {'days': days},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== User & Gamification ====================

  /// Get user statistics
  Future<UserStatisticsModel> getUserStatistics(String userId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.apiPrefix}/gamification/stats/$userId',
      );

      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'] as Map<String, dynamic>;

      // Map backend response to UserStatisticsModel
      return UserStatisticsModel(
        userId: userId,
        totalPoints: data['totalPoints'] ?? data['total_points'] ?? 0,
        totalCheckins: data['totalCheckins'] ?? data['total_checkins'] ?? 0,
        totalWasteCollected:
            double.tryParse(
              data['totalWasteCollected']?.toString() ??
                  data['total_waste_collected']?.toString() ??
                  '0.0',
            ) ??
            0.0,
        rank: int.tryParse(data['rank']?.toString() ?? '0') ?? 0,
        totalUsers:
            int.tryParse(
              data['totalUsers']?.toString() ??
                  data['total_users']?.toString() ??
                  '0',
            ) ??
            0,
        rankTier: data['rankTier'] ?? data['rank_tier'] ?? 'Người mới',
        currentStreak: data['streakDays'] ?? data['streak_days'] ?? 0,
        longestStreak:
            data['longestStreak'] ??
            data['longest_streak'] ??
            data['streakDays'] ??
            data['streak_days'] ??
            0,
        badges:
            (data['badges'] as List<dynamic>?)
                ?.map(
                  (badge) => BadgeModel.fromJson(badge as Map<String, dynamic>),
                )
                .toList() ??
            [],
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get leaderboard
  Future<List<LeaderboardEntryModel>> getLeaderboard({
    int limit = 20,
    String period = 'all',
    String? userId,
  }) async {
    try {
      final queryParams = {'limit': limit.toString(), 'period': period};
      if (userId != null) {
        queryParams['user_id'] = userId;
      }

      final response = await _apiClient.get(
        '${ApiConstants.apiPrefix}/gamification/leaderboard',
        queryParameters: queryParams,
      );

      final responseData = response.data as Map<String, dynamic>;
      final items = responseData['data'] as List<dynamic>?;

      if (items != null) {
        return items.map((item) {
          final itemMap = item as Map<String, dynamic>;
          return LeaderboardEntryModel(
            userId: itemMap['userId'] ?? '',
            userName: itemMap['userName'] ?? 'User',
            avatarUrl: itemMap['avatarUrl'],
            rank: itemMap['rank'] ?? 0,
            points: itemMap['points'] ?? 0,
            checkins: 0, // Not provided by backend
            wasteCollected: 0.0, // Not provided by backend
            rankTier:
                itemMap['rankTier'] ?? itemMap['rank_tier'] ?? 'Người mới',
            isCurrentUser: itemMap['isCurrentUser'] ?? false,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get user badges
  Future<List<BadgeModel>> getUserBadges(String userId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.apiPrefix}/citizen/badges',
        queryParameters: {'user_id': userId},
      );

      final data = response.data as Map<String, dynamic>;
      final items = data['data'] ?? data['badges'] ?? [];

      if (items is List) {
        return items
            .map((item) => BadgeModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get user notifications
  Future<List<NotificationModel>> getNotifications({
    bool unreadOnly = false,
    int limit = 50,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.notifications,
        queryParameters: {'unread_only': unreadOnly, 'limit': limit},
      );

      final data = response.data as Map<String, dynamic>;
      final items = data['data'] ?? data['notifications'] ?? [];

      if (items is List) {
        return items
            .map(
              (item) =>
                  NotificationModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Mark notification as read
  Future<void> markNotificationRead(String notificationId) async {
    try {
      await _apiClient.patch(ApiConstants.markNotificationRead(notificationId));
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Submit feedback
  Future<void> submitFeedback({
    required String subject,
    required String message,
    String? category,
  }) async {
    try {
      await _apiClient.post(
        ApiConstants.feedback,
        data: {'subject': subject, 'message': message, 'category': category},
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Schedule API ====================

  /// Get schedules with optional filters
  Future<List<ScheduleModel>> getSchedules({
    String? citizenId,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      if (citizenId != null) queryParams['citizen_id'] = citizenId;
      if (status != null) queryParams['status'] = status;

      final response = await _apiClient.get(
        '${ApiConstants.apiPrefix}/schedules',
        queryParameters: queryParams,
      );

      final data = response.data;

      // Handle different response formats
      if (data is String) {
        // Backend returned error string instead of JSON
        print('Warning: Backend returned string instead of JSON: $data');
        return [];
      }

      if (data is Map<String, dynamic> && data['data'] is List) {
        final schedules = (data['data'] as List)
            .where((item) => item is Map<String, dynamic>)
            .map((item) => ScheduleModel.fromJson(item as Map<String, dynamic>))
            .toList();
        return schedules;
      } else if (data is List) {
        // Fallback: if response.data is the list directly
        return data
            .where((item) => item is Map<String, dynamic>)
            .map((item) => ScheduleModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        print('Warning: Unexpected response format: ${data.runtimeType}');
        return [];
      }
    } catch (e) {
      print('Error in getSchedules: $e');
      throw _handleError(e);
    }
  }

  /// Get schedule by ID
  Future<ScheduleModel> getScheduleById(String scheduleId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.apiPrefix}/schedules/$scheduleId',
      );

      final data = response.data;

      if (data is String) {
        print('Error getting schedule: $data');
        throw ApiException(message: data);
      }

      if (data is Map<String, dynamic> && data['data'] != null) {
        return ScheduleModel.fromJson(data['data'] as Map<String, dynamic>);
      } else if (data is Map<String, dynamic>) {
        return ScheduleModel.fromJson(data);
      } else {
        throw Exception('Invalid response format: ${data.runtimeType}');
      }
    } catch (e) {
      print('Error in getScheduleById: $e');
      throw _handleError(e);
    }
  }

  /// Update schedule status
  Future<ScheduleModel> updateSchedule({
    required String scheduleId,
    String? status,
    String? employeeId,
    double? actualWeight,
    String? notes,
  }) async {
    try {
      final requestData = <String, dynamic>{};

      if (status != null) requestData['status'] = status;
      if (employeeId != null) requestData['employee_id'] = employeeId;
      if (actualWeight != null) requestData['actual_weight'] = actualWeight;
      if (notes != null) requestData['notes'] = notes;

      final response = await _apiClient.patch(
        '${ApiConstants.apiPrefix}/schedules/$scheduleId',
        data: requestData,
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return ScheduleModel.fromJson(data['data'] as Map<String, dynamic>);
      } else if (data is Map<String, dynamic>) {
        return ScheduleModel.fromJson(data);
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Cancel schedule
  Future<ScheduleModel> cancelSchedule(String scheduleId) async {
    try {
      final response = await _apiClient.patch(
        '${ApiConstants.apiPrefix}/schedules/$scheduleId/cancel',
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return ScheduleModel.fromJson(data['data'] as Map<String, dynamic>);
      } else if (data is Map<String, dynamic>) {
        return ScheduleModel.fromJson(data);
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete schedule
  Future<void> deleteSchedule(String scheduleId) async {
    try {
      await _apiClient.delete(
        '${ApiConstants.apiPrefix}/schedules/$scheduleId',
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Statistics ====================

  /// Get Statistics Summary for User
  Future<StatisticsSummary> getStatisticsSummary(String userId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.apiPrefix}/users/$userId/statistics/summary',
      );

      final data = response.data as Map<String, dynamic>;
      if (data['ok'] == true && data['data'] != null) {
        return StatisticsSummary.fromJson(data['data'] as Map<String, dynamic>);
      } else if (data['data'] != null) {
        return StatisticsSummary.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        return StatisticsSummary.fromJson(data);
      }
    } catch (e) {
      print('Error in getStatisticsSummary: $e');
      // Return empty/default data if backend doesn't have this endpoint yet
      if (e.toString().contains('404') || e.toString().contains('not found')) {
        print('Statistics API not available yet, returning default data');
        return const StatisticsSummary(
          totalWasteThisMonth: 0,
          totalCO2SavedThisMonth: 0,
          monthlyData: [],
          wasteDistribution: [],
        );
      }
      throw _handleError(e);
    }
  }

  // ==================== Schedules ====================

  /// Create collection schedule
  Future<ScheduleModel> createSchedule({
    required String citizenId,
    required DateTime scheduledDate,
    required String timeSlot,
    required String wasteType,
    required double estimatedWeight,
    required String address,
    required double latitude,
    required double longitude,
    String? notes,
    List<String>? photoUrls,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.apiPrefix}/schedules',
        data: {
          'citizen_id': citizenId,
          'scheduled_date': scheduledDate.toIso8601String(),
          'time_slot': timeSlot,
          'waste_type': wasteType,
          'estimated_weight': estimatedWeight,
          'address': address,
          'latitude': latitude,
          'longitude': longitude,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          if (photoUrls != null && photoUrls.isNotEmpty)
            'photo_urls': photoUrls,
          'status': 'pending',
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (data['ok'] == true) {
        return ScheduleModel.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw ApiException(
          message: data['error'] ?? 'Failed to create schedule',
        );
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get user's schedules
  Future<List<ScheduleModel>> getUserSchedules(String userId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.apiPrefix}/schedules/citizen/$userId',
      );

      final data = response.data as Map<String, dynamic>;
      if (data['ok'] == true && data['data'] is List) {
        return (data['data'] as List)
            .map((item) => ScheduleModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      if (e.toString().contains('404')) {
        return [];
      }
      throw _handleError(e);
    }
  }

  // ==================== Incidents/Reports ====================

  /// Create incident report
  Future<Map<String, dynamic>> createIncident({
    required String reporterId,
    String? reporterName,
    String? reporterPhone,
    required String reportCategory, // 'violation' or 'damage'
    required String type,
    required String description,
    double? latitude,
    double? longitude,
    String? locationAddress,
    required List<String> imageUrls,
    String priority = 'medium',
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.apiPrefix}/incidents',
        data: {
          'reporter_id': reporterId,
          'reporter_name': reporterName,
          'reporter_phone': reporterPhone,
          'report_category': reportCategory,
          'type': type,
          'description': description,
          'latitude': latitude,
          'longitude': longitude,
          'location_address': locationAddress,
          'image_urls': imageUrls,
          'priority': priority,
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (data['ok'] == true) {
        return data['data'] as Map<String, dynamic>;
      } else {
        throw ApiException(
          message: data['error'] ?? 'Failed to create incident',
        );
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get user's incident reports
  Future<List<Map<String, dynamic>>> getUserIncidents(String userId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.apiPrefix}/incidents/user/$userId',
      );

      final data = response.data as Map<String, dynamic>;
      if (data['ok'] == true && data['data'] is List) {
        return List<Map<String, dynamic>>.from(data['data'] as List);
      } else {
        return [];
      }
    } catch (e) {
      if (e.toString().contains('404')) {
        return [];
      }
      throw _handleError(e);
    }
  }

  // ==================== Error Handling ====================

  Exception _handleError(dynamic error) {
    if (error is ApiException) {
      return error;
    }
    return ApiException(message: error.toString());
  }
}
