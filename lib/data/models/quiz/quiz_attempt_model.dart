import 'package:equatable/equatable.dart';

class QuizAttempt extends Equatable {
  final String id;
  final String userId;
  final String quizId;

  /// Number of correctly answered questions.
  final int score;

  final int totalQuestions;

  /// Time taken to complete the quiz in seconds.
  final int timeTakenSecs;

  /// The index chosen for each question, in question order.
  final List<int> answers;

  final int holyPointsEarned;
  final int faithCoinsEarned;
  final DateTime completedAt;

  const QuizAttempt({
    required this.id,
    required this.userId,
    required this.quizId,
    required this.score,
    required this.totalQuestions,
    required this.timeTakenSecs,
    required this.answers,
    required this.holyPointsEarned,
    this.faithCoinsEarned = 0,
    required this.completedAt,
  });

  /// Score as a value from 0.0 to 1.0.
  double get scorePercent =>
      totalQuestions == 0 ? 0.0 : score / totalQuestions;

  bool get isPerfectScore => score == totalQuestions && totalQuestions > 0;

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      quizId: json['quiz_id'] as String? ?? '',
      score: json['questions_correct'] as int? ?? json['score'] as int? ?? 0,
      totalQuestions: json['questions_total'] as int? ??
          json['total_questions'] as int? ?? 0,
      timeTakenSecs: json['time_taken_seconds'] as int? ??
          json['time_taken_secs'] as int? ?? 0,
      answers: (json['answers_given'] as List<dynamic>? ??
              json['answers'] as List<dynamic>? ?? [])
          .map((a) => a as int)
          .toList(),
      holyPointsEarned: json['holy_points_awarded'] as int? ??
          json['holy_points_earned'] as int? ?? 0,
      faithCoinsEarned: json['faith_coins_awarded'] as int? ??
          json['faith_coins_earned'] as int? ?? 0,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'quiz_id': quizId,
      'score': score,
      'total_questions': totalQuestions,
      'time_taken_secs': timeTakenSecs,
      'answers': answers,
      'holy_points_earned': holyPointsEarned,
      'faith_coins_earned': faithCoinsEarned,
      'completed_at': completedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        quizId,
        score,
        totalQuestions,
        timeTakenSecs,
        answers,
        holyPointsEarned,
        faithCoinsEarned,
        completedAt,
      ];
}

/// Alias kept for backwards-compatibility with existing imports.
typedef QuizAttemptModel = QuizAttempt;
