import 'package:equatable/equatable.dart';
import '../kingdom/building_type.dart';
import 'question_model.dart';

enum QuizCategory {
  sacraments,
  saints,
  bible,
  churchHistory,
  liturgy,
  prayer,
  catechism,
  seasonal,
  moralTheology,
  general,
}

extension QuizCategoryX on QuizCategory {
  String get displayName {
    switch (this) {
      case QuizCategory.sacraments:
        return 'Sacraments';
      case QuizCategory.saints:
        return 'Saints';
      case QuizCategory.bible:
        return 'Bible';
      case QuizCategory.churchHistory:
        return 'Church History';
      case QuizCategory.liturgy:
        return 'Liturgy';
      case QuizCategory.prayer:
        return 'Prayer';
      case QuizCategory.catechism:
        return 'Catechism';
      case QuizCategory.seasonal:
        return 'Seasonal';
      case QuizCategory.moralTheology:
        return 'Moral Theology';
      case QuizCategory.general:
        return 'General';
    }
  }

  String get databaseKey {
    switch (this) {
      case QuizCategory.churchHistory:
        return 'church_history';
      case QuizCategory.prayer:
        return 'prayers';
      case QuizCategory.catechism:
        return 'moral_theology';
      case QuizCategory.seasonal:
        return 'general';
      case QuizCategory.moralTheology:
        return 'moral_theology';
      case QuizCategory.general:
        return 'general';
      default:
        return name;
    }
  }

  static QuizCategory fromDatabaseValue(String value) {
    switch (value) {
      case 'church_history':
        return QuizCategory.churchHistory;
      case 'prayers':
        return QuizCategory.prayer;
      case 'moral_theology':
        return QuizCategory.moralTheology;
      case 'general':
        return QuizCategory.general;
      default:
        return QuizCategory.values.firstWhere(
          (c) => c.name == value,
          orElse: () => QuizCategory.general,
        );
    }
  }
}

class QuizModel extends Equatable {
  final String id;
  final String title;
  final QuizCategory category;

  /// 1 = easy, 2 = medium, 3 = hard, 4 = legendary.
  final int difficultyLevel;

  /// Minimum age group (1–3) for this quiz.
  final int ageGroupMin;

  final int completionHolyPoints;
  final int completionFaithCoins;

  /// Bonus Holy Points awarded for a perfect score.
  final int perfectScoreBonusHp;

  /// Building required to unlock this quiz (null = always available).
  final BuildingType? requiredBuildingType;

  /// Liturgical season filter (null = year-round).
  final String? liturgicalSeason;

  final List<QuestionModel> questions;
  final bool isActive;

  const QuizModel({
    required this.id,
    required this.title,
    required this.category,
    required this.difficultyLevel,
    required this.ageGroupMin,
    required this.completionHolyPoints,
    this.completionFaithCoins = 0,
    this.perfectScoreBonusHp = 0,
    this.requiredBuildingType,
    this.liturgicalSeason,
    this.questions = const [],
    this.isActive = true,
  });

  int get questionCount => questions.length;

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      category: QuizCategoryX.fromDatabaseValue(
          json['category'] as String? ?? 'general'),
      difficultyLevel: json['difficulty'] as int? ??
          json['difficulty_level'] as int? ?? 1,
      ageGroupMin: json['min_age_group'] as int? ??
          json['age_group_min'] as int? ?? 1,
      completionHolyPoints: json['holy_points_reward'] as int? ??
          json['completion_holy_points'] as int? ?? 0,
      completionFaithCoins: json['faith_coins_reward'] as int? ??
          json['completion_faith_coins'] as int? ?? 0,
      perfectScoreBonusHp: json['perfect_score_bonus_hp'] as int? ?? 0,
      requiredBuildingType: json['required_building'] != null
          ? BuildingType.fromDatabaseValue(json['required_building'] as String)
          : json['required_building_type'] != null
              ? BuildingType.fromDatabaseValue(
                  json['required_building_type'] as String)
              : null,
      liturgicalSeason: json['liturgical_season'] as String?,
      questions: (json['quiz_questions'] as List<dynamic>? ??
                  json['questions'] as List<dynamic>?)
              ?.map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
              .toList() ??
          [],
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category.name,
      'difficulty_level': difficultyLevel,
      'age_group_min': ageGroupMin,
      'completion_holy_points': completionHolyPoints,
      'completion_faith_coins': completionFaithCoins,
      'perfect_score_bonus_hp': perfectScoreBonusHp,
      'required_building_type': requiredBuildingType?.name,
      'liturgical_season': liturgicalSeason,
      'questions': questions.map((q) => q.toJson()).toList(),
      'is_active': isActive,
    };
  }

  QuizModel copyWith({
    String? id,
    String? title,
    QuizCategory? category,
    int? difficultyLevel,
    int? ageGroupMin,
    int? completionHolyPoints,
    int? completionFaithCoins,
    int? perfectScoreBonusHp,
    BuildingType? requiredBuildingType,
    String? liturgicalSeason,
    List<QuestionModel>? questions,
    bool? isActive,
  }) {
    return QuizModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      ageGroupMin: ageGroupMin ?? this.ageGroupMin,
      completionHolyPoints: completionHolyPoints ?? this.completionHolyPoints,
      completionFaithCoins: completionFaithCoins ?? this.completionFaithCoins,
      perfectScoreBonusHp: perfectScoreBonusHp ?? this.perfectScoreBonusHp,
      requiredBuildingType: requiredBuildingType ?? this.requiredBuildingType,
      liturgicalSeason: liturgicalSeason ?? this.liturgicalSeason,
      questions: questions ?? this.questions,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        category,
        difficultyLevel,
        ageGroupMin,
        completionHolyPoints,
        completionFaithCoins,
        perfectScoreBonusHp,
        requiredBuildingType,
        liturgicalSeason,
        questions,
        isActive,
      ];
}
