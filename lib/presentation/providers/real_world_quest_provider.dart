import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kingdomcome/data/models/quest/real_world_quest_model.dart';
import 'package:kingdomcome/data/models/quest/real_world_completion_model.dart';
import 'package:kingdomcome/data/repositories/real_world_quest_repository.dart';
import 'package:kingdomcome/presentation/providers/auth_provider.dart';

part 'real_world_quest_provider.g.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

final realWorldQuestRepositoryProvider =
    Provider<RealWorldQuestRepository>((ref) {
  return RealWorldQuestRepositoryImpl(
    supabaseClient: Supabase.instance.client,
  );
});

// ---------------------------------------------------------------------------
// State classes
// ---------------------------------------------------------------------------

class RealWorldQuestState {
  final List<RealWorldQuestModel> quests;
  final RealWorldCategory selectedCategory;
  final List<RealWorldCompletionModel> pendingValidations;
  final List<RealWorldCompletionModel> myCompletions;
  final Set<String> activeQuestIds;
  final bool isLoading;
  final String? error;

  const RealWorldQuestState({
    this.quests = const [],
    this.selectedCategory = RealWorldCategory.homeLife,
    this.pendingValidations = const [],
    this.myCompletions = const [],
    this.activeQuestIds = const {},
    this.isLoading = false,
    this.error,
  });

  RealWorldQuestState copyWith({
    List<RealWorldQuestModel>? quests,
    RealWorldCategory? selectedCategory,
    List<RealWorldCompletionModel>? pendingValidations,
    List<RealWorldCompletionModel>? myCompletions,
    Set<String>? activeQuestIds,
    bool? isLoading,
    String? error,
  }) {
    return RealWorldQuestState(
      quests: quests ?? this.quests,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      pendingValidations: pendingValidations ?? this.pendingValidations,
      myCompletions: myCompletions ?? this.myCompletions,
      activeQuestIds: activeQuestIds ?? this.activeQuestIds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<RealWorldQuestModel> get filteredQuests =>
      quests.where((q) => q.category == selectedCategory).toList();

  List<RealWorldQuestModel> get customQuests =>
      quests.where((q) => q.isCustom).toList();

  int get pendingCount => pendingValidations.length;
}

// ---------------------------------------------------------------------------
// RealWorldQuestNotifier
// ---------------------------------------------------------------------------

@riverpod
class RealWorldQuestNotifier extends _$RealWorldQuestNotifier {
  @override
  RealWorldQuestState build() {
    _init();
    return const RealWorldQuestState();
  }

  Future<void> _init() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = state.copyWith(isLoading: true, error: null);

    final repo = ref.read(realWorldQuestRepositoryProvider);

    final questsResult = await repo.getAllQuests(user.ageGroup);
    final completionsResult = await repo.getCompletionsForUser(user.id);

    questsResult.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (quests) {
        completionsResult.fold(
          (_) => state = state.copyWith(
            quests: quests,
            isLoading: false,
          ),
          (completions) {
            final pendingIds = completions
                .where((c) => c.status == CompletionStatus.pendingValidation)
                .map((c) => c.questId)
                .toSet();
            state = state.copyWith(
              quests: quests,
              myCompletions: completions,
              activeQuestIds: pendingIds,
              isLoading: false,
            );
          },
        );
      },
    );
  }

  void selectCategory(RealWorldCategory category) {
    state = state.copyWith(selectedCategory: category);
  }

  void startQuest(String questId) {
    final updated = Set<String>.from(state.activeQuestIds)..add(questId);
    state = state.copyWith(activeQuestIds: updated);
  }

  Future<bool> submitCompletion(
    String questId,
    String? note,
    String? photoUrl,
  ) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return false;

    final repo = ref.read(realWorldQuestRepositoryProvider);
    final result = await repo.submitCompletion(user.id, questId, note, photoUrl);

    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (completion) {
        final updatedCompletions = [completion, ...state.myCompletions];
        final updatedActive = Set<String>.from(state.activeQuestIds)
          ..remove(questId);
        state = state.copyWith(
          myCompletions: updatedCompletions,
          activeQuestIds: updatedActive,
        );
        return true;
      },
    );
  }

  Future<void> refreshPending() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final repo = ref.read(realWorldQuestRepositoryProvider);
    // For children — refresh their own completions to check if any were
    // approved while they were waiting
    final result = await repo.getCompletionsForUser(user.id);
    result.fold(
      (_) {},
      (completions) {
        final pending = completions
            .where((c) => c.status == CompletionStatus.pendingValidation)
            .toList();
        state = state.copyWith(
          myCompletions: completions,
          pendingValidations: pending,
        );
      },
    );
  }

  Future<void> refresh() => _init();
}

// ---------------------------------------------------------------------------
// Derived providers
// ---------------------------------------------------------------------------

