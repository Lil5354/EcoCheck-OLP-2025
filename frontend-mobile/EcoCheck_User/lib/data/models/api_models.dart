/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck User
 */

import 'package:equatable/equatable.dart';

/// Base response model for API responses
class ApiResponse<T> extends Equatable {
  final bool ok;
  final T? data;
  final String? message;
  final String? error;

  const ApiResponse({required this.ok, this.data, this.message, this.error});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      ok: json['ok'] ?? true,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      message: json['message'] as String?,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'ok': ok,
    'data': data,
    'message': message,
    'error': error,
  };

  @override
  List<Object?> get props => [ok, data, message, error];
}

/// Alert model
class Alert extends Equatable {
  final String alertId;
  final String alertType;
  final String severity;
  final String status;
  final DateTime createdAt;
  final String? pointId;
  final String? pointName;
  final String? vehicleId;
  final String? licensePlate;
  final String? routeId;

  const Alert({
    required this.alertId,
    required this.alertType,
    required this.severity,
    required this.status,
    required this.createdAt,
    this.pointId,
    this.pointName,
    this.vehicleId,
    this.licensePlate,
    this.routeId,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      alertId: json['alert_id'] as String,
      alertType: json['alert_type'] as String,
      severity: json['severity'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      pointId: json['point_id'] as String?,
      pointName: json['point_name'] as String?,
      vehicleId: json['vehicle_id'] as String?,
      licensePlate: json['license_plate'] as String?,
      routeId: json['route_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'alert_id': alertId,
    'alert_type': alertType,
    'severity': severity,
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'point_id': pointId,
    'point_name': pointName,
    'vehicle_id': vehicleId,
    'license_plate': licensePlate,
    'route_id': routeId,
  };

  @override
  List<Object?> get props => [
    alertId,
    alertType,
    severity,
    status,
    createdAt,
    pointId,
    pointName,
    vehicleId,
    licensePlate,
    routeId,
  ];
}

/// Check-in Point model
class CheckinPoint extends Equatable {
  final String id;
  final String type;
  final String level;
  final bool incident;
  final double lat;
  final double lon;
  final int ts;

  const CheckinPoint({
    required this.id,
    required this.type,
    required this.level,
    required this.incident,
    required this.lat,
    required this.lon,
    required this.ts,
  });

  factory CheckinPoint.fromJson(Map<String, dynamic> json) {
    return CheckinPoint(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      level: json['level']?.toString() ?? 'low',
      incident: json['incident'] ?? false,
      lat: json['lat'] != null ? double.parse(json['lat'].toString()) : 0.0,
      lon: json['lon'] != null ? double.parse(json['lon'].toString()) : 0.0,
      ts: int.tryParse(json['ts']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'level': level,
    'incident': incident,
    'lat': lat,
    'lon': lon,
    'ts': ts,
  };

  @override
  List<Object?> get props => [id, type, level, incident, lat, lon, ts];
}

/// Collection Point model
class CollectionPoint extends Equatable {
  final String id;
  final String type;
  final double lat;
  final double lon;
  final int demand;
  final String status;

  const CollectionPoint({
    required this.id,
    required this.type,
    required this.lat,
    required this.lon,
    required this.demand,
    required this.status,
  });

  factory CollectionPoint.fromJson(Map<String, dynamic> json) {
    return CollectionPoint(
      id: json['id'] as String,
      type: json['type'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      demand: json['demand'] as int,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'lat': lat,
    'lon': lon,
    'demand': demand,
    'status': status,
  };

  @override
  List<Object?> get props => [id, type, lat, lon, demand, status];
}

/// Vehicle model
class Vehicle extends Equatable {
  final String id;
  final String plate;
  final String type;
  final int capacity;
  final List<String> types;
  final String status;
  final double? lat;
  final double? lon;
  final double? distance;

  const Vehicle({
    required this.id,
    required this.plate,
    required this.type,
    required this.capacity,
    required this.types,
    required this.status,
    this.lat,
    this.lon,
    this.distance,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      plate: json['plate'] as String,
      type: json['type'] as String,
      capacity: json['capacity'] as int,
      types: (json['types'] as List<dynamic>).map((e) => e as String).toList(),
      status: json['status'] as String,
      lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
      lon: json['lon'] != null ? (json['lon'] as num).toDouble() : null,
      distance: json['distance'] != null
          ? (json['distance'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'plate': plate,
    'type': type,
    'capacity': capacity,
    'types': types,
    'status': status,
    'lat': lat,
    'lon': lon,
    'distance': distance,
  };

  @override
  List<Object?> get props => [
    id,
    plate,
    type,
    capacity,
    types,
    status,
    lat,
    lon,
    distance,
  ];
}

/// Analytics Summary model
class AnalyticsSummary extends Equatable {
  final int routesActive;
  final double collectionRate;
  final double todayTons;

  const AnalyticsSummary({
    required this.routesActive,
    required this.collectionRate,
    required this.todayTons,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummary(
      routesActive: json['routesActive'] as int,
      collectionRate: (json['collectionRate'] as num).toDouble(),
      todayTons: (json['todayTons'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'routesActive': routesActive,
    'collectionRate': collectionRate,
    'todayTons': todayTons,
  };

  @override
  List<Object?> get props => [routesActive, collectionRate, todayTons];
}

/// Check-in request model
class CheckinRequest extends Equatable {
  final String routeId;
  final String pointId;
  final String vehicleId;

  const CheckinRequest({
    required this.routeId,
    required this.pointId,
    required this.vehicleId,
  });

  Map<String, dynamic> toJson() => {
    'route_id': routeId,
    'point_id': pointId,
    'vehicle_id': vehicleId,
  };

  @override
  List<Object?> get props => [routeId, pointId, vehicleId];
}

/// Check-in response model
class CheckinResponse extends Equatable {
  final bool ok;
  final String? status;
  final String? message;

  const CheckinResponse({required this.ok, this.status, this.message});

  factory CheckinResponse.fromJson(Map<String, dynamic> json) {
    return CheckinResponse(
      ok: json['ok'] as bool,
      status: json['status'] as String?,
      message: json['message'] as String?,
    );
  }

  @override
  List<Object?> get props => [ok, status, message];
}
