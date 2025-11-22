import 'package:flutter/material.dart';
import 'package:eco_check/core/constants/color_constants.dart';
import 'package:eco_check/core/constants/text_constants.dart';

/// Statistics Summary Card Widget
class StatisticsSummaryCard extends StatelessWidget {
  const StatisticsSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: StatItem(
                icon: Icons.delete_outline,
                value: '225',
                unit: 'kg',
                label: 'Rác đã thu',
                color: AppColors.primary,
              ),
            ),
            Container(width: 1, height: 40, color: AppColors.lightGrey),
            Expanded(
              child: StatItem(
                icon: Icons.eco,
                value: '112',
                unit: 'kg',
                label: 'CO2 tiết kiệm',
                color: AppColors.success,
              ),
            ),
            Container(width: 1, height: 40, color: AppColors.lightGrey),
            Expanded(
              child: StatItem(
                icon: Icons.star,
                value: '1,125',
                unit: '',
                label: 'Điểm',
                color: AppColors.warning,
              ),
            ),
          ],
        ),
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
