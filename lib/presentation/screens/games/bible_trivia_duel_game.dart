import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ── Question data ─────────────────────────────────────────────────────────────

class _Question {
  const _Question({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.category,
    required this.hint,
  });

  final String question;
  final List<String> options;
  final int correctIndex;
  final TriviaCategory category;
  final String hint;
}

enum TriviaCategory { saints, scripture, sacraments, churchHistory, liturgy }

extension TriviaCategoryExt on TriviaCategory {
  String get displayName => switch (this) {
        TriviaCategory.saints => 'Saints',
        TriviaCategory.scripture => 'Scripture',
        TriviaCategory.sacraments => 'Sacraments',
        TriviaCategory.churchHistory => 'Church History',
        TriviaCategory.liturgy => 'Liturgy',
      };

  Color get color => switch (this) {
        TriviaCategory.saints => const Color(0xFF9B59B6),
        TriviaCategory.scripture => const Color(0xFF3498DB),
        TriviaCategory.sacraments => const Color(0xFF27AE60),
        TriviaCategory.churchHistory => const Color(0xFFE67E22),
        TriviaCategory.liturgy => const Color(0xFFE74C3C),
      };
}

const List<_Question> _questionBank = [
  _Question(
    question: 'Who is known as the "Little Flower"?',
    options: ['St. Rose of Lima', 'St. Thérèse of Lisieux', 'St. Clare of Assisi', 'St. Bernadette'],
    correctIndex: 1,
    category: TriviaCategory.saints,
    hint: 'She is the patron saint of missions who died at 24.',
  ),
  _Question(
    question: 'How many books are in the Catholic Bible?',
    options: ['66', '72', '73', '75'],
    correctIndex: 2,
    category: TriviaCategory.scripture,
    hint: 'Catholics have 7 more books than most Protestants.',
  ),
  _Question(
    question: 'What are the 7 Sacraments?',
    options: [
      'Baptism, Eucharist, Penance, Confirmation, Marriage, Holy Orders, Anointing',
      'Baptism, Prayer, Fasting, Almsgiving, Confirmation, Marriage, Anointing',
      'Baptism, Eucharist, Confirmation, Marriage, Holy Orders, Penance, Rosary',
      'Baptism, Eucharist, Penance, Holy Orders, Anointing, Prayer, Confirmation',
    ],
    correctIndex: 0,
    category: TriviaCategory.sacraments,
    hint: 'Each sacrament was instituted by Christ himself.',
  ),
  _Question(
    question: 'In what year did the First Council of Nicaea take place?',
    options: ['95 AD', '325 AD', '451 AD', '787 AD'],
    correctIndex: 1,
    category: TriviaCategory.churchHistory,
    hint: 'This council defined the Nicene Creed.',
  ),
  _Question(
    question: 'What color is used during Ordinary Time?',
    options: ['Purple', 'Red', 'White', 'Green'],
    correctIndex: 3,
    category: TriviaCategory.liturgy,
    hint: 'This color symbolizes hope and growth in faith.',
  ),
  _Question(
    question: 'Who wrote the Summa Theologica?',
    options: ['St. Augustine', 'St. Francis', 'St. Thomas Aquinas', 'St. Anselm'],
    correctIndex: 2,
    category: TriviaCategory.saints,
    hint: 'He is called the "Angelic Doctor".',
  ),
  _Question(
    question: 'What is the first book of the Bible?',
    options: ['Exodus', 'Psalms', 'Genesis', 'Numbers'],
    correctIndex: 2,
    category: TriviaCategory.scripture,
    hint: 'It begins with "In the beginning, God created…"',
  ),
  _Question(
    question: 'Which sacrament forgives sins committed after Baptism?',
    options: ['Anointing of the Sick', 'Penance (Reconciliation)', 'Eucharist', 'Confirmation'],
    correctIndex: 1,
    category: TriviaCategory.sacraments,
    hint: 'Jesus said "whose sins you forgive are forgiven them."',
  ),
  _Question(
    question: 'Who was the first pope?',
    options: ['St. Paul', 'St. James', 'St. John', 'St. Peter'],
    correctIndex: 3,
    category: TriviaCategory.churchHistory,
    hint: 'Jesus said "upon this rock I will build my Church."',
  ),
  _Question(
    question: 'What does "Alleluia" mean?',
    options: ['Praise the Lord', 'Blessed are you', 'Give thanks', 'God is great'],
    correctIndex: 0,
    category: TriviaCategory.liturgy,
    hint: 'It is a Hebrew exclamation of praise.',
  ),
  _Question(
    question: 'Which apostle was known as the "Beloved Disciple"?',
    options: ['Peter', 'James', 'John', 'Andrew'],
    correctIndex: 2,
    category: TriviaCategory.saints,
    hint: 'He wrote the Book of Revelation.',
  ),
  _Question(
    question: 'What is the Scripture passage used at Christmas Mass called?',
    options: ['The Magnificat', 'The Prologue of John', 'The Beatitudes', 'The Great Commission'],
    correctIndex: 1,
    category: TriviaCategory.scripture,
    hint: 'It begins "In the beginning was the Word."',
  ),
  _Question(
    question: 'What matter is used for the Sacrament of Baptism?',
    options: ['Oil', 'Bread and Wine', 'Water', 'Fire'],
    correctIndex: 2,
    category: TriviaCategory.sacraments,
    hint: 'Jesus was baptized in the Jordan River.',
  ),
  _Question(
    question: 'The Great Schism of 1054 divided Christianity between:',
    options: [
      'Catholics and Lutherans',
      'Catholics and Calvinists',
      'Roman Catholics and Eastern Orthodox',
      'Catholics and Anglicans',
    ],
    correctIndex: 2,
    category: TriviaCategory.churchHistory,
    hint: 'It separated Rome from Constantinople.',
  ),
  _Question(
    question: 'Advent begins how many Sundays before Christmas?',
    options: ['Two', 'Three', 'Four', 'Five'],
    correctIndex: 2,
    category: TriviaCategory.liturgy,
    hint: 'The Advent wreath has four candles.',
  ),
];

