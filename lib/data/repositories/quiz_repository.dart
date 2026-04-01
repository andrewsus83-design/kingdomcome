import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failure.dart';
import '../models/quiz/quiz_attempt_model.dart';
import '../models/quiz/quiz_model.dart';

// ---------------------------------------------------------------------------
// Abstract interface
// ---------------------------------------------------------------------------

abstract class QuizRepository {
  /// Returns quizzes suitable for [ageGroup], optionally filtered by [category].
  Future<Either<Failure, List<QuizModel>>> getQuizzes(
    int ageGroup, {
    QuizCategory? category,
  });

  /// Returns a single quiz with its questions.
  Future<Either<Failure, QuizModel>> getQuiz(String quizId);

  /// Submits a completed quiz attempt for scoring and rewards.
  Future<Either<Failure, QuizAttempt>> submitQuiz(
    String userId,
    String quizId,
    List<int> answers,
    int timeTaken,
  );

  /// Returns all quiz attempts for [userId], newest first.
  Future<Either<Failure, List<QuizAttempt>>> getUserAttempts(String userId);
}

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

class QuizRepositoryImpl implements QuizRepository {
  QuizRepositoryImpl({required SupabaseClient supabaseClient})
      : _client = supabaseClient;

  final SupabaseClient _client;

  @override
  Future<Either<Failure, List<QuizModel>>> getQuizzes(
    int ageGroup, {
    QuizCategory? category,
  }) async {
    try {
      var query = _client
          .from('quizzes')
          .select('*, questions(*)')
          .eq('is_active', true)
          .lte('age_group_min', ageGroup);

      if (category != null) {
        query = query.eq('category', category.name);
      }

      final List<dynamic> data = await query.order('difficulty_level');

      final quizzes = data
          .map((q) => QuizModel.fromJson(q as Map<String, dynamic>))
          .toList();
      return Right(quizzes);
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, QuizModel>> getQuiz(String quizId) async {
    try {
      final data = await _client
          .from('quizzes')
          .select('*, questions(*)')
          .eq('id', quizId)
          .single();

      return Right(QuizModel.fromJson(data));
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return Left(
          NotFoundFailure(message: 'Quiz with id $quizId not found.'),
        );
      }
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, QuizAttempt>> submitQuiz(
    String userId,
    String quizId,
    List<int> answers,
    int timeTaken,
  ) async {
    try {
      // Edge function handles scoring, reward grant, and stores the attempt.
      final result = await _client.functions.invoke(
        'submit-quiz',
        body: {
          'user_id': userId,
          'quiz_id': quizId,
          'answers': answers,
          'time_taken_secs': timeTaken,
        },
      );

      if (result.data == null) {
        return const Left(
          GameFailure(message: 'Submit quiz returned no data.'),
        );
      }

      return Right(
        QuizAttempt.fromJson(result.data as Map<String, dynamic>),
      );
    } on FunctionException catch (e) {
      return Left(
        GameFailure(
          message: e.details?.toString() ?? 'Submit quiz failed.',
        ),
      );
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<QuizAttempt>>> getUserAttempts(
    String userId,
  ) async {
    try {
      final data = await _client
          .from('quiz_attempts')
          .select()
          .eq('user_id', userId)
          .order('completed_at', ascending: false);

      final attempts = (data as List<dynamic>)
          .map((a) => QuizAttempt.fromJson(a as Map<String, dynamic>))
          .toList();
      return Right(attempts);
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }
}
