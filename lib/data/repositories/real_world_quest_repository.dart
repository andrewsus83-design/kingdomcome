import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kingdomcome/core/errors/failure.dart';
import 'package:kingdomcome/data/models/quest/real_world_quest_model.dart';
import 'package:kingdomcome/data/models/quest/real_world_completion_model.dart';

// ---------------------------------------------------------------------------
// Abstract interface
// ---------------------------------------------------------------------------

abstract class RealWorldQuestRepository {
  /// Returns quests for [category] filtered to [ageGroup].
  Future<Either<Failure, List<RealWorldQuestModel>>> getQuestsByCategory(
    RealWorldCategory category,
    int ageGroup,
  );

  /// Returns all real-world quests available to [ageGroup].
  Future<Either<Failure, List<RealWorldQuestModel>>> getAllQuests(int ageGroup);

  /// Returns custom quests created by [parentId].
  Future<Either<Failure, List<RealWorldQuestModel>>> getParentCustomQuests(
    String parentId,
  );

  /// Submits a completion record.
  Future<Either<Failure, RealWorldCompletionModel>> submitCompletion(
    String userId,
    String questId,
    String? childNote,
    String? proofPhotoUrl,
  );

  /// Returns completions for all children of [parentId] that are
  /// pending validation.
  Future<Either<Failure, List<RealWorldCompletionModel>>> getPendingValidations(
    String parentId,
  );

  /// Parent validates a completion, awarding rewards to the child.
  Future<Either<Failure, void>> validateCompletion(
    String completionId,
    String? parentNote,
  );

  /// Parent rejects a completion (child is not penalised).
  Future<Either<Failure, void>> rejectCompletion(
    String completionId,
    String? reason,
  );

  /// Creates a custom quest for the specified child.
  Future<Either<Failure, RealWorldQuestModel>> createCustomQuest(
    String parentId,
    String title,
    String description,
    RealWorldCategory category,
    int holyPointsReward,
    int faithCoinsReward,
    RepeatFrequency repeatFrequency,
    RealWorldVerification verification,
  );

  /// Returns completions for [userId] across all statuses.
  Future<Either<Failure, List<RealWorldCompletionModel>>> getCompletionsForUser(
    String userId,
  );
}

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

class RealWorldQuestRepositoryImpl implements RealWorldQuestRepository {
  RealWorldQuestRepositoryImpl({required SupabaseClient supabaseClient})
      : _client = supabaseClient;

  final SupabaseClient _client;

  @override
  Future<Either<Failure, List<RealWorldQuestModel>>> getQuestsByCategory(
    RealWorldCategory category,
    int ageGroup,
  ) async {
    try {
      final data = await _client
          .from('real_world_quests')
          .select()
          .eq('category', category.name)
          .eq('is_active', true)
          .lte('age_group_min', ageGroup)
          .order('sort_order');

      final quests = (data as List<dynamic>)
          .map((q) =>
              RealWorldQuestModel.fromJson(q as Map<String, dynamic>))
          .toList();
      return Right(quests);
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RealWorldQuestModel>>> getAllQuests(
    int ageGroup,
  ) async {
    try {
      final data = await _client
          .from('real_world_quests')
          .select()
          .eq('is_active', true)
          .lte('age_group_min', ageGroup)
          .order('sort_order');

      final quests = (data as List<dynamic>)
          .map((q) =>
              RealWorldQuestModel.fromJson(q as Map<String, dynamic>))
          .toList();
      return Right(quests);
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RealWorldQuestModel>>> getParentCustomQuests(
    String parentId,
  ) async {
    try {
      final data = await _client
          .from('real_world_quests')
          .select()
          .eq('is_custom', true)
          .eq('created_by_parent_id', parentId)
          .eq('is_active', true)
          .order('sort_order');

      final quests = (data as List<dynamic>)
          .map((q) =>
              RealWorldQuestModel.fromJson(q as Map<String, dynamic>))
          .toList();
      return Right(quests);
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, RealWorldCompletionModel>> submitCompletion(
    String userId,
    String questId,
    String? childNote,
    String? proofPhotoUrl,
  ) async {
    try {
      final data = await _client
          .from('real_world_completions')
          .insert({
            'user_id': userId,
            'quest_id': questId,
            'status': 'pending_validation',
            if (childNote != null) 'child_note': childNote,
            if (proofPhotoUrl != null) 'proof_photo_url': proofPhotoUrl,
            'completed_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return Right(
          RealWorldCompletionModel.fromJson(data as Map<String, dynamic>));
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RealWorldCompletionModel>>> getPendingValidations(
    String parentId,
  ) async {
    try {
      // The RPC resolves child IDs from the parent's family group
      final data = await _client.rpc(
        'get_pending_real_world_validations',
        params: {'p_parent_id': parentId},
      ) as List<dynamic>;

      final completions = data
          .map((c) =>
              RealWorldCompletionModel.fromJson(c as Map<String, dynamic>))
          .toList();
      return Right(completions);
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> validateCompletion(
    String completionId,
    String? parentNote,
  ) async {
    try {
      await _client.rpc(
        'validate_real_world_quest',
        params: {
          'p_completion_id': completionId,
          if (parentNote != null) 'p_parent_note': parentNote,
        },
      );
      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } on FunctionException catch (e) {
      return Left(
          GameFailure(message: e.details?.toString() ?? 'Validation failed.'));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rejectCompletion(
    String completionId,
    String? reason,
  ) async {
    try {
      await _client
          .from('real_world_completions')
          .update({
            'status': 'rejected',
            if (reason != null) 'parent_note': reason,
          })
          .eq('id', completionId);
      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, RealWorldQuestModel>> createCustomQuest(
    String parentId,
    String title,
    String description,
    RealWorldCategory category,
    int holyPointsReward,
    int faithCoinsReward,
    RepeatFrequency repeatFrequency,
    RealWorldVerification verification,
  ) async {
    try {
      final data = await _client
          .from('real_world_quests')
          .insert({
            'title': title,
            'description': description,
            'category': category.name,
            'verification': verification.name,
            'holy_points_reward': holyPointsReward,
            'faith_coins_reward': faithCoinsReward,
            'grace_reward': 0,
            'estimated_minutes': 30,
            'age_group_min': 1,
            'is_repeatable': repeatFrequency != RepeatFrequency.once,
            'repeat_frequency': repeatFrequency.name,
            'icon_emoji': category.emoji,
            'inspirational_quote':
                '"Whatever you do, do it from the heart." — Colossians 3:23',
            'related_virtue': 'Love',
            'is_custom': true,
            'created_by_parent_id': parentId,
            'is_active': true,
            'sort_order': 999,
          })
          .select()
          .single();

      return Right(
          RealWorldQuestModel.fromJson(data as Map<String, dynamic>));
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RealWorldCompletionModel>>> getCompletionsForUser(
    String userId,
  ) async {
    try {
      final data = await _client
          .from('real_world_completions')
          .select()
          .eq('user_id', userId)
          .order('completed_at', ascending: false)
          .limit(50);

      final completions = (data as List<dynamic>)
          .map((c) =>
              RealWorldCompletionModel.fromJson(c as Map<String, dynamic>))
          .toList();
      return Right(completions);
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }
}
