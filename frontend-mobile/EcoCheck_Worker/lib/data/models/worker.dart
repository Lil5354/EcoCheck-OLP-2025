/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck Worker
 */
class Worker {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? avatar;
  final String vehicleType;
  final String vehiclePlate;
  final String status; // active, inactive, on_leave
  final String? teamId;
  final String? teamName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Worker({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.avatar,
    required this.vehicleType,
    required this.vehiclePlate,
    required this.status,
    this.teamId,
    this.teamName,
    required this.createdAt,
    this.updatedAt,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String?,
      avatar: json['avatar'] as String?,
      vehicleType: json['vehicle_type'] as String,
      vehiclePlate: json['vehicle_plate'] as String,
      status: json['status'] as String,
      teamId: json['team_id'] as String?,
      teamName: json['team_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'avatar': avatar,
      'vehicle_type': vehicleType,
      'vehicle_plate': vehiclePlate,
      'status': status,
      'team_id': teamId,
      'team_name': teamName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Worker copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? avatar,
    String? vehicleType,
    String? vehiclePlate,
    String? status,
    String? teamId,
    String? teamName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Worker(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatar: avatar ?? this.avatar,
      vehicleType: vehicleType ?? this.vehicleType,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      status: status ?? this.status,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
