/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck Worker
 */

import 'package:eco_check_worker/data/models/worker_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/ecocheck_repository.dart';
import 'route_event.dart';
import 'route_state.dart';

/// BLoC quản lý routes - sử dụng backend thực
class RouteBloc extends Bloc<RouteEvent, RouteState> {
  final EcoCheckRepository _repository;

  RouteBloc({required EcoCheckRepository repository})
    : _repository = repository,
      super(const RouteInitial()) {
    on<LoadRoutesRequested>(_onLoadRoutesRequested);
    on<LoadActiveRouteRequested>(_onLoadActiveRouteRequested);
    on<StartRouteRequested>(_onStartRouteRequested);
    on<CompleteRouteRequested>(_onCompleteRouteRequested);
    on<UpdatePointStatusRequested>(_onUpdatePointStatusRequested);
    on<SelectRouteRequested>(_onSelectRouteRequested);
  }

  /// Handler: Load routes
  Future<void> _onLoadRoutesRequested(
    LoadRoutesRequested event,
    Emitter<RouteState> emit,
  ) async {
    emit(const RouteLoading());

    try {
      // Get personnel_id from event (should be passed from auth)
      final personnelId = event.personnelId;

      if (personnelId == null || personnelId.isEmpty) {
        emit(const RouteError(message: 'Personnel ID không hợp lệ'));
        return;
      }

      // Call worker routes API
      final routesData = await _repository.getWorkerRoutes(personnelId);

      // Convert to WorkerRoute model using fromJson
      final routes = routesData.map((data) {
        return WorkerRoute.fromJson(data);
      }).toList();

      emit(RoutesLoaded(routes: routes, activeRoute: null));
    } catch (e) {
      emit(RouteError(message: e.toString()));
    }
  }

  /// Handler: Load active route
  Future<void> _onLoadActiveRouteRequested(
    LoadActiveRouteRequested event,
    Emitter<RouteState> emit,
  ) async {
    try {
      // TODO: Implement proper route model conversion
      await _repository.getActiveRoute();

      if (state is RoutesLoaded) {
        final currentState = state as RoutesLoaded;
        emit(RoutesLoaded(routes: currentState.routes, activeRoute: null));
      }
    } catch (e) {
      emit(RouteError(message: e.toString()));
    }
  }

  /// Handler: Start route
  Future<void> _onStartRouteRequested(
    StartRouteRequested event,
    Emitter<RouteState> emit,
  ) async {
    if (state is RoutesLoaded) {
      final currentState = state as RoutesLoaded;

      emit(
        RouteActionInProgress(
          actionType: 'starting',
          routes: currentState.routes,
          activeRoute: currentState.activeRoute,
        ),
      );

      try {
        await _repository.startWorkerRoute(event.routeId);

        emit(
          RouteActionSuccess(
            message: 'Đã bắt đầu lộ trình',
            routes: currentState.routes,
            activeRoute: null,
          ),
        );

        // Return to loaded state
        emit(RoutesLoaded(routes: currentState.routes, activeRoute: null));
      } catch (e) {
        emit(RouteError(message: e.toString()));
      }
    }
  }

  /// Handler: Complete route
  Future<void> _onCompleteRouteRequested(
    CompleteRouteRequested event,
    Emitter<RouteState> emit,
  ) async {
    if (state is RoutesLoaded) {
      final currentState = state as RoutesLoaded;

      emit(
        RouteActionInProgress(
          actionType: 'completing',
          routes: currentState.routes,
          activeRoute: currentState.activeRoute,
        ),
      );

      try {
        await _repository.completeWorkerRoute(
          routeId: event.routeId,
          actualDistanceKm: event.actualDistanceKm,
          notes: event.notes,
        );

        // Success - sẽ navigate trong listener
        emit(
          RouteActionSuccess(
            message: 'Đã hoàn thành lộ trình',
            routes: currentState.routes,
            activeRoute: null,
          ),
        );

        // Delay nhẹ để UI xử lý trước, sau đó reload data
        await Future.delayed(const Duration(milliseconds: 300));

        // Reload routes từ server để có data mới nhất
        final completedRoute = currentState.routes.firstWhere(
          (r) => r.id == event.routeId,
          orElse: () => currentState.routes.first,
        );
        final routesData = await _repository.getWorkerRoutes(
          completedRoute.workerId,
        );
        final routes = routesData.map((data) {
          return WorkerRoute.fromJson(data);
        }).toList();

        // Emit loaded state với data mới
        emit(RoutesLoaded(routes: routes, activeRoute: null));
      } catch (e) {
        emit(RouteError(message: e.toString()));
        // Revert to previous state
        emit(
          RoutesLoaded(
            routes: currentState.routes,
            activeRoute: currentState.activeRoute,
          ),
        );
      }
    }
  }

