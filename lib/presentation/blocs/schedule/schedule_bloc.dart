import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eco_check/data/models/schedule_model.dart';
import 'package:eco_check/core/constants/app_constants.dart';
import 'schedule_event.dart';
import 'schedule_state.dart';

/// Schedule BLoC
class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  ScheduleBloc() : super(const ScheduleInitial()) {
    on<SchedulesLoaded>(_onSchedulesLoaded);
    on<ScheduleCreateRequested>(_onScheduleCreateRequested);
    on<ScheduleCancelRequested>(_onScheduleCancelRequested);
    on<ScheduleDetailRequested>(_onScheduleDetailRequested);
  }

  // Mock data repository
  final List<ScheduleModel> _mockSchedules = [
    ScheduleModel(
      id: 'schedule-001',
      citizenId: 'user-123',
      scheduledDate: DateTime.now().add(const Duration(days: 2)),
      timeSlot: AppConstants.timeSlotMorning,
      wasteType: AppConstants.wasteTypeOrganic,
      estimatedWeight: 5.0,
      latitude: 10.762622,
      longitude: 106.660172,
      address: '123 Nguyễn Huệ, Q1, TP.HCM',
      status: AppConstants.statusPending,
      priority: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    ScheduleModel(
      id: 'schedule-002',
      citizenId: 'user-123',
      scheduledDate: DateTime.now().add(const Duration(days: 5)),
      timeSlot: AppConstants.timeSlotAfternoon,
      wasteType: AppConstants.wasteTypeRecyclable,
      estimatedWeight: 3.0,
      latitude: 10.762622,
      longitude: 106.660172,
      address: '123 Nguyễn Huệ, Q1, TP.HCM',
      status: AppConstants.statusConfirmed,
      priority: 0,
      employeeId: 'emp-001',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  /// Load Schedules
  Future<void> _onSchedulesLoaded(
    SchedulesLoaded event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(const ScheduleLoading());

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      List<ScheduleModel> schedules = _mockSchedules;

      // Filter by status if provided
      if (event.status != null) {
        schedules = schedules
            .where((schedule) => schedule.status == event.status)
            .toList();
      }

      emit(ScheduleLoaded(schedules));
    } catch (e) {
      emit(ScheduleError('Không thể tải lịch: ${e.toString()}'));
    }
  }

  /// Create Schedule
  Future<void> _onScheduleCreateRequested(
    ScheduleCreateRequested event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(const ScheduleCreating());

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      final newSchedule = ScheduleModel(
        id: 'schedule-${DateTime.now().millisecondsSinceEpoch}',
        citizenId: 'user-123',
        scheduledDate: event.scheduledDate,
        timeSlot: event.timeSlot,
        wasteType: event.wasteType,
        estimatedWeight: event.estimatedWeight,
        latitude: event.latitude,
        longitude: event.longitude,
        address: event.address,
        status: AppConstants.statusPending,
        priority: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add to mock repository
      _mockSchedules.insert(0, newSchedule);

      emit(ScheduleCreated(newSchedule));

      // Reload list after creation
      await Future.delayed(const Duration(milliseconds: 500));
      add(const SchedulesLoaded());
    } catch (e) {
      emit(ScheduleError('Đặt lịch thất bại: ${e.toString()}'));
    }
  }

  /// Cancel Schedule
  Future<void> _onScheduleCancelRequested(
    ScheduleCancelRequested event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(const ScheduleCancelling());

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Update mock data
      final index = _mockSchedules.indexWhere((s) => s.id == event.scheduleId);
      if (index != -1) {
        _mockSchedules[index] = _mockSchedules[index].copyWith(
          status: AppConstants.statusCancelled,
          updatedAt: DateTime.now(),
        );
      }

      emit(ScheduleCancelled(event.scheduleId));

      // Reload list
      await Future.delayed(const Duration(milliseconds: 500));
      add(const SchedulesLoaded());
    } catch (e) {
      emit(ScheduleError('Hủy lịch thất bại: ${e.toString()}'));
    }
  }

  /// Load Schedule Detail
  Future<void> _onScheduleDetailRequested(
    ScheduleDetailRequested event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(const ScheduleLoading());

    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      final schedule = _mockSchedules.firstWhere(
        (s) => s.id == event.scheduleId,
        orElse: () => throw Exception('Không tìm thấy lịch'),
      );

      emit(ScheduleDetailLoaded(schedule));
    } catch (e) {
      emit(ScheduleError('Không thể tải chi tiết: ${e.toString()}'));
    }
  }
}
