import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/worker_route.dart';
import '../../../data/repositories/route_repository.dart';
import 'route_event.dart';
import 'route_state.dart';

/// BLoC quản lý routes
class RouteBloc extends Bloc<RouteEvent, RouteState> {
  final RouteRepository _routeRepository;

  RouteBloc({required RouteRepository routeRepository})
    : _routeRepository = routeRepository,
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
      final routes = await _routeRepository.getAllRoutes();
      final activeRoute = await _routeRepository.getActiveRoute();

      emit(RoutesLoaded(routes: routes, activeRoute: activeRoute));
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
      final activeRoute = await _routeRepository.getActiveRoute();

      if (state is RoutesLoaded) {
        final currentState = state as RoutesLoaded;
        emit(
          RoutesLoaded(routes: currentState.routes, activeRoute: activeRoute),
        );
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
        final updatedRoute = await _routeRepository.startRoute(event.routeId);

        // Update routes list
        final updatedRoutes = currentState.routes.map((r) {
          return r.id == updatedRoute.id ? updatedRoute : r;
        }).toList();

        emit(
          RouteActionSuccess(
            message: 'Đã bắt đầu lộ trình',
            routes: updatedRoutes,
            activeRoute: updatedRoute,
          ),
        );

        // Return to loaded state
        emit(RoutesLoaded(routes: updatedRoutes, activeRoute: updatedRoute));
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
        final updatedRoute = await _routeRepository.completeRoute(
          event.routeId,
        );

        // Update routes list
        final updatedRoutes = currentState.routes.map((r) {
          return r.id == updatedRoute.id ? updatedRoute : r;
        }).toList();

        emit(
          RouteActionSuccess(
            message: 'Đã hoàn thành lộ trình',
            routes: updatedRoutes,
            activeRoute: null,
          ),
        );

        // Return to loaded state
        emit(RoutesLoaded(routes: updatedRoutes, activeRoute: null));
      } catch (e) {
        emit(RouteError(message: e.toString()));
      }
    }
  }

  /// Handler: Update point status
  Future<void> _onUpdatePointStatusRequested(
    UpdatePointStatusRequested event,
    Emitter<RouteState> emit,
  ) async {
    if (state is RoutesLoaded) {
      final currentState = state as RoutesLoaded;

      emit(
        RouteActionInProgress(
          actionType: 'updating_point',
          routes: currentState.routes,
          activeRoute: currentState.activeRoute,
        ),
      );

      try {
        final updatedPoint = await _routeRepository.updatePointStatus(
          routeId: event.routeId,
          pointId: event.pointId,
          status: event.status,
        );

        // Update routes list
        final updatedRoutes = currentState.routes.map((route) {
          if (route.id == event.routeId) {
            final updatedPoints = route.points.map((p) {
              return p.id == updatedPoint.id ? updatedPoint : p;
            }).toList();

            final completedCount = updatedPoints
                .where((p) => p.status == 'collected')
                .length;

            return WorkerRoute(
              id: route.id,
              name: route.name,
              workerId: route.workerId,
              workerName: route.workerName,
              vehiclePlate: route.vehiclePlate,
              scheduleDate: route.scheduleDate,
              status: route.status,
              points: updatedPoints,
              startedAt: route.startedAt,
              completedAt: route.completedAt,
              totalDistance: route.totalDistance,
              totalCollections: route.totalCollections,
              completedCollections: completedCount,
              createdAt: route.createdAt,
              updatedAt: DateTime.now(),
            );
          }
          return route;
        }).toList();

        // Update active route if it's the same
        WorkerRoute? updatedActiveRoute = currentState.activeRoute;
        if (updatedActiveRoute?.id == event.routeId) {
          updatedActiveRoute = updatedRoutes.firstWhere(
            (r) => r.id == event.routeId,
          );
        }

        emit(
          RouteActionSuccess(
            message: 'Đã cập nhật trạng thái',
            routes: updatedRoutes,
            activeRoute: updatedActiveRoute,
          ),
        );

        // Return to loaded state
        emit(
          RoutesLoaded(routes: updatedRoutes, activeRoute: updatedActiveRoute),
        );
      } catch (e) {
        emit(RouteError(message: e.toString()));
      }
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
