/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck Worker
 */

import 'package:flutter/foundation.dart';
import '../models/collection_request.dart';
import '../services/mock_data_service.dart';

class CollectionProvider with ChangeNotifier {
  List<CollectionRequest> _allRequests = [];
  List<CollectionRequest> _todayRequests = [];
  List<CollectionRequest> _pendingRequests = [];
  List<CollectionRequest> _completedRequests = [];
  CollectionRequest? _selectedRequest;
  bool _isLoading = false;
  String? _errorMessage;

  List<CollectionRequest> get allRequests => _allRequests;
  List<CollectionRequest> get todayRequests => _todayRequests;
  List<CollectionRequest> get pendingRequests => _pendingRequests;
  List<CollectionRequest> get completedRequests => _completedRequests;
  CollectionRequest? get selectedRequest => _selectedRequest;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load all collection requests
  Future<void> loadCollectionRequests() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      _allRequests = MockDataService.getCollectionRequests();
      _todayRequests = MockDataService.getTodayCollections();
      _pendingRequests = MockDataService.getPendingCollections();
      _completedRequests = MockDataService.getCompletedCollections();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể tải dữ liệu';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Select a collection request
  void selectRequest(CollectionRequest request) {
    _selectedRequest = request;
    notifyListeners();
  }

  // Update collection status
  Future<bool> updateCollectionStatus({
    required String requestId,
    required String status,
    double? actualWeight,
    String? notes,
    List<String>? images,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      final index = _allRequests.indexWhere((req) => req.id == requestId);
      if (index != -1) {
        _allRequests[index] = _allRequests[index].copyWith(
          status: status,
          actualWeight: actualWeight,
          collectionNotes: notes,
          collectionImages: images,
          collectedAt: status == 'collected' || status == 'completed'
              ? DateTime.now()
              : null,
        );

        // Update selected request if it's the same
        if (_selectedRequest?.id == requestId) {
          _selectedRequest = _allRequests[index];
        }

        // Reload categorized lists
        _todayRequests = MockDataService.getTodayCollections();
        _pendingRequests = MockDataService.getPendingCollections();
        _completedRequests = MockDataService.getCompletedCollections();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể cập nhật trạng thái';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Filter requests by status
  List<CollectionRequest> filterByStatus(String status) {
    return _allRequests.where((req) => req.status == status).toList();
  }

  // Filter requests by priority
  List<CollectionRequest> filterByPriority(String priority) {
    return _allRequests.where((req) => req.priority == priority).toList();
  }

  // Search requests
  List<CollectionRequest> searchRequests(String query) {
    final lowerQuery = query.toLowerCase();
    return _allRequests
        .where(
          (req) =>
              req.citizenName.toLowerCase().contains(lowerQuery) ||
              req.address.toLowerCase().contains(lowerQuery) ||
              req.wasteType.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }
}
