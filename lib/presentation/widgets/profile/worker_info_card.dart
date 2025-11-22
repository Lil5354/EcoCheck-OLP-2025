import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/worker.dart';

/// Widget hiển thị thông tin worker - tách ra để dễ quản lý
class WorkerInfoCard extends StatelessWidget {
  final Worker? worker;

  const WorkerInfoCard({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông tin nhân viên',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.phone,
                  'Số điện thoại',
                  worker?.phoneNumber ?? 'Chưa cập nhật',
                ),
                const Divider(),
                _buildInfoRow(
                  Icons.directions_car,
                  'Loại xe',
                  worker?.vehicleType ?? '',
                ),
                const Divider(),
                _buildInfoRow(
                  Icons.confirmation_number,
                  'Biển số xe',
                  worker?.vehiclePlate ?? '',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
