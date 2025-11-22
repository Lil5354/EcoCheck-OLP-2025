import 'package:flutter/material.dart';
import 'package:eco_check/core/constants/color_constants.dart';
import 'package:eco_check/core/constants/text_constants.dart';
import 'package:eco_check/presentation/widgets/dialogs/dialogs.dart';
import 'package:eco_check/presentation/pages/auth/login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profile)),
      body: ListView(
        children: [
          // Profile Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    'A',
                    style: AppTextStyles.h2.copyWith(color: AppColors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Nguyễn Văn A', style: AppTextStyles.h4),
                const SizedBox(height: 4),
                Text(
                  '0901234567',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ProfileStat(
                      icon: Icons.star,
                      value: '1,125',
                      label: 'Điểm',
                    ),
                    const SizedBox(width: 24),
                    _ProfileStat(
                      icon: Icons.emoji_events,
                      value: '4',
                      label: 'Thành tích',
                    ),
                    const SizedBox(width: 24),
                    _ProfileStat(
                      icon: Icons.eco,
                      value: '112kg',
                      label: 'CO2 giảm',
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Menu Items
          _MenuItem(
            icon: Icons.person,
            title: 'Thông tin cá nhân',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
          ),
          _MenuItem(
            icon: Icons.location_on,
            title: 'Địa chỉ của tôi',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
          ),
          _MenuItem(
            icon: Icons.history,
            title: 'Lịch sử thu gom',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
          ),
          _MenuItem(
            icon: Icons.card_giftcard,
            title: 'Đổi thưởng',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
          ),

          const Divider(height: 32),

          _MenuItem(
            icon: Icons.notifications,
            title: 'Thông báo',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
          ),
          _MenuItem(
            icon: Icons.settings,
            title: 'Cài đặt',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
          ),
          _MenuItem(
            icon: Icons.help,
            title: 'Trợ giúp & Hỗ trợ',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
          ),
          _MenuItem(
            icon: Icons.info,
            title: 'Về EcoCheck',
            onTap: () {
              _showAboutDialog(context);
            },
          ),

          const Divider(height: 32),

          _MenuItem(
            icon: Icons.logout,
            title: 'Đăng xuất',
            textColor: AppColors.error,
            onTap: () => _handleLogout(context),
          ),

          const SizedBox(height: 32),

          // Version
          Center(
            child: Text(
              'Phiên bản 1.0.0',
              style: AppTextStyles.caption.copyWith(color: AppColors.grey),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.recycling, color: AppColors.white),
            ),
            const SizedBox(width: 12),
            const Text('Về EcoCheck'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EcoCheck - Hệ thống thu gom rác thông minh',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ứng dụng giúp người dân dễ dàng đặt lịch thu gom rác, theo dõi tiến trình và tích lũy điểm thưởng.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Phiên bản: 1.0.0',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
            ),
            Text(
              '© 2024 EcoCheck. All rights reserved.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showConfirmationDialog(
      context,
      'Xác nhận đăng xuất',
      'Bạn có chắc chắn muốn đăng xuất không?',
    );

    if (confirmed != true || !context.mounted) return;

    // Mock logout
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _ProfileStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.h5.copyWith(color: AppColors.primary)),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? textColor;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? AppColors.grey),
      title: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith(color: textColor),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.grey),
      onTap: onTap,
    );
  }
}
