import 'package:equatable/equatable.dart';
import 'building_model.dart';

class KingdomModel extends Equatable {
  final String id;
  final String userId;
  final String name;
  final int level;
  final int landSize;
  final String? bannerImageUrl;
  final DateTime foundedAt;
  final List<BuildingModel> buildings;

  const KingdomModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.level,
    required this.landSize,
    this.bannerImageUrl,
    required this.foundedAt,
    this.buildings = const [],
  });

  factory KingdomModel.fromJson(Map<String, dynamic> json) {
    return KingdomModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      level: json['level'] as int? ?? 1,
      landSize: json['land_size'] as int? ?? 10,
      bannerImageUrl: json['banner_image_url'] as String?,
      foundedAt: DateTime.parse(json['founded_at'] as String),
      buildings: (json['buildings'] as List<dynamic>?)
              ?.map((b) => BuildingModel.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'level': level,
      'land_size': landSize,
      'banner_image_url': bannerImageUrl,
      'founded_at': foundedAt.toIso8601String(),
      'buildings': buildings.map((b) => b.toJson()).toList(),
    };
  }

  KingdomModel copyWith({
    String? id,
    String? userId,
    String? name,
    int? level,
    int? landSize,
    String? bannerImageUrl,
    DateTime? foundedAt,
    List<BuildingModel>? buildings,
  }) {
    return KingdomModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      level: level ?? this.level,
      landSize: landSize ?? this.landSize,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      foundedAt: foundedAt ?? this.foundedAt,
      buildings: buildings ?? this.buildings,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        level,
        landSize,
        bannerImageUrl,
        foundedAt,
        buildings,
      ];
}
