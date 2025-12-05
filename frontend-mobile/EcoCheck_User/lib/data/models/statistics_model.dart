/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck User
 */

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
  final int totalSchedules;
  final int completedSchedules;
  final double totalWasteKg;
  final double totalCO2Saved;
  final int totalPoints;
  final int level;
  final String rankTier;
  final int rank;
  final int totalBadges;
  final int streakDays;
  final int totalCheckins;
  final double totalWasteThisMonth;
  final double totalCO2SavedThisMonth;
  final List<MonthlyStatistics> monthlyData;
  final List<WasteTypeDistribution> wasteDistribution;

  const StatisticsSummary({
    this.totalSchedules = 0,
    this.completedSchedules = 0,
    this.totalWasteKg = 0.0,
    this.totalCO2Saved = 0.0,
    this.totalPoints = 0,
    this.level = 1,
    this.rankTier = 'Người mới',
    this.rank = 0,
    this.totalBadges = 0,
    this.streakDays = 0,
    this.totalCheckins = 0,
    required this.totalWasteThisMonth,
    required this.totalCO2SavedThisMonth,
    required this.monthlyData,
    required this.wasteDistribution,
  });

  factory StatisticsSummary.fromJson(Map<String, dynamic> json) {
    return StatisticsSummary(
      totalSchedules: json['totalSchedules'] as int? ?? 0,
      completedSchedules: json['completedSchedules'] as int? ?? 0,
      totalWasteKg:
          double.tryParse(json['totalWasteKg']?.toString() ?? '0') ?? 0.0,
      totalCO2Saved:
          double.tryParse(json['totalCO2Saved']?.toString() ?? '0') ?? 0.0,
      totalPoints: json['totalPoints'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      rankTier: json['rankTier'] as String? ?? 'Người mới',
      rank: json['rank'] as int? ?? 0,
      totalBadges: json['totalBadges'] as int? ?? 0,
      streakDays: json['streakDays'] as int? ?? 0,
      totalCheckins: json['totalCheckins'] as int? ?? 0,
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
    totalSchedules,
    completedSchedules,
    totalWasteKg,
    totalCO2Saved,
    totalPoints,
    level,
    rankTier,
    rank,
    totalBadges,
    streakDays,
    totalCheckins,
    totalWasteThisMonth,
    totalCO2SavedThisMonth,
    monthlyData,
    wasteDistribution,
  ];
}
