import 'package:equatable/equatable.dart';

class QuestionModel extends Equatable {
  final String id;
  final String quizId;
  final String questionText;

  /// Always exactly 4 options.
  final List<String> options;

  /// Zero-based index into [options] that is the correct answer.
  final int correctOptionIndex;
  final String explanation;
  final String? hintText;
  final String? relatedVerseId;
  final String? relatedSaintId;
  final String? imageAssetPath;
  final int sortOrder;

  const QuestionModel({
    required this.id,
    required this.quizId,
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
    this.hintText,
    this.relatedVerseId,
    this.relatedSaintId,
    this.imageAssetPath,
    this.sortOrder = 0,
  }) : assert(
          options.length == 4,
          'QuestionModel requires exactly 4 options',
        );

  String get correctAnswer => options[correctOptionIndex];

  bool isCorrect(int selectedIndex) => selectedIndex == correctOptionIndex;

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final rawOpts = (json['options'] as List<dynamic>? ?? [])
        .map((o) => o as String)
        .toList();
    // Pad to exactly 4 options if DB returns fewer
    final opts = rawOpts.length >= 4
        ? rawOpts.take(4).toList()
        : [...rawOpts, ...List.filled(4 - rawOpts.length, '')];
    return QuestionModel(
      id: json['id'] as String? ?? '',
      quizId: json['quiz_id'] as String? ?? '',
      questionText: json['question_text'] as String? ?? '',
      options: opts,
      correctOptionIndex: json['correct_index'] as int? ??
          json['correct_option_index'] as int? ?? 0,
      explanation: json['explanation'] as String? ?? '',
      hintText: json['hint_text'] as String?,
      relatedVerseId: json['related_verse_id'] as String?,
      relatedSaintId: json['related_saint_id'] as String?,
      imageAssetPath: json['image_asset_path'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quiz_id': quizId,
      'question_text': questionText,
      'options': options,
      'correct_option_index': correctOptionIndex,
      'explanation': explanation,
      'hint_text': hintText,
      'related_verse_id': relatedVerseId,
      'related_saint_id': relatedSaintId,
      'image_asset_path': imageAssetPath,
      'sort_order': sortOrder,
    };
  }

  @override
  List<Object?> get props => [
        id,
        quizId,
        questionText,
        options,
        correctOptionIndex,
        explanation,
        hintText,
        relatedVerseId,
        relatedSaintId,
        imageAssetPath,
        sortOrder,
      ];
}