  /// Handler: Update point status
  Future<void> _onUpdatePointStatusRequested(
    UpdatePointStatusRequested event,
    Emitter<RouteState> emit,
  ) async {
    if (state is! RoutesLoaded) return;

    final currentState = state as RoutesLoaded;

    emit(
      RouteActionInProgress(
        actionType: 'updating_point',
        routes: currentState.routes,
        activeRoute: currentState.activeRoute,
      ),
    );

    try {
      // Call API to update stop status
      if (event.status == 'completed') {
        await _repository.completeRouteStop(
          stopId: event.pointId,
          photoUrls: event.photoUrls,
          notes: event.notes,
        );
      } else if (event.status == 'skipped') {
        await _repository.skipRouteStop(
          stopId: event.pointId,
          reason: event.notes ?? 'Không có lý do',
        );
      }

      // Reload route detail to get updated data
      final routeDetail = await _repository.getWorkerRouteDetail(event.routeId);

      // Update local state
      final updatedRoutes = currentState.routes.map((route) {
        if (route.id == event.routeId) {
          // Reconstruct route with updated points
          final stopsData = routeDetail['stops'] ?? [];
          final updatedPoints = (stopsData as List)
              .map((stop) => RoutePoint.fromJson(stop as Map<String, dynamic>))
              .toList();

          return WorkerRoute(
            id: route.id,
            name: route.name,
            workerId: route.workerId,
            workerName: route.workerName,
            vehiclePlate: route.vehiclePlate,
            scheduledDate: route.scheduledDate,
            status: routeDetail['status'] as String? ?? route.status,
            points: updatedPoints,
            startedAt: route.startedAt,
            completedAt: routeDetail['completed_at'] != null
                ? DateTime.parse(routeDetail['completed_at'] as String)
                : route.completedAt,
            totalDistance: route.totalDistance,
            totalCollections: routeDetail['total_stops'] as int?,
            completedCollections: routeDetail['completed_stops'] as int?,
            createdAt: route.createdAt,
            updatedAt: DateTime.now(),
            // Keep depot/dump coordinates
            depotId: route.depotId,
            depotName: route.depotName,
            depotLat: route.depotLat,
            depotLon: route.depotLon,
            dumpId: route.dumpId,
            dumpName: route.dumpName,
            dumpLat: route.dumpLat,
            dumpLon: route.dumpLon,
          );
        }
        return route;
      }).toList();

      emit(
        RouteActionSuccess(
          message: event.status == 'completed'
              ? 'Đã hoàn thành điểm thu gom'
              : 'Đã bỏ qua điểm thu gom',
          routes: updatedRoutes,
          activeRoute: currentState.activeRoute,
        ),
      );

      // Return to loaded state with updated data
      emit(
        RoutesLoaded(
          routes: updatedRoutes,
          activeRoute: currentState.activeRoute,
        ),
      );
    } catch (e) {
      emit(RouteError(message: e.toString()));
      // Restore previous state
      emit(
        RoutesLoaded(
          routes: currentState.routes,
          activeRoute: currentState.activeRoute,
        ),
      );
    }
  }

  /// Handler: Select route
  Future<void> _onSelectRouteRequested(
    SelectRouteRequested event,
    Emitter<RouteState> emit,
  ) async {
    emit(RouteSelected(route: event.route));
  }
}
