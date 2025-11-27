import 'package:equatable/equatable.dart';

/// Monthly Statistics Data
class MonthlyStatistics extends Equatable {
  final String month;
  final double wasteCollected;
  final double co2Saved;

  const MonthlyStatistics({
    required this.month,
    required this.wasteCollected,
    required this.co2Saved,
  });

  factory MonthlyStatistics.fromJson(Map<String, dynamic> json) {
    return MonthlyStatistics(
      month: json['month'] as String? ?? '',
      wasteCollected:
          double.tryParse(
            json['wasteCollected']?.toString() ??
                json['waste_collected']?.toString() ??
                '0',
          ) ??
          0.0,
      co2Saved:
          double.tryParse(
            json['co2Saved']?.toString() ??
                json['co2_saved']?.toString() ??
                '0',
          ) ??
          0.0,
    );
  }

  @override
  List<Object?> get props => [month, wasteCollected, co2Saved];
}

/// Waste Type Distribution
class WasteTypeDistribution extends Equatable {
  final String type;
  final double amount;
  final int color;

  const WasteTypeDistribution({
    required this.type,
    required this.amount,
    required this.color,
  });

  factory WasteTypeDistribution.fromJson(Map<String, dynamic> json) {
    return WasteTypeDistribution(
      type: json['type'] as String? ?? json['wasteType'] as String? ?? '',
      amount:
          double.tryParse(
            json['amount']?.toString() ?? json['weight']?.toString() ?? '0',
          ) ??
          0.0,
      color:
          int.tryParse(json['color']?.toString() ?? '0xFF8BC34A') ?? 0xFF8BC34A,
    );
  }

  @override
  List<Object?> get props => [type, amount, color];
}

/// Overall Statistics Summary
class StatisticsSummary extends Equatable {
  final double totalWasteThisMonth;
  final double totalCO2SavedThisMonth;
  final List<MonthlyStatistics> monthlyData;
  final List<WasteTypeDistribution> wasteDistribution;

  const StatisticsSummary({
    required this.totalWasteThisMonth,
    required this.totalCO2SavedThisMonth,
    required this.monthlyData,
    required this.wasteDistribution,
  });

  factory StatisticsSummary.fromJson(Map<String, dynamic> json) {
    return StatisticsSummary(
      totalWasteThisMonth:
          double.tryParse(
            json['totalWasteThisMonth']?.toString() ??
                json['total_waste_this_month']?.toString() ??
                '0',
          ) ??
          0.0,
      totalCO2SavedThisMonth:
          double.tryParse(
            json['totalCO2SavedThisMonth']?.toString() ??
                json['total_co2_saved_this_month']?.toString() ??
                '0',
          ) ??
          0.0,
      monthlyData:
          (json['monthlyData'] as List<dynamic>?)
              ?.map(
                (e) => MonthlyStatistics.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          (json['monthly_data'] as List<dynamic>?)
              ?.map(
                (e) => MonthlyStatistics.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      wasteDistribution:
          (json['wasteDistribution'] as List<dynamic>?)
              ?.map(
                (e) =>
                    WasteTypeDistribution.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          (json['waste_distribution'] as List<dynamic>?)
              ?.map(
                (e) =>
                    WasteTypeDistribution.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
    totalWasteThisMonth,
    totalCO2SavedThisMonth,
    monthlyData,
    wasteDistribution,
  ];
}
