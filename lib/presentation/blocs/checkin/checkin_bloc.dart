import 'package:flutter_bloc/flutter_bloc.dart';
import 'checkin_event.dart';
import 'checkin_state.dart';

/// Check-in BLoC
class CheckinBloc extends Bloc<CheckinEvent, CheckinState> {
  CheckinBloc() : super(const CheckinInitial()) {
    on<WasteTypeSelected>(_onWasteTypeSelected);
    on<WeightSelected>(_onWeightSelected);
    on<CheckinSubmitted>(_onCheckinSubmitted);
    on<CheckinReset>(_onCheckinReset);
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

  /// Handle Check-in Submission
  Future<void> _onCheckinSubmitted(
    CheckinSubmitted event,
    Emitter<CheckinState> emit,
  ) async {
    emit(const CheckinSubmitting());

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      final points = _calculatePoints(event.wasteType, event.weight);

      // Mock success
      emit(CheckinSuccess(points));

      // Reset after 3 seconds
      await Future.delayed(const Duration(seconds: 3));
      emit(const CheckinInitial());
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
