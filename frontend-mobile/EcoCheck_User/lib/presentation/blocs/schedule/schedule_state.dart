import 'package:equatable/equatable.dart';
import 'package:eco_check/data/models/schedule_model.dart';

/// Schedule States
abstract class ScheduleState extends Equatable {
  const ScheduleState();

  @override
  List<Object?> get props => [];
}

/// Initial State
class ScheduleInitial extends ScheduleState {
  const ScheduleInitial();
}

/// Loading State
class ScheduleLoading extends ScheduleState {
  const ScheduleLoading();
}

/// Loaded State
class ScheduleLoaded extends ScheduleState {
  final List<ScheduleModel> schedules;

  const ScheduleLoaded(this.schedules);

  @override
  List<Object?> get props => [schedules];
}

/// Detail Loaded State
class ScheduleDetailLoaded extends ScheduleState {
  final ScheduleModel schedule;

  const ScheduleDetailLoaded(this.schedule);

  @override
  List<Object?> get props => [schedule];
}

/// Creating State
class ScheduleCreating extends ScheduleState {
  const ScheduleCreating();
}

/// Created Success State
class ScheduleCreated extends ScheduleState {
  final ScheduleModel schedule;

  const ScheduleCreated(this.schedule);

  @override
  List<Object?> get props => [schedule];
}

/// Cancelling State
class ScheduleCancelling extends ScheduleState {
  const ScheduleCancelling();
}

/// Cancelled Success State
class ScheduleCancelled extends ScheduleState {
  final String scheduleId;

  const ScheduleCancelled(this.scheduleId);

  @override
  List<Object?> get props => [scheduleId];
}

/// Error State
class ScheduleError extends ScheduleState {
  final String message;

  const ScheduleError(this.message);

  @override
  List<Object?> get props => [message];
}
