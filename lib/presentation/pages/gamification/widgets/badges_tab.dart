import 'package:flutter/material.dart';
import 'package:eco_check/core/constants/color_constants.dart';
import 'package:eco_check/core/constants/text_constants.dart';
import 'package:eco_check/presentation/blocs/gamification/gamification_state.dart';
import 'badge_card.dart';

/// Badges Tab Widget - Hiển thị danh sách huy hiệu
class BadgesTab extends StatelessWidget {
  final List<BadgeData> badges;

  const BadgesTab({super.key, required this.badges});

  @override
  Widget build(BuildContext context) {
    final unlockedBadges = badges.where((b) => b.unlocked).toList();
    final lockedBadges = badges.where((b) => !b.unlocked).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (unlockedBadges.isNotEmpty) ...[
          _SectionTitle(
            title: 'Huy hiệu đã mở khóa (${unlockedBadges.length})',
            color: AppColors.text,
          ),
          const SizedBox(height: 12),
          _BadgeGrid(badges: unlockedBadges),
          const SizedBox(height: 24),
        ],
        if (lockedBadges.isNotEmpty) ...[
          _SectionTitle(
            title: 'Huy hiệu chưa mở khóa (${lockedBadges.length})',
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          _BadgeGrid(badges: lockedBadges),
        ],
      ],
    );
  }
}

/// Section Title Widget
class _SectionTitle extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionTitle({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.h4.copyWith(color: color));
  }
}

/// Badge Grid Widget
class _BadgeGrid extends StatelessWidget {
  final List<BadgeData> badges;

  const _BadgeGrid({required this.badges});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) => BadgeCard(badge: badges[index]),
    );
  }
}
