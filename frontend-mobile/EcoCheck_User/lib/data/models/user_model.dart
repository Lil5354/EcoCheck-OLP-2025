/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck User
 */

import 'package:equatable/equatable.dart';

/// User Model
class UserModel extends Equatable {
  final String id;
  final String phone;
  final String? email;
  final String fullName;
  final String role;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? avatarUrl;
  final bool isVerified;
  final bool isActive;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.phone,
    this.email,
    required this.fullName,
    required this.role,
    this.address,
    this.latitude,
    this.longitude,
    this.avatarUrl,
    this.isVerified = false,
    this.isActive = true,
    this.fcmToken,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    phone,
    email,
    fullName,
    role,
    address,
    latitude,
    longitude,
    avatarUrl,
    isVerified,
    isActive,
    fcmToken,
    createdAt,
    updatedAt,
  ];

  /// From JSON - with null-safe parsing and field name variations
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle both direct latitude/longitude and nested location object
    double? lat;
    double? lon;

    if (json.containsKey('location') && json['location'] != null) {
      lat = json['location']['latitude'] != null
          ? double.tryParse(json['location']['latitude'].toString())
          : null;
      lon = json['location']['longitude'] != null
          ? double.tryParse(json['location']['longitude'].toString())
          : null;
    } else {
      lat = json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null;
      lon = json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null;
    }

    return UserModel(
      id: json['id']?.toString() ?? json['user_id']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      fullName:
          json['fullName']?.toString() ??
          json['full_name']?.toString() ??
          json['name']?.toString() ??
          'User',
      role: json['role']?.toString() ?? 'citizen',
      address: json['address']?.toString(),
      latitude: lat,
      longitude: lon,
      avatarUrl:
          json['avatar_url']?.toString() ?? json['avatarUrl']?.toString(),
      isVerified: json['isVerified'] ?? json['is_verified'] ?? false,
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      fcmToken: json['fcm_token']?.toString() ?? json['fcmToken']?.toString(),
      createdAt: json['created_at'] != null || json['createdAt'] != null
          ? DateTime.tryParse(
                  json['created_at']?.toString() ??
                      json['createdAt']?.toString() ??
                      DateTime.now().toIso8601String(),
                ) ??
                DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null || json['updatedAt'] != null
          ? DateTime.tryParse(
                  json['updated_at']?.toString() ??
                      json['updatedAt']?.toString() ??
                      DateTime.now().toIso8601String(),
                ) ??
                DateTime.now()
          : DateTime.now(),
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'email': email,
      'full_name': fullName,
      'role': role,
      'address': address,
      'location': latitude != null && longitude != null
          ? {'latitude': latitude, 'longitude': longitude}
          : null,
      'avatar_url': avatarUrl,
      'is_verified': isVerified,
      'is_active': isActive,
      'fcm_token': fcmToken,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with
  UserModel copyWith({
    String? id,
    String? phone,
    String? email,
    String? fullName,
    String? role,
    String? address,
    double? latitude,
    double? longitude,
    String? avatarUrl,
    bool? isVerified,
    bool? isActive,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
