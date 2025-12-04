/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck User
 */

import 'package:equatable/equatable.dart';
import 'package:eco_check/data/models/api_models.dart';

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
  final List<CheckinPoint>? recentCheckins;

  const CheckinFormUpdated({
    required this.selectedWasteType,
    required this.selectedWeight,
    required this.pointsReward,
    this.recentCheckins,
  });

  CheckinFormUpdated copyWith({
    String? selectedWasteType,
    String? selectedWeight,
    int? pointsReward,
    List<CheckinPoint>? recentCheckins,
  }) {
    return CheckinFormUpdated(
      selectedWasteType: selectedWasteType ?? this.selectedWasteType,
      selectedWeight: selectedWeight ?? this.selectedWeight,
      pointsReward: pointsReward ?? this.pointsReward,
      recentCheckins: recentCheckins ?? this.recentCheckins,
    );
  }

  @override
  List<Object?> get props => [
    selectedWasteType,
    selectedWeight,
    pointsReward,
    recentCheckins,
  ];
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
