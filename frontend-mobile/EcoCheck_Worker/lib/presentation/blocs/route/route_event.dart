import 'package:equatable/equatable.dart';
import '../../../data/models/worker_route.dart';

/// Base event cho Route
abstract class RouteEvent extends Equatable {
  const RouteEvent();

  @override
  List<Object?> get props => [];
}

/// Event: Load tất cả routes
class LoadRoutesRequested extends RouteEvent {
  const LoadRoutesRequested();
}

/// Event: Load active route
class LoadActiveRouteRequested extends RouteEvent {
  const LoadActiveRouteRequested();
}

/// Event: Bắt đầu route
class StartRouteRequested extends RouteEvent {
  final String routeId;

  const StartRouteRequested({required this.routeId});

  @override
  List<Object?> get props => [routeId];
}

/// Event: Hoàn thành route
class CompleteRouteRequested extends RouteEvent {
  final String routeId;

  const CompleteRouteRequested({required this.routeId});

  @override
  List<Object?> get props => [routeId];
}

/// Event: Cập nhật trạng thái point
class UpdatePointStatusRequested extends RouteEvent {
  final String routeId;
  final String pointId;
  final String status;

  const UpdatePointStatusRequested({
    required this.routeId,
    required this.pointId,
    required this.status,
  });

  @override
  List<Object?> get props => [routeId, pointId, status];
}

/// Event: Select route để xem detail
class SelectRouteRequested extends RouteEvent {
  final WorkerRoute route;

  const SelectRouteRequested({required this.route});

  @override
  List<Object?> get props => [route];
}
