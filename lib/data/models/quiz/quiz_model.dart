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
      title: json['title'] as String,
      category: QuizCategory.values.byName(json['category'] as String),
      difficultyLevel: json['difficulty_level'] as int? ?? 1,
      ageGroupMin: json['age_group_min'] as int? ?? 1,
      completionHolyPoints: json['completion_holy_points'] as int? ?? 0,
      completionFaithCoins: json['completion_faith_coins'] as int? ?? 0,
      perfectScoreBonusHp: json['perfect_score_bonus_hp'] as int? ?? 0,
      requiredBuildingType: json['required_building_type'] != null
          ? BuildingType.values
              .byName(json['required_building_type'] as String)
          : null,
      liturgicalSeason: json['liturgical_season'] as String?,
      questions: (json['questions'] as List<dynamic>?)
              ?.map((q) =>
                  QuestionModel.fromJson(q as Map<String, dynamic>))
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
