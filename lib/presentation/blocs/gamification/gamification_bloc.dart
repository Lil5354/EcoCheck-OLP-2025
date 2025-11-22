import 'package:flutter_bloc/flutter_bloc.dart';
import 'gamification_event.dart';
import 'gamification_state.dart';

/// Gamification BLoC
class GamificationBloc extends Bloc<GamificationEvent, GamificationState> {
  GamificationBloc() : super(const GamificationInitial()) {
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
    emit(const GamificationLoading());

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock data
      final points = 850;
      final rank = 'Chiến binh xanh';
      final position = 8;
      final badges = _getMockBadges();
      final leaderboard = _getMockLeaderboard();

      emit(
        GamificationDataLoaded(
          points: points,
          rank: rank,
          position: position,
          badges: badges,
          leaderboard: leaderboard,
        ),
      );
    } catch (e) {
      emit(GamificationError(e.toString()));
    }
  }

  /// Load Badges
  Future<void> _onLoadBadges(
    LoadBadges event,
    Emitter<GamificationState> emit,
  ) async {
    emit(const GamificationLoading());

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final badges = _getMockBadges();
      emit(BadgesLoaded(badges));
    } catch (e) {
      emit(GamificationError(e.toString()));
    }
  }

  /// Load Leaderboard
  Future<void> _onLoadLeaderboard(
    LoadLeaderboard event,
    Emitter<GamificationState> emit,
  ) async {
    emit(const GamificationLoading());

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final leaderboard = _getMockLeaderboard();
      emit(
        LeaderboardLoaded(
          entries: leaderboard,
          period: event.period,
          userPosition: 8,
        ),
      );
    } catch (e) {
      emit(GamificationError(e.toString()));
    }
  }

  /// Claim Reward
  Future<void> _onClaimReward(
    ClaimReward event,
    Emitter<GamificationState> emit,
  ) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      emit(const RewardClaimedSuccess('Nhận thưởng thành công!'));
    } catch (e) {
      emit(GamificationError(e.toString()));
    }
  }

  /// Unlock Badge
  Future<void> _onUnlockBadge(
    UnlockBadge event,
    Emitter<GamificationState> emit,
  ) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      final badge = _getMockBadges().firstWhere((b) => b.id == event.badgeId);
      emit(BadgeUnlockedSuccess(badge));
    } catch (e) {
      emit(GamificationError(e.toString()));
    }
  }

  /// Mock Badges Data
  List<BadgeData> _getMockBadges() {
    return [
      const BadgeData(
        id: '1',
        name: 'Người mới bắt đầu',
        description: 'Hoàn thành 1 lần check-in',
        icon: '🌱',
        unlocked: true,
        requiredPoints: 0,
      ),
      const BadgeData(
        id: '2',
        name: 'Chiến binh xanh',
        description: 'Đạt 500 điểm xanh',
        icon: '🏆',
        unlocked: true,
        requiredPoints: 500,
      ),
      const BadgeData(
        id: '3',
        name: 'Người bảo vệ môi trường',
        description: 'Hoàn thành 10 lần check-in',
        icon: '🌍',
        unlocked: true,
        requiredPoints: 100,
      ),
      const BadgeData(
        id: '4',
        name: 'Chuyên gia tái chế',
        description: 'Thu gom 50kg rác tái chế',
        icon: '♻️',
        unlocked: false,
        requiredPoints: 1000,
      ),
      const BadgeData(
        id: '5',
        name: 'Nhà vô địch xanh',
        description: 'Đạt top 3 bảng xếp hạng',
        icon: '🥇',
        unlocked: false,
        requiredPoints: 2000,
      ),
      const BadgeData(
        id: '6',
        name: 'Siêu anh hùng môi trường',
        description: 'Đạt 5000 điểm xanh',
        icon: '⭐',
        unlocked: false,
        requiredPoints: 5000,
      ),
    ];
  }

  /// Mock Leaderboard Data
  List<LeaderboardEntry> _getMockLeaderboard() {
    return const [
      LeaderboardEntry(
        position: 1,
        userId: '1',
        userName: 'Nguyễn Văn A',
        points: 2450,
        rank: 'Siêu anh hùng',
      ),
      LeaderboardEntry(
        position: 2,
        userId: '2',
        userName: 'Trần Thị B',
        points: 1980,
        rank: 'Nhà vô địch xanh',
      ),
      LeaderboardEntry(
        position: 3,
        userId: '3',
        userName: 'Lê Văn C',
        points: 1650,
        rank: 'Nhà vô địch xanh',
      ),
      LeaderboardEntry(
        position: 4,
        userId: '4',
        userName: 'Phạm Thị D',
        points: 1420,
        rank: 'Chuyên gia tái chế',
      ),
      LeaderboardEntry(
        position: 5,
        userId: '5',
        userName: 'Hoàng Văn E',
        points: 1200,
        rank: 'Chuyên gia tái chế',
      ),
      LeaderboardEntry(
        position: 6,
        userId: '6',
        userName: 'Võ Thị F',
        points: 1050,
        rank: 'Người bảo vệ môi trường',
      ),
      LeaderboardEntry(
        position: 7,
        userId: '7',
        userName: 'Đặng Văn G',
        points: 920,
        rank: 'Chiến binh xanh',
      ),
      LeaderboardEntry(
        position: 8,
        userId: 'current_user',
        userName: 'Bạn',
        points: 850,
        rank: 'Chiến binh xanh',
        isCurrentUser: true,
      ),
      LeaderboardEntry(
        position: 9,
        userId: '9',
        userName: 'Bùi Thị H',
        points: 780,
        rank: 'Chiến binh xanh',
      ),
      LeaderboardEntry(
        position: 10,
        userId: '10',
        userName: 'Dương Văn I',
        points: 650,
        rank: 'Chiến binh xanh',
      ),
    ];
  }
}
