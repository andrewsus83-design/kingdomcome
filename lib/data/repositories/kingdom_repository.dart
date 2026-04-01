import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/failure.dart';
import '../models/kingdom/building_model.dart';
import '../models/kingdom/building_type.dart';
import '../models/kingdom/kingdom_model.dart';

// ---------------------------------------------------------------------------
// Abstract interface
// ---------------------------------------------------------------------------

abstract class KingdomRepository {
  /// Fetches the kingdom belonging to [userId].
  Future<Either<Failure, KingdomModel>> getKingdom(String userId);

  /// Creates a new kingdom for [userId] with the given [name].
  Future<Either<Failure, KingdomModel>> createKingdom(
    String userId,
    String name,
  );

  /// Starts construction of a building of [buildingType] at ([gridX], [gridY]).
  Future<Either<Failure, BuildingModel>> buildStructure(
    String kingdomId,
    BuildingType buildingType,
    int gridX,
    int gridY,
  );

  /// Upgrades an existing building to the next level.
  Future<Either<Failure, BuildingModel>> upgradeBuilding(String buildingId);

  /// Associates an [artworkId] with a [buildingId] for display.
  Future<Either<Failure, void>> placeArtwork(
    String buildingId,
    String artworkId,
  );
}

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

class KingdomRepositoryImpl implements KingdomRepository {
  KingdomRepositoryImpl({required SupabaseClient supabaseClient})
      : _client = supabaseClient;

  final SupabaseClient _client;
  static const _uuid = Uuid();

  @override
  Future<Either<Failure, KingdomModel>> getKingdom(String userId) async {
    try {
      final kingdomData = await _client
          .from('kingdoms')
          .select('*, buildings(*)')
          .eq('user_id', userId)
          .single();
      return Right(KingdomModel.fromJson(kingdomData));
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return const Left(
          NotFoundFailure(message: 'Kingdom not found. Please create one.'),
        );
      }
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, KingdomModel>> createKingdom(
    String userId,
    String name,
  ) async {
    try {
      final id = _uuid.v4();
      final now = DateTime.now().toUtc().toIso8601String();

      final inserted = await _client
          .from('kingdoms')
          .insert({
            'id': id,
            'user_id': userId,
            'name': name,
            'level': 1,
            'land_size': 10,
            'founded_at': now,
          })
          .select('*, buildings(*)')
          .single();
      return Right(KingdomModel.fromJson(inserted));
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, BuildingModel>> buildStructure(
    String kingdomId,
    BuildingType buildingType,
    int gridX,
    int gridY,
  ) async {
    try {
      // Determine construction duration based on building type via edge function
      // so the server authoritative time is used.
      final result = await _client.functions.invoke(
        'build-structure',
        body: {
          'kingdom_id': kingdomId,
          'building_type': buildingType.databaseValue,
          'grid_x': gridX,
          'grid_y': gridY,
        },
      );

      if (result.data == null) {
        return const Left(
          GameFailure(message: 'Build structure returned no data.'),
        );
      }

      return Right(
        BuildingModel.fromJson(result.data as Map<String, dynamic>),
      );
    } on FunctionException catch (e) {
      final detail = e.details;
      if (detail is Map && detail['code'] == 'insufficient_resources') {
        return Left(GameFailure(
          message: detail['message']?.toString() ??
              'Not enough resources to build.',
          code: 'insufficient_resources',
        ));
      }
      return Left(
        GameFailure(message: detail?.toString() ?? 'Build structure failed.'),
      );
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, BuildingModel>> upgradeBuilding(
    String buildingId,
  ) async {
    try {
      final result = await _client.functions.invoke(
        'upgrade-building',
        body: {'building_id': buildingId},
      );

      if (result.data == null) {
        return const Left(
          GameFailure(message: 'Upgrade building returned no data.'),
        );
      }

      return Right(
        BuildingModel.fromJson(result.data as Map<String, dynamic>),
      );
    } on FunctionException catch (e) {
      final detail = e.details;
      if (detail is Map && detail['code'] == 'insufficient_resources') {
        return Left(GameFailure(
          message: detail['message']?.toString() ??
              'Not enough resources to upgrade.',
          code: 'insufficient_resources',
        ));
      }
      return Left(
        GameFailure(message: detail?.toString() ?? 'Upgrade failed.'),
      );
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> placeArtwork(
    String buildingId,
    String artworkId,
  ) async {
    try {
      await _client.from('building_artworks').upsert({
        'building_id': buildingId,
        'artwork_id': artworkId,
        'placed_at': DateTime.now().toUtc().toIso8601String(),
      });
      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }
}
