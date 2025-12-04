/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck Worker
 */

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
  final String? personnelId;

  const LoadRoutesRequested({this.personnelId});

  @override
  List<Object?> get props => [personnelId];
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
  final double? actualDistanceKm;
  final String? notes;

  const CompleteRouteRequested({
    required this.routeId,
    this.actualDistanceKm,
    this.notes,
  });

  @override
  List<Object?> get props => [routeId, actualDistanceKm, notes];
}

/// Event: Cập nhật trạng thái point
class UpdatePointStatusRequested extends RouteEvent {
  final String routeId;
  final String pointId;
  final String status;
  final List<String>? photoUrls;
  final String? notes;

  const UpdatePointStatusRequested({
    required this.routeId,
    required this.pointId,
    required this.status,
    this.photoUrls,
    this.notes,
  });

  @override
  List<Object?> get props => [routeId, pointId, status, photoUrls, notes];
}

/// Event: Select route để xem detail
class SelectRouteRequested extends RouteEvent {
  final WorkerRoute route;

  const SelectRouteRequested({required this.route});

  @override
  List<Object?> get props => [route];
}
