/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck Worker
 */

import 'package:equatable/equatable.dart';
import '../../../data/models/worker_route.dart';

/// Base state cho Route
abstract class RouteState extends Equatable {
  const RouteState();

  @override
  List<Object?> get props => [];
}

/// State: Initial
class RouteInitial extends RouteState {
  const RouteInitial();
}

/// State: Loading
class RouteLoading extends RouteState {
  const RouteLoading();
}

/// State: Đã load routes thành công
class RoutesLoaded extends RouteState {
  final List<WorkerRoute> routes;
  final WorkerRoute? activeRoute;

  const RoutesLoaded({required this.routes, this.activeRoute});

  @override
  List<Object?> get props => [routes, activeRoute];
}

/// State: Route đã được select
class RouteSelected extends RouteState {
  final WorkerRoute route;

  const RouteSelected({required this.route});

  @override
  List<Object?> get props => [route];
}

/// State: Đang thực hiện action (start, complete, update)
class RouteActionInProgress extends RouteState {
  final String actionType; // 'starting', 'completing', 'updating_point'
  final List<WorkerRoute> routes;
  final WorkerRoute? activeRoute;

  const RouteActionInProgress({
    required this.actionType,
    required this.routes,
    this.activeRoute,
  });

  @override
  List<Object?> get props => [actionType, routes, activeRoute];
}

/// State: Action thành công
class RouteActionSuccess extends RouteState {
  final String message;
  final List<WorkerRoute> routes;
  final WorkerRoute? activeRoute;

  const RouteActionSuccess({
    required this.message,
    required this.routes,
    this.activeRoute,
  });

  @override
  List<Object?> get props => [message, routes, activeRoute];
}

/// State: Error
class RouteError extends RouteState {
  final String message;

  const RouteError({required this.message});

  @override
  List<Object?> get props => [message];
}
