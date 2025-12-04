/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck Worker
 */

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/worker_statistics.dart';

/// Widget hiển thị quick stats - tách ra để dễ quản lý
class QuickStatsRow extends StatelessWidget {
  final WorkerStatistics stats;

  const QuickStatsRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickStat(
            icon: Icons.scale_outlined,
            label: 'Rác thu hôm nay',
            value: '${stats.todayWasteCollected.toStringAsFixed(1)} kg',
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickStat(
            icon: Icons.star_outline,
            label: 'Đánh giá',
            value: stats.averageRating.toStringAsFixed(1),
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
