/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck Worker
 */

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/worker_route.dart';
import 'shift_indicator.dart';

/// Widget hiển thị thông tin route - tách ra để dễ quản lý
class RouteInfoCard extends StatelessWidget {
  final WorkerRoute route;

  const RouteInfoCard({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route name and status
          Row(
            children: [
              Expanded(
                child: Text(
                  route.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _buildStatusChip(route.status),
            ],
          ),

          const SizedBox(height: 16),

          // Shift indicator
          ShiftIndicator(route: route),

          const SizedBox(height: 16),

          // Route info grid
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.calendar_today,
                  'Ngày',
                  DateFormatter.formatDate(route.scheduledDate),
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.location_on,
                  'Điểm',
                  '${route.points.length} điểm',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.route,
                  'Quãng đường',
                  '${route.totalDistance?.toStringAsFixed(1) ?? '0'} km',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.access_time,
                  'Thời gian',
                  _calculateEstimatedTime(),
                ),
              ),
            ],
          ),

          if (route.totalDistance != null && route.totalDistance! > 0) ...[
            const SizedBox(height: 12),
            _buildOptimizationInfo(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;

    switch (status) {
      case 'pending':
        color = AppColors.pending;
        text = 'Chờ bắt đầu';
        break;
      case 'in_progress':
        color = AppColors.inProgress;
        text = 'Đang thực hiện';
        break;
      case 'completed':
        color = AppColors.completed;
        text = 'Hoàn thành';
        break;
      default:
        color = AppColors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildOptimizationInfo() {
    final saved = _calculateSavedDistance();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.eco, color: AppColors.success, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '🎯 Tối ưu hóa: Tiết kiệm $saved',
              style: const TextStyle(
                color: AppColors.success,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _calculateEstimatedTime() {
    if (route.totalDistance == null) return '~30 phút';

    // Estimate: 20 km/h average + 3 minutes per point
    final drivingMinutes = (route.totalDistance! / 20 * 60).round();
    final stopMinutes = route.points.length * 3;
    final totalMinutes = drivingMinutes + stopMinutes;

    if (totalMinutes < 60) {
      return '~$totalMinutes phút';
    } else {
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      return '~${hours}h ${minutes}p';
    }
  }

  String _calculateSavedDistance() {
    if (route.totalDistance == null) return '0 km';

    // Mock calculation: assume optimization saves ~15-20%
    final saved = route.totalDistance! * 0.18;
    return '${saved.toStringAsFixed(1)} km (18%)';
  }
}
