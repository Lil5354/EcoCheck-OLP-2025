import '../models/worker_route.dart';
import '../services/mock_data_service.dart';

/// Repository cho Route - tách logic API
class RouteRepository {
  /// Lấy tất cả routes
  Future<List<WorkerRoute>> getAllRoutes() async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    // TODO: Replace with real API
    // final response = await api.get('/routes');
    // return (response.data as List).map((json) => WorkerRoute.fromJson(json)).toList();

    return MockDataService.getWorkerRoutes();
  }

  /// Lấy active route
  Future<WorkerRoute?> getActiveRoute() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockDataService.getActiveRoute();
  }

  /// Bắt đầu route
  Future<WorkerRoute> startRoute(String routeId) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // TODO: Replace with real API
    // final response = await api.post('/routes/$routeId/start');
    // return WorkerRoute.fromJson(response.data);

    final routes = MockDataService.getWorkerRoutes();
    final route = routes.firstWhere((r) => r.id == routeId);

    return WorkerRoute(
      id: route.id,
      name: route.name,
      workerId: route.workerId,
      workerName: route.workerName,
      vehiclePlate: route.vehiclePlate,
      scheduleDate: route.scheduleDate,
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

  /// Hoàn thành route
  Future<WorkerRoute> completeRoute(String routeId) async {
    await Future.delayed(const Duration(seconds: 1));

    final routes = MockDataService.getWorkerRoutes();
    final route = routes.firstWhere((r) => r.id == routeId);

    return WorkerRoute(
      id: route.id,
      name: route.name,
      workerId: route.workerId,
      workerName: route.workerName,
      vehiclePlate: route.vehiclePlate,
      scheduleDate: route.scheduleDate,
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

  /// Cập nhật trạng thái point
  Future<RoutePoint> updatePointStatus({
    required String routeId,
    required String pointId,
    required String status,
  }) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    // TODO: Replace with real API
    // final response = await api.patch('/routes/$routeId/points/$pointId', data: {'status': status});
    // return RoutePoint.fromJson(response.data);

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
