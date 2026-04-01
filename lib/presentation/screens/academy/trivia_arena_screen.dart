import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/presentation/providers/resource_provider.dart';
import 'package:kingdomcome/data/models/resources/resource_model.dart';
import 'package:kingdomcome/presentation/widgets/common/kingdom_button.dart';

// ── Question model ─────────────────────────────────────────────────────────────

class _TriviaQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String category;

  const _TriviaQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.category,
  });
}

// ── Sample question bank (rotates by day / category) ─────────────────────────

const _questionBank = [
  _TriviaQuestion(
    question: 'Which Apostle is known as the "Rock" and became the first Pope?',
    options: ['Andrew', 'Peter', 'James', 'John'],
    correctIndex: 1,
    explanation: 'Jesus renamed Simon as Peter (meaning "rock") in Matthew 16:18 and gave him the keys to the Kingdom.',
    category: 'Saints',
  ),
  _TriviaQuestion(
    question: 'How many days did Jesus spend in the desert before His public ministry?',
    options: ['7', '20', '40', '50'],
    correctIndex: 2,
    explanation: 'Jesus fasted for 40 days in the desert and was tempted by the devil (Matthew 4:1-11).',
    category: 'Scripture',
  ),
  _TriviaQuestion(
    question: 'Which sacrament first unites us to the Church?',
    options: ['Eucharist', 'Confirmation', 'Baptism', 'Reconciliation'],
    correctIndex: 2,
    explanation: 'Baptism is the sacrament of initiation that washes away original sin and makes us members of the Church.',
    category: 'Sacraments',
  ),
  _TriviaQuestion(
    question: 'What color vestments does a priest wear during Ordinary Time?',
    options: ['Purple', 'Red', 'White', 'Green'],
    correctIndex: 3,
    explanation: 'Green represents hope and the ordinary growth of the Church during Ordinary Time.',
    category: 'Liturgy',
  ),
  _TriviaQuestion(
    question: 'Saint Francis of Assisi is the patron saint of what?',
    options: ['Sailors', 'Animals & Ecology', 'Teachers', 'Children'],
    correctIndex: 1,
    explanation: 'Saint Francis loved all of God\'s creation and is the patron of animals and ecology.',
    category: 'Saints',
  ),
  _TriviaQuestion(
    question: 'In the Hail Mary, who do we ask to "pray for us sinners"?',
    options: ['The Saints', 'The Angels', 'Mary', 'St. Joseph'],
    correctIndex: 2,
    explanation: 'The Hail Mary asks the Blessed Virgin Mary to intercede for us now and at the hour of our death.',
    category: 'Prayer',
  ),
  _TriviaQuestion(
    question: 'Which Council defined the dogma of papal infallibility?',
    options: ['Council of Nicaea', 'Council of Trent', 'Vatican I', 'Vatican II'],
    correctIndex: 2,
    explanation: 'The First Vatican Council (1869-1870) formally defined the doctrine of papal infallibility.',
    category: 'History',
  ),
  _TriviaQuestion(
    question: 'The Rosary is divided into how many decades?',
    options: ['5', '10', '15', '20'],
    correctIndex: 3,
    explanation: 'A full Rosary consists of 20 decades (4 sets of mysteries × 5 decades each).',
    category: 'Prayer',
  ),
  _TriviaQuestion(
    question: 'What does "Eucharist" literally mean?',
    options: ['Body of Christ', 'Thanksgiving', 'Holy Bread', 'Sacrifice'],
    correctIndex: 1,
    explanation: 'Eucharist comes from the Greek "eucharistia" meaning thanksgiving — Jesus gave thanks before breaking the bread.',
    category: 'Sacraments',
  ),
  _TriviaQuestion(
    question: 'Which prophet foretold: "A virgin shall conceive and bear a son"?',
    options: ['Jeremiah', 'Ezekiel', 'Isaiah', 'Amos'],
    correctIndex: 2,
    explanation: 'Isaiah 7:14 prophesied the Virgin Birth of Christ, fulfilled in the Nativity.',
    category: 'Scripture',
  ),
];

// ── Trivia state ───────────────────────────────────────────────────────────────

enum _TriviaPhase { playing, halfTime, results }

