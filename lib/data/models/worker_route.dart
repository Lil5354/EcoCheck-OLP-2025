class WorkerRoute {
  final String id;
  final String name;
  final String workerId;
  final String workerName;
  final String? vehiclePlate;
  final DateTime scheduleDate;
  final String status; // pending, in_progress, completed, cancelled
  final List<RoutePoint> points;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final double? totalDistance;
  final int? totalCollections;
  final int? completedCollections;
  final DateTime createdAt;
  final DateTime? updatedAt;

  WorkerRoute({
    required this.id,
    required this.name,
    required this.workerId,
    required this.workerName,
    this.vehiclePlate,
    required this.scheduleDate,
    required this.status,
    required this.points,
    this.startedAt,
    this.completedAt,
    this.totalDistance,
    this.totalCollections,
    this.completedCollections,
    required this.createdAt,
    this.updatedAt,
  });

  factory WorkerRoute.fromJson(Map<String, dynamic> json) {
    return WorkerRoute(
      id: json['id'] as String,
      name: json['name'] as String,
      workerId: json['worker_id'] as String,
      workerName: json['worker_name'] as String,
      vehiclePlate: json['vehicle_plate'] as String?,
      scheduleDate: DateTime.parse(json['schedule_date'] as String),
      status: json['status'] as String,
      points: (json['points'] as List)
          .map((point) => RoutePoint.fromJson(point as Map<String, dynamic>))
          .toList(),
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      totalDistance: json['total_distance'] != null
          ? (json['total_distance'] as num).toDouble()
          : null,
      totalCollections: json['total_collections'] as int?,
      completedCollections: json['completed_collections'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'worker_id': workerId,
      'worker_name': workerName,
      'vehicle_plate': vehiclePlate,
      'schedule_date': scheduleDate.toIso8601String(),
      'status': status,
      'points': points.map((point) => point.toJson()).toList(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'total_distance': totalDistance,
      'total_collections': totalCollections,
      'completed_collections': completedCollections,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class RoutePoint {
  final String id;
  final int order;
  final String? collectionRequestId;
  final String address;
  final double latitude;
  final double longitude;
  final String? wasteType;
  final String status; // pending, completed, skipped
  final DateTime? arrivedAt;
  final DateTime? completedAt;

  RoutePoint({
    required this.id,
    required this.order,
    this.collectionRequestId,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.wasteType,
    required this.status,
    this.arrivedAt,
    this.completedAt,
  });

  factory RoutePoint.fromJson(Map<String, dynamic> json) {
    return RoutePoint(
      id: json['id'] as String,
      order: json['order'] as int,
      collectionRequestId: json['collection_request_id'] as String?,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      wasteType: json['waste_type'] as String?,
      status: json['status'] as String,
      arrivedAt: json['arrived_at'] != null
          ? DateTime.parse(json['arrived_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'collection_request_id': collectionRequestId,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'waste_type': wasteType,
      'status': status,
      'arrived_at': arrivedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}
