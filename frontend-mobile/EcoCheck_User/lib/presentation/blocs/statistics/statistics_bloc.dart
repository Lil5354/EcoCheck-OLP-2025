import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eco_check/data/repositories/ecocheck_repository.dart';
import 'statistics_event.dart';
import 'statistics_state.dart';

/// Statistics BLoC
class StatisticsBloc extends Bloc<StatisticsEvent, StatisticsState> {
  final EcoCheckRepository _repository;

  StatisticsBloc({required EcoCheckRepository repository})
    : _repository = repository,
      super(const StatisticsInitial()) {
    on<LoadStatisticsSummary>(_onLoadStatisticsSummary);
    on<RefreshStatistics>(_onRefreshStatistics);
  }

  /// Load Statistics Summary
  Future<void> _onLoadStatisticsSummary(
    LoadStatisticsSummary event,
    Emitter<StatisticsState> emit,
  ) async {
    emit(const StatisticsLoading());

    try {
      final summary = await _repository.getStatisticsSummary(event.userId);
      emit(StatisticsLoaded(summary));
    } catch (e) {
      emit(StatisticsError('Không thể tải thống kê: ${e.toString()}'));
    }
  }

  /// Refresh Statistics
  Future<void> _onRefreshStatistics(
    RefreshStatistics event,
    Emitter<StatisticsState> emit,
  ) async {
    // Keep current state while refreshing
    final currentState = state;

    try {
      final summary = await _repository.getStatisticsSummary(event.userId);
      emit(StatisticsLoaded(summary));
    } catch (e) {
      // If refresh fails, keep current data and show error briefly
      if (currentState is StatisticsLoaded) {
        emit(currentState);
      } else {
        emit(StatisticsError('Không thể làm mới: ${e.toString()}'));
      }
    }
  }
}