class _TriviaState {
  final List<_TriviaQuestion> questions;
  final int currentIndex;
  final int? selectedAnswer;
  final bool answered;
  final int score;
  final int streak;
  final double multiplier;
  final int secondsRemaining;
  final _TriviaPhase phase;
  final int roundsPlayed;
  final int totalHolyPoints;

  const _TriviaState({
    required this.questions,
    this.currentIndex = 0,
    this.selectedAnswer,
    this.answered = false,
    this.score = 0,
    this.streak = 0,
    this.multiplier = 1.0,
    this.secondsRemaining = 15,
    this.phase = _TriviaPhase.playing,
    this.roundsPlayed = 0,
    this.totalHolyPoints = 0,
  });

  _TriviaQuestion get current => questions[currentIndex];
  bool get isLastQuestion => currentIndex == questions.length - 1;
  int get totalQuestions => questions.length;

  _TriviaState copyWith({
    int? currentIndex,
    int? selectedAnswer,
    bool? answered,
    int? score,
    int? streak,
    double? multiplier,
    int? secondsRemaining,
    _TriviaPhase? phase,
    int? roundsPlayed,
    int? totalHolyPoints,
    bool clearSelectedAnswer = false,
  }) {
    return _TriviaState(
      questions: questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedAnswer: clearSelectedAnswer ? null : (selectedAnswer ?? this.selectedAnswer),
      answered: answered ?? this.answered,
      score: score ?? this.score,
      streak: streak ?? this.streak,
      multiplier: multiplier ?? this.multiplier,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      phase: phase ?? this.phase,
      roundsPlayed: roundsPlayed ?? this.roundsPlayed,
      totalHolyPoints: totalHolyPoints ?? this.totalHolyPoints,
    );
  }
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class TriviaArenaScreen extends ConsumerStatefulWidget {
  const TriviaArenaScreen({super.key});

  @override
  ConsumerState<TriviaArenaScreen> createState() => _TriviaArenaScreenState();
}

class _TriviaArenaScreenState extends ConsumerState<TriviaArenaScreen>
    with SingleTickerProviderStateMixin {
  late _TriviaState _state;
  Timer? _timer;
  late AnimationController _shakeController;

  static const int _questionsPerRound = 5;
  static const int _maxRewardRounds = 5;
  static const int _secondsPerQuestion = 15;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _initRound();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  void _initRound() {
    final rng = Random();
    final shuffled = List<_TriviaQuestion>.from(_questionBank)..shuffle(rng);
    final questions = shuffled.take(_questionsPerRound).toList();
    setState(() {
      _state = _TriviaState(questions: questions);
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      final remaining = _state.secondsRemaining - 1;
      if (remaining <= 0) {
        t.cancel();
        // Time up — auto-wrong
        if (!_state.answered) {
          setState(() {
            _state = _state.copyWith(answered: true, streak: 0, multiplier: 1.0);
          });
        }
      } else {
        setState(() {
          _state = _state.copyWith(secondsRemaining: remaining);
        });
      }
    });
  }

  void _selectAnswer(int index) {
    if (_state.answered) return;
    _timer?.cancel();

    final correct = index == _state.current.correctIndex;
    int newScore = _state.score;
    int newStreak = _state.streak;
    double newMultiplier = _state.multiplier;
    int pointsEarned = 0;

    if (correct) {
      newStreak = _state.streak + 1;
      newMultiplier = newStreak >= 3
          ? 3.0
          : newStreak >= 2
              ? 2.0
              : newStreak >= 1
                  ? 1.5
                  : 1.0;
      pointsEarned = (10 * newMultiplier).round();
      newScore = _state.score + pointsEarned;
    } else {
      newStreak = 0;
      newMultiplier = 1.0;
      _shakeController.forward(from: 0);
    }

    setState(() {
      _state = _state.copyWith(
        selectedAnswer: index,
        answered: true,
        score: newScore,
        streak: newStreak,
        multiplier: newMultiplier,
        totalHolyPoints: _state.totalHolyPoints + (correct ? pointsEarned : 0),
      );
    });
  }

  void _nextQuestion() {
    if (_state.isLastQuestion) {
      _timer?.cancel();
      final newRounds = _state.roundsPlayed + 1;
      setState(() {
        _state = _state.copyWith(
          phase: newRounds == 1 ? _TriviaPhase.halfTime : _TriviaPhase.results,
          roundsPlayed: newRounds,
        );
      });
      if (_state.roundsPlayed < 2) {
        // Award holy points optimistically
        _awardPoints(_state.totalHolyPoints);
      }
    } else {
      setState(() {
        _state = _state.copyWith(
          currentIndex: _state.currentIndex + 1,
          answered: false,
          secondsRemaining: _secondsPerQuestion,
          clearSelectedAnswer: true,
        );
      });
      _startTimer();
    }
  }

  void _awardPoints(int points) {
    if (points <= 0) return;
    ref.read(resourceNotifierProvider.notifier).optimisticAdd(
      ResourceReward(
        holyPoints: points,
        faithCoins: 0,
        blessings: 0,
        grace: 0,
      ),
    );
  }

  void _startNewRound() {
    _initRound();
    setState(() {
      _state = _TriviaState(
        questions: _state.questions,
        roundsPlayed: _state.roundsPlayed,
        totalHolyPoints: _state.totalHolyPoints,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      body: switch (_state.phase) {
        _TriviaPhase.halfTime => _HalfTimeScreen(
            score: _state.score,
            roundsPlayed: _state.roundsPlayed,
            onContinue: _startNewRound,
          ),
        _TriviaPhase.results => _ResultsScreen(
            score: _state.score,
            totalPoints: _state.totalHolyPoints,
            questionsAnswered: _questionsPerRound * _state.roundsPlayed,
            onPlayAgain: () {
              _awardPoints(_state.totalHolyPoints);
              _initRound();
              setState(() {
                _state = _TriviaState(questions: _state.questions);
              });
            },
            onBack: () => context.pop(),
          ),
        _TriviaPhase.playing => _PlayingView(
            state: _state,
            shakeController: _shakeController,
            onAnswer: _selectAnswer,
            onNext: _nextQuestion,
            onExit: () => _confirmExit(context),
          ),
      },
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: Text(
          'Leave Trivia?',
          style:
              AppTextStyles.headlineSmall.copyWith(color: AppColors.goldLight),
        ),
        content: Text(
          'Your current round progress will be lost.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.parchment),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay', style: TextStyle(color: AppColors.gold)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child:
                const Text('Leave', style: TextStyle(color: AppColors.crimson)),
          ),
        ],
      ),
    );
  }
}

// ── Playing view ───────────────────────────────────────────────────────────────

class _PlayingView extends StatelessWidget {
  final _TriviaState state;
  final AnimationController shakeController;
  final void Function(int) onAnswer;
  final VoidCallback onNext;
  final VoidCallback onExit;

