/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck User
 */

import 'package:flutter/material.dart';
import 'package:eco_check/core/constants/color_constants.dart';
import 'package:eco_check/core/constants/text_constants.dart';
import 'package:eco_check/presentation/blocs/gamification/gamification_state.dart';

/// Leaderboard Entry Card Widget
class LeaderboardEntryCard extends StatelessWidget {
  final LeaderboardEntry entry;

  const LeaderboardEntryCard({super.key, required this.entry});

  bool get isTop3 => entry.position <= 3;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: entry.isCurrentUser ? 3 : 1,
        color: entry.isCurrentUser
            ? AppColors.primary.withOpacity(0.1)
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: entry.isCurrentUser
              ? const BorderSide(color: AppColors.primary, width: 2)
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _PositionBadge(position: entry.position, isTop3: isTop3),
              const SizedBox(width: 16),
              _UserAvatar(entry: entry),
              const SizedBox(width: 12),
              Expanded(child: _UserInfo(entry: entry)),
              _PointsDisplay(points: entry.points),
            ],
          ),
        ),
      ),
    );
  }
}

/// Position Badge
class _PositionBadge extends StatelessWidget {
  final int position;
  final bool isTop3;

  const _PositionBadge({required this.position, required this.isTop3});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isTop3
            ? LinearGradient(
                colors: _getPositionColors(),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isTop3 ? null : AppColors.surface,
      ),
      child: Center(
        child: Text(
          isTop3 ? _getPositionEmoji() : '#$position',
          style: TextStyle(
            fontSize: isTop3 ? 20 : 14,
            fontWeight: FontWeight.bold,
            color: isTop3 ? Colors.white : AppColors.text,
          ),
        ),
      ),
    );
  }

  List<Color> _getPositionColors() {
    switch (position) {
      case 1:
        return [const Color(0xFFFFD700), const Color(0xFFFFA500)]; // Gold
      case 2:
        return [const Color(0xFFC0C0C0), const Color(0xFF808080)]; // Silver
      case 3:
        return [const Color(0xFFCD7F32), const Color(0xFF8B4513)]; // Bronze
      default:
        return [AppColors.surface, AppColors.surface];
    }
  }

  String _getPositionEmoji() {
    switch (position) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$position';
    }
  }
}

/// User Avatar
class _UserAvatar extends StatelessWidget {
  final LeaderboardEntry entry;

  const _UserAvatar({required this.entry});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.primary.withOpacity(0.1),
      backgroundImage: entry.avatarUrl != null
          ? NetworkImage(entry.avatarUrl!)
          : null,
      child: entry.avatarUrl == null
          ? Text(
              entry.userName[0].toUpperCase(),
              style: AppTextStyles.h4.copyWith(color: AppColors.primary),
            )
          : null,
    );
  }
}

/// User Info
class _UserInfo extends StatelessWidget {
  final LeaderboardEntry entry;

  const _UserInfo({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                entry.userName,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: entry.isCurrentUser
                      ? AppColors.primary
                      : AppColors.text,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (entry.isCurrentUser) ...[
              const SizedBox(width: 4),
              const Icon(Icons.star, size: 16, color: AppColors.warning),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          entry.rank,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// Points Display
class _PointsDisplay extends StatelessWidget {
  final int points;

  const _PointsDisplay({required this.points});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$points',
          style: AppTextStyles.h4.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'điểm',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
