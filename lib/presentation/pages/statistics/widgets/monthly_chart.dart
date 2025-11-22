import 'package:flutter/material.dart';
import 'package:eco_check/core/constants/color_constants.dart';
import 'package:eco_check/core/constants/text_constants.dart';

/// Monthly Chart Widget
class MonthlyChart extends StatelessWidget {
  const MonthlyChart({super.key});

  final List<Map<String, dynamic>> _data = const [
    {'month': 'T1', 'value': 45.0},
    {'month': 'T2', 'value': 52.0},
    {'month': 'T3', 'value': 38.0},
    {'month': 'T4', 'value': 65.0},
    {'month': 'T5', 'value': 48.0},
    {'month': 'T6', 'value': 55.0},
  ];

  @override
  Widget build(BuildContext context) {
    final maxValue = _data
        .map((e) => e['value'] as double)
        .reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _data.map((item) {
                final value = item['value'] as double;
                final height = (value / maxValue) * 150;

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
                    Text(item['month'] as String, style: AppTextStyles.caption),
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
