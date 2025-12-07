/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck Worker
 */

import 'package:shared_preferences/shared_preferences.dart';
import '../models/worker_route.dart';
import '../services/mock_data_service.dart';
import '../services/api_client.dart';
import '../../core/constants/api_constants.dart';

/// Repository cho Route - kết nối với backend API
class RouteRepository {
  final SharedPreferences _prefs;
  final ApiClient _apiClient = ApiClient();

  RouteRepository(this._prefs);

  String? get _employeeId => _prefs.getString('worker_id');

  /// Lấy tất cả routes (fallback to active route for now)
  Future<List<WorkerRoute>> getAllRoutes() async {
    try {
      final activeRoute = await getActiveRoute();
      if (activeRoute != null) {
        return [activeRoute];
      }
      return [];
    } catch (e) {
      print('Error getting routes: $e');
      // Fallback to mock for development
      return MockDataService.getWorkerRoutes();
    }
  }

  /// Lấy active route từ backend
  Future<WorkerRoute?> getActiveRoute() async {
    if (_employeeId == null) {
      throw Exception('Worker ID not found. Please login again.');
    }

    try {
      final response = await _apiClient.get(
        ApiConstants.activeRouteEndpoint,
        queryParams: {'employee_id': _employeeId!},
      );

      if (response['ok'] == true) {
        final data = response['data'];
        if (data == null) {
          return null; // No active route
        }

        return WorkerRoute.fromJson(data);
      } else {
        throw Exception(response['error'] ?? 'Failed to get active route');
      }
    } catch (e) {
      print('Error getting active route: $e');
      // Fallback to mock for development
      return MockDataService.getActiveRoute();
    }
  }

  /// Bắt đầu route
  Future<WorkerRoute> startRoute(String routeId) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.startRouteEndpoint(routeId),
        {},
      );

      if (response['ok'] == true) {
        // Reload active route to get updated status
        final route = await getActiveRoute();
        if (route == null) {
          throw Exception('Route not found after starting');
        }
        return route;
      } else {
        throw Exception(response['error'] ?? 'Failed to start route');
      }
    } catch (e) {
      print('Error starting route: $e');
      // Fallback to mock for development
      final routes = MockDataService.getWorkerRoutes();
      final route = routes.firstWhere((r) => r.id == routeId);

      return WorkerRoute(
        id: route.id,
        name: route.name,
        workerId: route.workerId,
        workerName: route.workerName,
        vehiclePlate: route.vehiclePlate,
        scheduledDate: route.scheduledDate,
        status: 'in_progress',
        points: route.points,
        startedAt: DateTime.now(),
        completedAt: route.completedAt,
        totalDistance: route.totalDistance,
        totalCollections: route.totalCollections,
        completedCollections: route.completedCollections,
        createdAt: route.createdAt,
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Hoàn thành route
  Future<WorkerRoute> completeRoute(String routeId) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.completeRouteEndpoint(routeId),
        {},
      );

      if (response['ok'] == true) {
        // Reload active route to get updated status
        final updatedRoute = await getActiveRoute();
        if (updatedRoute != null && updatedRoute.id == routeId) {
          return updatedRoute;
        }
        // If route is completed, it won't be in active routes anymore
        // Return a completed version
        final currentRoute = await getActiveRoute();
        if (currentRoute != null) {
          throw Exception('Route still active after completion');
        }
        // Create completed route from memory (fallback)
        final routes = await getAllRoutes();
        final route = routes.firstWhere((r) => r.id == routeId);
        return WorkerRoute(
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
          completedCollections: route.points.length,
          createdAt: route.createdAt,
          updatedAt: DateTime.now(),
        );
      } else {
        throw Exception(response['error'] ?? 'Failed to complete route');
      }
    } catch (e) {
      print('Error completing route: $e');
      // Fallback to mock for development
      final routes = MockDataService.getWorkerRoutes();
      final route = routes.firstWhere((r) => r.id == routeId);

      return WorkerRoute(
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
        completedCollections: route.points.length,
        createdAt: route.createdAt,
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Cập nhật trạng thái point (update schedule status)
  Future<RoutePoint> updatePointStatus({
    required String routeId,
    required String pointId,
    required String status,
  }) async {
    try {
      // Update schedule status via PATCH /api/schedules/:id
      final response = await _apiClient.patch(
        ApiConstants.updateScheduleEndpoint(pointId),
        {'status': status},
      );

      if (response['ok'] == true) {
        // Reload active route to get updated point status
        final updatedRoute = await getActiveRoute();
        if (updatedRoute != null) {
          final updatedPoint = updatedRoute.points.firstWhere(
            (p) => p.id == pointId,
            orElse: () => throw Exception('Point not found'),
          );
          return updatedPoint;
        }
      }

      throw Exception(response['error'] ?? 'Failed to update point status');
    } catch (e) {
      print('Error updating point status: $e');
      // Fallback to mock for development
      final routes = MockDataService.getWorkerRoutes();
      final route = routes.firstWhere((r) => r.id == routeId);
      final point = route.points.firstWhere((p) => p.id == pointId);

      return RoutePoint(
        id: point.id,
        order: point.order,
        collectionRequestId: point.collectionRequestId,
        address: point.address,
        latitude: point.latitude,
        longitude: point.longitude,
        wasteType: point.wasteType,
        status: status,
        arrivedAt: point.arrivedAt,
        completedAt: status == 'collected' ? DateTime.now() : point.completedAt,
      );
    }
  }
}
