import 'package:equatable/equatable.dart';
import '../kingdom/building_type.dart';
import 'quest_category.dart';

class QuestModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final QuestCategory category;
  final QuestDifficulty difficulty;
  final QuestVerificationType verificationType;

  /// Minimum seconds required for timed verification (0 = no minimum).
  final int verificationRequiredSeconds;

  // Rewards
  final int holyPointsReward;
  final int faithCoinsReward;
  final int graceReward;
  final int blessingsReward;

  final bool isRepeatable;
  final QuestRepeatFrequency? repeatFrequency;

  /// Building required to unlock this quest (null = always available).
  final BuildingType? requiredBuildingType;

  /// Minimum user level required (null = no restriction).
  final int? requiredLevel;

  /// Liturgical season filter (e.g. "Advent", "Lent", "Ordinary Time", null = year-round).
  final String? liturgicalSeason;

  final List<String> steps;
  final String iconAssetPath;

  final DateTime? availableFrom;
  final DateTime? availableUntil;

  final int sortOrder;
  final bool isActive;

  const QuestModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.verificationType,
    this.verificationRequiredSeconds = 0,
    required this.holyPointsReward,
    this.faithCoinsReward = 0,
    this.graceReward = 0,
    this.blessingsReward = 0,
    this.isRepeatable = true,
    this.repeatFrequency,
    this.requiredBuildingType,
    this.requiredLevel,
    this.liturgicalSeason,
    this.steps = const [],
    required this.iconAssetPath,
    this.availableFrom,
    this.availableUntil,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory QuestModel.fromJson(Map<String, dynamic> json) {
    return QuestModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: QuestCategoryX.fromDatabaseValue(
          json['category'] as String? ?? 'prayer'),
      difficulty: QuestDifficultyX.fromDatabaseValue(
          json['difficulty'] as String? ?? 'easy'),
      verificationType: QuestVerificationTypeX.fromDatabaseValue(
          json['verification_type'] as String? ?? 'self_report'),
      verificationRequiredSeconds:
          json['verification_required_seconds'] as int? ?? 0,
      holyPointsReward: json['holy_points_reward'] as int? ?? 0,
      faithCoinsReward: json['faith_coins_reward'] as int? ?? 0,
      graceReward: json['grace_reward'] as int? ?? 0,
      blessingsReward: json['blessings_reward'] as int? ?? 0,
      isRepeatable: json['repeat_frequency'] != null,
      repeatFrequency: QuestRepeatFrequencyX.fromDatabaseValue(
          json['repeat_frequency'] as String?),
      requiredBuildingType:
          json['required_building'] != null
              ? BuildingType.fromDatabaseValue(
                  json['required_building'] as String)
              : json['required_building_type'] != null
                  ? BuildingType.fromDatabaseValue(
                      json['required_building_type'] as String)
                  : null,
      requiredLevel: json['min_level'] as int? ?? json['required_level'] as int?,
      liturgicalSeason: json['liturgical_season'] as String?,
      steps: (json['steps'] as List<dynamic>?)
              ?.map((s) => s as String)
              .toList() ??
          [],
      iconAssetPath: json['icon_name'] != null
          ? 'assets/images/quests/${json['icon_name']}.png'
          : json['icon_asset_path'] as String? ??
              'assets/images/quests/default.png',
      availableFrom: json['available_from'] != null
          ? DateTime.tryParse(json['available_from'] as String)
          : null,
      availableUntil: json['available_until'] != null
          ? DateTime.tryParse(json['available_until'] as String)
          : null,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'difficulty': difficulty.name,
      'verification_type': verificationType.name,
      'verification_required_seconds': verificationRequiredSeconds,
      'holy_points_reward': holyPointsReward,
      'faith_coins_reward': faithCoinsReward,
      'grace_reward': graceReward,
      'blessings_reward': blessingsReward,
      'is_repeatable': isRepeatable,
      'repeat_frequency': repeatFrequency?.name,
      'required_building_type': requiredBuildingType?.name,
      'required_level': requiredLevel,
      'liturgical_season': liturgicalSeason,
      'steps': steps,
      'icon_asset_path': iconAssetPath,
      'available_from': availableFrom?.toIso8601String(),
      'available_until': availableUntil?.toIso8601String(),
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }

  QuestModel copyWith({
    String? id,
    String? title,
    String? description,
    QuestCategory? category,
    QuestDifficulty? difficulty,
    QuestVerificationType? verificationType,
    int? verificationRequiredSeconds,
    int? holyPointsReward,
    int? faithCoinsReward,
    int? graceReward,
    int? blessingsReward,
    bool? isRepeatable,
    QuestRepeatFrequency? repeatFrequency,
    BuildingType? requiredBuildingType,
    int? requiredLevel,
    String? liturgicalSeason,
    List<String>? steps,
    String? iconAssetPath,
    DateTime? availableFrom,
    DateTime? availableUntil,
    int? sortOrder,
    bool? isActive,
  }) {
    return QuestModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      verificationType: verificationType ?? this.verificationType,
      verificationRequiredSeconds:
          verificationRequiredSeconds ?? this.verificationRequiredSeconds,
      holyPointsReward: holyPointsReward ?? this.holyPointsReward,
      faithCoinsReward: faithCoinsReward ?? this.faithCoinsReward,
      graceReward: graceReward ?? this.graceReward,
      blessingsReward: blessingsReward ?? this.blessingsReward,
      isRepeatable: isRepeatable ?? this.isRepeatable,
      repeatFrequency: repeatFrequency ?? this.repeatFrequency,
      requiredBuildingType: requiredBuildingType ?? this.requiredBuildingType,
      requiredLevel: requiredLevel ?? this.requiredLevel,
      liturgicalSeason: liturgicalSeason ?? this.liturgicalSeason,
      steps: steps ?? this.steps,
      iconAssetPath: iconAssetPath ?? this.iconAssetPath,
      availableFrom: availableFrom ?? this.availableFrom,
      availableUntil: availableUntil ?? this.availableUntil,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        difficulty,
        verificationType,
        verificationRequiredSeconds,
        holyPointsReward,
        faithCoinsReward,
        graceReward,
        blessingsReward,
        isRepeatable,
        repeatFrequency,
        requiredBuildingType,
        requiredLevel,
        liturgicalSeason,
        steps,
        iconAssetPath,
        availableFrom,
        availableUntil,
        sortOrder,
        isActive,
      ];
}
