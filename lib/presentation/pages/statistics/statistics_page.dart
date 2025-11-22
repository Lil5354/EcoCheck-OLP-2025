import 'package:flutter/material.dart';
import 'package:eco_check/core/constants/text_constants.dart';
import 'widgets/stat_card.dart';
import 'widgets/monthly_chart.dart';
import 'widgets/waste_type_distribution.dart';
import 'widgets/achievements_list.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.statistics)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary Cards (using extracted StatCard widget)
          Text('Tổng quan tháng này', style: AppTextStyles.h4),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(
                child: StatCard(
                  icon: Icons.delete_outline,
                  value: '225',
                  unit: 'kg',
                  label: 'Rác đã thu',
                  color: Color(0xFF2ECC71),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.eco,
                  value: '112',
                  unit: 'kg',
                  label: 'CO2 tiết kiệm',
                  color: Color(0xFF27AE60),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Monthly Chart
          Text('Biểu đồ 6 tháng gần đây', style: AppTextStyles.h4),
          const SizedBox(height: 12),
          const MonthlyChart(),

          const SizedBox(height: 24),

          // Waste Type Distribution
          Text('Phân loại rác', style: AppTextStyles.h4),
          const SizedBox(height: 12),
          const WasteTypeDistribution(),

          const SizedBox(height: 24),

          // Achievements
          Text('Thành tựu', style: AppTextStyles.h4),
          const SizedBox(height: 12),
          const AchievementsList(),
        ],
      ),
    );
  }
}
