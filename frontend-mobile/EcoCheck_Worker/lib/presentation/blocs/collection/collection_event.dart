import 'package:equatable/equatable.dart';
import '../../../data/models/schedule_model.dart';

/// Base event cho Collection
abstract class CollectionEvent extends Equatable {
  const CollectionEvent();

  @override
  List<Object?> get props => [];
}

/// Event: Load tất cả collections
class LoadCollectionsRequested extends CollectionEvent {
  const LoadCollectionsRequested();
}

/// Event: Load today collections
class LoadTodayCollectionsRequested extends CollectionEvent {
  const LoadTodayCollectionsRequested();
}

/// Event: Filter by status
class FilterCollectionsByStatus extends CollectionEvent {
  final String status;

  const FilterCollectionsByStatus({required this.status});

  @override
  List<Object?> get props => [status];
}

/// Event: Update collection status
class UpdateCollectionStatusRequested extends CollectionEvent {
  final String requestId;
  final String status;
  final double? actualWeight;
  final String? notes;
  final List<String>? images;

  const UpdateCollectionStatusRequested({
    required this.requestId,
    required this.status,
    this.actualWeight,
    this.notes,
    this.images,
  });

  @override
  List<Object?> get props => [requestId, status, actualWeight, notes, images];
}

/// Event: Select collection
class SelectCollectionRequested extends CollectionEvent {
  final ScheduleModel collection;

  const SelectCollectionRequested({required this.collection});

  @override
  List<Object?> get props => [collection];
}
