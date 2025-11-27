import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Widget hiển thị phần cài đặt - tách ra để dễ quản lý
class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cài đặt',
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
          child: Column(
            children: [
              _buildSettingTile(
                icon: Icons.person_outline,
                title: 'Chỉnh sửa thông tin',
                onTap: () {
                  // TODO: Navigate to edit profile
                },
              ),
              const Divider(height: 1),
              _buildSettingTile(
                icon: Icons.lock_outline,
                title: 'Đổi mật khẩu',
                onTap: () {
                  // TODO: Navigate to change password
                },
              ),
              const Divider(height: 1),
              _buildSettingTile(
                icon: Icons.notifications,
                title: 'Thông báo',
                onTap: () {
                  // TODO: Navigate to notification settings
                },
              ),
              const Divider(height: 1),
              _buildSettingTile(
                icon: Icons.help_outline,
                title: 'Trợ giúp',
                onTap: () {
                  // TODO: Navigate to help
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
