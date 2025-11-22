import 'package:flutter/material.dart';
import 'package:eco_check/core/constants/color_constants.dart';
import 'package:eco_check/core/constants/text_constants.dart';

/// Waste Type Distribution Widget
class WasteTypeDistribution extends StatelessWidget {
  const WasteTypeDistribution({super.key});

  final List<Map<String, dynamic>> _data = const [
    {'type': 'Hữu cơ', 'value': 120.0, 'color': Color(0xFF8BC34A)},
    {'type': 'Tái chế', 'value': 85.0, 'color': Color(0xFF2196F3)},
    {'type': 'Nguy hại', 'value': 15.0, 'color': Color(0xFFFF5722)},
    {'type': 'Điện tử', 'value': 5.0, 'color': Color(0xFF9C27B0)},
  ];

  @override
  Widget build(BuildContext context) {
    final total = _data
        .map((e) => e['value'] as double)
        .reduce((a, b) => a + b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: _data.map((item) {
            final value = item['value'] as double;
            final percentage = (value / total * 100).toInt();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item['type'] as String,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${value.toInt()}kg ($percentage%)',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: value / total,
                      backgroundColor: AppColors.lightGrey,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        item['color'] as Color,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
