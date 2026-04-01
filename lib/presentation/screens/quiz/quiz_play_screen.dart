import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/data/models/quiz/quiz_model.dart';
import 'package:kingdomcome/data/models/quiz/question_model.dart';
import 'package:kingdomcome/presentation/providers/quiz_provider.dart';
import 'package:kingdomcome/presentation/widgets/common/kingdom_button.dart';

class QuizPlayScreen extends ConsumerStatefulWidget {
  final String quizId;
  const QuizPlayScreen({super.key, required this.quizId});

  @override
  ConsumerState<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends ConsumerState<QuizPlayScreen> {
  int _currentIndex = 0;
  int? _selectedAnswer;
  bool _answered = false;
  final Map<String, int> _answers = {};
  int _totalSeconds = 0;
  Timer? _timer;
  bool _submitting = false;

  static const int _secondsPerQuestion = 30;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _totalSeconds++);
    });
  }

  @override
  Widget build(BuildContext context) {
    final quizzesAsync = ref.watch(quizNotifierProvider);
    final quizzes = quizzesAsync.valueOrNull ?? [];
    final quiz = quizzes.where((q) => q.id == widget.quizId).firstOrNull;

    if (quiz == null || quiz.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.purpleDark,
          title: Text(
            'Quiz',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.goldLight,
            ),
          ),
        ),
        body: const Center(
          child: Text('Quiz not found.',
              style: TextStyle(color: AppColors.ivory)),
        ),
      );
    }

    final question = quiz.questions[_currentIndex];
    final isLast = _currentIndex == quiz.questions.length - 1;
    final progress = (_currentIndex + 1) / quiz.questions.length;

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            _QuizHeader(
              quiz: quiz,
              currentIndex: _currentIndex,
              totalSeconds: _totalSeconds,
              progress: progress,
              onExit: () => _confirmExit(context),
            ),

            // Question
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _QuestionCard(
                      question: question,
                      index: _currentIndex,
                    ).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: AppSpacing.lg),

                    // Answer options
                    ...question.options.asMap().entries.map((e) {
                      return _AnswerOption(
                        text: e.value,
                        index: e.key,
                        selectedIndex: _selectedAnswer,
                        correctIndex: _answered
                            ? question.correctOptionIndex
                            : null,
                        onTap: _answered
                            ? null
                            : () => _selectAnswer(question, e.key),
                      ).animate(delay: (e.key * 80).ms).fadeIn().slideX(begin: 0.1);
                    }),

                    // Explanation
                    if (_answered && question.explanation.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      _ExplanationCard(
                        explanation: question.explanation,
                        isCorrect: _selectedAnswer ==
                            question.correctOptionIndex,
                      ).animate().fadeIn(delay: 200.ms),
                    ],

                    // Related verse
                    if (_answered &&
                        question.relatedVerseReference != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _RelatedVerseChip(
                        reference: question.relatedVerseReference!,
                      ).animate().fadeIn(delay: 300.ms),
                    ],
                  ],
                ),
              ),
            ),

            // Next / Submit button
            if (_answered)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: KingdomButton(
                  label: isLast ? 'Submit Quiz' : 'Next Question',
                  onPressed: _submitting ? null : () => _next(quiz, isLast),
                  isLoading: _submitting,
                  icon: isLast ? Icons.check : Icons.arrow_forward,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _selectAnswer(QuestionModel question, int index) {
    setState(() {
      _selectedAnswer = index;
      _answered = true;
      _answers[question.id] = index;
    });
  }

  Future<void> _next(QuizModel quiz, bool isLast) async {
    if (isLast) {
      await _submitQuiz(quiz);
    } else {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answered = false;
      });
    }
  }

  Future<void> _submitQuiz(QuizModel quiz) async {
    setState(() => _submitting = true);
    _timer?.cancel();

    try {
      final attempt = await ref.read(quizNotifierProvider.notifier).submitQuiz(
            quizId: quiz.id,
            answers: _answers,
            timeTaken: _totalSeconds,
          );

      if (mounted) {
        // Show results
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => _ResultsDialog(
            quiz: quiz,
            correctCount: attempt.correctAnswers,
            totalCount: quiz.questions.length,
            holyPointsEarned: attempt.holyPointsEarned,
            onContinue: () {
              Navigator.of(ctx).pop();
              context.go('/kingdom');
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not submit quiz: $e'),
            backgroundColor: AppColors.crimson,
          ),
        );
      }
    }
  }

  void _confirmExit(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: Text(
          'Abandon Quiz?',
          style:
              AppTextStyles.headlineSmall.copyWith(color: AppColors.ivory),
        ),
        content: Text(
          'Your progress will be lost.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.midGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay',
                style: TextStyle(color: AppColors.gold)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('Leave',
                style: TextStyle(color: AppColors.crimson)),
          ),
        ],
      ),
    );
  }
}

// ── Quiz header ───────────────────────────────────────────────────────────────

class _QuizHeader extends StatelessWidget {
  final QuizModel quiz;
  final int currentIndex;
  final int totalSeconds;
  final double progress;
  final VoidCallback onExit;

