/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck User
 */

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eco_check/data/repositories/ecocheck_repository.dart';
import 'package:eco_check/data/models/api_models.dart';
import 'package:eco_check/core/network/api_client.dart';
import 'checkin_event.dart';
import 'checkin_state.dart';

/// Check-in BLoC
class CheckinBloc extends Bloc<CheckinEvent, CheckinState> {
  final EcoCheckRepository _repository;

  CheckinBloc({required EcoCheckRepository repository})
    : _repository = repository,
      super(const CheckinInitial()) {
    on<WasteTypeSelected>(_onWasteTypeSelected);
    on<WeightSelected>(_onWeightSelected);
    on<CheckinSubmitted>(_onCheckinSubmitted);
    on<CheckinReset>(_onCheckinReset);
    on<CheckinDataLoaded>(_onCheckinDataLoaded);
  }

  /// Handle Waste Type Selection
  void _onWasteTypeSelected(
    WasteTypeSelected event,
    Emitter<CheckinState> emit,
  ) {
    final currentState = state;
    String currentWeight = 'medium';

    if (currentState is CheckinFormUpdated) {
      currentWeight = currentState.selectedWeight;
    } else if (currentState is CheckinInitial) {
      currentWeight = currentState.selectedWeight;
    }

    final points = _calculatePoints(event.wasteType, currentWeight);

    emit(
      CheckinFormUpdated(
        selectedWasteType: event.wasteType,
        selectedWeight: currentWeight,
        pointsReward: points,
      ),
    );
  }

  /// Handle Weight Selection
  void _onWeightSelected(WeightSelected event, Emitter<CheckinState> emit) {
    final currentState = state;
    String currentWasteType = 'household';

    if (currentState is CheckinFormUpdated) {
      currentWasteType = currentState.selectedWasteType;
    } else if (currentState is CheckinInitial) {
      currentWasteType = currentState.selectedWasteType;
    }

    final points = _calculatePoints(currentWasteType, event.weight);

    emit(
      CheckinFormUpdated(
        selectedWasteType: currentWasteType,
        selectedWeight: event.weight,
        pointsReward: points,
      ),
    );
  }

  /// Load check-in data from backend
  Future<void> _onCheckinDataLoaded(
    CheckinDataLoaded event,
    Emitter<CheckinState> emit,
  ) async {
    try {
      // Load real-time check-ins from backend
      final checkins = await _repository.getCheckins(count: event.count ?? 20);

      if (state is CheckinFormUpdated) {
        final currentState = state as CheckinFormUpdated;
        emit(currentState.copyWith(recentCheckins: checkins));
      }
    } catch (e) {
      // Silently fail, keep current state
      print('Error loading check-in data: $e');
    }
  }

  /// Handle Check-in Submission
  Future<void> _onCheckinSubmitted(
    CheckinSubmitted event,
    Emitter<CheckinState> emit,
  ) async {
    emit(const CheckinSubmitting());

    try {
      // Create check-in request
      final request = CheckinRequest(
        routeId:
            event.routeId ??
            'route-user-${DateTime.now().millisecondsSinceEpoch}',
        pointId: event.pointId ?? 'P-${DateTime.now().millisecondsSinceEpoch}',
        vehicleId: event.vehicleId ?? 'V-USER',
      );

      // Send check-in to backend
      final response = await _repository.postCheckin(request);

      if (response.ok) {
        final points = _calculatePoints(event.wasteType, event.weight);
        emit(CheckinSuccess(points));

        // Reset after 3 seconds
        await Future.delayed(const Duration(seconds: 3));
        emit(const CheckinInitial());
      } else {
        emit(CheckinError(response.message ?? 'Check-in thất bại'));
      }
    } on ApiException catch (e) {
      emit(CheckinError('Lỗi kết nối: ${e.message}'));
    } catch (e) {
      emit(CheckinError('Check-in thất bại: ${e.toString()}'));
    }
  }

  /// Reset Check-in Form
  void _onCheckinReset(CheckinReset event, Emitter<CheckinState> emit) {
    emit(const CheckinInitial());
  }

  /// Calculate Points Based on Waste Type and Weight
  int _calculatePoints(String wasteType, String weight) {
    int basePoints = 10;

    // Base points by waste type
    if (wasteType == 'recyclable') {
      basePoints = 20;
    } else if (wasteType == 'bulky') {
      basePoints = 30;
    }

    // Bonus for large weight
    if (weight == 'large') {
      basePoints += 5;
    }

    return basePoints;
  }
}
