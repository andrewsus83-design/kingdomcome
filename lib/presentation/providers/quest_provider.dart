import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kingdomcome/data/models/quest/quest_model.dart';
import 'package:kingdomcome/presentation/providers/auth_provider.dart';
import 'package:kingdomcome/presentation/providers/liturgical_calendar_provider.dart';
import 'package:kingdomcome/core/theme/liturgical_colors.dart';

part 'quest_provider.g.dart';

final _supabase = Supabase.instance.client;

@riverpod
class QuestNotifier extends _$QuestNotifier {
  @override
  Future<List<QuestModel>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];

    final season = ref.watch(currentSeasonProvider);
    return _fetchQuests(userId: user.id, season: season);
  }

  /// Marks a quest as complete and awards rewards.
  ///
  /// [proofUrl] is an optional photo-evidence URL for [QuestVerificationType.photoUpload] quests.
  Future<void> completeQuest(String questId, {String? proofUrl}) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    await _supabase.rpc('complete_quest', params: {
      'p_user_id': user.id,
      'p_quest_id': questId,
      if (proofUrl != null) 'p_proof_url': proofUrl,
    });

    // Remove completed quest from the list immediately
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((q) => q.id != questId).toList());

    // Refresh to pick up newly available quests
    await refresh();
  }

  /// Forces a full refresh of quests (e.g. at midnight for daily reset).
  Future<void> refreshDaily() async {
    state = const AsyncLoading();
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = const AsyncData([]);
      return;
    }
    final season = ref.read(currentSeasonProvider);
    state = await AsyncValue.guard(
      () => _fetchQuests(userId: user.id, season: season),
    );
  }

  Future<void> refresh() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final season = ref.read(currentSeasonProvider);
    state = await AsyncValue.guard(
      () => _fetchQuests(userId: user.id, season: season),
    );
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<List<QuestModel>> _fetchQuests({
    required String userId,
    required LiturgicalSeason season,
  }) async {
    final seasonName = LiturgicalColors.displayNameFor(season);

    // Fetch quests available to this user (server filters by age group,
    // building unlocks, and current season)
    final data = await _supabase
        .from('quests')
        .select()
        .or('liturgical_season.is.null,liturgical_season.eq.$seasonName')
        .eq('is_active', true)
        .order('sort_order')
        .limit(50) as List<dynamic>;

    // Fetch already-completed quest IDs for today/week
    final completedData = await _supabase
        .from('player_quests')
        .select('quest_id')
        .eq('user_id', userId)
        .gte('completed_at',
            DateTime.now().subtract(const Duration(days: 7)).toIso8601String())
        as List<dynamic>;

    final completedIds =
        completedData.map((e) => e['quest_id'] as String).toSet();

    return data
        .map((e) => QuestModel.fromJson(e as Map<String, dynamic>))
        .where((q) => !completedIds.contains(q.id) || q.isRepeatable)
        .toList();
  }
}

// ── Derived providers ─────────────────────────────────────────────────────────

/// Quests with [QuestRepeatFrequency.daily].
final dailyQuestsProvider = Provider<List<QuestModel>>((ref) {
  final all = ref.watch(questNotifierProvider).valueOrNull ?? [];
  return all.where((q) => q.repeatFrequency == QuestRepeatFrequency.daily).toList();
});

/// Quests with [QuestRepeatFrequency.weekly].
final weeklyQuestsProvider = Provider<List<QuestModel>>((ref) {
  final all = ref.watch(questNotifierProvider).valueOrNull ?? [];
  return all.where((q) => q.repeatFrequency == QuestRepeatFrequency.weekly).toList();
});

/// Quests tied to the current liturgical season.
final liturgicalQuestsProvider = Provider<List<QuestModel>>((ref) {
  final all = ref.watch(questNotifierProvider).valueOrNull ?? [];
  final season = LiturgicalColors.displayNameFor(ref.watch(currentSeasonProvider));
  return all.where((q) => q.liturgicalSeason == season).toList();
});
