import 'package:flutter/material.dart';
import 'package:eco_check/core/constants/color_constants.dart';
import 'package:eco_check/core/constants/text_constants.dart';
import 'package:eco_check/data/models/statistics_model.dart';

/// Monthly Chart Widget
class MonthlyChart extends StatelessWidget {
  final List<MonthlyStatistics> data;

  const MonthlyChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text('Chưa có dữ liệu', style: AppTextStyles.bodyMedium),
          ),
        ),
      );
    }

    final maxValue = data
        .map((e) => e.wasteCollected)
        .reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((item) {
                final value = item.wasteCollected;
                final height = maxValue > 0 ? (value / maxValue) * 150 : 0.0;

                return Column(
                  children: [
                    Text(
                      '${value.toInt()}kg',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 40,
                      height: height,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(item.month, style: AppTextStyles.caption),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
