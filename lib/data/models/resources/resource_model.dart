import 'package:equatable/equatable.dart';
import 'resource_type.dart';

class ResourceModel extends Equatable {
  final String userId;
  final int holyPoints;
  final int faithCoins;
  final int blessings;
  final int grace;
  final DateTime updatedAt;

  const ResourceModel({
    required this.userId,
    required this.holyPoints,
    required this.faithCoins,
    required this.blessings,
    required this.grace,
    required this.updatedAt,
  });

  /// Returns the current amount for a given [ResourceType].
  int getByType(ResourceType type) {
    switch (type) {
      case ResourceType.holyPoints:
        return holyPoints;
      case ResourceType.faithCoins:
        return faithCoins;
      case ResourceType.blessings:
        return blessings;
      case ResourceType.grace:
        return grace;
    }
  }

  factory ResourceModel.fromJson(Map<String, dynamic> json) {
    return ResourceModel(
      userId: json['user_id'] as String,
      holyPoints: json['holy_points'] as int? ?? 0,
      faithCoins: json['faith_coins'] as int? ?? 0,
      blessings: json['blessings'] as int? ?? 0,
      grace: json['grace'] as int? ?? 0,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'holy_points': holyPoints,
      'faith_coins': faithCoins,
      'blessings': blessings,
      'grace': grace,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ResourceModel copyWith({
    String? userId,
    int? holyPoints,
    int? faithCoins,
    int? blessings,
    int? grace,
    DateTime? updatedAt,
  }) {
    return ResourceModel(
      userId: userId ?? this.userId,
      holyPoints: holyPoints ?? this.holyPoints,
      faithCoins: faithCoins ?? this.faithCoins,
      blessings: blessings ?? this.blessings,
      grace: grace ?? this.grace,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        holyPoints,
        faithCoins,
        blessings,
        grace,
        updatedAt,
      ];
}
