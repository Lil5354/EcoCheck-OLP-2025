/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck Worker
 */
class CollectionRequest {
  final String id;
  final String citizenId;
  final String citizenName;
  final String? citizenPhone;
  final String address;
  final double latitude;
  final double longitude;
  final String wasteType;
  final double? estimatedWeight;
  final String? description;
  final List<String>? images;
  final String
  status; // pending, assigned, in_progress, collected, completed, cancelled
  final String priority; // low, medium, high, urgent
  final DateTime? scheduledDate;
  final String? assignedWorkerId;
  final String? assignedWorkerName;
  final String? routeId;
  final DateTime? collectedAt;
  final double? actualWeight;
  final String? collectionNotes;
  final List<String>? collectionImages;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CollectionRequest({
    required this.id,
    required this.citizenId,
    required this.citizenName,
    this.citizenPhone,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.wasteType,
    this.estimatedWeight,
    this.description,
    this.images,
    required this.status,
    required this.priority,
    this.scheduledDate,
    this.assignedWorkerId,
    this.assignedWorkerName,
    this.routeId,
    this.collectedAt,
    this.actualWeight,
    this.collectionNotes,
    this.collectionImages,
    required this.createdAt,
    this.updatedAt,
  });

  factory CollectionRequest.fromJson(Map<String, dynamic> json) {
    return CollectionRequest(
      id: json['id'] as String,
      citizenId: json['citizen_id'] as String,
      citizenName: json['citizen_name'] as String,
      citizenPhone: json['citizen_phone'] as String?,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      wasteType: json['waste_type'] as String,
      estimatedWeight: json['estimated_weight'] != null
          ? (json['estimated_weight'] as num).toDouble()
          : null,
      description: json['description'] as String?,
      images: json['images'] != null
          ? List<String>.from(json['images'] as List)
          : null,
      status: json['status'] as String,
      priority: json['priority'] as String,
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.parse(json['scheduled_date'] as String)
          : null,
      assignedWorkerId: json['assigned_worker_id'] as String?,
      assignedWorkerName: json['assigned_worker_name'] as String?,
      routeId: json['route_id'] as String?,
      collectedAt: json['collected_at'] != null
          ? DateTime.parse(json['collected_at'] as String)
          : null,
      actualWeight: json['actual_weight'] != null
          ? (json['actual_weight'] as num).toDouble()
          : null,
      collectionNotes: json['collection_notes'] as String?,
      collectionImages: json['collection_images'] != null
          ? List<String>.from(json['collection_images'] as List)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'citizen_id': citizenId,
      'citizen_name': citizenName,
      'citizen_phone': citizenPhone,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'waste_type': wasteType,
      'estimated_weight': estimatedWeight,
      'description': description,
      'images': images,
      'status': status,
      'priority': priority,
      'scheduled_date': scheduledDate?.toIso8601String(),
      'assigned_worker_id': assignedWorkerId,
      'assigned_worker_name': assignedWorkerName,
      'route_id': routeId,
      'collected_at': collectedAt?.toIso8601String(),
      'actual_weight': actualWeight,
      'collection_notes': collectionNotes,
      'collection_images': collectionImages,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  CollectionRequest copyWith({
    String? status,
    DateTime? collectedAt,
    double? actualWeight,
    String? collectionNotes,
    List<String>? collectionImages,
  }) {
    return CollectionRequest(
      id: id,
      citizenId: citizenId,
      citizenName: citizenName,
      citizenPhone: citizenPhone,
      address: address,
      latitude: latitude,
      longitude: longitude,
      wasteType: wasteType,
      estimatedWeight: estimatedWeight,
      description: description,
      images: images,
      status: status ?? this.status,
      priority: priority,
      scheduledDate: scheduledDate,
      assignedWorkerId: assignedWorkerId,
      assignedWorkerName: assignedWorkerName,
      routeId: routeId,
      collectedAt: collectedAt ?? this.collectedAt,
      actualWeight: actualWeight ?? this.actualWeight,
      collectionNotes: collectionNotes ?? this.collectionNotes,
      collectionImages: collectionImages ?? this.collectionImages,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
