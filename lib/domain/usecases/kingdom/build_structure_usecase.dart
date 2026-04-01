import 'package:dartz/dartz.dart';

import '../../../core/errors/failure.dart';
import '../../../data/models/kingdom/building_model.dart';
import '../../../data/models/kingdom/building_type.dart';
import '../../../data/models/resources/resource_type.dart';
import '../../../data/repositories/kingdom_repository.dart';
import '../../entities/kingdom_entity.dart';

/// Parameters for [BuildStructureUseCase].
class BuildStructureParams {
  final String userId;
  final KingdomEntity kingdom;
  final BuildingType buildingType;
  final int gridX;
  final int gridY;

  const BuildStructureParams({
    required this.userId,
    required this.kingdom,
    required this.buildingType,
    required this.gridX,
    required this.gridY,
  });
}

/// Use case that validates all preconditions before delegating to the
/// [KingdomRepository] to construct a building.
///
/// Validations performed (client-side, server also re-validates):
///  1. User's kingdom level meets the minimum for this building type.
///  2. The building type has not already been placed (one per type).
///  3. The target grid cell is not occupied.
///  4. The user has sufficient Holy Points.
class BuildStructureUseCase {
  const BuildStructureUseCase({
    required KingdomRepository kingdomRepository,
  }) : _kingdomRepository = kingdomRepository;

  final KingdomRepository _kingdomRepository;

  Future<Either<Failure, BuildingModel>> call(
    BuildStructureParams params,
  ) async {
    final kingdom = params.kingdom;
    final buildingType = params.buildingType;

    // -----------------------------------------------------------------------
    // 1. Kingdom level check
    // -----------------------------------------------------------------------
    final requiredLevel = KingdomEntity.requiredKingdomLevelFor(buildingType);
    if (kingdom.level < requiredLevel) {
      return Left(
        ValidationFailure(
          message:
              'Your kingdom must be level $requiredLevel to build a '
              '${buildingType.displayName}. '
              'You are currently level ${kingdom.level}.',
          code: 'kingdom_level_too_low',
        ),
      );
    }

    // -----------------------------------------------------------------------
    // 2. One building per type
    // -----------------------------------------------------------------------
    if (kingdom.hasBuilding(buildingType)) {
      return Left(
        ValidationFailure(
          message:
              'You already have a ${buildingType.displayName} in your kingdom.',
          code: 'building_already_exists',
        ),
      );
    }

    // -----------------------------------------------------------------------
    // 3. Grid cell availability
    // -----------------------------------------------------------------------
    if (kingdom.isGridOccupied(params.gridX, params.gridY)) {
      return Left(
        ValidationFailure(
          message:
              'Grid cell (${params.gridX}, ${params.gridY}) is already '
              'occupied by another building.',
          code: 'grid_cell_occupied',
        ),
      );
    }

    // -----------------------------------------------------------------------
    // 4. Resource check (Holy Points)
    // -----------------------------------------------------------------------
    final cost = KingdomEntity.holyPointsCostFor(buildingType);
    if (!kingdom.hasEnough(ResourceType.holyPoints, cost)) {
      final current =
          kingdom.availableResources.getByType(ResourceType.holyPoints);
      return Left(
        InsufficientResourcesFailure(
          message:
              'Not enough Holy Points to build ${buildingType.displayName}. '
              'Required: $cost, Available: $current.',
          resourceType: 'holyPoints',
          required: cost,
          available: current,
        ),
      );
    }

    // -----------------------------------------------------------------------
    // Delegate to repository (server performs authoritative validation)
    // -----------------------------------------------------------------------
    return _kingdomRepository.buildStructure(
      kingdom.id,
      buildingType,
      params.gridX,
      params.gridY,
    );
  }
}
