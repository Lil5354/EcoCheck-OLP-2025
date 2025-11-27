import 'package:equatable/equatable.dart';

/// Badge model - Huy hiệu người dùng
class BadgeModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final String? icon;
  final String category;
  final int requiredPoints;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    this.icon,
    required this.category,
    required this.requiredPoints,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      icon: json['icon']?.toString() ?? json['icon_url']?.toString(),
      category:
          json['category']?.toString() ??
          json['rarity']?.toString() ??
          'general',
      requiredPoints:
          json['requiredPoints'] ??
          json['required_points'] ??
          json['points_reward'] ??
          0,
      isUnlocked: json['isUnlocked'] ?? json['is_unlocked'] ?? false,
      unlockedAt: json['unlockedAt'] != null || json['unlocked_at'] != null
          ? DateTime.tryParse(
              json['unlockedAt']?.toString() ??
                  json['unlocked_at']?.toString() ??
                  '',
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'category': category,
      'required_points': requiredPoints,
      'is_unlocked': isUnlocked,
      'unlocked_at': unlockedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    icon,
    category,
    requiredPoints,
    isUnlocked,
    unlockedAt,
  ];
}

/// Daily statistic - Thống kê hằng ngày
class DailyStatistic extends Equatable {
  final DateTime date;
  final int points;
  final int checkins;
  final double wasteCollected;

  const DailyStatistic({
    required this.date,
    required this.points,
    required this.checkins,
    required this.wasteCollected,
  });

  factory DailyStatistic.fromJson(Map<String, dynamic> json) {
    return DailyStatistic(
      date: DateTime.parse(json['date']),
      points: json['points'] ?? 0,
      checkins: json['checkins'] ?? 0,
      wasteCollected: (json['waste_collected'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'points': points,
      'checkins': checkins,
      'waste_collected': wasteCollected,
    };
  }

  @override
  List<Object?> get props => [date, points, checkins, wasteCollected];
}

/// User statistics model - Thống kê người dùng chi tiết
class UserStatisticsModel extends Equatable {
  final String userId;
  final int totalPoints;
  final int totalCheckins;
  final double totalWasteCollected; // kg
  final int rank;
  final int totalUsers;
  final String rankTier; // bronze, silver, gold, platinum
  final int currentStreak; // số ngày liên tiếp
  final int longestStreak;
  final List<BadgeModel> badges;
  final List<DailyStatistic> dailyStats;

  const UserStatisticsModel({
    required this.userId,
    required this.totalPoints,
    required this.totalCheckins,
    required this.totalWasteCollected,
    required this.rank,
    required this.totalUsers,
    required this.rankTier,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.badges = const [],
    this.dailyStats = const [],
  });

  factory UserStatisticsModel.fromJson(Map<String, dynamic> json) {
    return UserStatisticsModel(
      userId: json['user_id']?.toString() ?? '',
      totalPoints: json['total_points'] ?? 0,
      totalCheckins: json['total_checkins'] ?? 0,
      totalWasteCollected: (json['total_waste_collected'] ?? 0).toDouble(),
      rank: json['rank'] ?? 0,
      totalUsers: json['total_users'] ?? 0,
      rankTier: json['rank_tier'] ?? 'bronze',
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      badges:
          (json['badges'] as List<dynamic>?)
              ?.map(
                (badge) => BadgeModel.fromJson(badge as Map<String, dynamic>),
              )
              .toList() ??
          [],
      dailyStats:
          (json['daily_stats'] as List<dynamic>?)
              ?.map(
                (stat) => DailyStatistic.fromJson(stat as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'total_points': totalPoints,
      'total_checkins': totalCheckins,
      'total_waste_collected': totalWasteCollected,
      'rank': rank,
      'total_users': totalUsers,
      'rank_tier': rankTier,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'badges': badges.map((badge) => badge.toJson()).toList(),
      'daily_stats': dailyStats.map((stat) => stat.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
    userId,
    totalPoints,
    totalCheckins,
    totalWasteCollected,
    rank,
    totalUsers,
    rankTier,
    currentStreak,
    longestStreak,
    badges,
    dailyStats,
  ];
}

/// Leaderboard entry - Thông tin người chơi trên bảng xếp hạng
class LeaderboardEntryModel extends Equatable {
  final String userId;
  final String userName;
  final String? avatarUrl;
  final int rank;
  final int points;
  final int checkins;
  final double wasteCollected;
  final String rankTier;
  final bool isCurrentUser;

  const LeaderboardEntryModel({
    required this.userId,
    required this.userName,
    this.avatarUrl,
    required this.rank,
    required this.points,
    required this.checkins,
    required this.wasteCollected,
    required this.rankTier,
    this.isCurrentUser = false,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntryModel(
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name'] ?? json['name'] ?? 'Unknown User',
      avatarUrl: json['avatar_url'] ?? json['avatar'],
      rank: json['rank'] ?? 0,
      points: json['points'] ?? 0,
      checkins: json['checkins'] ?? 0,
      wasteCollected: (json['waste_collected'] ?? 0).toDouble(),
      rankTier: json['rank_tier'] ?? 'bronze',
      isCurrentUser: json['is_current_user'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'avatar_url': avatarUrl,
      'rank': rank,
      'points': points,
      'checkins': checkins,
      'waste_collected': wasteCollected,
      'rank_tier': rankTier,
      'is_current_user': isCurrentUser,
    };
  }

  @override
  List<Object?> get props => [
    userId,
    userName,
    avatarUrl,
    rank,
    points,
    checkins,
    wasteCollected,
    rankTier,
    isCurrentUser,
  ];
}

/// Notification model - Thông báo trong app
class NotificationModel extends Equatable {
  final String id;
  final String userId;
  final String type; // badge_unlocked, level_up, achievement, reminder
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      type: json['type'] ?? 'general',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'message': message,
      'data': data,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  NotificationModel copyWith({bool? isRead, DateTime? readAt}) {
    return NotificationModel(
      id: id,
      userId: userId,
      type: type,
      title: title,
      message: message,
      data: data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    type,
    title,
    message,
    data,
    isRead,
    createdAt,
    readAt,
  ];
}