  const _PlayingView({
    required this.state,
    required this.shakeController,
    required this.onAnswer,
    required this.onNext,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ArenaHeader(
            state: state,
            onExit: onExit,
          ),

          // Timer bar
          _TimerBar(secondsRemaining: state.secondsRemaining),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Category chip
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.deepPurple.withOpacity(0.4),
                        borderRadius: AppSpacing.borderRadiusSm,
                        border: Border.all(
                            color: AppColors.purpleLight.withOpacity(0.5)),
                      ),
                      child: Text(
                        state.current.category.toUpperCase(),
                        style: AppTextStyles.badge.copyWith(
                          color: AppColors.grace,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Question
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: AppSpacing.borderRadiusLg,
                      border: Border.all(
                          color: AppColors.goldDark.withOpacity(0.3)),
                    ),
                    child: Text(
                      state.current.question,
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.ivory,
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ).animate(key: ValueKey(state.currentIndex)).fadeIn(duration: 300.ms),

                  const SizedBox(height: AppSpacing.lg),

                  // Answer tiles
                  ...state.current.options.asMap().entries.map((e) {
                    return _AnswerTile(
                      label: e.value,
                      index: e.key,
                      selectedIndex: state.selectedAnswer,
                      correctIndex: state.answered
                          ? state.current.correctIndex
                          : null,
                      shakeController: shakeController,
                      onTap: state.answered ? null : () => onAnswer(e.key),
                    )
                        .animate(
                          key: ValueKey('${state.currentIndex}_${e.key}'),
                          delay: (e.key * 60).ms,
                        )
                        .fadeIn()
                        .slideX(begin: 0.08);
                  }),

                  // Explanation
                  if (state.answered) ...[
                    const SizedBox(height: AppSpacing.md),
                    _ExplanationCard(
                      text: state.current.explanation,
                      isCorrect: state.selectedAnswer == state.current.correctIndex,
                    ).animate().fadeIn(delay: 150.ms),
                  ],
                ],
              ),
            ),
          ),

          // Next button
          if (state.answered)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: KingdomButton(
                label: state.isLastQuestion ? 'See Results' : 'Next Question',
                onPressed: onNext,
                icon: state.isLastQuestion ? Icons.check : Icons.arrow_forward,
              ).animate().fadeIn(delay: 200.ms),
            ),
        ],
      ),
    );
  }
}

