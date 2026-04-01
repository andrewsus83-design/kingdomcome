import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kingdomcome/data/models/saint/saint_model.dart';
import 'package:kingdomcome/data/models/saint/user_saint_model.dart';
import 'package:kingdomcome/presentation/providers/auth_provider.dart';

part 'saint_provider.g.dart';

final _supabase = Supabase.instance.client;

// ── All saints ────────────────────────────────────────────────────────────────

@riverpod
class SaintNotifier extends _$SaintNotifier {
  @override
  Future<List<SaintModel>> build() async {
    final data = await _supabase
        .from('saints')
        .select()
        .eq('is_active', true)
        .order('sort_order') as List<dynamic>;

    return data
        .map((e) => SaintModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Unlocks [saintId] for the current user, deducting Holy Points.
  Future<void> unlockSaint(String saintId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw StateError('Not authenticated');

    await _supabase.rpc('unlock_saint', params: {
      'p_user_id': user.id,
      'p_saint_id': saintId,
    });

    // Refresh user saints
    ref.invalidate(userSaintsNotifierProvider);
  }

  /// Sets [saintId] as the user's active guardian saint.
  Future<void> setActiveSaint(String saintId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw StateError('Not authenticated');

    await _supabase.from('user_saints').update({
      'is_active': false,
    }).eq('user_id', user.id);

    await _supabase.from('user_saints').upsert({
      'user_id': user.id,
      'saint_id': saintId,
      'is_active': true,
    });

    ref.invalidate(userSaintsNotifierProvider);
  }

  /// Activates the special ability for [saintId], consuming Grace.
  Future<void> activateAbility(String saintId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw StateError('Not authenticated');

    await _supabase.rpc('activate_saint_ability', params: {
      'p_user_id': user.id,
      'p_saint_id': saintId,
    });

    ref.invalidate(userSaintsNotifierProvider);
  }
}

// ── User's unlocked saints ─────────────────────────────────────────────────────

@riverpod
class UserSaintsNotifier extends _$UserSaintsNotifier {
  @override
  Future<List<UserSaintModel>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];

    final data = await _supabase
        .from('user_saints')
        .select()
        .eq('user_id', user.id)
        .order('unlocked_at') as List<dynamic>;

    return data
        .map((e) => UserSaintModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// ── Derived providers ─────────────────────────────────────────────────────────

/// The currently active (guardian) saint for the user.
final activeSaintProvider = Provider<UserSaintModel?>((ref) {
  final userSaints = ref.watch(userSaintsNotifierProvider).valueOrNull ?? [];
  try {
    return userSaints.firstWhere((s) => s.isActive);
  } catch (_) {
    return null;
  }
});

/// Set of saint IDs that the user has unlocked.
final unlockedSaintIdsProvider = Provider<Set<String>>((ref) {
  final userSaints = ref.watch(userSaintsNotifierProvider).valueOrNull ?? [];
  return userSaints.map((s) => s.saintId).toSet();
});
