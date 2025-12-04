/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck User
 */

import 'package:equatable/equatable.dart';

/// Gamification States
abstract class GamificationState extends Equatable {
  const GamificationState();

  @override
  List<Object?> get props => [];
}

/// Initial State
class GamificationInitial extends GamificationState {
  const GamificationInitial();
}

/// Loading State
class GamificationLoading extends GamificationState {
  const GamificationLoading();
}

/// User Stats Loaded
class UserStatsLoaded extends GamificationState {
  final int points;
  final String rank;
  final int position;
  final int totalUsers;

  const UserStatsLoaded({
    required this.points,
    required this.rank,
    required this.position,
    required this.totalUsers,
  });

  @override
  List<Object?> get props => [points, rank, position, totalUsers];
}

/// Badges Loaded
class BadgesLoaded extends GamificationState {
  final List<BadgeData> badges;

  const BadgesLoaded(this.badges);

  @override
  List<Object?> get props => [badges];
}

/// Leaderboard Loaded
class LeaderboardLoaded extends GamificationState {
  final List<LeaderboardEntry> entries;
  final String period;
  final int? userPosition;

  const LeaderboardLoaded({
    required this.entries,
    required this.period,
    this.userPosition,
  });

  @override
  List<Object?> get props => [entries, period, userPosition];
}

/// Combined Data Loaded (for UI display)
class GamificationDataLoaded extends GamificationState {
  final int points;
  final String rank;
  final int position;
  final List<BadgeData> badges;
  final List<LeaderboardEntry> leaderboard;

  const GamificationDataLoaded({
    required this.points,
    required this.rank,
    required this.position,
    required this.badges,
    required this.leaderboard,
  });

  @override
  List<Object?> get props => [points, rank, position, badges, leaderboard];
}

/// Reward Claimed Success
class RewardClaimedSuccess extends GamificationState {
  final String message;

  const RewardClaimedSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

/// Badge Unlocked Success
class BadgeUnlockedSuccess extends GamificationState {
  final BadgeData badge;

  const BadgeUnlockedSuccess(this.badge);

  @override
  List<Object?> get props => [badge];
}

/// Error State
class GamificationError extends GamificationState {
  final String message;

  const GamificationError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Badge Data Model
class BadgeData extends Equatable {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool unlocked;
  final int requiredPoints;
  final DateTime? unlockedAt;

  const BadgeData({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.unlocked,
    required this.requiredPoints,
    this.unlockedAt,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    icon,
    unlocked,
    requiredPoints,
    unlockedAt,
  ];
}

/// Leaderboard Entry Model
class LeaderboardEntry extends Equatable {
  final int position;
  final String userId;
  final String userName;
  final String? avatarUrl;
  final int points;
  final String rank;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.position,
    required this.userId,
    required this.userName,
    this.avatarUrl,
    required this.points,
    required this.rank,
    this.isCurrentUser = false,
  });

  @override
  List<Object?> get props => [
    position,
    userId,
    userName,
    avatarUrl,
    points,
    rank,
    isCurrentUser,
  ];
}