/// Quests for the currently selected category.
final filteredRealWorldQuestsProvider =
    Provider<List<RealWorldQuestModel>>((ref) {
  return ref.watch(realWorldQuestNotifierProvider).filteredQuests;
});

/// Count of completions waiting for parent approval (for badge display).
final pendingRealWorldCountProvider = Provider<int>((ref) {
  return ref
      .watch(realWorldQuestNotifierProvider)
      .myCompletions
      .where((c) => c.status == CompletionStatus.pendingValidation)
      .length;
});

// ---------------------------------------------------------------------------
// Digital Fast State
// ---------------------------------------------------------------------------

class DigitalFastState {
  final bool isTimerRunning;
  final DateTime? sessionStartTime;
  final int todayGadgetFreeMinutes;
  final String? activeChallengeId;
  final int streakDays;

  const DigitalFastState({
    this.isTimerRunning = false,
    this.sessionStartTime,
    this.todayGadgetFreeMinutes = 0,
    this.activeChallengeId,
    this.streakDays = 0,
  });

  DigitalFastState copyWith({
    bool? isTimerRunning,
    DateTime? sessionStartTime,
    int? todayGadgetFreeMinutes,
    String? activeChallengeId,
    int? streakDays,
  }) {
    return DigitalFastState(
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      todayGadgetFreeMinutes:
          todayGadgetFreeMinutes ?? this.todayGadgetFreeMinutes,
      activeChallengeId: activeChallengeId ?? this.activeChallengeId,
      streakDays: streakDays ?? this.streakDays,
    );
  }

  /// Elapsed seconds in the current session.
  int get currentSessionSeconds {
    if (!isTimerRunning || sessionStartTime == null) return 0;
    return DateTime.now().difference(sessionStartTime!).inSeconds;
  }

  /// Total gadget-free minutes today including the ongoing session.
  int get totalGadgetFreeMinutesToday {
    if (!isTimerRunning || sessionStartTime == null) {
      return todayGadgetFreeMinutes;
    }
    return todayGadgetFreeMinutes + currentSessionSeconds ~/ 60;
  }

  /// Number of candles lit (1 candle per 30 minutes, max 8).
  int get candlesLit =>
      (totalGadgetFreeMinutesToday ~/ 30).clamp(0, 8);
}

// ---------------------------------------------------------------------------
// DigitalFastNotifier
// ---------------------------------------------------------------------------

@riverpod
class DigitalFastNotifier extends _$DigitalFastNotifier {
  Ticker? _ticker;
  int _tickCount = 0;

  @override
  DigitalFastState build() {
    ref.onDispose(() {
      _ticker?.dispose();
    });
    return const DigitalFastState();
  }

  void startSession({String? challengeId}) {
    if (state.isTimerRunning) return;

    // Rebuild every second via a Ticker
    _ticker?.dispose();
    _ticker = Ticker((_) {
      _tickCount++;
      // Trigger a rebuild every second by emitting a new state
      if (_tickCount % 60 == 0) {
        // Every 60 ticks (~1 second with Ticker) — check challenge completion
        checkAndAwardChallenge();
      }
      // Force the provider to recalculate currentSessionSeconds
      state = state.copyWith(isTimerRunning: true);
    });
    _ticker!.start();

    state = state.copyWith(
      isTimerRunning: true,
      sessionStartTime: DateTime.now(),
      activeChallengeId: challengeId,
    );
  }

  void pauseSession() {
    if (!state.isTimerRunning) return;
    _ticker?.stop();

    final elapsed = state.currentSessionSeconds ~/ 60;
    state = DigitalFastState(
      isTimerRunning: false,
      sessionStartTime: null,
      todayGadgetFreeMinutes: state.todayGadgetFreeMinutes + elapsed,
      activeChallengeId: state.activeChallengeId,
      streakDays: state.streakDays,
    );
  }

  void stopSession() {
    pauseSession();
    checkAndAwardChallenge();
    state = state.copyWith(activeChallengeId: null);
    _ticker?.dispose();
    _ticker = null;
    _tickCount = 0;
  }

  void checkAndAwardChallenge() {
    if (state.activeChallengeId == null) return;
    final minutes = state.totalGadgetFreeMinutesToday;

    bool completed = false;
    switch (state.activeChallengeId) {
      case 'gadget_free_meal':
        completed = minutes >= 30;
      case 'two_hour_break':
        completed = minutes >= 120;
      case 'screen_free_bedtime':
        completed = minutes >= 60;
      default:
        completed = false;
    }

    if (completed) {
      // Notify the quest notifier to submit the completion for this challenge
      final user = ref.read(currentUserProvider);
      if (user != null && state.activeChallengeId != null) {
        ref
            .read(realWorldQuestNotifierProvider.notifier)
            .submitCompletion(state.activeChallengeId!, null, null);
      }
      state = state.copyWith(activeChallengeId: null);
    }
  }
}
