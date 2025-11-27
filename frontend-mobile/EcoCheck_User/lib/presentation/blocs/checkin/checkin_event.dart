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
  final String? routeId;
  final String? pointId;
  final String? vehicleId;

  const CheckinSubmitted({
    required this.wasteType,
    required this.weight,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.routeId,
    this.pointId,
    this.vehicleId,
  });

  @override
  List<Object?> get props => [
    wasteType,
    weight,
    latitude,
    longitude,
    address,
    routeId,
    pointId,
    vehicleId,
  ];
}

/// Load Check-in Data from Backend
class CheckinDataLoaded extends CheckinEvent {
  final int? count;

  const CheckinDataLoaded({this.count});

  @override
  List<Object?> get props => [count];
}

/// Reset Check-in Form
class CheckinReset extends CheckinEvent {
  const CheckinReset();
}
