import 'package:equatable/equatable.dart';

/// Schedule Model
class ScheduleModel extends Equatable {
  final String id;
  final String citizenId;
  final DateTime scheduledDate;
  final String timeSlot; // morning, afternoon, evening
  final String wasteType; // organic, recyclable, hazardous, general
  final double? estimatedWeight; // kg
  final double? actualWeight; // kg
  final double latitude;
  final double longitude;
  final String address;
  final String? specialInstructions;
  final String? notes;
  final String
  status; // pending, confirmed, assigned, in_progress, completed, cancelled
  final int priority; // 0: normal, 1: high, 2: urgent
  final String? employeeId;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ScheduleModel({
    required this.id,
    required this.citizenId,
    required this.scheduledDate,
    required this.timeSlot,
    required this.wasteType,
    this.estimatedWeight,
    this.actualWeight,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.specialInstructions,
    this.notes,
    required this.status,
    this.priority = 0,
    this.employeeId,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    citizenId,
    scheduledDate,
    timeSlot,
    wasteType,
    estimatedWeight,
    actualWeight,
    latitude,
    longitude,
    address,
    specialInstructions,
    notes,
    status,
    priority,
    employeeId,
    completedAt,
    createdAt,
    updatedAt,
  ];

  /// From JSON
  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    try {
      // Handle both formats: direct lat/lon or nested location object
      double lat = 0.0;
      double lon = 0.0;

      if (json.containsKey('location') && json['location'] != null) {
        // Nested format: {location: {latitude: x, longitude: y}}
        final location = json['location'];
        if (location is Map<String, dynamic>) {
          lat = double.tryParse(location['latitude']?.toString() ?? '0') ?? 0.0;
          lon =
              double.tryParse(location['longitude']?.toString() ?? '0') ?? 0.0;
        }
      } else {
        // Direct format: {latitude: x, longitude: y}
        lat = double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0;
        lon = double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0;
      }

      // Handle schedule_id vs id
      final scheduleId = json['schedule_id'] ?? json['id'] ?? '';

      // Parse dates with fallback
      DateTime? parseDateNullable(dynamic value) {
        if (value == null) return null;
        try {
          return DateTime.parse(value.toString());
        } catch (e) {
          return null;
        }
      }

      DateTime parseDate(dynamic value, DateTime fallback) {
        if (value == null) return fallback;
        try {
          return DateTime.parse(value.toString());
        } catch (e) {
          return fallback;
        }
      }

      final now = DateTime.now();

      return ScheduleModel(
        id: scheduleId.toString(),
        citizenId: json['citizen_id']?.toString() ?? '',
        scheduledDate: parseDate(
          json['scheduled_date'],
          now.add(const Duration(days: 1)),
        ),
        timeSlot: json['time_slot']?.toString() ?? 'morning',
        wasteType: json['waste_type']?.toString() ?? 'general',
        estimatedWeight: double.tryParse(
          json['estimated_weight']?.toString() ?? '0',
        ),
        actualWeight: double.tryParse(json['actual_weight']?.toString() ?? '0'),
        latitude: lat,
        longitude: lon,
        address: json['address']?.toString() ?? '',
        specialInstructions: json['special_instructions']?.toString(),
        notes: json['notes']?.toString(),
        status: json['status']?.toString() ?? 'pending',
        priority: int.tryParse(json['priority']?.toString() ?? '0') ?? 0,
        employeeId: json['employee_id']?.toString(),
        completedAt: parseDateNullable(json['completed_at']),
        createdAt: parseDate(json['created_at'], now),
        updatedAt: parseDate(json['updated_at'], now),
      );
    } catch (e) {
      print('Error parsing ScheduleModel: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'citizen_id': citizenId,
      'scheduled_date': scheduledDate.toIso8601String(),
      'time_slot': timeSlot,
      'waste_type': wasteType,
      'estimated_weight': estimatedWeight,
      'location': {'latitude': latitude, 'longitude': longitude},
      'address': address,
      'special_instructions': specialInstructions,
      'status': status,
      'priority': priority,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with
  ScheduleModel copyWith({
    String? id,
    String? citizenId,
    DateTime? scheduledDate,
    String? timeSlot,
    String? wasteType,
    double? estimatedWeight,
    double? latitude,
    double? longitude,
    String? address,
    String? specialInstructions,
    String? status,
    int? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      citizenId: citizenId ?? this.citizenId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      timeSlot: timeSlot ?? this.timeSlot,
      wasteType: wasteType ?? this.wasteType,
      estimatedWeight: estimatedWeight ?? this.estimatedWeight,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if schedule is editable
  bool get isEditable {
    return status == 'pending' || status == 'confirmed';
  }

  /// Check if schedule is cancellable
  bool get isCancellable {
    return status == 'pending' || status == 'confirmed' || status == 'assigned';
  }

  /// Check if schedule is trackable
  bool get isTrackable {
    return status == 'assigned' || status == 'in_progress';
  }

  /// Get time slot display text
  String get timeSlotDisplay {
    switch (timeSlot) {
      case 'morning':
        return 'Buổi sáng (6:00 - 10:00)';
      case 'afternoon':
        return 'Buổi chiều (13:00 - 17:00)';
      case 'evening':
        return 'Buổi tối (18:00 - 20:00)';
      default:
        return timeSlot;
    }
  }

  /// Get waste type display text
  String get wasteTypeDisplay {
    switch (wasteType) {
      case 'organic':
        return 'Rác hữu cơ';
      case 'recyclable':
        return 'Rác tái chế';
      case 'hazardous':
        return 'Rác nguy hại';
      case 'general':
        return 'Rác thông thường';
      default:
        return wasteType;
    }
  }

  /// Get status display text
  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'assigned':
        return 'Đã phân công';
      case 'in_progress':
        return 'Đang thu gom';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }
}
