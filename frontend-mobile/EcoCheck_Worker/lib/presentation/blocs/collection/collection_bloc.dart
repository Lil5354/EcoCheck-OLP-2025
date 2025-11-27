import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/schedule_model.dart';
import '../../../data/repositories/ecocheck_repository.dart';
import 'collection_event.dart';
import 'collection_state.dart';

/// BLoC quản lý collections - sử dụng backend thực
class CollectionBloc extends Bloc<CollectionEvent, CollectionState> {
  final EcoCheckRepository _repository;

  CollectionBloc({required EcoCheckRepository repository})
    : _repository = repository,
      super(const CollectionInitial()) {
    on<LoadCollectionsRequested>(_onLoadCollectionsRequested);
    on<LoadTodayCollectionsRequested>(_onLoadTodayCollectionsRequested);
    on<FilterCollectionsByStatus>(_onFilterCollectionsByStatus);
    on<UpdateCollectionStatusRequested>(_onUpdateCollectionStatusRequested);
    on<SelectCollectionRequested>(_onSelectCollectionRequested);
  }

  /// Handler: Load all collections (assigned schedules)
  Future<void> _onLoadCollectionsRequested(
    LoadCollectionsRequested event,
    Emitter<CollectionState> emit,
  ) async {
    emit(const CollectionLoading());

    try {
      final allSchedules = await _repository.getAssignedSchedules();

      // Filter by status
      final today = DateTime.now();
      final todaySchedules = allSchedules
          .where(
            (s) =>
                s.scheduledDate.year == today.year &&
                s.scheduledDate.month == today.month &&
                s.scheduledDate.day == today.day,
          )
          .toList();

      final pendingSchedules = allSchedules
          .where((s) => s.status == 'assigned' || s.status == 'scheduled')
          .toList();

      final completedSchedules = allSchedules
          .where((s) => s.status == 'completed')
          .toList();

      emit(
        CollectionsLoaded(
          allCollections: allSchedules,
          todayCollections: todaySchedules,
          pendingCollections: pendingSchedules,
          completedCollections: completedSchedules,
        ),
      );
    } catch (e) {
      emit(CollectionError(message: e.toString()));
    }
  }

  /// Handler: Load today collections
  Future<void> _onLoadTodayCollectionsRequested(
    LoadTodayCollectionsRequested event,
    Emitter<CollectionState> emit,
  ) async {
    try {
      final allSchedules = await _repository.getAssignedSchedules();

      final today = DateTime.now();
      final todaySchedules = allSchedules
          .where(
            (s) =>
                s.scheduledDate.year == today.year &&
                s.scheduledDate.month == today.month &&
                s.scheduledDate.day == today.day,
          )
          .toList();

      if (state is CollectionsLoaded) {
        final currentState = state as CollectionsLoaded;
        emit(
          CollectionsLoaded(
            allCollections: currentState.allCollections,
            todayCollections: todaySchedules,
            pendingCollections: currentState.pendingCollections,
            completedCollections: currentState.completedCollections,
          ),
        );
      }
    } catch (e) {
      emit(CollectionError(message: e.toString()));
    }
  }

  /// Handler: Filter by status
  Future<void> _onFilterCollectionsByStatus(
    FilterCollectionsByStatus event,
    Emitter<CollectionState> emit,
  ) async {
    if (state is CollectionsLoaded) {
      final currentState = state as CollectionsLoaded;
      emit(
        CollectionsLoaded(
          allCollections: currentState.allCollections,
          todayCollections: currentState.todayCollections,
          pendingCollections: currentState.pendingCollections,
          completedCollections: currentState.completedCollections,
          filterStatus: event.status,
        ),
      );
    }
  }

  /// Handler: Update collection status
  Future<void> _onUpdateCollectionStatusRequested(
    UpdateCollectionStatusRequested event,
    Emitter<CollectionState> emit,
  ) async {
    if (state is CollectionsLoaded) {
      final currentState = state as CollectionsLoaded;
      emit(const CollectionActionInProgress());

      try {
        late ScheduleModel updatedSchedule;

        if (event.status == 'in_progress') {
          updatedSchedule = await _repository.startSchedule(event.requestId);
        } else if (event.status == 'completed') {
          updatedSchedule = await _repository.completeSchedule(
            scheduleId: event.requestId,
            actualWeight: event.actualWeight ?? 0.0,
            notes: event.notes,
          );
        } else {
          throw Exception('Unsupported status: ${event.status}');
        }

        // Update collections list
        final updatedCollections = currentState.allCollections.map((s) {
          return s.id == updatedSchedule.id ? updatedSchedule : s;
        }).toList();

        // Reload categorized lists
        final today = DateTime.now();
        final todaySchedules = updatedCollections
            .where(
              (s) =>
                  s.scheduledDate.year == today.year &&
                  s.scheduledDate.month == today.month &&
                  s.scheduledDate.day == today.day,
            )
            .toList();

        final pendingSchedules = updatedCollections
            .where((s) => s.status == 'assigned' || s.status == 'scheduled')
            .toList();

        final completedSchedules = updatedCollections
            .where((s) => s.status == 'completed')
            .toList();

        emit(
          CollectionActionSuccess(
            message: 'Đã cập nhật trạng thái',
            allCollections: updatedCollections,
            todayCollections: todaySchedules,
            pendingCollections: pendingSchedules,
            completedCollections: completedSchedules,
          ),
        );

        // Return to loaded state
        emit(
          CollectionsLoaded(
            allCollections: updatedCollections,
            todayCollections: todaySchedules,
            pendingCollections: pendingSchedules,
            completedCollections: completedSchedules,
          ),
        );
      } catch (e) {
        emit(CollectionError(message: e.toString()));
      }
    }
  }

  /// Handler: Select collection
  Future<void> _onSelectCollectionRequested(
    SelectCollectionRequested event,
    Emitter<CollectionState> emit,
  ) async {
    emit(CollectionSelected(collection: event.collection));
  }
}
