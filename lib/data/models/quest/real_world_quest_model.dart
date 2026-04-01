import 'package:equatable/equatable.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum RealWorldCategory {
  homeLife,
  schoolLife,
  community,
  digitalFast,
  characterBuilding,
  family,
  church,
}

extension RealWorldCategoryX on RealWorldCategory {
  String get displayName {
    switch (this) {
      case RealWorldCategory.homeLife:
        return 'Home Life';
      case RealWorldCategory.schoolLife:
        return 'School Life';
      case RealWorldCategory.community:
        return 'Community';
      case RealWorldCategory.digitalFast:
        return 'Digital Fast';
      case RealWorldCategory.characterBuilding:
        return 'Character';
      case RealWorldCategory.family:
        return 'Family';
      case RealWorldCategory.church:
        return 'Church';
    }
  }

  String get emoji {
    switch (this) {
      case RealWorldCategory.homeLife:
        return '🏠';
      case RealWorldCategory.schoolLife:
        return '🎒';
      case RealWorldCategory.community:
        return '👥';
      case RealWorldCategory.digitalFast:
        return '📵';
      case RealWorldCategory.characterBuilding:
        return '❤️';
      case RealWorldCategory.family:
        return '👨‍👩‍👧';
      case RealWorldCategory.church:
        return '⛪';
    }
  }
}

enum RealWorldVerification {
  parentValidate,
  photoScan,
  appTimer,
  honorSystem,
  churchCheckin,
}

extension RealWorldVerificationX on RealWorldVerification {
  String get displayName {
    switch (this) {
      case RealWorldVerification.parentValidate:
        return 'Parent Confirms';
      case RealWorldVerification.photoScan:
        return 'Photo Proof';
      case RealWorldVerification.appTimer:
        return 'Built-in Timer';
      case RealWorldVerification.honorSystem:
        return 'Honor System';
      case RealWorldVerification.churchCheckin:
        return 'Church Check-in';
    }
  }

  String get emoji {
    switch (this) {
      case RealWorldVerification.parentValidate:
        return '👨‍👩‍👧';
      case RealWorldVerification.photoScan:
        return '📸';
      case RealWorldVerification.appTimer:
        return '⏱️';
      case RealWorldVerification.honorSystem:
        return '🤝';
      case RealWorldVerification.churchCheckin:
        return '⛪';
    }
  }

  String get explanation {
    switch (this) {
      case RealWorldVerification.parentValidate:
        return 'Your parent will confirm this in the Parent Gate.';
      case RealWorldVerification.photoScan:
        return 'Take a photo as proof using the Masterpiece Scanner.';
      case RealWorldVerification.appTimer:
        return 'A built-in timer will track the time automatically.';
      case RealWorldVerification.honorSystem:
        return 'You confirm on your honor that you completed this.';
      case RealWorldVerification.churchCheckin:
        return 'Check in at church or have your parent confirm attendance.';
    }
  }
}

enum RepeatFrequency {
  daily,
  weekly,
  once,
}

