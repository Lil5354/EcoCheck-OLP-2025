/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck User
 */

import 'package:equatable/equatable.dart';

/// Gamification Events
abstract class GamificationEvent extends Equatable {
  const GamificationEvent();

  @override
  List<Object?> get props => [];
}

/// Load User Points and Rank
class LoadUserStats extends GamificationEvent {
  final String userId;

  const LoadUserStats(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Load Badges
class LoadBadges extends GamificationEvent {
  final String userId;

  const LoadBadges(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Load Leaderboard
class LoadLeaderboard extends GamificationEvent {
  final String period; // 'weekly', 'monthly', 'all_time'

  const LoadLeaderboard({this.period = 'weekly'});

  @override
  List<Object?> get props => [period];
}

/// Claim Reward
class ClaimReward extends GamificationEvent {
  final String rewardId;

  const ClaimReward(this.rewardId);

  @override
  List<Object?> get props => [rewardId];
}

/// Unlock Badge
class UnlockBadge extends GamificationEvent {
  final String userId;
  final String badgeId;

  const UnlockBadge({required this.userId, required this.badgeId});

  @override
  List<Object?> get props => [userId, badgeId];
}
