import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kingdomcome/data/models/quiz/quiz_model.dart';
import 'package:kingdomcome/data/models/quiz/quiz_attempt_model.dart';
import 'package:kingdomcome/presentation/providers/auth_provider.dart';

part 'quiz_provider.g.dart';

final _supabase = Supabase.instance.client;

@riverpod
class QuizNotifier extends _$QuizNotifier {
  @override
  Future<List<QuizModel>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];

    final ageGroup = user.ageGroup;
    return _fetchQuizzes(ageGroup: ageGroup);
  }

  /// Submits a completed quiz attempt and awards rewards.
  ///
  /// [answers] is a map from questionId → selectedAnswerIndex.
  /// [timeTaken] is the total seconds taken for the quiz.
  Future<QuizAttemptModel> submitQuiz({
    required String quizId,
    required Map<String, int> answers,
    required int timeTaken,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw StateError('Not authenticated');

    final result = await _supabase.rpc('submit_quiz', params: {
      'p_user_id': user.id,
      'p_quiz_id': quizId,
      'p_answers': answers,
      'p_time_taken_seconds': timeTaken,
    }) as Map<String, dynamic>;

    return QuizAttemptModel.fromJson(result);
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<List<QuizModel>> _fetchQuizzes({required int ageGroup}) async {
    final data = await _supabase
        .from('quizzes')
        .select('*, quiz_questions(*)')
        .lte('min_age_group', ageGroup)
        .eq('is_active', true)
        .order('sort_order')
        .limit(30) as List<dynamic>;

    return data
        .map((e) => QuizModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// ── Derived providers ─────────────────────────────────────────────────────────

/// Quizzes grouped by category.
final quizzesByCategoryProvider =
    Provider<Map<QuizCategory, List<QuizModel>>>((ref) {
  final all = ref.watch(quizNotifierProvider).valueOrNull ?? [];
  final map = <QuizCategory, List<QuizModel>>{};
  for (final quiz in all) {
    map.putIfAbsent(quiz.category, () => []).add(quiz);
  }
  return map;
});
