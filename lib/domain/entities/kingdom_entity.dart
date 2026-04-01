import '../../data/models/kingdom/building_model.dart';
import '../../data/models/kingdom/building_type.dart';
import '../../data/models/resources/resource_model.dart';
import '../../data/models/resources/resource_type.dart';

/// Pure domain entity for a user's kingdom.
/// Combines kingdom structure with available resources to support
/// use-case business logic without UI or network dependencies.
class KingdomEntity {
  final String id;
  final String name;
  final int level;
  final List<BuildingModel> buildings;
  final ResourceModel availableResources;

  const KingdomEntity({
    required this.id,
    required this.name,
    required this.level,
    required this.buildings,
    required this.availableResources,
  });

  // ---------------------------------------------------------------------------
  // Grid helpers
  // ---------------------------------------------------------------------------

  /// Returns true when grid cell ([x], [y]) is already occupied.
  bool isGridOccupied(int x, int y) {
    return buildings.any((b) => b.gridX == x && b.gridY == y);
  }

  /// Returns all occupied grid coordinates as a set of "(x,y)" strings.
  Set<String> get occupiedCells =>
      buildings.map((b) => '${b.gridX},${b.gridY}').toSet();

  // ---------------------------------------------------------------------------
  // Building helpers
  // ---------------------------------------------------------------------------

  /// Returns true when the kingdom already contains a building of [type].
  bool hasBuilding(BuildingType type) =>
      buildings.any((b) => b.type == type);

  /// Returns the building of [type], or null if not built.
  BuildingModel? buildingOfType(BuildingType type) {
    try {
      return buildings.firstWhere((b) => b.type == type);
    } catch (_) {
      return null;
    }
  }

  /// Returns the level of the building of [type], or 0 if not built.
  int buildingLevel(BuildingType type) =>
      buildingOfType(type)?.level ?? 0;

  // ---------------------------------------------------------------------------
  // Resource helpers
  // ---------------------------------------------------------------------------

  /// Returns true when the kingdom has at least [amount] of [resourceType].
  bool hasEnough(ResourceType resourceType, int amount) =>
      availableResources.getByType(resourceType) >= amount;

  // ---------------------------------------------------------------------------
  // Building cost table
  // ---------------------------------------------------------------------------

  /// Returns the construction cost in Holy Points for a new building of [type].
  static int holyPointsCostFor(BuildingType type) {
    switch (type) {
      case BuildingType.cathedral:
        return 500;
      case BuildingType.monastery:
        return 300;
      case BuildingType.school:
        return 200;
      case BuildingType.workshop:
        return 150;
      case BuildingType.chapel:
        return 100;
      case BuildingType.bellTower:
        return 75;
      case BuildingType.parishHall:
        return 250;
      case BuildingType.scriptorium:
        return 175;
      case BuildingType.oratory:
        return 80;
      case BuildingType.garden:
        return 120;
    }
  }

  /// Returns the minimum kingdom level required to build [type].
  static int requiredKingdomLevelFor(BuildingType type) {
    switch (type) {
      case BuildingType.oratory:
        return 1;
      case BuildingType.bellTower:
        return 1;
      case BuildingType.chapel:
        return 2;
      case BuildingType.school:
        return 2;
      case BuildingType.garden:
        return 3;
      case BuildingType.workshop:
        return 3;
      case BuildingType.scriptorium:
        return 4;
      case BuildingType.parishHall:
        return 4;
      case BuildingType.monastery:
        return 5;
      case BuildingType.cathedral:
        return 6;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KingdomEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'KingdomEntity(id: $id, name: $name, level: $level, '
      'buildings: ${buildings.length})';
}
