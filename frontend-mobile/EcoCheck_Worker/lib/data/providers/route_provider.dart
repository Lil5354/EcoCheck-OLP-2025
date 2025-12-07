/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck Worker
 */

import 'package:flutter/foundation.dart';
import '../models/worker_route.dart';
import '../services/mock_data_service.dart';

class RouteProvider with ChangeNotifier {
  List<WorkerRoute> _allRoutes = [];
  WorkerRoute? _activeRoute;
  bool _isLoading = false;
  String? _errorMessage;

  List<WorkerRoute> get allRoutes => _allRoutes;
  WorkerRoute? get activeRoute => _activeRoute;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load all routes
  Future<void> loadRoutes() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      _allRoutes = MockDataService.getWorkerRoutes();
      _activeRoute = MockDataService.getActiveRoute();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể tải dữ liệu lộ trình';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Start route
  Future<bool> startRoute(String routeId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      final routeIndex = _allRoutes.indexWhere((r) => r.id == routeId);
      if (routeIndex != -1) {
        // Update route status
        final route = _allRoutes[routeIndex];
        _activeRoute = WorkerRoute(
          id: route.id,
          name: route.name,
          workerId: route.workerId,
          workerName: route.workerName,
          vehiclePlate: route.vehiclePlate,
          scheduledDate: route.scheduledDate,
          status: 'in_progress',
          points: route.points,
          startedAt: DateTime.now(),
          completedAt: null,
          totalDistance: route.totalDistance,
          totalCollections: route.totalCollections,
          completedCollections: 0,
          createdAt: route.createdAt,
          updatedAt: DateTime.now(),
        );
        _allRoutes[routeIndex] = _activeRoute!;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể bắt đầu lộ trình';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Complete route
  Future<bool> completeRoute(String routeId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      final routeIndex = _allRoutes.indexWhere((r) => r.id == routeId);
      if (routeIndex != -1) {
        final route = _allRoutes[routeIndex];
        _allRoutes[routeIndex] = WorkerRoute(
          id: route.id,
          name: route.name,
          workerId: route.workerId,
          workerName: route.workerName,
          vehiclePlate: route.vehiclePlate,
          scheduledDate: route.scheduledDate,
          status: 'completed',
          points: route.points,
          startedAt: route.startedAt,
          completedAt: DateTime.now(),
          totalDistance: route.totalDistance,
          totalCollections: route.totalCollections,
          completedCollections: route.totalCollections,
          createdAt: route.createdAt,
          updatedAt: DateTime.now(),
        );
        _activeRoute = null;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể hoàn thành lộ trình';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update point status
  Future<bool> updatePointStatus(
    String routeId,
    String pointId,
    String status,
  ) async {
    try {
      final routeIndex = _allRoutes.indexWhere((r) => r.id == routeId);
      if (routeIndex != -1) {
        final route = _allRoutes[routeIndex];
        final points = List<RoutePoint>.from(route.points);
        final pointIndex = points.indexWhere((p) => p.id == pointId);

        if (pointIndex != -1) {
          points[pointIndex] = RoutePoint(
            id: points[pointIndex].id,
            order: points[pointIndex].order,
            collectionRequestId: points[pointIndex].collectionRequestId,
            address: points[pointIndex].address,
            latitude: points[pointIndex].latitude,
            longitude: points[pointIndex].longitude,
            wasteType: points[pointIndex].wasteType,
            status: status,
            arrivedAt: status == 'completed'
                ? DateTime.now()
                : points[pointIndex].arrivedAt,
            completedAt: status == 'completed' ? DateTime.now() : null,
          );

          // Update route with new points
          _allRoutes[routeIndex] = WorkerRoute(
            id: route.id,
            name: route.name,
            workerId: route.workerId,
            workerName: route.workerName,
            vehiclePlate: route.vehiclePlate,
            scheduledDate: route.scheduledDate,
            status: route.status,
            points: points,
            startedAt: route.startedAt,
            completedAt: route.completedAt,
            totalDistance: route.totalDistance,
            totalCollections: route.totalCollections,
            completedCollections: points
                .where((p) => p.status == 'completed')
                .length,
            createdAt: route.createdAt,
            updatedAt: DateTime.now(),
          );

          if (_activeRoute?.id == routeId) {
            _activeRoute = _allRoutes[routeIndex];
          }
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
}
