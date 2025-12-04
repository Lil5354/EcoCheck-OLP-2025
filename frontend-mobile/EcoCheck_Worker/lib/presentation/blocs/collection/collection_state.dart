/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck Worker
 */

import 'package:equatable/equatable.dart';
import '../../../data/models/schedule_model.dart';

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
  final List<ScheduleModel> allCollections;
  final List<ScheduleModel> todayCollections;
  final List<ScheduleModel> pendingCollections;
  final List<ScheduleModel> completedCollections;
  final String? filterStatus;

  const CollectionsLoaded({
    required this.allCollections,
    required this.todayCollections,
    required this.pendingCollections,
    required this.completedCollections,
    this.filterStatus,
  });

  /// Lấy filtered collections
  List<ScheduleModel> get filteredCollections {
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
  final ScheduleModel collection;

  const CollectionSelected({required this.collection});

  @override
  List<Object?> get props => [collection];
}

/// State: Action in progress
class CollectionActionInProgress extends CollectionState {
  const CollectionActionInProgress();
}

/// State: Action success
class CollectionActionSuccess extends CollectionState {
  final String message;
  final List<ScheduleModel> allCollections;
  final List<ScheduleModel> todayCollections;
  final List<ScheduleModel> pendingCollections;
  final List<ScheduleModel> completedCollections;

  const CollectionActionSuccess({
    required this.message,
    required this.allCollections,
    required this.todayCollections,
    required this.pendingCollections,
    required this.completedCollections,
  });

  @override
  List<Object?> get props => [
    message,
    allCollections,
    todayCollections,
    pendingCollections,
    completedCollections,
  ];
}

/// State: Error
class CollectionError extends CollectionState {
  final String message;

  const CollectionError({required this.message});

  @override
  List<Object?> get props => [message];
}