// ── CPU Opponent ──────────────────────────────────────────────────────────────

enum CpuDifficulty { easy, medium, hard }

// ── Game state ────────────────────────────────────────────────────────────────

class _DuelState {
  const _DuelState({
    required this.questions,
    this.currentQuestionIndex = 0,
    this.playerScore = 0,
    this.cpuScore = 0,
    this.playerAnsweredIndex,
    this.cpuAnsweredIndex,
    this.timeRemaining = 15,
    this.questionsAnswered = 0,
    this.isComplete = false,
    this.hintUsed = false,
    this.skipUsed = false,
    this.stealUsed = false,
    this.playerGrace = 30,
    this.showCpuAnswer = false,
  });

  final List<_Question> questions;
  final int currentQuestionIndex;
  final int playerScore;
  final int cpuScore;
  final int? playerAnsweredIndex;
  final int? cpuAnsweredIndex;
  final int timeRemaining;
  final int questionsAnswered;
  final bool isComplete;
  final bool hintUsed;
  final bool skipUsed;
  final bool stealUsed;
  final int playerGrace;
  final bool showCpuAnswer;

  _Question get currentQuestion => questions[currentQuestionIndex];

  _DuelState copyWith({
    int? currentQuestionIndex,
    int? playerScore,
    int? cpuScore,
    int? playerAnsweredIndex,
    int? cpuAnsweredIndex,
    int? timeRemaining,
    int? questionsAnswered,
    bool? isComplete,
    bool? hintUsed,
    bool? skipUsed,
    bool? stealUsed,
    int? playerGrace,
    bool? showCpuAnswer,
    bool clearPlayerAnswer = false,
    bool clearCpuAnswer = false,
  }) {
    return _DuelState(
      questions: questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      playerScore: playerScore ?? this.playerScore,
      cpuScore: cpuScore ?? this.cpuScore,
      playerAnsweredIndex:
          clearPlayerAnswer ? null : (playerAnsweredIndex ?? this.playerAnsweredIndex),
      cpuAnsweredIndex:
          clearCpuAnswer ? null : (cpuAnsweredIndex ?? this.cpuAnsweredIndex),
      timeRemaining: timeRemaining ?? this.timeRemaining,
      questionsAnswered: questionsAnswered ?? this.questionsAnswered,
      isComplete: isComplete ?? this.isComplete,
      hintUsed: hintUsed ?? this.hintUsed,
      skipUsed: skipUsed ?? this.skipUsed,
      stealUsed: stealUsed ?? this.stealUsed,
      playerGrace: playerGrace ?? this.playerGrace,
      showCpuAnswer: showCpuAnswer ?? this.showCpuAnswer,
    );
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class BibleTriviaDuelGameScreen extends ConsumerStatefulWidget {
  const BibleTriviaDuelGameScreen({super.key});

  @override
  ConsumerState<BibleTriviaDuelGameScreen> createState() =>
      _BibleTriviaDuelGameScreenState();
}

class _BibleTriviaDuelGameScreenState
    extends ConsumerState<BibleTriviaDuelGameScreen> {
  late _DuelState _state;
  CpuDifficulty _cpuDifficulty = CpuDifficulty.medium;
  Timer? _timer;
  Timer? _cpuTimer;
  bool _roundLocked = false;
  bool _showHint = false;
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cpuTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    final shuffled = List<_Question>.from(_questionBank)..shuffle(_rng);
    _state = _DuelState(questions: shuffled.take(7).toList());
    _roundLocked = false;
    _showHint = false;
    _startRound();
  }

  void _startRound() {
    _timer?.cancel();
    _cpuTimer?.cancel();
    _roundLocked = false;
    _showHint = false;

    // CPU thinks for random time based on difficulty
    final cpuDelay = switch (_cpuDifficulty) {
      CpuDifficulty.easy => 5.0 + _rng.nextDouble() * 8,
      CpuDifficulty.medium => 2.0 + _rng.nextDouble() * 6,
      CpuDifficulty.hard => 0.5 + _rng.nextDouble() * 3,
    };

    _cpuTimer = Timer(
      Duration(milliseconds: (cpuDelay * 1000).toInt()),
      _cpuAnswer,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_state.timeRemaining <= 0) {
        t.cancel();
        _onTimeUp();
        return;
      }
      setState(() {
        _state = _state.copyWith(timeRemaining: _state.timeRemaining - 1);
      });
    });
  }

  void _cpuAnswer() {
    if (_roundLocked) return;
    final q = _state.currentQuestion;

    // CPU accuracy by difficulty
    final accuracy = switch (_cpuDifficulty) {
      CpuDifficulty.easy => 0.4,
      CpuDifficulty.medium => 0.7,
      CpuDifficulty.hard => 0.9,
    };

    final isCorrect = _rng.nextDouble() < accuracy;
    final answerIdx = isCorrect
        ? q.correctIndex
        : _randomWrongAnswer(q.correctIndex, q.options.length);

    setState(() {
      _state = _state.copyWith(cpuAnsweredIndex: answerIdx, showCpuAnswer: true);
    });

    // Score CPU
    if (isCorrect) {
      final bonus = _state.playerAnsweredIndex == null ? 20 : 10;
      setState(() {
        _state = _state.copyWith(cpuScore: _state.cpuScore + bonus);
      });
    }

    if (_state.playerAnsweredIndex != null) {
      _lockAndAdvance();
    }
  }

  int _randomWrongAnswer(int correct, int length) {
    int ans;
    do {
      ans = _rng.nextInt(length);
    } while (ans == correct);
    return ans;
  }

  void _onPlayerAnswer(int index) {
    if (_roundLocked) return;
    _roundLocked = true;
    _timer?.cancel();

    final q = _state.currentQuestion;
    final isCorrect = index == q.correctIndex;
    final cpuAlreadyAnswered = _state.cpuAnsweredIndex != null;
    final firstAnswer = !cpuAlreadyAnswered;
    final bonus = isCorrect ? (firstAnswer ? 20 : 10) : 0;

    setState(() {
      _state = _state.copyWith(
        playerAnsweredIndex: index,
        playerScore: _state.playerScore + bonus,
      );
    });

    if (cpuAlreadyAnswered) {
      _lockAndAdvance();
    }
    // else wait for CPU to answer, which calls _lockAndAdvance
  }

  void _onTimeUp() {
    _roundLocked = true;
    _cpuTimer?.cancel();
    _lockAndAdvance();
  }

  void _lockAndAdvance() {
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      final nextIndex = _state.currentQuestionIndex + 1;
      if (nextIndex >= _state.questions.length) {
        setState(() {
          _state = _state.copyWith(isComplete: true);
        });
      } else {
        setState(() {
          _state = _state.copyWith(
            currentQuestionIndex: nextIndex,
            questionsAnswered: _state.questionsAnswered + 1,
            timeRemaining: 15,
            clearPlayerAnswer: true,
            clearCpuAnswer: true,
            showCpuAnswer: false,
          );
        });
        _startRound();
      }
    });
  }

  void _useHint() {
    if (_state.hintUsed || _state.playerGrace < 5) return;
    setState(() {
      _state = _state.copyWith(hintUsed: true, playerGrace: _state.playerGrace - 5);
      _showHint = true;
    });
  }

  void _useSkip() {
    if (_state.skipUsed || _state.playerGrace < 8) return;
    _timer?.cancel();
    _cpuTimer?.cancel();
    setState(() {
      _state = _state.copyWith(skipUsed: true, playerGrace: _state.playerGrace - 8);
    });
    _lockAndAdvance();
  }

  void _useSteal() {
    if (_state.stealUsed || _state.playerGrace < 12) return;
    final steal = (_state.cpuScore * 0.15).round();
    setState(() {
      _state = _state.copyWith(
        stealUsed: true,
        playerGrace: _state.playerGrace - 12,
        playerScore: _state.playerScore + steal,
        cpuScore: (_state.cpuScore - steal).clamp(0, 9999),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_state.isComplete) return _buildResult();

    final q = _state.currentQuestion;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Question ${_state.currentQuestionIndex + 1} / ${_state.questions.length}',
          style: const TextStyle(
            color: Color(0xFFFFD700),
            fontFamily: 'Cinzel',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Difficulty selector
          PopupMenuButton<CpuDifficulty>(
            icon: const Icon(Icons.person, color: Color(0xFFFFD700)),
            color: const Color(0xFF1A2A3A),
            onSelected: (d) {
              _cpuDifficulty = d;
              _startGame();
            },
            itemBuilder: (context) => CpuDifficulty.values
                .map(
                  (d) => PopupMenuItem(
                    value: d,
                    child: Text(
                      d.name.toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
      ),
      body: Column(
        children: [
          // ── Score row ─────────────────────────────────────────────────────
          _buildScoreRow(),
          // ── Timer ─────────────────────────────────────────────────────────
          _buildTimer(),
          // ── Category badge ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: q.category.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: q.category.color.withOpacity(0.5)),
                  ),
                  child: Text(
                    q.category.displayName,
                    style: TextStyle(
                      color: q.category.color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_state.showCpuAnswer)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: const Text(
                      '🤖 CPU answered!',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          // ── Question ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              q.question,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
          ).animate().fadeIn(),
          // ── Hint ─────────────────────────────────────────────────────────
          if (_showHint)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.4),
                  ),
                ),
                child: Text(
                  '💡 ${q.hint}',
                  style: const TextStyle(color: Color(0xFFFFD700), fontSize: 13),
                ),
              ),
            ),
          // ── Answer options ────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: q.options.length,
              itemBuilder: (context, i) => _buildAnswerOption(q, i),
            ),
          ),
          // ── Power-ups ─────────────────────────────────────────────────────
          _buildPowerUps(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildScoreRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _ScoreCard(
              label: 'You',
              score: _state.playerScore,
              color: const Color(0xFF3498DB),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'VS',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontFamily: 'Cinzel',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: _ScoreCard(
              label: '🤖 CPU',
              score: _state.cpuScore,
              color: const Color(0xFFE74C3C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    final frac = _state.timeRemaining / 15;
    final color = frac > 0.5
        ? const Color(0xFF27AE60)
        : frac > 0.25
            ? const Color(0xFFE67E22)
            : const Color(0xFFE74C3C);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.timer, color: color, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: frac,
                backgroundColor: Colors.white12,
                color: color,
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${_state.timeRemaining}s',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOption(_Question q, int index) {
    final playerAnswered = _state.playerAnsweredIndex != null;
    final isPlayerChoice = _state.playerAnsweredIndex == index;
    final isCpuChoice = _state.cpuAnsweredIndex == index;
    final isCorrect = q.correctIndex == index;

    Color borderColor = Colors.white24;
    Color bgColor = const Color(0xFF1A2A3A);
    Color textColor = Colors.white;

    if (playerAnswered || _roundLocked) {
      if (isCorrect) {
        borderColor = const Color(0xFF27AE60);
        bgColor = const Color(0xFF27AE60).withOpacity(0.2);
        textColor = const Color(0xFF2ECC71);
      } else if (isPlayerChoice) {
        borderColor = const Color(0xFFE74C3C);
        bgColor = const Color(0xFFE74C3C).withOpacity(0.15);
        textColor = Colors.redAccent;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: playerAnswered || _roundLocked
              ? null
              : () => _onPlayerAnswer(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: borderColor.withOpacity(0.2),
                  ),
                  child: Center(
                    child: Text(
                      ['A', 'B', 'C', 'D'][index],
                      style: TextStyle(
                        color: borderColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    q.options[index],
                    style: TextStyle(color: textColor, fontSize: 14),
                  ),
                ),
                if (isPlayerChoice) const Icon(Icons.person, color: Color(0xFF3498DB), size: 18),
                if (isCpuChoice && _state.showCpuAnswer)
                  const Icon(Icons.smart_toy, color: Colors.orange, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPowerUps() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _PowerUpButton(
            label: 'Hint',
            icon: '💡',
            cost: 5,
            used: _state.hintUsed,
            grace: _state.playerGrace,
            onTap: _useHint,
          ),
          const SizedBox(width: 8),
          _PowerUpButton(
            label: 'Skip',
            icon: '⏭️',
            cost: 8,
            used: _state.skipUsed,
            grace: _state.playerGrace,
            onTap: _useSkip,
          ),
          const SizedBox(width: 8),
          _PowerUpButton(
            label: 'Steal',
            icon: '⚡',
            cost: 12,
            used: _state.stealUsed,
            grace: _state.playerGrace,
            onTap: _useSteal,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF27AE60).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Text('✨', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '${_state.playerGrace} Grace',
                  style: const TextStyle(
                    color: Color(0xFF27AE60),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final playerWon = _state.playerScore > _state.cpuScore;
    final tied = _state.playerScore == _state.cpuScore;
    final faithCoins = playerWon ? 40 : tied ? 20 : 10;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                tied
                    ? '🤝 Tie!'
                    : playerWon
                        ? '🏆 You Win!'
                        : '😔 CPU Wins',
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontFamily: 'Cinzel',
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn().scale(),
              const SizedBox(height: 24),
              _ScoreCard(label: 'Your Score', score: _state.playerScore, color: const Color(0xFF3498DB)),
              const SizedBox(height: 8),
              _ScoreCard(label: 'CPU Score', score: _state.cpuScore, color: const Color(0xFFE74C3C)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
                ),
                child: Text(
                  '+$faithCoins FaithCoins earned!',
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cinzel',
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: const Color(0xFF1A0A2E),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => setState(() => _startGame()),
                child: const Text(
                  'Play Again',
                  style: TextStyle(fontFamily: 'Cinzel', fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to Games', style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.label, required this.score, required this.color});
  final String label;
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
          Text(
            '$score pts',
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _PowerUpButton extends StatelessWidget {
  const _PowerUpButton({
    required this.label,
    required this.icon,
    required this.cost,
    required this.used,
    required this.grace,
    required this.onTap,
  });
  final String label;
  final String icon;
  final int cost;
  final bool used;
  final int grace;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final canAfford = grace >= cost;
    final enabled = !used && canAfford;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: used
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFF1A2A3A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: used ? Colors.white12 : const Color(0xFFFFD700).withOpacity(0.4),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 9),
              ),
              Text(
                '$cost Grace',
                style: const TextStyle(color: Color(0xFF27AE60), fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
