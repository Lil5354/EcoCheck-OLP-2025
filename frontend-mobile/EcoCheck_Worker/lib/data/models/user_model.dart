import 'package:equatable/equatable.dart';

/// User Model (Worker)
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

  // Worker-specific fields
  final String? personnelRole; // driver, collector, etc.
  final String? depotId;
  final String? depotName;
  final String? groupId;
  final String? groupName;
  final String? groupCode;
  final String? roleInGroup; // leader, member
  final String? operatingArea;
  final String? vehicleId;
  final String? vehiclePlate;
  final String? vehicleType;
  final List<String>? skills;
  final int? experience;
  final String? license;

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
    this.personnelRole,
    this.depotId,
    this.depotName,
    this.groupId,
    this.groupName,
    this.groupCode,
    this.roleInGroup,
    this.operatingArea,
    this.vehicleId,
    this.vehiclePlate,
    this.vehicleType,
    this.skills,
    this.experience,
    this.license,
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
    personnelRole,
    depotId,
    depotName,
    groupId,
    groupName,
    groupCode,
    roleInGroup,
    operatingArea,
    vehicleId,
    vehiclePlate,
    vehicleType,
    skills,
    experience,
    license,
  ];

  /// From JSON - with null-safe parsing and field name variations
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle both direct latitude/longitude and nested location object
    double? lat;
    double? lon;

    // Check depotLocation first (for worker data)
    if (json.containsKey('depotLocation') && json['depotLocation'] != null) {
      lat = json['depotLocation']['latitude'] != null
          ? double.tryParse(json['depotLocation']['latitude'].toString())
          : null;
      lon = json['depotLocation']['longitude'] != null
          ? double.tryParse(json['depotLocation']['longitude'].toString())
          : null;
    } else if (json.containsKey('location') && json['location'] != null) {
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

    // Parse skills array
    List<String>? skills;
    if (json['skills'] != null) {
      if (json['skills'] is List) {
        skills = (json['skills'] as List).map((e) => e.toString()).toList();
      }
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
      role: json['role']?.toString() ?? 'worker',
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
      // Worker-specific fields
      personnelRole: json['personnelRole']?.toString(),
      depotId: json['depotId']?.toString(),
      depotName: json['depotName']?.toString(),
      groupId: json['groupId']?.toString(),
      groupName: json['groupName']?.toString(),
      groupCode: json['groupCode']?.toString(),
      roleInGroup: json['roleInGroup']?.toString(),
      operatingArea: json['operatingArea']?.toString(),
      vehicleId: json['vehicleId']?.toString(),
      vehiclePlate: json['vehiclePlate']?.toString(),
      vehicleType: json['vehicleType']?.toString(),
      skills: skills,
      experience: json['experience'] != null
          ? int.tryParse(json['experience'].toString())
          : null,
      license: json['license']?.toString(),
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'email': email,
      'full_name': fullName,
      'fullName': fullName,
      'role': role,
      'address': address,
      'location': latitude != null && longitude != null
          ? {'latitude': latitude, 'longitude': longitude}
          : null,
      'latitude': latitude,
      'longitude': longitude,
      'avatar_url': avatarUrl,
      'avatarUrl': avatarUrl,
      'is_verified': isVerified,
      'isVerified': isVerified,
      'is_active': isActive,
      'isActive': isActive,
      'fcm_token': fcmToken,
      'fcmToken': fcmToken,
      'created_at': createdAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      // Worker-specific fields
      'personnelRole': personnelRole,
      'depotId': depotId,
      'depotName': depotName,
      'groupId': groupId,
      'groupName': groupName,
      'groupCode': groupCode,
      'roleInGroup': roleInGroup,
      'operatingArea': operatingArea,
      'vehicleId': vehicleId,
      'vehiclePlate': vehiclePlate,
      'vehicleType': vehicleType,
      'skills': skills,
      'experience': experience,
      'license': license,
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
    String? personnelRole,
    String? depotId,
    String? depotName,
    String? groupId,
    String? groupName,
    String? groupCode,
    String? roleInGroup,
    String? operatingArea,
    String? vehicleId,
    String? vehiclePlate,
    String? vehicleType,
    List<String>? skills,
    int? experience,
    String? license,
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
      personnelRole: personnelRole ?? this.personnelRole,
      depotId: depotId ?? this.depotId,
      depotName: depotName ?? this.depotName,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      groupCode: groupCode ?? this.groupCode,
      roleInGroup: roleInGroup ?? this.roleInGroup,
      operatingArea: operatingArea ?? this.operatingArea,
      vehicleId: vehicleId ?? this.vehicleId,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleType: vehicleType ?? this.vehicleType,
      skills: skills ?? this.skills,
      experience: experience ?? this.experience,
      license: license ?? this.license,
    );
  }
}
