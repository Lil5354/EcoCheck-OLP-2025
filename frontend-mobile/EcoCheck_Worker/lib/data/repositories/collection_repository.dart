/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck Worker
 */

import 'package:shared_preferences/shared_preferences.dart';
import '../models/collection_request.dart';
import '../services/mock_data_service.dart';
import '../services/api_client.dart';
import '../../core/constants/api_constants.dart';

/// Repository cho Collection - kết nối với backend API
class CollectionRepository {
  final SharedPreferences _prefs;
  final ApiClient _apiClient = ApiClient();

  CollectionRepository(this._prefs);

  String? get _employeeId => _prefs.getString('worker_id');

  /// Lấy tất cả collection requests từ backend
  Future<List<CollectionRequest>> getAllCollections() async {
    if (_employeeId == null) {
      throw Exception('Worker ID not found. Please login again.');
    }

    try {
      final response = await _apiClient.get(
        ApiConstants.assignedSchedulesEndpoint,
        queryParams: {'employee_id': _employeeId!},
      );

      if (response['ok'] == true) {
        final data = response['data'] as List;
        return data.map((json) => CollectionRequest.fromJson(json)).toList();
      } else {
        throw Exception(response['error'] ?? 'Failed to get collections');
      }
    } catch (e) {
      print('Error getting collections: $e');
      // Fallback to mock for development
      return MockDataService.getCollectionRequests();
    }
  }

  /// Lấy collections hôm nay
  Future<List<CollectionRequest>> getTodayCollections() async {
    final all = await getAllCollections();
    final today = DateTime.now();
    return all.where((c) {
      if (c.scheduledDate == null) return false;
      final scheduled = c.scheduledDate!;
      return scheduled.year == today.year &&
          scheduled.month == today.month &&
          scheduled.day == today.day;
    }).toList();
  }

  /// Lấy pending collections
  Future<List<CollectionRequest>> getPendingCollections() async {
    final all = await getAllCollections();
    return all.where((c) => 
        c.status == 'pending' || 
        c.status == 'assigned' || 
        c.status == 'in_progress'
    ).toList();
  }

  /// Lấy completed collections
  Future<List<CollectionRequest>> getCompletedCollections() async {
    final all = await getAllCollections();
    return all.where((c) => 
        c.status == 'collected' || 
        c.status == 'completed'
    ).toList();
  }

  /// Cập nhật trạng thái collection
  Future<CollectionRequest> updateCollectionStatus({
    required String requestId,
    required String status,
    double? actualWeight,
    String? notes,
    List<String>? images,
  }) async {
    try {
      // Update schedule via PATCH /api/schedules/:id
      final updateData = <String, dynamic>{
        'status': status,
      };

      if (actualWeight != null) {
        updateData['actual_weight'] = actualWeight;
      }

      if (notes != null) {
        updateData['notes'] = notes;
      }

      // TODO: Handle images upload if needed

      final response = await _apiClient.patch(
        ApiConstants.updateScheduleEndpoint(requestId),
        updateData,
      );

      if (response['ok'] == true) {
        // Reload collection to get updated data
        final all = await getAllCollections();
        final updated = all.firstWhere(
          (c) => c.id == requestId,
          orElse: () => throw Exception('Collection not found'),
        );

        return updated.copyWith(
          status: status,
          collectedAt: status == 'collected' ? DateTime.now() : updated.collectedAt,
          actualWeight: actualWeight ?? updated.actualWeight,
          collectionNotes: notes ?? updated.collectionNotes,
          collectionImages: images ?? updated.collectionImages,
        );
      } else {
        throw Exception(response['error'] ?? 'Failed to update collection');
      }
    } catch (e) {
      print('Error updating collection: $e');
      // Fallback to mock for development
      final collections = MockDataService.getCollectionRequests();
      final collection = collections.firstWhere((c) => c.id == requestId);

      return collection.copyWith(
        status: status,
        collectedAt: status == 'collected'
            ? DateTime.now()
            : collection.collectedAt,
        actualWeight: actualWeight,
        collectionNotes: notes,
        collectionImages: images,
      );
    }
  }
}
