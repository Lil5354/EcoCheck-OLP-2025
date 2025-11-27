import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eco_check/data/repositories/ecocheck_repository.dart';
import 'package:eco_check/core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'schedule_event.dart';
import 'schedule_state.dart';

/// Schedule BLoC with Backend Integration
class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  final EcoCheckRepository repository;
  final SharedPreferences? prefs;

  ScheduleBloc({required this.repository, this.prefs})
    : super(const ScheduleInitial()) {
    on<SchedulesLoaded>(_onSchedulesLoaded);
    on<ScheduleCreateRequested>(_onScheduleCreateRequested);
    on<ScheduleCancelRequested>(_onScheduleCancelRequested);
    on<ScheduleDetailRequested>(_onScheduleDetailRequested);
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
}
