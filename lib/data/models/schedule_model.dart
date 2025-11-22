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
    return ScheduleModel(
      id: json['id'] as String,
      citizenId: json['citizen_id'] as String,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      timeSlot: json['time_slot'] as String,
      wasteType: json['waste_type'] as String,
      estimatedWeight: json['estimated_weight'] != null
          ? (json['estimated_weight'] as num).toDouble()
          : null,
      latitude: (json['location']['latitude'] as num).toDouble(),
      longitude: (json['location']['longitude'] as num).toDouble(),
      address: json['address'] as String,
      specialInstructions: json['special_instructions'] as String?,
      status: json['status'] as String,
      priority: json['priority'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
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
