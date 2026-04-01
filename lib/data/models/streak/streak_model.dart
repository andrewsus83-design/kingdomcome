import 'package:equatable/equatable.dart';

// DB user_streaks.streak_type values:
// 'daily_quest', 'prayer', 'bible_reading', 'rosary', 'mass'
enum StreakType {
  prayer,
  bibleReading,
  rosary,
  mass,
  dailyQuest,
}

extension StreakTypeX on StreakType {
  String get displayName {
    switch (this) {
      case StreakType.prayer:
        return 'Prayer Streak';
      case StreakType.bibleReading:
        return 'Bible Reading Streak';
      case StreakType.rosary:
        return 'Rosary Streak';
      case StreakType.mass:
        return 'Mass Streak';
      case StreakType.dailyQuest:
        return 'Daily Quest Streak';
    }
  }

  String get databaseKey {
    switch (this) {
      case StreakType.prayer:
        return 'prayer';
      case StreakType.bibleReading:
        return 'bible_reading';
      case StreakType.rosary:
        return 'rosary';
      case StreakType.mass:
        return 'mass';
      case StreakType.dailyQuest:
        return 'daily_quest';
    }
  }

  static StreakType fromDatabaseValue(String value) {
    return StreakType.values.firstWhere(
      (t) => t.databaseKey == value,
      orElse: () => StreakType.prayer,
    );
  }
}

class StreakModel extends Equatable {
  final String userId;
  final StreakType type;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityAt;
  final bool shieldActive;
  final DateTime? shieldExpiresAt;

  const StreakModel({
    required this.userId,
    required this.type,
    required this.currentStreak,
    required this.longestStreak,
    this.lastActivityAt,
    this.shieldActive = false,
    this.shieldExpiresAt,
  });

  bool get isActiveToday {
    if (lastActivityAt == null) return false;
    final now = DateTime.now();
    final last = lastActivityAt!;
    return last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;
  }

  bool get isAtRisk => !isActiveToday && !shieldActive;

  factory StreakModel.fromJson(Map<String, dynamic> json) {
    return StreakModel(
      userId: json['user_id'] as String? ?? '',
      type: StreakTypeX.fromDatabaseValue(
          json['streak_type'] as String? ?? 'prayer'),
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      lastActivityAt: json['last_completed_date'] != null
          ? DateTime.tryParse(json['last_completed_date'] as String)
          : json['last_activity_at'] != null
              ? DateTime.tryParse(json['last_activity_at'] as String)
              : null,
      shieldActive: json['shield_active'] as bool? ?? false,
      shieldExpiresAt: json['shield_expires_at'] != null
          ? DateTime.tryParse(json['shield_expires_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'streak_type': type.databaseKey,
        'current_streak': currentStreak,
        'longest_streak': longestStreak,
        'last_activity_at': lastActivityAt?.toIso8601String(),
        'shield_active': shieldActive,
        'shield_expires_at': shieldExpiresAt?.toIso8601String(),
      };

  StreakModel copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActivityAt,
    bool? shieldActive,
    DateTime? shieldExpiresAt,
  }) {
    return StreakModel(
      userId: userId,
      type: type,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      shieldActive: shieldActive ?? this.shieldActive,
      shieldExpiresAt: shieldExpiresAt ?? this.shieldExpiresAt,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        type,
        currentStreak,
        longestStreak,
        lastActivityAt,
        shieldActive,
        shieldExpiresAt,
      ];
}
