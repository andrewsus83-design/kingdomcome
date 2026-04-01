import 'package:equatable/equatable.dart';

class UserProfileModel extends Equatable {
  final String userId;
  final int totalHolyPoints;
  final int currentLevel;
  final int levelXp;
  final int faithCoins;
  final int blessings;
  final int grace;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;
  final String? activeSaintId;
  final List<String> completedAchievementIds;
  final Map<String, dynamic> preferences;

  const UserProfileModel({
    required this.userId,
    required this.totalHolyPoints,
    required this.currentLevel,
    required this.levelXp,
    required this.faithCoins,
    required this.blessings,
    required this.grace,
    required this.currentStreak,
    required this.longestStreak,
    this.lastActivityDate,
    this.activeSaintId,
    this.completedAchievementIds = const [],
    this.preferences = const {},
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: json['user_id'] as String,
      totalHolyPoints: json['total_holy_points'] as int? ?? 0,
      currentLevel: json['current_level'] as int? ?? 1,
      levelXp: json['level_xp'] as int? ?? 0,
      faithCoins: json['faith_coins'] as int? ?? 0,
      blessings: json['blessings'] as int? ?? 0,
      grace: json['grace'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      lastActivityDate: json['last_activity_date'] != null
          ? DateTime.parse(json['last_activity_date'] as String)
          : null,
      activeSaintId: json['active_saint_id'] as String?,
      completedAchievementIds:
          (json['completed_achievement_ids'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              [],
      preferences: (json['preferences'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'total_holy_points': totalHolyPoints,
      'current_level': currentLevel,
      'level_xp': levelXp,
      'faith_coins': faithCoins,
      'blessings': blessings,
      'grace': grace,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_activity_date': lastActivityDate?.toIso8601String(),
      'active_saint_id': activeSaintId,
      'completed_achievement_ids': completedAchievementIds,
      'preferences': preferences,
    };
  }

  UserProfileModel copyWith({
    String? userId,
    int? totalHolyPoints,
    int? currentLevel,
    int? levelXp,
    int? faithCoins,
    int? blessings,
    int? grace,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActivityDate,
    String? activeSaintId,
    List<String>? completedAchievementIds,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfileModel(
      userId: userId ?? this.userId,
      totalHolyPoints: totalHolyPoints ?? this.totalHolyPoints,
      currentLevel: currentLevel ?? this.currentLevel,
      levelXp: levelXp ?? this.levelXp,
      faithCoins: faithCoins ?? this.faithCoins,
      blessings: blessings ?? this.blessings,
      grace: grace ?? this.grace,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      activeSaintId: activeSaintId ?? this.activeSaintId,
      completedAchievementIds:
          completedAchievementIds ?? this.completedAchievementIds,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        totalHolyPoints,
        currentLevel,
        levelXp,
        faithCoins,
        blessings,
        grace,
        currentStreak,
        longestStreak,
        lastActivityDate,
        activeSaintId,
        completedAchievementIds,
        preferences,
      ];
}
