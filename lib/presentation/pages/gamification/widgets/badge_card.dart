import 'package:flutter/material.dart';
import 'package:eco_check/core/constants/color_constants.dart';
import 'package:eco_check/core/constants/text_constants.dart';
import 'package:eco_check/presentation/blocs/gamification/gamification_state.dart';

/// Badge Card Widget - Hiển thị một huy hiệu
class BadgeCard extends StatelessWidget {
  final BadgeData badge;

  const BadgeCard({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: badge.unlocked ? 2 : 0,
      color: badge.unlocked ? Colors.white : AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _BadgeIcon(badge: badge),
            const SizedBox(height: 12),
            _BadgeName(badge: badge),
            const SizedBox(height: 4),
            _BadgeDescription(badge: badge),
            if (!badge.unlocked) ...[
              const SizedBox(height: 8),
              _RequiredPoints(points: badge.requiredPoints),
            ],
          ],
        ),
      ),
    );
  }
}

/// Badge Icon
class _BadgeIcon extends StatelessWidget {
  final BadgeData badge;

  const _BadgeIcon({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: badge.unlocked
            ? AppColors.primary.withOpacity(0.1)
            : AppColors.disabled.withOpacity(0.1),
      ),
      child: Center(
        child: Text(
          badge.icon,
          style: TextStyle(
            fontSize: 40,
            color: badge.unlocked ? null : AppColors.disabled,
          ),
        ),
      ),
    );
  }
}

/// Badge Name
class _BadgeName extends StatelessWidget {
  final BadgeData badge;

  const _BadgeName({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Text(
      badge.name,
      style: AppTextStyles.h5.copyWith(
        color: badge.unlocked ? AppColors.text : AppColors.textSecondary,
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Badge Description
class _BadgeDescription extends StatelessWidget {
  final BadgeData badge;

  const _BadgeDescription({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Text(
      badge.description,
      style: AppTextStyles.caption.copyWith(
        color: badge.unlocked ? AppColors.textSecondary : AppColors.disabled,
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Required Points Badge
class _RequiredPoints extends StatelessWidget {
  final int points;

  const _RequiredPoints({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$points điểm',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.warning,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
