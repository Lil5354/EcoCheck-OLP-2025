import 'package:flutter/material.dart';
import 'package:eco_check/core/constants/color_constants.dart';
import 'package:eco_check/core/constants/text_constants.dart';

/// Achievements List Widget
class AchievementsList extends StatelessWidget {
  const AchievementsList({super.key});

  final List<Map<String, dynamic>> _achievements = const [
    {
      'icon': '🌟',
      'title': 'Người mới',
      'description': 'Hoàn thành lịch thu đầu tiên',
      'unlocked': true,
    },
    {
      'icon': '🏆',
      'title': 'Chiến binh xanh',
      'description': 'Thu gom 100kg rác',
      'unlocked': true,
    },
    {
      'icon': '♻️',
      'title': 'Tái chế cao thủ',
      'description': 'Thu gom 50kg rác tái chế',
      'unlocked': true,
    },
    {
      'icon': '🌍',
      'title': 'Bảo vệ trái đất',
      'description': 'Giảm 100kg CO2',
      'unlocked': true,
    },
    {
      'icon': '💎',
      'title': 'Huyền thoại',
      'description': 'Thu gom 500kg rác',
      'unlocked': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _achievements.map((achievement) {
        final unlocked = achievement['unlocked'] as bool;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: unlocked ? null : AppColors.lightGrey.withOpacity(0.3),
          child: ListTile(
            leading: Opacity(
              opacity: unlocked ? 1.0 : 0.3,
              child: Text(
                achievement['icon'] as String,
                style: const TextStyle(fontSize: 32),
              ),
            ),
            title: Text(
              achievement['title'] as String,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: unlocked ? null : AppColors.grey,
              ),
            ),
            subtitle: Text(
              achievement['description'] as String,
              style: AppTextStyles.bodySmall.copyWith(
                color: unlocked
                    ? AppColors.grey
                    : AppColors.grey.withOpacity(0.5),
              ),
            ),
            trailing: unlocked
                ? const Icon(Icons.check_circle, color: AppColors.success)
                : const Icon(Icons.lock, color: AppColors.grey),
          ),
        );
      }).toList(),
    );
  }
}
