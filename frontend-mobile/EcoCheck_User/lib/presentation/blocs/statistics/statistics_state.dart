import 'package:equatable/equatable.dart';
import 'package:eco_check/data/models/statistics_model.dart';

/// Statistics States
abstract class StatisticsState extends Equatable {
  const StatisticsState();

  @override
  List<Object?> get props => [];
}

/// Initial State
class StatisticsInitial extends StatisticsState {
  const StatisticsInitial();
}

/// Loading State
class StatisticsLoading extends StatisticsState {
  const StatisticsLoading();
}

/// Loaded State
class StatisticsLoaded extends StatisticsState {
  final StatisticsSummary summary;

  const StatisticsLoaded(this.summary);

  @override
  List<Object?> get props => [summary];
}

/// Error State
class StatisticsError extends StatisticsState {
  final String message;

  const StatisticsError(this.message);

  @override
  List<Object?> get props => [message];
}
