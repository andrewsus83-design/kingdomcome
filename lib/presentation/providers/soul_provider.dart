import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kingdomcome/presentation/providers/auth_provider.dart';

part 'soul_provider.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Parent Gate
// ─────────────────────────────────────────────────────────────────────────────

class ParentGateState extends Equatable {
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final String mathProblem;
  final int correctAnswer;
  final int attempts;

  const ParentGateState({
    this.isUnlocked = false,
    this.unlockedAt,
    required this.mathProblem,
    required this.correctAnswer,
    this.attempts = 0,
  });

  ParentGateState copyWith({
    bool? isUnlocked,
    DateTime? unlockedAt,
    String? mathProblem,
    int? correctAnswer,
    int? attempts,
  }) {
    return ParentGateState(
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      mathProblem: mathProblem ?? this.mathProblem,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      attempts: attempts ?? this.attempts,
    );
  }

  @override
  List<Object?> get props =>
      [isUnlocked, unlockedAt, mathProblem, correctAnswer, attempts];
}

/// Generates a random 2-digit addition or subtraction problem.
///
/// Returns a record of (displayString, correctAnswer).
({String problem, int answer}) _generateMathProblem() {
  final rng = Random();
  final a = rng.nextInt(50) + 20; // 20–69
  final b = rng.nextInt(30) + 10; // 10–39
  final useAddition = rng.nextBool();

  if (useAddition) {
    return (problem: '$a + $b = ?', answer: a + b);
  } else {
    final bigger = a >= b ? a : b;
    final smaller = a < b ? a : b;
    return (problem: '$bigger − $smaller = ?', answer: bigger - smaller);
  }
}

@riverpod
class ParentGateNotifier extends _$ParentGateNotifier {
  Timer? _autoLockTimer;

  @override
  ParentGateState build() {
    final p = _generateMathProblem();
    ref.onDispose(() => _autoLockTimer?.cancel());
    return ParentGateState(
      mathProblem: p.problem,
      correctAnswer: p.answer,
    );
  }

  /// Generates a fresh math problem and resets attempt count.
  void generateNewProblem() {
    final p = _generateMathProblem();
    state = state.copyWith(
      mathProblem: p.problem,
      correctAnswer: p.answer,
      attempts: 0,
    );
  }

  /// Submits [answer]. Returns true if correct and unlocks the gate.
  bool submitAnswer(int answer) {
    final newAttempts = state.attempts + 1;
    if (answer == state.correctAnswer) {
      state = state.copyWith(
        isUnlocked: true,
        unlockedAt: DateTime.now(),
        attempts: 0,
      );
      _scheduleAutoLock();
      return true;
    } else {
      state = state.copyWith(attempts: newAttempts);
      return false;
    }
  }

  /// Manually locks the parent gate immediately.
  void lock() {
    _autoLockTimer?.cancel();
    final p = _generateMathProblem();
    state = ParentGateState(
      isUnlocked: false,
      mathProblem: p.problem,
      correctAnswer: p.answer,
    );
  }

