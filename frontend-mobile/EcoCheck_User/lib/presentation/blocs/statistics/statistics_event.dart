/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck User
 */

import 'package:equatable/equatable.dart';

/// Statistics Events
abstract class StatisticsEvent extends Equatable {
  const StatisticsEvent();

  @override
  List<Object?> get props => [];
}

/// Load Statistics Summary
class LoadStatisticsSummary extends StatisticsEvent {
  final String userId;

  const LoadStatisticsSummary(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Refresh Statistics
class RefreshStatistics extends StatisticsEvent {
  final String userId;

  const RefreshStatistics(this.userId);

  @override
  List<Object?> get props => [userId];
}
