/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck User
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eco_check/core/constants/color_constants.dart';
import 'package:eco_check/core/constants/text_constants.dart';
import 'package:eco_check/core/di/injection_container.dart';
import 'package:eco_check/presentation/blocs/auth/auth_bloc.dart';
import 'package:eco_check/presentation/blocs/auth/auth_state.dart';
import 'package:eco_check/presentation/blocs/statistics/statistics_bloc.dart';
import 'package:eco_check/presentation/blocs/statistics/statistics_event.dart';
import 'package:eco_check/presentation/blocs/statistics/statistics_state.dart';

/// Statistics Summary Card Widget
class StatisticsSummaryCard extends StatefulWidget {
  const StatisticsSummaryCard({super.key});

  @override
  State<StatisticsSummaryCard> createState() => _StatisticsSummaryCardState();
}

class _StatisticsSummaryCardState extends State<StatisticsSummaryCard> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = sl<StatisticsBloc>();
        final authState = context.read<AuthBloc>().state;
        if (authState is Authenticated) {
          bloc.add(LoadStatisticsSummary(authState.user.id));
        }
        return bloc;
      },
      child: BlocBuilder<StatisticsBloc, StatisticsState>(
        builder: (context, state) {
          // Default values
          String wasteCollected = '0';
          String co2Saved = '0';
          String points = '0';

          if (state is StatisticsLoaded) {
            wasteCollected = state.summary.totalWasteKg.toStringAsFixed(0);
            co2Saved = state.summary.totalCO2Saved.toStringAsFixed(0);
            points = state.summary.totalPoints.toString();
          }

          if (state is StatisticsLoading) {
            return const Card(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: StatItem(
                      icon: Icons.delete_outline,
                      value: wasteCollected,
                      unit: 'kg',
                      label: 'Rác đã thu',
                      color: AppColors.primary,
                    ),
                  ),
                  Container(width: 1, height: 40, color: AppColors.lightGrey),
                  Expanded(
                    child: StatItem(
                      icon: Icons.eco,
                      value: co2Saved,
                      unit: 'kg',
                      label: 'CO2 tiết kiệm',
                      color: AppColors.success,
                    ),
                  ),
                  Container(width: 1, height: 40, color: AppColors.lightGrey),
                  Expanded(
                    child: StatItem(
                      icon: Icons.star,
                      value: points,
                      unit: '',
                      label: 'Điểm',
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Stat Item Widget
class StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final String label;
  final Color color;

  const StatItem({
    super.key,
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: AppTextStyles.h4.copyWith(color: color)),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(unit, style: AppTextStyles.caption),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
      ],
    );
  }
}
