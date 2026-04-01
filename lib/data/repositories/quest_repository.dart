import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failure.dart';
import '../models/quest/quest_completion_model.dart';
import '../models/quest/quest_model.dart';

// ---------------------------------------------------------------------------
// Abstract interface
// ---------------------------------------------------------------------------

abstract class QuestRepository {
  /// Returns all quests available to [userId] during [season].
  /// [season] is a liturgical season string (e.g. "Advent", "Lent",
  /// "Ordinary Time"). Passing null returns year-round quests.
  Future<Either<Failure, List<QuestModel>>> getAvailableQuests(
    String userId,
    String? season,
  );

  /// Returns the subset of quests designated as "daily" for [userId].
  Future<Either<Failure, List<QuestModel>>> getDailyQuests(String userId);

  /// Submits a quest completion for [userId] and [questId].
  /// [proofUrl] is required for quests with [QuestVerificationType.photoUpload].
  Future<Either<Failure, QuestCompletionModel>> completeQuest(
    String userId,
    String questId, {
    String? proofUrl,
  });

  /// Returns all completions for [userId] on [date].
  Future<Either<Failure, List<QuestCompletionModel>>> getCompletions(
    String userId,
    DateTime date,
  );
}

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

class QuestRepositoryImpl implements QuestRepository {
  QuestRepositoryImpl({required SupabaseClient supabaseClient})
      : _client = supabaseClient;

  final SupabaseClient _client;

  @override
  Future<Either<Failure, List<QuestModel>>> getAvailableQuests(
    String userId,
    String? season,
  ) async {
    try {
      // Fetch quests that are active and either have no season filter or
      // match the current season.
      var query = _client
          .from('quests')
          .select()
          .eq('is_active', true);

      if (season != null) {
        // Return year-round quests OR season-specific quests.
        query = query.or(
          'liturgical_season.is.null,liturgical_season.eq.$season',
        );
      } else {
        query = query.filter('liturgical_season', 'is', null);
      }

      final List<dynamic> data = await query.order('sort_order');
      final quests = data
          .map((q) => QuestModel.fromJson(q as Map<String, dynamic>))
          .toList();
      return Right(quests);
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<QuestModel>>> getDailyQuests(
    String userId,
  ) async {
    try {
      final data = await _client
          .from('quests')
          .select()
          .eq('is_active', true)
          .eq('repeat_frequency', 'daily')
          .order('sort_order');

      final quests = (data as List<dynamic>)
          .map((q) => QuestModel.fromJson(q as Map<String, dynamic>))
          .toList();
      return Right(quests);
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, QuestCompletionModel>> completeQuest(
    String userId,
    String questId, {
    String? proofUrl,
  }) async {
    try {
      // Server-side edge function handles:
      //  1. Duplicate-completion guard (once / daily / weekly throttle).
      //  2. Resource grant (holyPoints, faithCoins, grace, blessings).
      //  3. Streak update.
      //  4. Level-up check.
      final result = await _client.functions.invoke(
        'complete-quest',
        body: {
          'user_id': userId,
          'quest_id': questId,
          if (proofUrl != null) 'proof_url': proofUrl,
        },
      );

      if (result.data == null) {
        return const Left(
          GameFailure(message: 'Quest completion returned no data.'),
        );
      }

      return Right(
        QuestCompletionModel.fromJson(
          result.data as Map<String, dynamic>,
        ),
      );
    } on FunctionException catch (e) {
      final detail = e.details;
      if (detail is Map) {
        final code = detail['code']?.toString() ?? '';
        final msg = detail['message']?.toString() ?? 'Quest completion failed.';
        if (code == 'already_completed') {
          return Left(ValidationFailure(message: msg, code: code));
        }
        if (code == 'not_yet_available') {
          return Left(ValidationFailure(message: msg, code: code));
        }
      }
      return Left(
        GameFailure(
          message: detail?.toString() ?? 'Quest completion failed.',
        ),
      );
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<QuestCompletionModel>>> getCompletions(
    String userId,
    DateTime date,
  ) async {
    try {
      final dayStart = DateTime(date.year, date.month, date.day)
          .toUtc()
          .toIso8601String();
      final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59)
          .toUtc()
          .toIso8601String();

      final data = await _client
          .from('quest_completions')
          .select()
          .eq('user_id', userId)
          .gte('completed_at', dayStart)
          .lte('completed_at', dayEnd)
          .order('completed_at', ascending: false);

      final completions = (data as List<dynamic>)
          .map((c) =>
              QuestCompletionModel.fromJson(c as Map<String, dynamic>))
          .toList();
      return Right(completions);
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }
}
