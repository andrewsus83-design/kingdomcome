import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failure.dart';
import '../models/parish/parish_member_model.dart';
import '../models/parish/parish_model.dart';

// ---------------------------------------------------------------------------
// Abstract interface
// ---------------------------------------------------------------------------

abstract class ParishRepository {
  /// Searches for a parish by name or city using [query].
  Future<Either<Failure, ParishModel>> searchParish(String query);

  /// Joins a parish identified by its [inviteCode] for [userId].
  Future<Either<Failure, ParishModel>> joinByInviteCode(
    String userId,
    String inviteCode,
  );

  /// Creates a private family group owned by [userId] with [name].
  Future<Either<Failure, ParishModel>> createFamilyGroup(
    String userId,
    String name,
  );

  /// Returns the leaderboard for [parishId] for the week starting [weekStart].
  Future<Either<Failure, List<ParishMemberModel>>> getLeaderboard(
    String parishId,
    DateTime weekStart,
  );

  /// Removes [userId] from [parishId].
  Future<Either<Failure, void>> leaveParish(
    String userId,
    String parishId,
  );
}

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

class ParishRepositoryImpl implements ParishRepository {
  ParishRepositoryImpl({required SupabaseClient supabaseClient})
      : _client = supabaseClient;

  final SupabaseClient _client;

  @override
  Future<Either<Failure, ParishModel>> searchParish(String query) async {
    try {
      final data = await _client
          .from('parishes')
          .select()
          .or('name.ilike.%$query%,city.ilike.%$query%,diocese.ilike.%$query%')
          .eq('is_family_group', false)
          .limit(1)
          .single();

      return Right(ParishModel.fromJson(data));
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return Left(
          NotFoundFailure(message: 'No parish found matching "$query".'),
        );
      }
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ParishModel>> joinByInviteCode(
    String userId,
    String inviteCode,
  ) async {
    try {
      final result = await _client.functions.invoke(
        'join-parish',
        body: {
          'user_id': userId,
          'invite_code': inviteCode.trim().toUpperCase(),
        },
      );

      if (result.data == null) {
        return const Left(
          GameFailure(message: 'Join parish returned no data.'),
        );
      }

      return Right(
        ParishModel.fromJson(result.data as Map<String, dynamic>),
      );
    } on FunctionException catch (e) {
      final detail = e.details;
      if (detail is Map) {
        final code = detail['code']?.toString() ?? '';
        final msg =
            detail['message']?.toString() ?? 'Join parish failed.';
        if (code == 'invalid_invite_code') {
          return Left(ValidationFailure(message: msg, code: code));
        }
        if (code == 'already_member') {
          return Left(ValidationFailure(message: msg, code: code));
        }
      }
      return Left(
        GameFailure(message: detail?.toString() ?? 'Join parish failed.'),
      );
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ParishModel>> createFamilyGroup(
    String userId,
    String name,
  ) async {
    try {
      final result = await _client.functions.invoke(
        'create-family-group',
        body: {
          'user_id': userId,
          'name': name,
        },
      );

      if (result.data == null) {
        return const Left(
          GameFailure(message: 'Create family group returned no data.'),
        );
      }

      return Right(
        ParishModel.fromJson(result.data as Map<String, dynamic>),
      );
    } on FunctionException catch (e) {
      return Left(
        GameFailure(
          message: e.details?.toString() ?? 'Create family group failed.',
        ),
      );
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ParishMemberModel>>> getLeaderboard(
    String parishId,
    DateTime weekStart,
  ) async {
    try {
      final weekStartIso = DateTime(
        weekStart.year,
        weekStart.month,
        weekStart.day,
      ).toUtc().toIso8601String();

      // Call a Supabase RPC that aggregates weekly holy points for the parish.
      final data = await _client.rpc(
        'get_parish_leaderboard',
        params: {
          'p_parish_id': parishId,
          'p_week_start': weekStartIso,
        },
      );

      final members = (data as List<dynamic>)
          .map((m) =>
              ParishMemberModel.fromJson(m as Map<String, dynamic>))
          .toList();
      return Right(members);
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> leaveParish(
    String userId,
    String parishId,
  ) async {
    try {
      await _client
          .from('parish_members')
          .delete()
          .eq('user_id', userId)
          .eq('parish_id', parishId);

      // Clear parish_id from user profile.
      await _client
          .from('user_profiles')
          .update({'parish_id': null})
          .eq('id', userId);

      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }
}
