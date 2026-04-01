import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/failure.dart';
import '../models/game/game_session_model.dart';

// ── Abstract interface ────────────────────────────────────────────────────────

abstract class GameRepository {
  /// Saves a completed game session to Supabase.
  Future<Either<Failure, GameSessionModel>> saveSession({
    required String userId,
    required GameType gameType,
    required int score,
    required int maxScore,
    required int durationSeconds,
    required int holyPointsEarned,
    int faithCoinsEarned = 0,
    int graceEarned = 0,
    Map<String, dynamic> metadata = const {},
  });

  /// Returns all sessions for [userId], optionally filtered by [gameType].
  Future<Either<Failure, List<GameSessionModel>>> getUserSessions(
    String userId, {
    GameType? gameType,
  });

  /// Returns the highest score achieved by [userId] for [gameType].
  Future<Either<Failure, int>> getHighScore(String userId, GameType gameType);

  /// Returns parish leaderboard entries for [gameType].
  ///
  /// Each map contains: user_id, display_name, avatar_url, high_score.
  Future<Either<Failure, List<Map<String, dynamic>>>> getParishLeaderboard(
    String parishId,
    GameType gameType,
  );
}

// ── Implementation ────────────────────────────────────────────────────────────

class GameRepositoryImpl implements GameRepository {
  GameRepositoryImpl({required SupabaseClient supabaseClient})
      : _client = supabaseClient;

  final SupabaseClient _client;
  static const _uuid = Uuid();

  // ── saveSession ───────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, GameSessionModel>> saveSession({
    required String userId,
    required GameType gameType,
    required int score,
    required int maxScore,
    required int durationSeconds,
    required int holyPointsEarned,
    int faithCoinsEarned = 0,
    int graceEarned = 0,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final id = _uuid.v4();
      final now = DateTime.now().toUtc();

      final inserted = await _client
          .from('game_sessions')
          .insert({
            'id': id,
            'user_id': userId,
            'game_type': gameType.name,
            'score': score,
            'max_score': maxScore,
            'duration_seconds': durationSeconds,
            'holy_points_earned': holyPointsEarned,
            'faith_coins_earned': faithCoinsEarned,
            'grace_earned': graceEarned,
            'meta_data': metadata,
            'completed_at': now.toIso8601String(),
          })
          .select()
          .single();

      // Also award resources via Supabase RPC
      if (holyPointsEarned > 0 || faithCoinsEarned > 0 || graceEarned > 0) {
        await _client.rpc('award_game_resources', params: {
          'p_user_id': userId,
          'p_holy_points': holyPointsEarned,
          'p_faith_coins': faithCoinsEarned,
          'p_grace': graceEarned,
        }).catchError((_) {}); // Non-fatal if RPC doesn't exist yet
      }

      return Right(GameSessionModel.fromJson(inserted));
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  // ── getUserSessions ───────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<GameSessionModel>>> getUserSessions(
    String userId, {
    GameType? gameType,
  }) async {
    try {
      var query = _client
          .from('game_sessions')
          .select()
          .eq('user_id', userId);

      if (gameType != null) {
        query = query.eq('game_type', gameType.name);
      }

      final data = await query.order('completed_at', ascending: false).limit(100);

      final sessions = (data as List<dynamic>)
          .map((s) => GameSessionModel.fromJson(s as Map<String, dynamic>))
          .toList();

      return Right(sessions);
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  // ── getHighScore ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, int>> getHighScore(
    String userId,
    GameType gameType,
  ) async {
    try {
      // Use the high_scores view defined in the migration
      final data = await _client
          .from('high_scores')
          .select('score')
          .eq('user_id', userId)
          .eq('game_type', gameType.name)
          .maybeSingle();

      if (data == null) return const Right(0);
      return Right(data['score'] as int? ?? 0);
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  // ── getParishLeaderboard ──────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getParishLeaderboard(
    String parishId,
    GameType gameType,
  ) async {
    try {
      // Join game_sessions with user_profiles filtered by parish
      final data = await _client
          .from('parish_game_leaderboard')
          .select('user_id, display_name, avatar_url, high_score')
          .eq('parish_id', parishId)
          .eq('game_type', gameType.name)
          .order('high_score', ascending: false)
          .limit(50);

      return Right((data as List<dynamic>).cast<Map<String, dynamic>>());
    } on PostgrestException catch (e) {
      // Fallback: query high_scores view directly if view not created yet
      try {
        final fallback = await _client
            .from('game_sessions')
            .select('user_id, score')
            .eq('game_type', gameType.name)
            .order('score', ascending: false)
            .limit(50);

        final results = (fallback as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map((row) => {
                  'user_id': row['user_id'],
                  'display_name': 'Player',
                  'avatar_url': '',
                  'high_score': row['score'],
                })
            .toList();

        return Right(results);
      } catch (_) {
        return Left(GameFailure(message: e.message, code: e.code));
      }
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }
}
