import 'package:equatable/equatable.dart';

enum ArtworkType {
  stainedGlass,
  manuscript,
  mosaic,
  banner,
}

extension ArtworkTypeX on ArtworkType {
  String get displayName {
    switch (this) {
      case ArtworkType.stainedGlass:
        return 'Stained Glass';
      case ArtworkType.manuscript:
        return 'Manuscript';
      case ArtworkType.mosaic:
        return 'Mosaic';
      case ArtworkType.banner:
        return 'Banner';
    }
  }
}

class ArtworkModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final ArtworkType artworkType;

  /// Serialised canvas state (paths, layers, colours, etc.).
  final Map<String, dynamic> canvasData;

  final String? thumbnailUrl;
  final bool isDisplayedInKingdom;

  /// Grid coordinates and display metadata when placed in the kingdom.
  final Map<String, dynamic>? kingdomLocation;

  final int holyPointsEarned;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ArtworkModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.artworkType,
    required this.canvasData,
    this.thumbnailUrl,
    this.isDisplayedInKingdom = false,
    this.kingdomLocation,
    this.holyPointsEarned = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ArtworkModel.fromJson(Map<String, dynamic> json) {
    return ArtworkModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      artworkType: ArtworkType.values.byName(json['artwork_type'] as String),
      canvasData: (json['canvas_data'] as Map<String, dynamic>?) ?? {},
      thumbnailUrl: json['thumbnail_url'] as String?,
      isDisplayedInKingdom: json['is_displayed_in_kingdom'] as bool? ?? false,
      kingdomLocation:
          json['kingdom_location'] as Map<String, dynamic>?,
      holyPointsEarned: json['holy_points_earned'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'artwork_type': artworkType.name,
      'canvas_data': canvasData,
      'thumbnail_url': thumbnailUrl,
      'is_displayed_in_kingdom': isDisplayedInKingdom,
      'kingdom_location': kingdomLocation,
      'holy_points_earned': holyPointsEarned,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ArtworkModel copyWith({
    String? id,
    String? userId,
    String? title,
    ArtworkType? artworkType,
    Map<String, dynamic>? canvasData,
    String? thumbnailUrl,
    bool? isDisplayedInKingdom,
    Map<String, dynamic>? kingdomLocation,
    int? holyPointsEarned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ArtworkModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      artworkType: artworkType ?? this.artworkType,
      canvasData: canvasData ?? this.canvasData,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isDisplayedInKingdom: isDisplayedInKingdom ?? this.isDisplayedInKingdom,
      kingdomLocation: kingdomLocation ?? this.kingdomLocation,
      holyPointsEarned: holyPointsEarned ?? this.holyPointsEarned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        artworkType,
        canvasData,
        thumbnailUrl,
        isDisplayedInKingdom,
        kingdomLocation,
        holyPointsEarned,
        createdAt,
        updatedAt,
      ];
}
