import 'package:equatable/equatable.dart';

enum StreakType {
  prayer,
  bible,
  general,
}

extension StreakTypeX on StreakType {
  String get displayName {
    switch (this) {
      case StreakType.prayer:
        return 'Prayer Streak';
      case StreakType.bible:
        return 'Bible Streak';
      case StreakType.general:
        return 'Daily Streak';
    }
  }
}

class StreakModel extends Equatable {
  final String userId;
  final StreakType streakType;
  final int currentStreak;
  final int longestStreak;

  /// The most recent date on which this streak was completed (date only, no time).
  final DateTime? lastCompletedDate;

  /// Ordered list of dates when this streak was completed (up to 90 days).
  final List<DateTime> completionHistory;

  /// When true, the next missed day will not break the streak.
  final bool hasStreakShield;

  const StreakModel({
    required this.userId,
    required this.streakType,
    required this.currentStreak,
    required this.longestStreak,
    this.lastCompletedDate,
    this.completionHistory = const [],
    this.hasStreakShield = false,
  });

  /// True when the streak has been recorded on today's date.
  bool get isActiveToday {
    if (lastCompletedDate == null) return false;
    final today = _dateOnly(DateTime.now());
    final last = _dateOnly(lastCompletedDate!);
    return today == last;
  }

  /// True when the streak has NOT been completed today but was completed
  /// yesterday, meaning it will break at midnight if not recorded.
  bool get isAtRisk {
    if (lastCompletedDate == null) return false;
    if (isActiveToday) return false;
    final yesterday = _dateOnly(DateTime.now().subtract(const Duration(days: 1)));
    final last = _dateOnly(lastCompletedDate!);
    return last == yesterday && currentStreak > 0;
  }

  static DateTime _dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  factory StreakModel.fromJson(Map<String, dynamic> json) {
    return StreakModel(
      userId: json['user_id'] as String,
      streakType: StreakType.values.byName(json['streak_type'] as String),
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      lastCompletedDate: json['last_completed_date'] != null
          ? DateTime.parse(json['last_completed_date'] as String)
          : null,
      completionHistory:
          (json['completion_history'] as List<dynamic>?)
                  ?.map((d) => DateTime.parse(d as String))
                  .toList() ??
              [],
      hasStreakShield: json['has_streak_shield'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'streak_type': streakType.name,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_completed_date': lastCompletedDate?.toIso8601String(),
      'completion_history':
          completionHistory.map((d) => d.toIso8601String()).toList(),
      'has_streak_shield': hasStreakShield,
    };
  }

  StreakModel copyWith({
    String? userId,
    StreakType? streakType,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastCompletedDate,
    List<DateTime>? completionHistory,
    bool? hasStreakShield,
  }) {
    return StreakModel(
      userId: userId ?? this.userId,
      streakType: streakType ?? this.streakType,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      completionHistory: completionHistory ?? this.completionHistory,
      hasStreakShield: hasStreakShield ?? this.hasStreakShield,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        streakType,
        currentStreak,
        longestStreak,
        lastCompletedDate,
        completionHistory,
        hasStreakShield,
      ];
}
