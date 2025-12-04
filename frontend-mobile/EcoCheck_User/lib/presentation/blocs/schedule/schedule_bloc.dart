/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck User
 */

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eco_check/data/repositories/ecocheck_repository.dart';
import 'package:eco_check/data/services/socket_service.dart';
import 'package:eco_check/core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'schedule_event.dart';
import 'schedule_state.dart';

/// Schedule BLoC with Backend Integration and Real-time Updates
class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  final EcoCheckRepository repository;
  final SharedPreferences? prefs;
  final SocketService? socketService;

  StreamSubscription? _scheduleUpdateSubscription;
  StreamSubscription? _scheduleCompletedSubscription;
  StreamSubscription? _pointsEarnedSubscription;

  ScheduleBloc({required this.repository, this.prefs, this.socketService})
    : super(const ScheduleInitial()) {
    on<SchedulesLoaded>(_onSchedulesLoaded);
    on<ScheduleCreateRequested>(_onScheduleCreateRequested);
    on<ScheduleCancelRequested>(_onScheduleCancelRequested);
    on<ScheduleDetailRequested>(_onScheduleDetailRequested);
    on<ScheduleRealtimeUpdated>(_onScheduleRealtimeUpdated);

    // Listen to Socket.IO events
    _initializeSocketListeners();
  }

  /// Initialize Socket.IO event listeners
  void _initializeSocketListeners() {
    if (socketService == null) return;

    // Connect to socket
    final userId = _getCitizenId();
    socketService!.connect(userId: userId);

    // Listen for schedule updates (when web assigns employee)
    _scheduleUpdateSubscription = socketService!.scheduleUpdated.listen((data) {
      print(
        '🔄 [ScheduleBloc] Real-time update received: ${data['schedule_id']}',
      );
      add(ScheduleRealtimeUpdated(data));
    });

    // Listen for schedule completion (when worker completes task)
    _scheduleCompletedSubscription = socketService!.scheduleCompleted.listen((
      data,
    ) {
      print('✅ [ScheduleBloc] Schedule completed: ${data['schedule_id']}');
      add(ScheduleRealtimeUpdated(data));
    });

    // Listen for points earned
    _pointsEarnedSubscription = socketService!.pointsEarned.listen((data) {
      print('🎁 [ScheduleBloc] Points earned: ${data['points']} points');
      // TODO: Update gamification state
    });
  }

  /// Get citizen ID from SharedPreferences or use default
  String _getCitizenId() {
    return prefs?.getString(AppConstants.keyUserId) ?? 'user-123';
  }

  /// Load Schedules from Backend
  Future<void> _onSchedulesLoaded(
    SchedulesLoaded event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(const ScheduleLoading());

    try {
      final citizenId = _getCitizenId();
      final schedules = await repository.getSchedules(
        citizenId: citizenId,
        status: event.status,
      );

      emit(ScheduleLoaded(schedules));
    } catch (e) {
      final errorMsg = _getErrorMessage(e);
      emit(ScheduleError(errorMsg));
    }
  }

  /// Create Schedule via Backend API
  Future<void> _onScheduleCreateRequested(
    ScheduleCreateRequested event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(const ScheduleCreating());

    try {
      final citizenId = _getCitizenId();

      final newSchedule = await repository.createSchedule(
        citizenId: citizenId,
        scheduledDate: event.scheduledDate,
        timeSlot: event.timeSlot,
        wasteType: event.wasteType,
        estimatedWeight: event.estimatedWeight,
        latitude: event.latitude,
        longitude: event.longitude,
        address: event.address,
      );

      emit(ScheduleCreated(newSchedule));

      // Reload list after creation
      await Future.delayed(const Duration(milliseconds: 500));
      add(const SchedulesLoaded());
    } catch (e) {
      final errorMsg = _getErrorMessage(e);
      emit(ScheduleError('Đặt lịch thất bại: $errorMsg'));
    }
  }

  /// Cancel Schedule via Backend API
  Future<void> _onScheduleCancelRequested(
    ScheduleCancelRequested event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(const ScheduleCancelling());

    try {
      await repository.cancelSchedule(event.scheduleId);

      emit(ScheduleCancelled(event.scheduleId));

      // Reload list
      await Future.delayed(const Duration(milliseconds: 300));
      add(const SchedulesLoaded());
    } catch (e) {
      final errorMsg = _getErrorMessage(e);
      emit(ScheduleError('Hủy lịch thất bại: $errorMsg'));
    }
  }

  /// Load Schedule Detail via Backend API
  Future<void> _onScheduleDetailRequested(
    ScheduleDetailRequested event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(const ScheduleLoading());

    try {
      final schedule = await repository.getScheduleById(event.scheduleId);

      emit(ScheduleDetailLoaded(schedule));
    } catch (e) {
      final errorMsg = _getErrorMessage(e);
      emit(ScheduleError(errorMsg));
    }
  }

  /// Handle Real-time Schedule Update from Socket.IO
  Future<void> _onScheduleRealtimeUpdated(
    ScheduleRealtimeUpdated event,
    Emitter<ScheduleState> emit,
  ) async {
    final data = event.data;

    // If we're currently viewing a detail page, update it
    if (state is ScheduleDetailLoaded) {
      final currentSchedule = (state as ScheduleDetailLoaded).schedule;

      // Check if the update is for the current schedule
      if (currentSchedule.id == data['schedule_id']) {
        try {
          // Fetch fresh data from backend
          final updatedSchedule = await repository.getScheduleById(
            data['schedule_id'],
          );
          emit(ScheduleDetailLoaded(updatedSchedule));

          print(
            '📱 [ScheduleBloc] Detail view updated: ${updatedSchedule.status}',
          );
        } catch (e) {
          print('⚠️ [ScheduleBloc] Failed to fetch updated schedule: $e');
          // Keep current state on error
        }
      }
    }

    // If we're viewing a list, reload it
    if (state is ScheduleLoaded) {
      print(
        '📱 [ScheduleBloc] Reloading schedule list due to real-time update',
      );
      add(const SchedulesLoaded());
    }
  }

  /// Extract user-friendly error message
  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString();

    // Extract message from ApiException
    if (errorStr.contains('ApiException:')) {
      return errorStr.split('ApiException:').last.trim();
    }

    // Extract message from Exception
    if (errorStr.contains('Exception:')) {
      return errorStr.split('Exception:').last.trim();
    }

    // Check for common errors
    if (errorStr.contains('SocketException') ||
        errorStr.contains('Failed host lookup')) {
      return 'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.';
    }

    if (errorStr.contains('TimeoutException')) {
      return 'Kết nối quá lâu. Vui lòng thử lại.';
    }

    if (errorStr.contains('FormatException')) {
      return 'Dữ liệu không hợp lệ từ server.';
    }

    // Return original if can't extract
    return errorStr;
  }

  @override
  Future<void> close() {
    // Cancel socket subscriptions
    _scheduleUpdateSubscription?.cancel();
    _scheduleCompletedSubscription?.cancel();
    _pointsEarnedSubscription?.cancel();

    return super.close();
  }
}
