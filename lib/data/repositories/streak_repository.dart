import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failure.dart';
import '../models/streak/streak_model.dart';

// ---------------------------------------------------------------------------
// Abstract interface
// ---------------------------------------------------------------------------

abstract class StreakRepository {
  /// Returns the streak of [streakType] for [userId].
  Future<Either<Failure, StreakModel>> getStreak(
    String userId,
    StreakType streakType,
  );

  /// Records an activity for [userId] of [streakType], advancing the streak
  /// if the activity has not already been recorded today.
  Future<Either<Failure, StreakModel>> recordActivity(
    String userId,
    StreakType streakType,
  );

  /// Activates the streak shield for [userId] of [streakType].
  /// A streak shield prevents the streak from breaking on the next missed day.
  Future<Either<Failure, void>> activateStreakShield(
    String userId,
    StreakType streakType,
  );
}

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

class StreakRepositoryImpl implements StreakRepository {
  StreakRepositoryImpl({required SupabaseClient supabaseClient})
      : _client = supabaseClient;

  final SupabaseClient _client;

  @override
  Future<Either<Failure, StreakModel>> getStreak(
    String userId,
    StreakType streakType,
  ) async {
    try {
      final data = await _client
          .from('user_streaks')
          .select()
          .eq('user_id', userId)
          .eq('streak_type', streakType.databaseKey)
          .single();

      return Right(StreakModel.fromJson(data));
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        // No streak record yet; return a fresh default.
        return Right(
          StreakModel(
            userId: userId,
            type: streakType,
            currentStreak: 0,
            longestStreak: 0,
          ),
        );
      }
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, StreakModel>> recordActivity(
    String userId,
    StreakType streakType,
  ) async {
    try {
      // Edge function handles the streak logic:
      //  - Idempotent: calling twice on the same day is a no-op.
      //  - If last completed was yesterday → increment streak.
      //  - If last completed was 2+ days ago and no shield → reset to 1.
      //  - If last completed was 2+ days ago and shield active → reset to 1,
      //    consume the shield.
      //  - Updates longest_streak if current exceeds it.
      final result = await _client.functions.invoke(
        'record-streak-activity',
        body: {
          'user_id': userId,
          'streak_type': streakType.databaseKey,
        },
      );

      if (result.data == null) {
        return const Left(
          GameFailure(message: 'Record activity returned no data.'),
        );
      }

      return Right(
        StreakModel.fromJson(result.data as Map<String, dynamic>),
      );
    } on FunctionException catch (e) {
      return Left(
        GameFailure(
          message: e.details?.toString() ?? 'Record activity failed.',
        ),
      );
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> activateStreakShield(
    String userId,
    StreakType streakType,
  ) async {
    try {
      await _client.rpc('activate_streak_shield', params: {
        'p_user_id': userId,
        'p_streak_type': streakType.databaseKey,
      });
      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }
}