// ── Arena header ───────────────────────────────────────────────────────────────

class _ArenaHeader extends StatelessWidget {
  final _TriviaState state;
  final VoidCallback onExit;

  const _ArenaHeader({required this.state, required this.onExit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      color: AppColors.purpleDark,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.midGrey),
            onPressed: onExit,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Q${state.currentIndex + 1} / ${state.totalQuestions}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.midGrey,
                  ),
                ),
                ClipRRect(
                  borderRadius: AppSpacing.borderRadiusSm,
                  child: LinearProgressIndicator(
                    value: (state.currentIndex + 1) / state.totalQuestions,
                    backgroundColor: AppColors.darkCard,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.gold),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),

          // Score
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
                const Icon(Icons.star, color: AppColors.holyPoints, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${state.score}',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.holyPoints,
                  ),
                ),
                if (state.streak >= 2) ...[
                  const SizedBox(width: 4),
                  Text(
                    'x${state.multiplier.toStringAsFixed(1)}',
                    style: AppTextStyles.badge.copyWith(
                      color: AppColors.faithCoins,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Timer bar ──────────────────────────────────────────────────────────────────

class _TimerBar extends StatelessWidget {
  final int secondsRemaining;

  const _TimerBar({required this.secondsRemaining});

  @override
  Widget build(BuildContext context) {
    final fraction = secondsRemaining / 15.0;
    final color = fraction > 0.5
        ? AppColors.forestGreen
        : fraction > 0.25
            ? AppColors.faithCoins
            : AppColors.crimson;

    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 900),
          height: 8,
          color: AppColors.darkCard,
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 900),
          curve: Curves.linear,
          height: 8,
          width: MediaQuery.of(context).size.width * fraction.clamp(0, 1),
          color: color,
        ),
        Positioned.fill(
          child: Center(
            child: Text(
              '$secondsRemaining',
              style: AppTextStyles.badge.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Answer tile ────────────────────────────────────────────────────────────────

class _AnswerTile extends StatelessWidget {
  final String label;
  final int index;
  final int? selectedIndex;
  final int? correctIndex;
  final AnimationController shakeController;
  final VoidCallback? onTap;

  const _AnswerTile({
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.correctIndex,
    required this.shakeController,
    required this.onTap,
  });

  static const _letterLabels = ['A', 'B', 'C', 'D'];
  static const _bgColors = [
    Color(0xFF1A3A6B),
    Color(0xFF6B1A1A),
    Color(0xFF1A5C1A),
    Color(0xFF5C3A1A),
  ];

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIndex == index;
    final isCorrect = correctIndex == index;
    final isWrong = isSelected && correctIndex != null && !isCorrect;

    Color borderColor = _bgColors[index % _bgColors.length];
    Color bgColor = _bgColors[index % _bgColors.length].withOpacity(0.35);

    if (isCorrect && correctIndex != null) {
      borderColor = AppColors.forestGreen;
      bgColor = AppColors.forestGreen.withOpacity(0.25);
    } else if (isWrong) {
      borderColor = AppColors.crimson;
      bgColor = AppColors.crimson.withOpacity(0.2);
    } else if (isSelected) {
      borderColor = AppColors.gold;
      bgColor = AppColors.deepPurple.withOpacity(0.4);
    }

    Widget tile = GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: borderColor.withOpacity(0.25),
                border: Border.all(color: borderColor, width: 1.5),
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
                        _letterLabels[index],
                        style: AppTextStyles.labelMedium.copyWith(
                          color: borderColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.ivory,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (isWrong) {
      tile = tile
          .animate(controller: shakeController)
          .shake(hz: 4, curve: Curves.easeInOut);
    } else if (isCorrect && correctIndex != null) {
      tile = tile.animate().scale(
            begin: const Offset(1, 1),
            end: const Offset(1.03, 1.03),
            duration: 200.ms,
          );
    }

    return tile;
  }
}

// ── Explanation card ───────────────────────────────────────────────────────────

class _ExplanationCard extends StatelessWidget {
  final String text;
  final bool isCorrect;

  const _ExplanationCard({required this.text, required this.isCorrect});

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
              text,
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

// ── Half time screen ───────────────────────────────────────────────────────────

class _HalfTimeScreen extends StatelessWidget {
  final int score;
  final int roundsPlayed;
  final VoidCallback onContinue;

  const _HalfTimeScreen({
    required this.score,
    required this.roundsPlayed,
    required this.onContinue,
  });

  static const _saintTips = [
    '"Pray, hope, and don\'t worry." — St. Padre Pio',
    '"Do small things with great love." — St. Teresa of Calcutta',
    '"A saint is not someone who never sins, but one who never gives up." — St. John Vianney',
    '"You learn to speak by speaking, study by studying — and so you learn to love God by loving Him." — St. Francis de Sales',
  ];

  @override
  Widget build(BuildContext context) {
    final tip = _saintTips[roundsPlayed % _saintTips.length];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('⚡', style: TextStyle(fontSize: 60))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1)),

            const SizedBox(height: AppSpacing.lg),

            Text(
              'Half Time!',
              style: AppTextStyles.displaySmall.copyWith(
                color: AppColors.goldLight,
              ),
            ).animate().fadeIn().slideY(begin: -0.2),

            const SizedBox(height: AppSpacing.md),

            Text(
              'Score so far: $score pts',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.ivory,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: AppSpacing.borderRadiusLg,
                border: Border.all(color: AppColors.goldDark.withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.church, color: AppColors.gold, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Saint\'s Wisdom',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    tip,
                    style: AppTextStyles.scriptureQuote.copyWith(
                      color: AppColors.parchment,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: AppSpacing.xl),

            KingdomButton(
              label: 'Continue Round 2',
              onPressed: onContinue,
              icon: Icons.play_arrow,
            ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }
}

// ── Results screen ─────────────────────────────────────────────────────────────

class _ResultsScreen extends StatelessWidget {
  final int score;
  final int totalPoints;
  final int questionsAnswered;
  final VoidCallback onPlayAgain;
  final VoidCallback onBack;

  const _ResultsScreen({
    required this.score,
    required this.totalPoints,
    required this.questionsAnswered,
    required this.onPlayAgain,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final rank = score >= 80
        ? 'Apostle Scholar'
        : score >= 50
            ? 'Faithful Learner'
            : 'Rising Disciple';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.lg),

            const Icon(Icons.emoji_events, color: AppColors.gold, size: 72)
                .animate()
                .scale(begin: const Offset(0.3, 0.3), duration: 600.ms, curve: Curves.elasticOut),

            const SizedBox(height: AppSpacing.md),

            Text(
              'Round Complete!',
              style: AppTextStyles.displaySmall.copyWith(
                color: AppColors.goldLight,
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: AppSpacing.xs),

            Text(
              rank,
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.grace,
              ),
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: AppSpacing.xl),

            // Score stats
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: AppSpacing.borderRadiusLg,
                border: Border.all(color: AppColors.goldDark.withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  _StatRow(
                    icon: Icons.check_circle,
                    color: AppColors.forestGreen,
                    label: 'Questions Answered',
                    value: '$questionsAnswered',
                  ),
                  const Divider(color: AppColors.darkElevated, height: AppSpacing.md),
                  _StatRow(
                    icon: Icons.star,
                    color: AppColors.holyPoints,
                    label: 'Total Score',
                    value: '$score pts',
                  ),
                  const Divider(color: AppColors.darkElevated, height: AppSpacing.md),
                  _StatRow(
                    icon: Icons.auto_awesome,
                    color: AppColors.faithCoins,
                    label: 'HolyPoints Earned',
                    value: '+$totalPoints ✨',
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: AppSpacing.xl),

            KingdomButton(
              label: 'Play Again',
              onPressed: onPlayAgain,
              icon: Icons.refresh,
            ).animate().fadeIn(delay: 600.ms),

            const SizedBox(height: AppSpacing.sm),

            KingdomButton(
              label: 'Back to Academy',
              onPressed: onBack,
              icon: Icons.arrow_back,
              isPrimary: false,
            ).animate().fadeIn(delay: 700.ms),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.midGrey),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.ivory,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
