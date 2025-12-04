/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck User
 */
class IncidentModel {
  final String id;
  final String reporterId;
  final String? reporterName;
  final String? reporterPhone;
  final String reportCategory; // 'violation' or 'damage'
  final String type;
  final String description;
  final double? latitude;
  final double? longitude;
  final String? locationAddress;
  final List<String> imageUrls;
  final String status; // pending, open, in_progress, resolved, closed, rejected
  final String priority; // low, medium, high, urgent
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final String? resolutionNotes;

  IncidentModel({
    required this.id,
    required this.reporterId,
    this.reporterName,
    this.reporterPhone,
    required this.reportCategory,
    required this.type,
    required this.description,
    this.latitude,
    this.longitude,
    this.locationAddress,
    this.imageUrls = const [],
    required this.status,
    this.priority = 'medium',
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.resolutionNotes,
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    // Parse image_urls from database array format
    List<String> parseImageUrls(dynamic imageUrls) {
      if (imageUrls == null) return [];
      if (imageUrls is List) {
        return imageUrls.map((e) => e.toString()).toList();
      }
      if (imageUrls is String) {
        // Handle PostgreSQL array string format: {url1,url2,url3}
        if (imageUrls.startsWith('{') && imageUrls.endsWith('}')) {
          return imageUrls
              .substring(1, imageUrls.length - 1)
              .split(',')
              .where((s) => s.isNotEmpty)
              .toList();
        }
        return [imageUrls];
      }
      return [];
    }

    // Parse coordinates from PostGIS geometry
    double? parseLat(dynamic geom) {
      if (geom == null) return null;
      // PostGIS returns geometry as hex string, needs parsing
      // For now, use separate latitude field if available
      return json['latitude']?.toDouble();
    }

    double? parseLon(dynamic geom) {
      if (geom == null) return null;
      return json['longitude']?.toDouble();
    }

    return IncidentModel(
      id: json['id'] ?? '',
      reporterId: json['reporter_id'] ?? '',
      reporterName: json['reporter_name'],
      reporterPhone: json['reporter_phone'],
      reportCategory: json['report_category'] ?? 'violation',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      latitude: parseLat(json['geom']),
      longitude: parseLon(json['geom']),
      locationAddress: json['location_address'],
      imageUrls: parseImageUrls(json['image_urls']),
      status: json['status'] ?? 'pending',
      priority: json['priority'] ?? 'medium',
      assignedTo: json['assigned_to'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'])
          : null,
      resolutionNotes: json['resolution_notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporter_id': reporterId,
      'reporter_name': reporterName,
      'reporter_phone': reporterPhone,
      'report_category': reportCategory,
      'type': type,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'location_address': locationAddress,
      'image_urls': imageUrls,
      'status': status,
      'priority': priority,
      'assigned_to': assignedTo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolution_notes': resolutionNotes,
    };
  }

  // Helper methods
  String get categoryLabel {
    return reportCategory == 'violation' ? 'Vi phạm' : 'Hư hỏng';
  }

  String get typeLabel {
    const typeMap = {
      // Violations
      'illegal_dump': 'Vứt rác trái phép',
      'wrong_classification': 'Phân loại sai',
      'overloaded_bin': 'Thùng rác quá tải',
      'littering': 'Xả rác bừa bãi',
      'burning_waste': 'Đốt rác',
      // Damages
      'broken_bin': 'Thùng rác hỏng',
      'damaged_equipment': 'Thiết bị hư hỏng',
      'road_damage': 'Đường bị hư',
      'facility_damage': 'Cơ sở vật chất hư hỏng',
      // Other
      'missed_collection': 'Bỏ sót thu gom',
      'overflow': 'Tràn rác',
      'vehicle_issue': 'Sự cố xe',
      'other': 'Khác',
    };
    return typeMap[type] ?? type;
  }

  String get statusLabel {
    const statusMap = {
      'pending': 'Chờ xử lý',
      'open': 'Đã tiếp nhận',
      'in_progress': 'Đang xử lý',
      'resolved': 'Đã giải quyết',
      'closed': 'Đã đóng',
      'rejected': 'Từ chối',
    };
    return statusMap[status] ?? status;
  }

  String get priorityLabel {
    const priorityMap = {
      'low': 'Thấp',
      'medium': 'Trung bình',
      'high': 'Cao',
      'urgent': 'Khẩn cấp',
    };
    return priorityMap[priority] ?? priority;
  }
}
