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

/// Widget hiển thị active route card - tách ra để dễ quản lý
class ActiveRouteCard extends StatelessWidget {
  final WorkerRoute route;

  const ActiveRouteCard({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.route, color: AppColors.white, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Lộ trình đang thực hiện',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              route.name,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildRouteInfo(
                  Icons.location_on,
                  '${route.completedCollections}/${route.totalCollections} điểm',
                ),
                const SizedBox(width: 16),
                _buildRouteInfo(
                  Icons.access_time,
                  DateFormatter.formatTime(route.startedAt!),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.white, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: AppColors.white, fontSize: 14),
        ),
      ],
    );
  }
}
