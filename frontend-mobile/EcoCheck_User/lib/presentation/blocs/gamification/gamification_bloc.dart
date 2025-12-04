/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck User
 */

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eco_check/data/repositories/ecocheck_repository.dart';
import 'package:eco_check/data/models/gamification_model.dart';
import 'gamification_event.dart';
import 'gamification_state.dart';

/// Gamification BLoC
class GamificationBloc extends Bloc<GamificationEvent, GamificationState> {
  final EcoCheckRepository _repository;

  GamificationBloc({required EcoCheckRepository repository})
    : _repository = repository,
      super(const GamificationInitial()) {
    on<LoadUserStats>(_onLoadUserStats);
    on<LoadBadges>(_onLoadBadges);
    on<LoadLeaderboard>(_onLoadLeaderboard);
    on<ClaimReward>(_onClaimReward);
    on<UnlockBadge>(_onUnlockBadge);
  }

  /// Load User Stats
  Future<void> _onLoadUserStats(
    LoadUserStats event,
    Emitter<GamificationState> emit,
  ) async {
    print('[GamificationBloc] Loading user stats for userId: ${event.userId}');
    emit(const GamificationLoading());

    try {
      // Load all data from backend in parallel
      print('[GamificationBloc] Calling API...');
      final results = await Future.wait([
        _repository.getUserStatistics(event.userId),
        _repository.getLeaderboard(period: 'all', limit: 20),
      ]);

      final stats = results[0] as UserStatisticsModel;
      final leaderboardData = results[1] as List<LeaderboardEntryModel>;

      print('[GamificationBloc] Stats loaded: ${stats.totalPoints} points');
      print(
        '[GamificationBloc] Leaderboard entries: ${leaderboardData.length}',
      );

      // Convert badges to BLoC state format
      final badges = stats.badges
          .map(
            (b) => BadgeData(
              id: b.id,
              name: b.name,
              description: b.description,
              icon: b.icon ?? '🏆',
              unlocked: b.isUnlocked,
              requiredPoints: b.requiredPoints,
            ),
          )
          .toList();

      // Convert leaderboard to BLoC state format
      final leaderboard = leaderboardData
          .map(
            (e) => LeaderboardEntry(
              userId: e.userId,
              userName: e.userName,
              avatarUrl: e.avatarUrl,
              points: e.points,
              position: e.rank,
              rank: e.rankTier,
              isCurrentUser: e.userId == event.userId,
            ),
          )
          .toList();

      print(
        '[GamificationBloc] Converted leaderboard: ${leaderboard.length} entries',
      );
      print(
        '[GamificationBloc] Top 3: ${leaderboard.take(3).map((e) => '${e.userName}:${e.points}').join(", ")}',
      );

      emit(
        GamificationDataLoaded(
          points: stats.totalPoints,
          rank: stats.rankTier,
          position: stats.rank,
          badges: badges,
          leaderboard: leaderboard,
        ),
      );
      print('[GamificationBloc] Data loaded successfully!');
    } catch (e, stackTrace) {
      print('[GamificationBloc] Error: $e');
      print('[GamificationBloc] Stack trace: $stackTrace');
      emit(GamificationError('Không thể tải thống kê: ${e.toString()}'));
    }
  }

  /// Load Badges
  Future<void> _onLoadBadges(
    LoadBadges event,
    Emitter<GamificationState> emit,
  ) async {
    emit(const GamificationLoading());

    try {
      // Load badges from backend
      final userBadges = await _repository.getUserBadges(event.userId);

      final badges = userBadges
          .map(
            (b) => BadgeData(
              id: b.id,
              name: b.name,
              description: b.description,
              icon: b.icon ?? '🏆',
              unlocked: b.isUnlocked,
              requiredPoints: b.requiredPoints,
            ),
          )
          .toList();

      emit(BadgesLoaded(badges));
    } catch (e) {
      emit(GamificationError('Không thể tải huy hiệu: ${e.toString()}'));
    }
  }

  /// Load Leaderboard
  Future<void> _onLoadLeaderboard(
    LoadLeaderboard event,
    Emitter<GamificationState> emit,
  ) async {
    emit(const GamificationLoading());

    try {
      // Load real leaderboard from backend
      final entries = await _repository.getLeaderboard(
        period: event.period,
        limit: 20,
      );

      // Convert to BLoC state format
      final leaderboardEntries = entries
          .map(
            (e) => LeaderboardEntry(
              userId: e.userId,
              userName: e.userName,
              avatarUrl: e.avatarUrl,
              points: e.points,
              position: e.rank,
              rank: e.rankTier,
              isCurrentUser: e.isCurrentUser,
            ),
          )
          .toList();

      final userPosition = entries
          .firstWhere((e) => e.isCurrentUser, orElse: () => entries.first)
          .rank;

      emit(
        LeaderboardLoaded(
          entries: leaderboardEntries,
          period: event.period,
          userPosition: userPosition,
        ),
      );
    } catch (e) {
      emit(GamificationError('Không thể tải bảng xếp hạng: ${e.toString()}'));
    }
  }

  /// Claim Reward
  Future<void> _onClaimReward(
    ClaimReward event,
    Emitter<GamificationState> emit,
  ) async {
    try {
      // TODO: Implement reward claiming API
      await Future.delayed(const Duration(seconds: 1));
      emit(const RewardClaimedSuccess('Nhận thưởng thành công!'));
    } catch (e) {
      emit(GamificationError('Không thể nhận thưởng: ${e.toString()}'));
    }
  }

  /// Unlock Badge
  Future<void> _onUnlockBadge(
    UnlockBadge event,
    Emitter<GamificationState> emit,
  ) async {
    try {
      // TODO: Implement badge unlock API
      await Future.delayed(const Duration(seconds: 1));

      // Reload badges to get updated status
      final userBadges = await _repository.getUserBadges(event.userId);
      final badge = userBadges.firstWhere((b) => b.id == event.badgeId);

      emit(
        BadgeUnlockedSuccess(
          BadgeData(
            id: badge.id,
            name: badge.name,
            description: badge.description,
            icon: badge.icon ?? '🏆',
            unlocked: badge.isUnlocked,
            requiredPoints: badge.requiredPoints,
          ),
        ),
      );
    } catch (e) {
      emit(GamificationError('Không thể mở khóa huy hiệu: ${e.toString()}'));
    }
  }
}
