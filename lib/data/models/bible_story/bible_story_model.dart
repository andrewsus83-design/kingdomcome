import 'package:equatable/equatable.dart';
import '../kingdom/building_type.dart';

class StoryPanel extends Equatable {
  final String imageUrl;
  final String text;
  final String? verseReference;
  final String? audioUrl;

  const StoryPanel({
    required this.imageUrl,
    required this.text,
    this.verseReference,
    this.audioUrl,
  });

  factory StoryPanel.fromJson(Map<String, dynamic> json) {
    return StoryPanel(
      imageUrl: json['image_url'] as String,
      text: json['text'] as String,
      verseReference: json['verse_reference'] as String?,
      audioUrl: json['audio_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image_url': imageUrl,
      'text': text,
      'verse_reference': verseReference,
      'audio_url': audioUrl,
    };
  }

  @override
  List<Object?> get props => [imageUrl, text, verseReference, audioUrl];
}

class BibleStoryModel extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String coverImageUrl;
  final List<StoryPanel> panels;

  /// IDs of Bible verses referenced in this story.
  final List<String> relatedVerseIds;

  /// Minimum age group (1–3) required to access this story.
  final int ageGroupMin;

  /// Estimated reading time in minutes.
  final int durationMinutes;

  /// Liturgical season filter (null = year-round).
  final String? liturgicalSeason;

  /// HeyGen AI video URL for narrated version (optional).
  final String? heygenVideoUrl;

  final int holyPointsReward;
  final bool isLocked;

  /// Building required to unlock this story (null = always available).
  final BuildingType? requiredBuildingType;

  const BibleStoryModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.coverImageUrl,
    required this.panels,
    this.relatedVerseIds = const [],
    this.ageGroupMin = 1,
    required this.durationMinutes,
    this.liturgicalSeason,
    this.heygenVideoUrl,
    this.holyPointsReward = 0,
    this.isLocked = false,
    this.requiredBuildingType,
  });

  factory BibleStoryModel.fromJson(Map<String, dynamic> json) {
    return BibleStoryModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      description: json['description'] as String,
      coverImageUrl: json['cover_image_url'] as String,
      panels: (json['panels'] as List<dynamic>)
          .map((p) => StoryPanel.fromJson(p as Map<String, dynamic>))
          .toList(),
      relatedVerseIds: (json['related_verse_ids'] as List<dynamic>?)
              ?.map((v) => v as String)
              .toList() ??
          [],
      ageGroupMin: json['age_group_min'] as int? ?? 1,
      durationMinutes: json['duration_minutes'] as int,
      liturgicalSeason: json['liturgical_season'] as String?,
      heygenVideoUrl: json['heygen_video_url'] as String?,
      holyPointsReward: json['holy_points_reward'] as int? ?? 0,
      isLocked: json['is_locked'] as bool? ?? false,
      requiredBuildingType: json['required_building_type'] != null
          ? BuildingType.fromDatabaseValue(
              json['required_building_type'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'cover_image_url': coverImageUrl,
      'panels': panels.map((p) => p.toJson()).toList(),
      'related_verse_ids': relatedVerseIds,
      'age_group_min': ageGroupMin,
      'duration_minutes': durationMinutes,
      'liturgical_season': liturgicalSeason,
      'heygen_video_url': heygenVideoUrl,
      'holy_points_reward': holyPointsReward,
      'is_locked': isLocked,
      'required_building_type': requiredBuildingType?.name,
    };
  }

  BibleStoryModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? description,
    String? coverImageUrl,
    List<StoryPanel>? panels,
    List<String>? relatedVerseIds,
    int? ageGroupMin,
    int? durationMinutes,
    String? liturgicalSeason,
    String? heygenVideoUrl,
    int? holyPointsReward,
    bool? isLocked,
    BuildingType? requiredBuildingType,
  }) {
    return BibleStoryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      panels: panels ?? this.panels,
      relatedVerseIds: relatedVerseIds ?? this.relatedVerseIds,
      ageGroupMin: ageGroupMin ?? this.ageGroupMin,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      liturgicalSeason: liturgicalSeason ?? this.liturgicalSeason,
      heygenVideoUrl: heygenVideoUrl ?? this.heygenVideoUrl,
      holyPointsReward: holyPointsReward ?? this.holyPointsReward,
      isLocked: isLocked ?? this.isLocked,
      requiredBuildingType: requiredBuildingType ?? this.requiredBuildingType,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        subtitle,
        description,
        coverImageUrl,
        panels,
        relatedVerseIds,
        ageGroupMin,
        durationMinutes,
        liturgicalSeason,
        heygenVideoUrl,
        holyPointsReward,
        isLocked,
        requiredBuildingType,
      ];
}
