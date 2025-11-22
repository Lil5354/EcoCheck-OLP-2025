import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/collection_repository.dart';
import 'collection_event.dart';
import 'collection_state.dart';

/// BLoC quản lý collections
class CollectionBloc extends Bloc<CollectionEvent, CollectionState> {
  final CollectionRepository _collectionRepository;

  CollectionBloc({required CollectionRepository collectionRepository})
    : _collectionRepository = collectionRepository,
      super(const CollectionInitial()) {
    on<LoadCollectionsRequested>(_onLoadCollectionsRequested);
    on<LoadTodayCollectionsRequested>(_onLoadTodayCollectionsRequested);
    on<FilterCollectionsByStatus>(_onFilterCollectionsByStatus);
    on<UpdateCollectionStatusRequested>(_onUpdateCollectionStatusRequested);
    on<SelectCollectionRequested>(_onSelectCollectionRequested);
  }

  /// Handler: Load all collections
  Future<void> _onLoadCollectionsRequested(
    LoadCollectionsRequested event,
    Emitter<CollectionState> emit,
  ) async {
    emit(const CollectionLoading());

    try {
      final allCollections = await _collectionRepository.getAllCollections();
      final todayCollections = await _collectionRepository
          .getTodayCollections();
      final pendingCollections = await _collectionRepository
          .getPendingCollections();
      final completedCollections = await _collectionRepository
          .getCompletedCollections();

      emit(
        CollectionsLoaded(
          allCollections: allCollections,
          todayCollections: todayCollections,
          pendingCollections: pendingCollections,
          completedCollections: completedCollections,
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
      final todayCollections = await _collectionRepository
          .getTodayCollections();

      if (state is CollectionsLoaded) {
        final currentState = state as CollectionsLoaded;
        emit(
          CollectionsLoaded(
            allCollections: currentState.allCollections,
            todayCollections: todayCollections,
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
        final updatedCollection = await _collectionRepository
            .updateCollectionStatus(
              requestId: event.requestId,
              status: event.status,
              actualWeight: event.actualWeight,
              notes: event.notes,
              images: event.images,
            );

        // Update all collections
        final updatedAllCollections = currentState.allCollections.map((c) {
          return c.id == updatedCollection.id ? updatedCollection : c;
        }).toList();

        // Re-filter other lists
        final updatedToday = updatedAllCollections
            .where((c) => _isToday(c.scheduledDate ?? c.createdAt))
            .toList();
        final updatedPending = updatedAllCollections
            .where((c) => c.status == 'pending' || c.status == 'assigned')
            .toList();
        final updatedCompleted = updatedAllCollections
            .where((c) => c.status == 'collected' || c.status == 'completed')
            .toList();

        emit(const CollectionActionSuccess(message: 'Đã cập nhật trạng thái'));

        emit(
          CollectionsLoaded(
            allCollections: updatedAllCollections,
            todayCollections: updatedToday,
            pendingCollections: updatedPending,
            completedCollections: updatedCompleted,
            filterStatus: currentState.filterStatus,
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
    emit(CollectionSelected(request: event.request));
  }

  /// Helper: Check if date is today
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
