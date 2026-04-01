import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kingdomcome/data/models/streak/streak_model.dart';
import 'package:kingdomcome/presentation/providers/auth_provider.dart';

export 'package:kingdomcome/data/models/streak/streak_model.dart'
    show StreakModel, StreakType, StreakTypeX;

part 'streak_provider.g.dart';

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
        .from('user_streaks')
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
