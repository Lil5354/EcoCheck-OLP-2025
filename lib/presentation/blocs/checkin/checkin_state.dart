import 'package:equatable/equatable.dart';

/// Check-in States
abstract class CheckinState extends Equatable {
  const CheckinState();

  @override
  List<Object?> get props => [];
}

/// Initial State
class CheckinInitial extends CheckinState {
  final String selectedWasteType;
  final String selectedWeight;

  const CheckinInitial({
    this.selectedWasteType = 'household',
    this.selectedWeight = 'medium',
  });

  @override
  List<Object?> get props => [selectedWasteType, selectedWeight];
}

/// Form Updated State
class CheckinFormUpdated extends CheckinState {
  final String selectedWasteType;
  final String selectedWeight;
  final int pointsReward;

  const CheckinFormUpdated({
    required this.selectedWasteType,
    required this.selectedWeight,
    required this.pointsReward,
  });

  @override
  List<Object?> get props => [selectedWasteType, selectedWeight, pointsReward];
}

/// Submitting State
class CheckinSubmitting extends CheckinState {
  const CheckinSubmitting();
}

/// Success State
class CheckinSuccess extends CheckinState {
  final int pointsEarned;

  const CheckinSuccess(this.pointsEarned);

  @override
  List<Object?> get props => [pointsEarned];
}

/// Error State
class CheckinError extends CheckinState {
  final String message;

  const CheckinError(this.message);

  @override
  List<Object?> get props => [message];
}
