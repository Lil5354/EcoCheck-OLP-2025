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

  /// From JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      address: json['address'] as String?,
      latitude: json['location']?['latitude'] as double?,
      longitude: json['location']?['longitude'] as double?,
      avatarUrl: json['avatar_url'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      fcmToken: json['fcm_token'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
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
