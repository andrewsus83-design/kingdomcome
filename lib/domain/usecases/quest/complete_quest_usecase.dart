import 'package:dartz/dartz.dart';

import '../../../core/errors/failure.dart';
import '../../../data/models/quest/quest_completion_model.dart';
import '../../../data/models/quest/quest_model.dart';
import '../../../data/repositories/quest_repository.dart';
import '../../../data/repositories/streak_repository.dart';
import '../../../data/models/streak/streak_model.dart';

/// Parameters for [CompleteQuestUseCase].
class CompleteQuestParams {
  final String userId;
  final QuestModel quest;

  /// Required for [QuestVerificationType.photoUpload] quests.
  final String? proofUrl;

  /// The time the user spent on a timed session (for verification).
  final Duration? sessionDuration;

  /// The completions already recorded today (used for repeat throttling).
  final List<QuestCompletionModel> todaysCompletions;

  const CompleteQuestParams({
    required this.userId,
    required this.quest,
    this.proofUrl,
    this.sessionDuration,
    required this.todaysCompletions,
  });
}

/// Result returned by [CompleteQuestUseCase].
class CompleteQuestResult {
  final QuestCompletionModel completion;

  /// Whether this completion triggered a streak increment.
  final bool streakAdvanced;

  const CompleteQuestResult({
    required this.completion,
    required this.streakAdvanced,
  });
}

/// Use case that validates quest completion eligibility then delegates to
/// [QuestRepository] (which calls the Supabase Edge Function for authoritative
/// server-side validation and resource grant).
///
/// Client-side validations performed:
///  1. Quest is currently active.
///  2. Timed-session quests: minimum time was met.
///  3. Photo-upload quests: proof URL is provided.
///  4. Daily quests: not already completed today.
///  5. Once quests: not already completed ever.
class CompleteQuestUseCase {
  const CompleteQuestUseCase({
    required QuestRepository questRepository,
    required StreakRepository streakRepository,
  })  : _questRepository = questRepository,
        _streakRepository = streakRepository;

  final QuestRepository _questRepository;
  final StreakRepository _streakRepository;

  Future<Either<Failure, CompleteQuestResult>> call(
    CompleteQuestParams params,
  ) async {
    final quest = params.quest;

    // -----------------------------------------------------------------------
    // 1. Quest active check
    // -----------------------------------------------------------------------
    if (!quest.isActive) {
      return const Left(
        ValidationFailure(
          message: 'This quest is no longer active.',
          code: 'quest_inactive',
        ),
      );
    }

    // -----------------------------------------------------------------------
    // 2. Timed-session verification
    // -----------------------------------------------------------------------
    if (quest.verificationType == QuestVerificationType.timedSession &&
        quest.verificationRequiredSeconds > 0) {
      final duration = params.sessionDuration;
      if (duration == null ||
          duration.inSeconds < quest.verificationRequiredSeconds) {
        final needed = quest.verificationRequiredSeconds;
        final actual = duration?.inSeconds ?? 0;
        return Left(
          ValidationFailure(
            message:
                'Session too short. Required: ${needed}s, '
                'completed: ${actual}s.',
            code: 'timed_session_too_short',
          ),
        );
      }
    }

    // -----------------------------------------------------------------------
    // 3. Photo upload verification
    // -----------------------------------------------------------------------
    if (quest.verificationType == QuestVerificationType.photoUpload) {
      if (params.proofUrl == null || params.proofUrl!.trim().isEmpty) {
        return const Left(
          ValidationFailure(
            message: 'A photo is required to complete this quest.',
            code: 'proof_required',
          ),
        );
      }
    }

    // -----------------------------------------------------------------------
    // 4. Repeat-frequency throttling
    // -----------------------------------------------------------------------
    if (!quest.isRepeatable) {
      // "once" quests cannot be completed more than once ever.
      // todaysCompletions is a proxy for all-time; server also validates.
      final alreadyDone = params.todaysCompletions
          .any((c) => c.questId == quest.id);
      if (alreadyDone) {
        return const Left(
          ValidationFailure(
            message: 'You have already completed this quest.',
            code: 'already_completed',
          ),
        );
      }
    }

    if (quest.isRepeatable &&
        quest.repeatFrequency == QuestRepeatFrequency.daily) {
      final alreadyDoneToday = params.todaysCompletions
          .any((c) => c.questId == quest.id);
      if (alreadyDoneToday) {
        return const Left(
          ValidationFailure(
            message: 'You have already completed this quest today. '
                'Come back tomorrow!',
            code: 'daily_limit_reached',
          ),
        );
      }
    }

    // -----------------------------------------------------------------------
    // Delegate to repository
    // -----------------------------------------------------------------------
    final completionResult = await _questRepository.completeQuest(
      params.userId,
      quest.id,
      proofUrl: params.proofUrl,
    );

    return completionResult.fold(
      (failure) => Left(failure),
      (completion) async {
        // Advance the general streak after a successful completion.
        bool streakAdvanced = false;
        final streakResult = await _streakRepository.recordActivity(
          params.userId,
          StreakType.dailyQuest,
        );
        streakResult.fold(
          (_) => null, // Non-fatal: streak update failure doesn't block completion.
          (streak) {
            streakAdvanced = streak.currentStreak > 0;
          },
        );

        return Right(
          CompleteQuestResult(
            completion: completion,
            streakAdvanced: streakAdvanced,
          ),
        );
      },
    );
  }
}