  /// Automatically locks the gate after 10 minutes of inactivity.
  void _scheduleAutoLock() {
    _autoLockTimer?.cancel();
    _autoLockTimer = Timer(const Duration(minutes: 10), () {
      if (state.isUnlocked) lock();
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grace Stats
// ─────────────────────────────────────────────────────────────────────────────

class GraceStatsState extends Equatable {
  /// Number of good deeds completed this week (0–7)
  final int weeklyDeeds;

  /// HolyPoints earned per day for the past 30 days (index 0 = oldest)
  final List<int> monthlyPoints;

  /// Activity breakdown as fractions (summing to 1.0)
  final Map<String, double> activityBreakdown;

  /// Virtue progress as a fraction (0.0–1.0) per virtue name
  final Map<String, double> virtueProgress;

  const GraceStatsState({
    required this.weeklyDeeds,
    required this.monthlyPoints,
    required this.activityBreakdown,
    required this.virtueProgress,
  });

  @override
  List<Object?> get props =>
      [weeklyDeeds, monthlyPoints, activityBreakdown, virtueProgress];
}

final _supabase = Supabase.instance.client;

@riverpod
class GraceStatsNotifier extends _$GraceStatsNotifier {
  @override
  Future<GraceStatsState> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return _emptyStats();
    }
    return _fetchStats(user.id);
  }

  // ── Private ─────────────────────────────────────────────────────────────────

  Future<GraceStatsState> _fetchStats(String userId) async {
    try {
      // Fetch weekly good deeds count
      final weeklyDeedsData = await _supabase
          .from('quest_completions')
          .select('id, completed_at')
          .eq('user_id', userId)
          .eq('deed_type', 'good_deed')
          .gte(
            'completed_at',
            DateTime.now()
                .subtract(const Duration(days: 7))
                .toIso8601String(),
          )
          .count() as dynamic;

      final weeklyDeeds =
          (weeklyDeedsData is int ? weeklyDeedsData : 0).clamp(0, 7) as int;

      // Fetch last 30 days of HolyPoints per day
      final now = DateTime.now();
      final monthlyPoints = <int>[];

      for (int i = 29; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        final dayStart = DateTime(day.year, day.month, day.day);
        final dayEnd = dayStart.add(const Duration(days: 1));

        final pointsData = await _supabase
            .from('resource_transactions')
            .select('holy_points')
            .eq('user_id', userId)
            .eq('transaction_type', 'earn')
            .gte('created_at', dayStart.toIso8601String())
            .lt('created_at', dayEnd.toIso8601String()) as List<dynamic>;

        final total = pointsData.fold<int>(
          0,
          (sum, row) =>
              sum + ((row as Map<String, dynamic>)['holy_points'] as int? ?? 0),
        );
        monthlyPoints.add(total);
      }

      // Activity breakdown (derived from quest_completions category counts)
      final breakdown = await _fetchActivityBreakdown(userId);

      // Virtue progress (derived from completed quests with virtue tags)
      final virtues = await _fetchVirtueProgress(userId);

      return GraceStatsState(
        weeklyDeeds: weeklyDeeds,
        monthlyPoints: monthlyPoints,
        activityBreakdown: breakdown,
        virtueProgress: virtues,
      );
    } catch (_) {
      // Return seeded sample data if DB is unavailable
      return _sampleStats();
    }
  }

  Future<Map<String, double>> _fetchActivityBreakdown(String userId) async {
    try {
      final data = await _supabase
          .from('quest_completions')
          .select('quest_category')
          .eq('user_id', userId)
          .gte(
            'completed_at',
            DateTime.now()
                .subtract(const Duration(days: 30))
                .toIso8601String(),
          ) as List<dynamic>;

      final counts = <String, int>{};
      for (final row in data) {
        final cat = (row as Map<String, dynamic>)['quest_category'] as String? ??
            'other';
        counts[cat] = (counts[cat] ?? 0) + 1;
      }

      final total = counts.values.fold(0, (a, b) => a + b);
      if (total == 0) return _defaultBreakdown();

      final categoryMap = {
        'prayer': 'Prayer',
        'bible': 'Bible',
        'good_deed': 'Good Deeds',
        'quiz': 'Quizzes',
        'art': 'Arts',
      };

      final result = <String, double>{};
      for (final entry in categoryMap.entries) {
        result[entry.value] =
            ((counts[entry.key] ?? 0) / total).clamp(0.0, 1.0);
      }
      return result;
    } catch (_) {
      return _defaultBreakdown();
    }
  }

  Future<Map<String, double>> _fetchVirtueProgress(String userId) async {
    try {
      final virtueMapping = {
        'kindness': 'Kindness',
        'courage': 'Courage',
        'patience': 'Patience',
        'humility': 'Humility',
        'faith': 'Faith',
      };

      final result = <String, double>{};

      for (final entry in virtueMapping.entries) {
        final data = await _supabase
            .from('quest_completions')
            .select('id')
            .eq('user_id', userId)
            .eq('virtue_tag', entry.key)
            .count() as dynamic;

        final count = (data is int ? data : 0).clamp(0, 20);
        result[entry.value] = count / 20.0;
      }

      return result;
    } catch (_) {
      return _defaultVirtues();
    }
  }

  GraceStatsState _emptyStats() {
    return GraceStatsState(
      weeklyDeeds: 0,
      monthlyPoints: List.filled(30, 0),
      activityBreakdown: _defaultBreakdown(),
      virtueProgress: _defaultVirtues(),
    );
  }

  GraceStatsState _sampleStats() {
    final rng = Random(42);
    final points = List.generate(30, (i) => rng.nextInt(80));
    return GraceStatsState(
      weeklyDeeds: 4,
      monthlyPoints: points,
      activityBreakdown: _defaultBreakdown(),
      virtueProgress: _defaultVirtues(),
    );
  }

  Map<String, double> _defaultBreakdown() => {
        'Prayer': 0.30,
        'Bible': 0.25,
        'Good Deeds': 0.20,
        'Quizzes': 0.15,
        'Arts': 0.10,
      };

  Map<String, double> _defaultVirtues() => {
        'Kindness': 0.4,
        'Courage': 0.25,
        'Patience': 0.55,
        'Humility': 0.35,
        'Faith': 0.70,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Parental settings
// ─────────────────────────────────────────────────────────────────────────────

class ParentalSettings extends Equatable {
  final int dailyLimitMinutes; // 0 = unlimited
  final bool aiChatEnabled;
  final bool allowCoinSpending;

  const ParentalSettings({
    this.dailyLimitMinutes = 60,
    this.aiChatEnabled = true,
    this.allowCoinSpending = true,
  });

  ParentalSettings copyWith({
    int? dailyLimitMinutes,
    bool? aiChatEnabled,
    bool? allowCoinSpending,
  }) {
    return ParentalSettings(
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      aiChatEnabled: aiChatEnabled ?? this.aiChatEnabled,
      allowCoinSpending: allowCoinSpending ?? this.allowCoinSpending,
    );
  }

  @override
  List<Object?> get props =>
      [dailyLimitMinutes, aiChatEnabled, allowCoinSpending];
}

@riverpod
class ParentalSettingsNotifier extends _$ParentalSettingsNotifier {
  @override
  ParentalSettings build() => const ParentalSettings();

  void updateScreenTime(int minutes) {
    state = state.copyWith(dailyLimitMinutes: minutes);
  }

  void toggleAiChat(bool enabled) {
    state = state.copyWith(aiChatEnabled: enabled);
  }

  void toggleCoinSpending(bool allowed) {
    state = state.copyWith(allowCoinSpending: allowed);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pending good deeds (parent validation queue)
// ─────────────────────────────────────────────────────────────────────────────

class GoodDeedItem extends Equatable {
  final String id;
  final String title;
  final String completedAt;
  final bool parentValidated;
  final String? parentNote;

  const GoodDeedItem({
    required this.id,
    required this.title,
    required this.completedAt,
    this.parentValidated = false,
    this.parentNote,
  });

  GoodDeedItem copyWith({bool? parentValidated, String? parentNote}) {
    return GoodDeedItem(
      id: id,
      title: title,
      completedAt: completedAt,
      parentValidated: parentValidated ?? this.parentValidated,
      parentNote: parentNote ?? this.parentNote,
    );
  }

  @override
  List<Object?> get props =>
      [id, title, completedAt, parentValidated, parentNote];
}

@riverpod
class PendingGoodDeeds extends _$PendingGoodDeeds {
  @override
  List<GoodDeedItem> build() {
    // Seed with sample data; in production this fetches from Supabase
    return [
      GoodDeedItem(
        id: '1',
        title: 'Helped set the dinner table',
        completedAt: 'Today',
      ),
      GoodDeedItem(
        id: '2',
        title: 'Read a Bible story to my sibling',
        completedAt: 'Yesterday',
      ),
      GoodDeedItem(
        id: '3',
        title: 'Said a prayer before bed',
        completedAt: 'Yesterday',
      ),
    ];
  }

  /// Marks the good deed as parent-validated.
  void validate(String id, {String? note}) {
    state = state.map((d) {
      if (d.id == id) {
        return d.copyWith(parentValidated: true, parentNote: note);
      }
      return d;
    }).toList();
    // Remove from pending list after a short delay (shows success briefly)
    Future.delayed(const Duration(seconds: 1), () {
      state = state.where((d) => !d.parentValidated).toList();
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Weekly report
// ─────────────────────────────────────────────────────────────────────────────

class WeeklyReport extends Equatable {
  final int questsCompleted;
  final int minutesSpent;
  final int quizzesPlayed;
  final int goodDeedsRecorded;

  const WeeklyReport({
    required this.questsCompleted,
    required this.minutesSpent,
    required this.quizzesPlayed,
    required this.goodDeedsRecorded,
  });

  @override
  List<Object?> get props =>
      [questsCompleted, minutesSpent, quizzesPlayed, goodDeedsRecorded];
}

final weeklyReportProvider = Provider<WeeklyReport>((ref) {
  // In production, this queries Supabase for the current week's activity.
  return const WeeklyReport(
    questsCompleted: 5,
    minutesSpent: 87,
    quizzesPlayed: 3,
    goodDeedsRecorded: 4,
  );
});