extension RepeatFrequencyX on RepeatFrequency {
  String get displayName {
    switch (this) {
      case RepeatFrequency.daily:
        return 'Daily';
      case RepeatFrequency.weekly:
        return 'Weekly';
      case RepeatFrequency.once:
        return 'One Time';
    }
  }
}

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class RealWorldQuestModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final RealWorldCategory category;
  final RealWorldVerification verification;
  final int holyPointsReward;
  final int faithCoinsReward;
  final int graceReward;
  final int estimatedMinutes;
  final int ageGroupMin;
  final bool isRepeatable;
  final RepeatFrequency repeatFrequency;
  final String iconEmoji;
  final String inspirationalQuote;
  final String relatedVirtue;
  final bool isCustom;
  final String? createdByParentId;
  final bool isActive;
  final int sortOrder;

  const RealWorldQuestModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.verification,
    required this.holyPointsReward,
    this.faithCoinsReward = 0,
    this.graceReward = 0,
    required this.estimatedMinutes,
    this.ageGroupMin = 1,
    this.isRepeatable = true,
    this.repeatFrequency = RepeatFrequency.once,
    required this.iconEmoji,
    required this.inspirationalQuote,
    required this.relatedVirtue,
    this.isCustom = false,
    this.createdByParentId,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory RealWorldQuestModel.fromJson(Map<String, dynamic> json) {
    return RealWorldQuestModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: RealWorldCategory.values.byName(json['category'] as String),
      verification:
          RealWorldVerification.values.byName(json['verification'] as String),
      holyPointsReward: json['holy_points_reward'] as int? ?? 0,
      faithCoinsReward: json['faith_coins_reward'] as int? ?? 0,
      graceReward: json['grace_reward'] as int? ?? 0,
      estimatedMinutes: json['estimated_minutes'] as int? ?? 15,
      ageGroupMin: json['age_group_min'] as int? ?? 1,
      isRepeatable: json['is_repeatable'] as bool? ?? true,
      repeatFrequency: json['repeat_frequency'] != null
          ? RepeatFrequency.values.byName(json['repeat_frequency'] as String)
          : RepeatFrequency.once,
      iconEmoji: json['icon_emoji'] as String? ?? '⭐',
      inspirationalQuote: json['inspirational_quote'] as String? ?? '',
      relatedVirtue: json['related_virtue'] as String? ?? '',
      isCustom: json['is_custom'] as bool? ?? false,
      createdByParentId: json['created_by_parent_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'verification': verification.name,
      'holy_points_reward': holyPointsReward,
      'faith_coins_reward': faithCoinsReward,
      'grace_reward': graceReward,
      'estimated_minutes': estimatedMinutes,
      'age_group_min': ageGroupMin,
      'is_repeatable': isRepeatable,
      'repeat_frequency': repeatFrequency.name,
      'icon_emoji': iconEmoji,
      'inspirational_quote': inspirationalQuote,
      'related_virtue': relatedVirtue,
      'is_custom': isCustom,
      'created_by_parent_id': createdByParentId,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }

  RealWorldQuestModel copyWith({
    String? id,
    String? title,
    String? description,
    RealWorldCategory? category,
    RealWorldVerification? verification,
    int? holyPointsReward,
    int? faithCoinsReward,
    int? graceReward,
    int? estimatedMinutes,
    int? ageGroupMin,
    bool? isRepeatable,
    RepeatFrequency? repeatFrequency,
    String? iconEmoji,
    String? inspirationalQuote,
    String? relatedVirtue,
    bool? isCustom,
    String? createdByParentId,
    bool? isActive,
    int? sortOrder,
  }) {
    return RealWorldQuestModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      verification: verification ?? this.verification,
      holyPointsReward: holyPointsReward ?? this.holyPointsReward,
      faithCoinsReward: faithCoinsReward ?? this.faithCoinsReward,
      graceReward: graceReward ?? this.graceReward,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      ageGroupMin: ageGroupMin ?? this.ageGroupMin,
      isRepeatable: isRepeatable ?? this.isRepeatable,
      repeatFrequency: repeatFrequency ?? this.repeatFrequency,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      inspirationalQuote: inspirationalQuote ?? this.inspirationalQuote,
      relatedVirtue: relatedVirtue ?? this.relatedVirtue,
      isCustom: isCustom ?? this.isCustom,
      createdByParentId: createdByParentId ?? this.createdByParentId,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        verification,
        holyPointsReward,
        faithCoinsReward,
        graceReward,
        estimatedMinutes,
        ageGroupMin,
        isRepeatable,
        repeatFrequency,
        iconEmoji,
        inspirationalQuote,
        relatedVirtue,
        isCustom,
        createdByParentId,
        isActive,
        sortOrder,
      ];
}
