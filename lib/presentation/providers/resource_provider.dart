import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kingdomcome/core/constants/game_constants.dart';
import 'package:kingdomcome/data/models/resources/resource_model.dart';
import 'package:kingdomcome/presentation/providers/auth_provider.dart';

part 'resource_provider.g.dart';

final _supabase = Supabase.instance.client;

@riverpod
class ResourceNotifier extends _$ResourceNotifier {
  StreamSubscription<List<Map<String, dynamic>>>? _realtimeSub;

  @override
  Future<ResourceModel> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) throw StateError('Not authenticated');

    // Subscribe to realtime updates on user_profiles
    _subscribeToRealtime(user.id);

    // Cleanup subscription when provider is disposed
    ref.onDispose(() {
      _realtimeSub?.cancel();
    });

    return _fetchResources(user.id);
  }

  /// Forces a fresh fetch from Supabase.
  Future<void> refresh() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchResources(user.id));
  }

  /// Applies [reward] immediately to the local state before server confirmation.
  ///
  /// Call this when a quest/activity is completed so the UI feels snappy.
  /// The server will reconcile the actual values shortly via realtime.
  void optimisticAdd(ResourceReward reward) {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncData(
      current.copyWith(
        holyPoints: current.holyPoints + reward.holyPoints,
        faithCoins: current.faithCoins + reward.faithCoins,
        blessings: current.blessings + reward.blessings,
        grace: current.grace + reward.grace,
        updatedAt: DateTime.now(),
      ),
    );
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<ResourceModel> _fetchResources(String userId) async {
    final data = await _supabase
        .from('user_profiles')
        .select('id, total_holy_points, faith_coins, blessings, grace, last_active_at')
        .eq('id', userId)
        .maybeSingle();

    if (data == null) {
      return ResourceModel(
        userId: userId,
        holyPoints: 0,
        faithCoins: 0,
        blessings: 0,
        grace: 0,
        updatedAt: DateTime.now(),
      );
    }

    return ResourceModel.fromJson(data);
  }

  void _subscribeToRealtime(String userId) {
    _realtimeSub?.cancel();
    _realtimeSub = _supabase
        .from('user_profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .listen((rows) {
          if (rows.isNotEmpty) {
            state = AsyncData(ResourceModel.fromJson(rows.first));
          }
        }, onError: (_) {
          // Silently ignore realtime errors — next refresh will fix it
        });
  }
}
