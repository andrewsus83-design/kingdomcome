import 'package:equatable/equatable.dart';
import 'building_type.dart';

class BuildingModel extends Equatable {
  final String id;
  final String kingdomId;
  final BuildingType type;
  final int level;
  final int gridX;
  final int gridY;
  final bool isUnderConstruction;
  final DateTime? constructionCompletesAt;
  final Map<String, dynamic> metadata;

  const BuildingModel({
    required this.id,
    required this.kingdomId,
    required this.type,
    required this.level,
    required this.gridX,
    required this.gridY,
    this.isUnderConstruction = false,
    this.constructionCompletesAt,
    this.metadata = const {},
  });

  bool get isConstructionComplete {
    if (!isUnderConstruction) return true;
    if (constructionCompletesAt == null) return true;
    return DateTime.now().isAfter(constructionCompletesAt!);
  }

  factory BuildingModel.fromJson(Map<String, dynamic> json) {
    return BuildingModel(
      id: json['id'] as String,
      kingdomId: json['kingdom_id'] as String,
      type: BuildingType.fromDatabaseValue(
          json['building_type'] as String? ?? json['type'] as String? ?? 'chapel'),
      level: json['level'] as int? ?? 1,
      gridX: json['grid_x'] as int,
      gridY: json['grid_y'] as int,
      isUnderConstruction: json['is_under_construction'] as bool? ?? false,
      constructionCompletesAt: json['construction_completes_at'] != null
          ? DateTime.parse(json['construction_completes_at'] as String)
          : null,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kingdom_id': kingdomId,
      'building_type': type.databaseValue,
      'level': level,
      'grid_x': gridX,
      'grid_y': gridY,
      'is_under_construction': isUnderConstruction,
      'construction_completes_at': constructionCompletesAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  BuildingModel copyWith({
    String? id,
    String? kingdomId,
    BuildingType? type,
    int? level,
    int? gridX,
    int? gridY,
    bool? isUnderConstruction,
    DateTime? constructionCompletesAt,
    Map<String, dynamic>? metadata,
  }) {
    return BuildingModel(
      id: id ?? this.id,
      kingdomId: kingdomId ?? this.kingdomId,
      type: type ?? this.type,
      level: level ?? this.level,
      gridX: gridX ?? this.gridX,
      gridY: gridY ?? this.gridY,
      isUnderConstruction: isUnderConstruction ?? this.isUnderConstruction,
      constructionCompletesAt:
          constructionCompletesAt ?? this.constructionCompletesAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        kingdomId,
        type,
        level,
        gridX,
        gridY,
        isUnderConstruction,
        constructionCompletesAt,
        metadata,
      ];
}
