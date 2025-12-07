/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck User
 */

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule_model.dart';
import '../../core/constants/api_constants.dart';

/// Repository cho Schedule - kết nối với backend API
class ScheduleRepository {
  final SharedPreferences _prefs;
  final Dio _dio;

  ScheduleRepository(this._prefs, this._dio);

  String? get _userId => _prefs.getString('user_id');

  /// Lấy tất cả schedules của user
  Future<List<ScheduleModel>> getAllSchedules() async {
    if (_userId == null) {
      throw Exception('User ID not found. Please login again.');
    }

    try {
      // Note: Backend doesn't have a direct endpoint for user schedules
      // We'll need to filter by citizen_id on the client side or add endpoint
      // For now, using mock data fallback
      return [];
    } catch (e) {
      throw Exception('Failed to get schedules: ${e.toString()}');
    }
  }

  /// Tạo schedule mới
  Future<ScheduleModel> createSchedule({
    required DateTime scheduledDate,
    required String timeSlot,
    required String wasteType,
    required double estimatedWeight,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    if (_userId == null) {
      throw Exception('User ID not found. Please login again.');
    }

    try {
      final response = await _dio.post(
        ApiConstants.schedulesUrl,
        data: {
          'citizen_id': _userId,
          'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
          'time_slot': timeSlot,
          'waste_type': wasteType,
          'estimated_weight': estimatedWeight,
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
        },
      );

      if (response.data['ok'] == true && response.data['data'] != null) {
        // Map backend response to ScheduleModel
        final data = response.data['data'];
        return ScheduleModel(
          id: data['id'],
          citizenId: data['citizen_id'],
          scheduledDate: DateTime.parse(data['scheduled_date']),
          timeSlot: data['time_slot'],
          wasteType: data['waste_type'],
          estimatedWeight: data['estimated_weight_kg']?.toDouble() ?? estimatedWeight,
          latitude: data['latitude']?.toDouble() ?? latitude,
          longitude: data['longitude']?.toDouble() ?? longitude,
          address: data['address'] ?? address,
          status: data['status'] ?? 'scheduled',
          priority: (data['priority'] as num?)?.toInt() ?? 0,
          createdAt: DateTime.parse(data['created_at']),
          updatedAt: data['updated_at'] != null 
              ? DateTime.parse(data['updated_at']) 
              : DateTime.now(),
        );
      } else {
        throw Exception(response.data['error'] ?? 'Tạo lịch thất bại');
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['error'] ?? 'Lỗi kết nối');
      }
      throw Exception(e.toString());
    }
  }

  /// Hủy schedule
  Future<void> cancelSchedule(String scheduleId) async {
    try {
      final response = await _dio.delete(
        ApiConstants.deleteSchedule(scheduleId),
      );

      if (response.data['ok'] != true) {
        throw Exception(response.data['error'] ?? 'Hủy lịch thất bại');
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['error'] ?? 'Lỗi kết nối');
      }
      throw Exception(e.toString());
    }
  }
}