  const _QuizHeader({
    required this.quiz,
    required this.currentIndex,
    required this.totalSeconds,
    required this.progress,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.purpleDark,
        border: Border(bottom: BorderSide(color: AppColors.goldDark)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.midGrey),
                onPressed: onExit,
              ),
              Expanded(
                child: Text(
                  quiz.title,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.goldLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined,
                        color: AppColors.grace, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${totalSeconds ~/ 60}:${(totalSeconds % 60).toString().padLeft(2, '0')}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.grace,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Text(
                'Q${currentIndex + 1} of ${quiz.questions.length}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.midGrey,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ClipRRect(
                  borderRadius: AppSpacing.borderRadiusSm,
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.darkCard,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.gold),
                    minHeight: 6,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Question card ─────────────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  final QuestionModel question;
  final int index;

  const _QuestionCard({required this.question, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.goldDark.withOpacity(0.3)),
      ),
      child: Text(
        question.questionText,
        style: AppTextStyles.headlineMedium.copyWith(
          color: AppColors.ivory,
          height: 1.4,
        ),
      ),
    );
  }
}

// ── Answer option ─────────────────────────────────────────────────────────────

class _AnswerOption extends StatelessWidget {
  final String text;
  final int index;
  final int? selectedIndex;
  final int? correctIndex;
  final VoidCallback? onTap;

  const _AnswerOption({
    required this.text,
    required this.index,
    required this.selectedIndex,
    required this.correctIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIndex == index;
    final isCorrect = correctIndex == index;
    final isWrong = isSelected && correctIndex != null && !isCorrect;

    Color borderColor = AppColors.darkElevated;
    Color bgColor = AppColors.darkCard;
    Color textColor = AppColors.ivory;

    if (isCorrect && correctIndex != null) {
      borderColor = AppColors.forestGreen;
      bgColor = AppColors.forestGreen.withOpacity(0.15);
      textColor = AppColors.ivory;
    } else if (isWrong) {
      borderColor = AppColors.crimson;
      bgColor = AppColors.crimson.withOpacity(0.15);
      textColor = AppColors.ivory;
    } else if (isSelected) {
      borderColor = AppColors.gold;
      bgColor = AppColors.deepPurple.withOpacity(0.3);
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: borderColor.withOpacity(0.2),
                border: Border.all(color: borderColor),
              ),
              child: Center(
                child: correctIndex != null
                    ? Icon(
                        isCorrect
                            ? Icons.check
                            : isWrong
                                ? Icons.close
                                : null,
                        color: borderColor,
                        size: 16,
                      )
                    : Text(
                        String.fromCharCode(65 + index), // A, B, C, D
                        style: AppTextStyles.labelMedium.copyWith(
                          color: borderColor,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.bodyMedium.copyWith(color: textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Explanation & verse ───────────────────────────────────────────────────────

class _ExplanationCard extends StatelessWidget {
  final String explanation;
  final bool isCorrect;

  const _ExplanationCard(
      {required this.explanation, required this.isCorrect});

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? AppColors.forestGreen : AppColors.blessings;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCorrect ? Icons.check_circle_outline : Icons.info_outline,
            color: color,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              explanation,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.parchment,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RelatedVerseChip extends StatelessWidget {
  final String reference;
  const _RelatedVerseChip({required this.reference});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.deepPurple.withOpacity(0.2),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: AppColors.deepPurple.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.menu_book, color: AppColors.gold, size: 14),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Scripture: $reference',
            style: AppTextStyles.scriptureQuote.copyWith(
              fontSize: 12,
              color: AppColors.goldLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Results dialog ────────────────────────────────────────────────────────────

class _ResultsDialog extends StatelessWidget {
  final QuizModel quiz;
  final int correctCount;
  final int totalCount;
  final int holyPointsEarned;
  final VoidCallback onContinue;

  const _ResultsDialog({
    required this.quiz,
    required this.correctCount,
    required this.totalCount,
    required this.holyPointsEarned,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final percent = correctCount / totalCount;
    final isPerfect = percent == 1.0;

    return Dialog(
      backgroundColor: AppColors.darkCard,
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusXl),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPerfect ? Icons.emoji_events : Icons.school,
              color: isPerfect ? AppColors.gold : AppColors.holyPoints,
              size: 64,
            ).animate().scale(begin: const Offset(0.5, 0.5)),

            const SizedBox(height: AppSpacing.md),

            Text(
              isPerfect ? 'Perfect Score!' : 'Quiz Complete!',
              style: AppTextStyles.displaySmall.copyWith(
                color: isPerfect ? AppColors.gold : AppColors.goldLight,
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            Text(
              '$correctCount / $totalCount correct',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.ivory,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Score bar
            ClipRRect(
              borderRadius: AppSpacing.borderRadiusSm,
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: AppColors.darkElevated,
                valueColor: AlwaysStoppedAnimation<Color>(
                  percent >= 0.8
                      ? AppColors.forestGreen
                      : percent >= 0.5
                          ? AppColors.faithCoins
                          : AppColors.crimson,
                ),
                minHeight: 12,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.holyPoints.withOpacity(0.1),
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(
                    color: AppColors.holyPoints.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: AppColors.holyPoints, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '+$holyPointsEarned Holy Points',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.holyPoints,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            KingdomButton(
              label: 'Continue',
              onPressed: onContinue,
              icon: Icons.arrow_forward,
            ),
          ],
        ),
      ),
    );
  }
}
