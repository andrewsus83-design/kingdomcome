import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kingdomcome/presentation/providers/auth_provider.dart';

part 'streak_provider.g.dart';

// ── Streak model (defined here since no existing streak model file exists) ───

enum StreakType {
  prayer,
  bibleReading,
  login,
  quest,
}

extension StreakTypeX on StreakType {
  String get displayName {
    switch (this) {
      case StreakType.prayer:
        return 'Prayer Streak';
      case StreakType.bibleReading:
        return 'Bible Reading Streak';
      case StreakType.login:
        return 'Daily Login Streak';
      case StreakType.quest:
        return 'Quest Streak';
    }
  }

  String get databaseKey {
    switch (this) {
      case StreakType.prayer:
        return 'prayer';
      case StreakType.bibleReading:
        return 'bible_reading';
      case StreakType.login:
        return 'login';
      case StreakType.quest:
        return 'quest';
    }
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

  /// True if activity was recorded today, keeping the streak alive.
  bool get isActiveToday {
    if (lastActivityAt == null) return false;
    final now = DateTime.now();
    final last = lastActivityAt!;
    return last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;
  }

  /// True if the streak is at risk of breaking (not completed today and no shield).
  bool get isAtRisk => !isActiveToday && !shieldActive;

  factory StreakModel.fromJson(Map<String, dynamic> json) {
    return StreakModel(
      userId: json['user_id'] as String,
      type: StreakType.values.firstWhere(
        (t) => t.databaseKey == (json['streak_type'] as String),
        orElse: () => StreakType.login,
      ),
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      lastActivityAt: json['last_activity_at'] != null
          ? DateTime.parse(json['last_activity_at'] as String)
          : null,
      shieldActive: json['shield_active'] as bool? ?? false,
      shieldExpiresAt: json['shield_expires_at'] != null
          ? DateTime.parse(json['shield_expires_at'] as String)
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

// ── Notifier ──────────────────────────────────────────────────────────────────

final _supabase = Supabase.instance.client;

@riverpod
class StreakNotifier extends _$StreakNotifier {
  @override
  Future<List<StreakModel>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    return _fetchStreaks(user.id);
  }

  /// Records activity of [type] for today, incrementing the streak if needed.
  Future<void> recordActivity(StreakType type) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    await _supabase.rpc('increment_streak', params: {
      'p_user_id': user.id,
      'p_streak_type': type.databaseKey,
    });

    // Optimistic update
    final current = state.valueOrNull ?? [];
    final idx = current.indexWhere((s) => s.type == type);
    if (idx >= 0) {
      final streak = current[idx];
      final newCount = streak.isActiveToday
          ? streak.currentStreak
          : streak.currentStreak + 1;
      final updated = streak.copyWith(
        currentStreak: newCount,
        longestStreak: newCount > streak.longestStreak
            ? newCount
            : streak.longestStreak,
        lastActivityAt: DateTime.now(),
      );
      final newList = [...current];
      newList[idx] = updated;
      state = AsyncData(newList);
    } else {
      // New streak type
      state = AsyncData([
        ...current,
        StreakModel(
          userId: user.id,
          type: type,
          currentStreak: 1,
          longestStreak: 1,
          lastActivityAt: DateTime.now(),
        ),
      ]);
    }
  }

  /// Activates a streak shield for [type] using Blessings.
  Future<void> activateShield(StreakType type) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    await _supabase.rpc('activate_streak_shield', params: {
      'p_user_id': user.id,
      'p_streak_type': type.databaseKey,
    });

    final current = state.valueOrNull ?? [];
    final idx = current.indexWhere((s) => s.type == type);
    if (idx >= 0) {
      final updated = current[idx].copyWith(
        shieldActive: true,
        shieldExpiresAt: DateTime.now().add(const Duration(hours: 24)),
      );
      final newList = [...current];
      newList[idx] = updated;
      state = AsyncData(newList);
    }
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<List<StreakModel>> _fetchStreaks(String userId) async {
    final data = await _supabase
        .from('player_streaks')
        .select()
        .eq('user_id', userId) as List<dynamic>;

    if (data.isEmpty) {
      // Seed default streaks for new user
      return StreakType.values
          .map((t) => StreakModel(
                userId: userId,
                type: t,
                currentStreak: 0,
                longestStreak: 0,
              ))
          .toList();
    }

    return data
        .map((e) => StreakModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// ── Derived providers ─────────────────────────────────────────────────────────

/// The combined "daily" streak — the highest of prayer + login streaks.
final primaryStreakProvider = Provider<StreakModel?>((ref) {
  final streaks = ref.watch(streakNotifierProvider).valueOrNull ?? [];
  if (streaks.isEmpty) return null;
  return streaks.reduce(
    (a, b) => a.currentStreak >= b.currentStreak ? a : b,
  );
});
