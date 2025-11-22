import 'package:equatable/equatable.dart';

/// Check-in Events
abstract class CheckinEvent extends Equatable {
  const CheckinEvent();

  @override
  List<Object?> get props => [];
}

/// Waste Type Selected
class WasteTypeSelected extends CheckinEvent {
  final String wasteType; // household, recyclable, bulky

  const WasteTypeSelected(this.wasteType);

  @override
  List<Object?> get props => [wasteType];
}

/// Weight Selected
class WeightSelected extends CheckinEvent {
  final String weight; // small, medium, large

  const WeightSelected(this.weight);

  @override
  List<Object?> get props => [weight];
}

/// Submit Check-in
class CheckinSubmitted extends CheckinEvent {
  final String wasteType;
  final String weight;
  final double latitude;
  final double longitude;
  final String address;

  const CheckinSubmitted({
    required this.wasteType,
    required this.weight,
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  @override
  List<Object?> get props => [wasteType, weight, latitude, longitude, address];
}

/// Reset Check-in Form
class CheckinReset extends CheckinEvent {
  const CheckinReset();
}
