import 'package:equatable/equatable.dart';
import '../../../data/models/collection_request.dart';

/// Base state cho Collection
abstract class CollectionState extends Equatable {
  const CollectionState();

  @override
  List<Object?> get props => [];
}

/// State: Initial
class CollectionInitial extends CollectionState {
  const CollectionInitial();
}

/// State: Loading
class CollectionLoading extends CollectionState {
  const CollectionLoading();
}

/// State: Loaded
class CollectionsLoaded extends CollectionState {
  final List<CollectionRequest> allCollections;
  final List<CollectionRequest> todayCollections;
  final List<CollectionRequest> pendingCollections;
  final List<CollectionRequest> completedCollections;
  final String? filterStatus;

  const CollectionsLoaded({
    required this.allCollections,
    required this.todayCollections,
    required this.pendingCollections,
    required this.completedCollections,
    this.filterStatus,
  });

  /// Lấy filtered collections
  List<CollectionRequest> get filteredCollections {
    if (filterStatus == null) return allCollections;
    return allCollections.where((c) => c.status == filterStatus).toList();
  }

  @override
  List<Object?> get props => [
    allCollections,
    todayCollections,
    pendingCollections,
    completedCollections,
    filterStatus,
  ];
}

/// State: Collection selected
class CollectionSelected extends CollectionState {
  final CollectionRequest request;

  const CollectionSelected({required this.request});

  @override
  List<Object?> get props => [request];
}

/// State: Action in progress
class CollectionActionInProgress extends CollectionState {
  const CollectionActionInProgress();
}

/// State: Action success
class CollectionActionSuccess extends CollectionState {
  final String message;

  const CollectionActionSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

/// State: Error
class CollectionError extends CollectionState {
  final String message;

  const CollectionError({required this.message});

  @override
  List<Object?> get props => [message];
}
