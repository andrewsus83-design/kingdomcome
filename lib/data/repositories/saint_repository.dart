import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failure.dart';
import '../models/saint/saint_model.dart';
import '../models/saint/user_saint_model.dart';

// ---------------------------------------------------------------------------
// Abstract interface
// ---------------------------------------------------------------------------

abstract class SaintRepository {
  /// Returns all Saints visible in the app catalogue.
  Future<Either<Failure, List<SaintModel>>> getAllSaints();

  /// Returns the Saints unlocked by [userId].
  Future<Either<Failure, List<UserSaintModel>>> getUserSaints(String userId);

  /// Unlocks [saintId] for [userId], deducting the Holy Points cost.
  Future<Either<Failure, UserSaintModel>> unlockSaint(
    String userId,
    String saintId,
  );

  /// Sets [saintId] as the active (companion) Saint for [userId].
  Future<Either<Failure, void>> setActiveSaint(
    String userId,
    String saintId,
  );

  /// Activates the ability of [saintId] for [userId], deducting Grace.
  Future<Either<Failure, void>> activateSaintAbility(
    String userId,
    String saintId,
  );

  /// Returns the Saint whose feast day matches [date] (MM-DD).
  Future<Either<Failure, SaintModel>> getSaintByFeastDay(DateTime date);
}

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

class SaintRepositoryImpl implements SaintRepository {
  SaintRepositoryImpl({required SupabaseClient supabaseClient})
      : _client = supabaseClient;

  final SupabaseClient _client;

  @override
  Future<Either<Failure, List<SaintModel>>> getAllSaints() async {
    try {
      final data = await _client
          .from('saints')
          .select()
          .eq('is_active', true)
          .order('sort_order');

      final saints = (data as List<dynamic>)
          .map((s) => SaintModel.fromJson(s as Map<String, dynamic>))
          .toList();
      return Right(saints);
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UserSaintModel>>> getUserSaints(
    String userId,
  ) async {
    try {
      final data = await _client
          .from('user_saints')
          .select()
          .eq('user_id', userId);

      final userSaints = (data as List<dynamic>)
          .map((s) => UserSaintModel.fromJson(s as Map<String, dynamic>))
          .toList();
      return Right(userSaints);
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserSaintModel>> unlockSaint(
    String userId,
    String saintId,
  ) async {
    try {
      // Edge function validates Holy Points balance and inserts user_saints row.
      final result = await _client.functions.invoke(
        'unlock-saint',
        body: {
          'user_id': userId,
          'saint_id': saintId,
        },
      );

      if (result.data == null) {
        return const Left(
          GameFailure(message: 'Unlock saint returned no data.'),
        );
      }

      return Right(
        UserSaintModel.fromJson(result.data as Map<String, dynamic>),
      );
    } on FunctionException catch (e) {
      final detail = e.details;
      if (detail is Map && detail['code'] == 'insufficient_resources') {
        return Left(GameFailure(
          message: detail['message']?.toString() ??
              'Not enough Holy Points to unlock this Saint.',
          code: 'insufficient_resources',
        ));
      }
      return Left(
        GameFailure(
          message: detail?.toString() ?? 'Unlock saint failed.',
        ),
      );
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setActiveSaint(
    String userId,
    String saintId,
  ) async {
    try {
      // Deactivate any currently active saint.
      await _client
          .from('user_saints')
          .update({'is_active': false})
          .eq('user_id', userId);

      // Activate the chosen saint.
      await _client
          .from('user_saints')
          .update({'is_active': true})
          .eq('user_id', userId)
          .eq('saint_id', saintId);

      // Mirror on the user profile for quick access.
      await _client
          .from('user_profiles')
          .update({'active_saint_id': saintId})
          .eq('user_id', userId);

      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> activateSaintAbility(
    String userId,
    String saintId,
  ) async {
    try {
      // Edge function validates Grace balance, sets ability_activated_at /
      // ability_expires_at, and deducts Grace.
      await _client.functions.invoke(
        'activate-saint-ability',
        body: {
          'user_id': userId,
          'saint_id': saintId,
        },
      );
      return const Right(null);
    } on FunctionException catch (e) {
      final detail = e.details;
      if (detail is Map && detail['code'] == 'insufficient_resources') {
        return Left(GameFailure(
          message: detail['message']?.toString() ??
              'Not enough Grace to activate this ability.',
          code: 'insufficient_resources',
        ));
      }
      return Left(
        GameFailure(
          message: detail?.toString() ?? 'Activate saint ability failed.',
        ),
      );
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SaintModel>> getSaintByFeastDay(
    DateTime date,
  ) async {
    try {
      final mmdd =
          '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final data = await _client
          .from('saints')
          .select()
          .eq('feast_day', mmdd)
          .eq('is_active', true)
          .limit(1)
          .single();

      return Right(SaintModel.fromJson(data));
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return Left(
          NotFoundFailure(
            message: 'No saint found for feast day on this date.',
          ),
        );
      }
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }
}
