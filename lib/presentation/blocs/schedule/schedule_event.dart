import 'package:equatable/equatable.dart';

/// Schedule Events
abstract class ScheduleEvent extends Equatable {
  const ScheduleEvent();

  @override
  List<Object?> get props => [];
}

/// Load Schedules by Status
class SchedulesLoaded extends ScheduleEvent {
  final String? status; // null = all, 'pending', 'confirmed', 'completed'

  const SchedulesLoaded({this.status});

  @override
  List<Object?> get props => [status];
}

/// Create Schedule
class ScheduleCreateRequested extends ScheduleEvent {
  final String wasteType;
  final String timeSlot;
  final DateTime scheduledDate;
  final double estimatedWeight;
  final String address;
  final double latitude;
  final double longitude;

  const ScheduleCreateRequested({
    required this.wasteType,
    required this.timeSlot,
    required this.scheduledDate,
    required this.estimatedWeight,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [
    wasteType,
    timeSlot,
    scheduledDate,
    estimatedWeight,
    address,
    latitude,
    longitude,
  ];
}

/// Cancel Schedule
class ScheduleCancelRequested extends ScheduleEvent {
  final String scheduleId;

  const ScheduleCancelRequested(this.scheduleId);

  @override
  List<Object?> get props => [scheduleId];
}

/// Load Schedule Detail
class ScheduleDetailRequested extends ScheduleEvent {
  final String scheduleId;

  const ScheduleDetailRequested(this.scheduleId);

  @override
  List<Object?> get props => [scheduleId];
}
