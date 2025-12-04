/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck Worker
 */

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';

/// Widget hiển thị thông tin worker - tách ra để dễ quản lý
class WorkerInfoCard extends StatelessWidget {
  final UserModel? worker;

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
                  worker?.phone ?? 'Chưa cập nhật',
                ),
                if (worker?.depotName != null) ...[
                  const Divider(),
                  _buildInfoRow(
                    Icons.warehouse,
                    'Trạm thu gom',
                    worker!.depotName!,
                  ),
                ],
                if (worker?.operatingArea != null) ...[
                  const Divider(),
                  _buildInfoRow(
                    Icons.map,
                    'Khu vực hoạt động',
                    worker!.operatingArea!,
                  ),
                ],
                if (worker?.vehiclePlate != null) ...[
                  const Divider(),
                  _buildInfoRow(
                    Icons.local_shipping,
                    'Phương tiện',
                    '${worker!.vehiclePlate!}${worker?.vehicleType != null ? " (${_getVehicleTypeName(worker!.vehicleType!)})" : ""}',
                  ),
                ],
                if (worker?.personnelRole != null) ...[
                  const Divider(),
                  _buildInfoRow(
                    Icons.badge,
                    'Vai trò',
                    _getPersonnelRoleName(worker!.personnelRole!),
                  ),
                ],
                if (worker?.experience != null) ...[
                  const Divider(),
                  _buildInfoRow(
                    Icons.star,
                    'Kinh nghiệm',
                    '${worker!.experience} năm',
                  ),
                ],
                if (worker?.license != null) ...[
                  const Divider(),
                  _buildInfoRow(
                    Icons.credit_card,
                    'Bằng lái',
                    'Hạng ${worker!.license}',
                  ),
                ],
                if (worker?.skills != null && worker!.skills!.isNotEmpty) ...[
                  const Divider(),
                  _buildSkillsRow(Icons.verified, 'Kỹ năng', worker!.skills!),
                ],
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

  Widget _buildSkillsRow(IconData icon, String label, List<String> skills) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: skills.map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _getSkillName(skill),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPersonnelRoleName(String role) {
    const roleMap = {
      'driver': 'Lái xe',
      'collector': 'Thu gom rác',
      'supervisor': 'Giám sát',
      'manager': 'Quản lý',
      'dispatcher': 'Điều phối',
    };
    return roleMap[role] ?? role.toUpperCase();
  }

  String _getVehicleTypeName(String type) {
    const typeMap = {
      'compactor': 'Xe ép rác',
      'dump_truck': 'Xe ben',
      'small_truck': 'Xe tải nhỏ',
      'electric': 'Xe điện',
    };
    return typeMap[type] ?? type;
  }

  String _getSkillName(String skill) {
    const skillMap = {
      'driving': 'Lái xe',
      'compactor_operation': 'Vận hành xe ép',
      'waste_sorting': 'Phân loại rác',
      'customer_service': 'Dịch vụ khách hàng',
      'route_planning': 'Lập kế hoạch tuyến',
      'heavy_machinery': 'Máy móc hạng nặng',
      'first_aid': 'Sơ cứu',
      'safety_training': 'An toàn lao động',
    };
    return skillMap[skill] ?? skill;
  }
}
