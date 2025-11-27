import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../stat_card.dart';
import '../../../data/models/worker_statistics.dart';

/// Widget hiển thị header với thời gian và stats - tách ra để dễ quản lý
class DashboardHeader extends StatelessWidget {
  final WorkerStatistics stats;

  const DashboardHeader({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormatter.formatDateTimeFull(DateTime.now()),
              style: const TextStyle(fontSize: 14, color: AppColors.white),
            ),
            const SizedBox(height: 16),

            // Statistics Row
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.assignment_outlined,
                    title: 'Hôm nay',
                    value: '${stats.todayCollections}',
                    subtitle: 'nhiệm vụ',
                    color: AppColors.white,
                    backgroundColor: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.check_circle_outline,
                    title: 'Hoàn thành',
                    value: '${stats.completedCollections}',
                    subtitle: 'nhiệm vụ',
                    color: AppColors.white,
                    backgroundColor: AppColors.success.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
