/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck User
 */

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eco_check/core/constants/api_constants.dart';
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
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _BadgeIcon(badge: badge),
            const SizedBox(height: 8),
            _BadgeName(badge: badge),
            const SizedBox(height: 4),
            Flexible(child: _BadgeDescription(badge: badge)),
            if (!badge.unlocked) ...[
              const SizedBox(height: 6),
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

  bool _isImageUrl(String icon) {
    return icon.startsWith('/') ||
        icon.startsWith('http://') ||
        icon.startsWith('https://') ||
        icon.contains('.png') ||
        icon.contains('.jpg') ||
        icon.contains('.jpeg') ||
        icon.contains('.svg');
  }

  String _buildImageUrl(String icon) {
    if (icon.startsWith('http://') || icon.startsWith('https://')) {
      return icon;
    }
    return '${ApiConstants.baseUrl}$icon';
  }

  @override
  Widget build(BuildContext context) {
    final bool isImage = _isImageUrl(badge.icon);

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: badge.unlocked
            ? AppColors.primary.withOpacity(0.1)
            : AppColors.disabled.withOpacity(0.1),
      ),
      child: Center(
        child: isImage
            ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: _buildImageUrl(badge.icon),
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Icon(
                    Icons.emoji_events,
                    size: 32,
                    color: AppColors.primary,
                  ),
                  errorWidget: (context, url, error) => Text(
                    '🏆',
                    style: TextStyle(
                      fontSize: 32,
                      color: badge.unlocked ? null : AppColors.disabled,
                    ),
                  ),
                ),
              )
            : Text(
                badge.icon,
                style: TextStyle(
                  fontSize: 32,
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
      style: AppTextStyles.bodyMedium.copyWith(
        color: badge.unlocked ? AppColors.text : AppColors.textSecondary,
        fontWeight: FontWeight.w600,
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
