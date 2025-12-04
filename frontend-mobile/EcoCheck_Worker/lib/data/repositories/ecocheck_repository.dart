import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/user_model.dart';
import '../models/schedule_model.dart';

/// EcoCheck API Repository for Worker App
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
        ApiConstants.login,
        data: {'phone': phone, 'password': password},
      );

      final data = response.data as Map<String, dynamic>;
      if (data['ok'] == true) {
        // Set auth token
        final token = data['data']['access_token'] as String?;
        if (token != null) {
          _apiClient.setAuthToken(token);
        }

        return UserModel.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw ApiException(message: data['error'] ?? 'Login failed');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiConstants.logout);
      _apiClient.clearAuthToken();
    } catch (e) {
      // Even if logout fails, clear local token
      _apiClient.clearAuthToken();
    }
  }

  // ==================== Schedules (Worker specific) ====================

  /// Get assigned schedules for worker
  Future<List<ScheduleModel>> getAssignedSchedules({
    String? status,
    int? page,
    int? limit,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.assignedSchedules,
        queryParameters: {
          if (status != null) 'status': status,
          if (page != null) 'page': page,
          if (limit != null) 'limit': limit,
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (data['ok'] == true) {
        final schedules = (data['data'] as List)
            .map((json) => ScheduleModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return schedules;
      } else {
        throw ApiException(message: data['error'] ?? 'Failed to get schedules');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get schedule detail
  Future<ScheduleModel> getScheduleDetail(String scheduleId) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.scheduleDetail(scheduleId),
      );

      final data = response.data as Map<String, dynamic>;
      if (data['ok'] == true) {
        return ScheduleModel.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw ApiException(message: data['error'] ?? 'Failed to get schedule');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Start schedule (change status to in_progress)
  Future<ScheduleModel> startSchedule(String scheduleId) async {
    try {
      final response = await _apiClient.patch(
        ApiConstants.updateSchedule(scheduleId),
        data: {'status': 'in_progress'},
      );

      final data = response.data as Map<String, dynamic>;
      if (data['ok'] == true) {
        return ScheduleModel.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw ApiException(
          message: data['error'] ?? 'Failed to start schedule',
        );
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Complete schedule
  Future<ScheduleModel> completeSchedule({
    required String scheduleId,
    required double actualWeight,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.completeSchedule(scheduleId),
        data: {
          'actual_weight': actualWeight,
          'status': 'completed',
          if (notes != null) 'notes': notes,
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (data['ok'] == true) {
        return ScheduleModel.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw ApiException(
          message: data['error'] ?? 'Failed to complete schedule',
        );
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Routes ====================

  /// Get all routes for worker (by personnel_id)
  Future<List<Map<String, dynamic>>> getWorkerRoutes(String personnelId) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.workerRoutes,
        queryParameters: {'personnel_id': personnelId},
      );

      final data = response.data as Map<String, dynamic>;
      if (data['ok'] == true) {
        final routes = data['data'] as List?;
        if (routes != null) {
          return routes.map((route) => route as Map<String, dynamic>).toList();
        }
        return [];
      } else {
        throw ApiException(message: data['error'] ?? 'Failed to get routes');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get active route for worker
  Future<Map<String, dynamic>?> getActiveRoute() async {
    try {
      final response = await _apiClient.get(ApiConstants.activeRoute);

      final data = response.data as Map<String, dynamic>;
      if (data['ok'] == true) {
        return data['data'] as Map<String, dynamic>?;
      } else {
        return null;
      }
    } catch (e) {
      // Return null if no active route
      if (e is ApiException && e.statusCode == 404) {
        return null;
      }
      throw _handleError(e);
    }
  }

  /// Get route detail
  Future<Map<String, dynamic>> getRouteDetail(String routeId) async {
    try {
      final response = await _apiClient.get(ApiConstants.routeDetail(routeId));

      final data = response.data as Map<String, dynamic>;
      if (data['ok'] == true) {
        return data['data'] as Map<String, dynamic>;
      } else {
        throw ApiException(message: data['error'] ?? 'Failed to get route');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get worker route detail with stops
  Future<Map<String, dynamic>> getWorkerRouteDetail(String routeId) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.workerRouteDetail(routeId),
      );

      final data = response.data as Map<String, dynamic>;
      if (data['ok'] == true) {
        return data['data'] as Map<String, dynamic>;
      } else {
        throw ApiException(
          message: data['error'] ?? 'Failed to get route detail',
        );
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Start route
  Future<Map<String, dynamic>> startRoute(String routeId) async {
    try {
      final response = await _apiClient.post(ApiConstants.startRoute(routeId));

      final data = response.data as Map<String, dynamic>;
      if (data['ok'] == true) {
        return data['data'] as Map<String, dynamic>;
      } else {
        throw ApiException(message: data['error'] ?? 'Failed to start route');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Start worker route
  Future<Map<String, dynamic>> startWorkerRoute(String routeId) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.startWorkerRoute(routeId),
      );

      final data = response.data as Map<String, dynamic>;
      if (data['ok'] == true) {
        return data['data'] as Map<String, dynamic>;
      } else {
        throw ApiException(message: data['error'] ?? 'Failed to start route');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Complete route
  Future<Map<String, dynamic>> completeRoute(String routeId) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.completeRoute(routeId),
      );

      final data = response.data as Map<String, dynamic>;
      if (data['ok'] == true) {
        return data['data'] as Map<String, dynamic>;
      } else {
        throw ApiException(
          message: data['error'] ?? 'Failed to complete route',
        );
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Complete worker route
  Future<Map<String, dynamic>> completeWorkerRoute({
    required String routeId,
    double? actualDistanceKm,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.completeWorkerRoute(routeId),
        data: {
          if (actualDistanceKm != null) 'actual_distance_km': actualDistanceKm,
          if (notes != null) 'notes': notes,
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (data['ok'] == true) {
        return data['data'] as Map<String, dynamic>;
      } else {
        throw ApiException(
          message: data['error'] ?? 'Failed to complete route',
        );
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Complete route stop
  Future<Map<String, dynamic>> completeRouteStop({
    required String stopId,
    double? actualWeightKg,
    List<String>? photoUrls,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.completeRouteStop(stopId),
        data: {
          if (actualWeightKg != null) 'actual_weight_kg': actualWeightKg,
          if (photoUrls != null) 'photo_urls': photoUrls,
          if (notes != null) 'notes': notes,
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (data['ok'] == true) {
        return data['data'] as Map<String, dynamic>;
      } else {
        throw ApiException(message: data['error'] ?? 'Failed to complete stop');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Skip route stop
  Future<Map<String, dynamic>> skipRouteStop({
    required String stopId,
    required String reason,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.skipRouteStop(stopId),
        data: {'reason': reason},
      );

      final data = response.data as Map<String, dynamic>;
      if (data['ok'] == true) {
        return data['data'] as Map<String, dynamic>;
      } else {
        throw ApiException(message: data['error'] ?? 'Failed to skip stop');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Location Tracking ====================

  /// Update worker location
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _apiClient.post(
        ApiConstants.updateLocation,
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // Silently fail for location updates
      print('Failed to update location: $e');
    }
  }

  // ==================== Statistics ====================

  /// Get worker statistics
  Future<Map<String, dynamic>> getWorkerStatistics() async {
    try {
      final response = await _apiClient.get(ApiConstants.workerStats);

      final data = response.data as Map<String, dynamic>;
      if (data['ok'] == true) {
        return data['data'] as Map<String, dynamic>;
      } else {
        throw ApiException(
          message: data['error'] ?? 'Failed to get statistics',
        );
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

  /// Handle errors and convert to ApiException
  ApiException _handleError(dynamic error) {
    if (error is ApiException) {
      return error;
    }
    return ApiException(message: error.toString());
  }
}
