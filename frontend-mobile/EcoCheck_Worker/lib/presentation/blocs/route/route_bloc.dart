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
      // TODO: Implement getAllRoutes and proper route model in repository
      await _repository.getActiveRoute();

      emit(const RoutesLoaded(routes: [], activeRoute: null));
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
        await _repository.startRoute(event.routeId);

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
        await _repository.completeRoute(event.routeId);

        emit(
          RouteActionSuccess(
            message: 'Đã hoàn thành lộ trình',
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

  /// Handler: Update point status (stub for now)
  Future<void> _onUpdatePointStatusRequested(
    UpdatePointStatusRequested event,
    Emitter<RouteState> emit,
  ) async {
    // TODO: Implement when backend supports this
  }

  /// Handler: Select route
  Future<void> _onSelectRouteRequested(
    SelectRouteRequested event,
    Emitter<RouteState> emit,
  ) async {
    emit(RouteSelected(route: event.route));
  }
}
