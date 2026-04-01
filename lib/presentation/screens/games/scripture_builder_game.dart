import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ── Verse data ────────────────────────────────────────────────────────────────

class _Verse {
  const _Verse({required this.text, required this.reference, required this.context});
  final String text;
  final String reference;
  final String context;

  List<String> get words => text.split(' ');
}

const List<_Verse> _verses = [
  _Verse(
    text: 'For God so loved the world that he gave his only Son',
    reference: 'John 3:16',
    context: 'Jesus explains God\'s love to Nicodemus during the night.',
  ),
  _Verse(
    text: 'I can do all things through Christ who strengthens me',
    reference: 'Philippians 4:13',
    context: 'Paul writes this from prison, trusting in God\'s strength.',
  ),
  _Verse(
    text: 'Be not afraid I am with you always',
    reference: 'Matthew 28:20',
    context: 'Jesus\' final words to the disciples before ascending to heaven.',
  ),
  _Verse(
    text: 'Love one another as I have loved you',
    reference: 'John 15:12',
    context: 'Jesus gives the new commandment at the Last Supper.',
  ),
  _Verse(
    text: 'The Lord is my shepherd I shall not want',
    reference: 'Psalm 23:1',
    context: 'David\'s beloved psalm of trust in God\'s care.',
  ),
  _Verse(
    text: 'Ask and it will be given to you seek and you will find',
    reference: 'Matthew 7:7',
    context: 'Jesus teaches on prayer in the Sermon on the Mount.',
  ),
  _Verse(
    text: 'Trust in the Lord with all your heart',
    reference: 'Proverbs 3:5',
    context: 'Wisdom literature encouraging total reliance on God.',
  ),
  _Verse(
    text: 'Do to others as you would have them do to you',
    reference: 'Luke 6:31',
    context: 'The Golden Rule from Luke\'s Sermon on the Plain.',
  ),
  _Verse(
    text: 'Your word is a lamp to my feet and a light to my path',
    reference: 'Psalm 119:105',
    context: 'The longest Psalm, a meditation on God\'s law.',
  ),
  _Verse(
    text: 'Come to me all who labor and are heavy laden',
    reference: 'Matthew 11:28',
    context: 'Jesus invites all who are weary to find rest in him.',
  ),
];

// ── Difficulty ────────────────────────────────────────────────────────────────

enum _Difficulty { easy, medium, hard }

// ── Game state ────────────────────────────────────────────────────────────────

class _GameState {
  _GameState({
    required this.verse,
    required this.difficulty,
    required this.slots,
    required this.availableWords,
    required this.correctWords,
    this.score = 0,
    this.verseIndex = 0,
    this.startTime,
    this.correctPlacements = 0,
  });

  final _Verse verse;
  final _Difficulty difficulty;
  final List<String?> slots; // null = unfilled slot
  final List<String> availableWords; // words to drag
  final List<String> correctWords; // correct order
  final int score;
  final int verseIndex;
  final DateTime? startTime;
  final int correctPlacements;

  bool get isComplete => !slots.contains(null);
  bool get isCorrect => isComplete &&
      slots.asMap().entries.every((e) => e.value == correctWords[e.key]);
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ScriptureBuilderGameScreen extends ConsumerStatefulWidget {
  const ScriptureBuilderGameScreen({super.key});

  @override
  ConsumerState<ScriptureBuilderGameScreen> createState() =>
      _ScriptureBuilderGameScreenState();
}

class _ScriptureBuilderGameScreenState
    extends ConsumerState<ScriptureBuilderGameScreen>
    with SingleTickerProviderStateMixin {
  _Difficulty _difficulty = _Difficulty.easy;
  _GameState? _gameState;
  bool _sessionComplete = false;
  int _sessionScore = 0;
  int _faithCoinsEarned = 0;
  int _versesCompleted = 0;
  final math.Random _rng = math.Random();
  late AnimationController _snapController;
  int? _lastSnappedSlot;
  Timer? _timer;
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _startSession();
  }

  @override
  void dispose() {
    _snapController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startSession() {
    _sessionScore = 0;
    _faithCoinsEarned = 0;
    _versesCompleted = 0;
    _secondsElapsed = 0;
    _sessionComplete = false;
    _loadNextVerse(0);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _secondsElapsed++);
    });
  }

  void _loadNextVerse(int index) {
    if (index >= 10) {
      _timer?.cancel();
      setState(() => _sessionComplete = true);
      return;
    }

    final verse = _verses[index % _verses.length];
    final words = verse.words;

    List<String?> slots;
    List<String> available;

    switch (_difficulty) {
      case _Difficulty.easy:
        // Fill in 1 random word
        final missingIdx = _rng.nextInt(words.length);
        slots = List.generate(
          words.length,
          (i) => i == missingIdx ? null : words[i],
        );
        available = [words[missingIdx], ...List.generate(2, (_) => _randomWord())];

      case _Difficulty.medium:
        // Fill in 3 words
        final missingIndices = <int>{};
        while (missingIndices.length < math.min(3, words.length)) {
          missingIndices.add(_rng.nextInt(words.length));
        }
        slots = List.generate(
          words.length,
          (i) => missingIndices.contains(i) ? null : words[i],
        );
        available = [
          ...missingIndices.map((i) => words[i]),
          ...List.generate(2, (_) => _randomWord()),
        ]..shuffle(_rng);

      case _Difficulty.hard:
        // Unscramble whole verse
        slots = List.filled(words.length, null);
        available = List.from(words)..shuffle(_rng);
    }

    setState(() {
      _gameState = _GameState(
        verse: verse,
        difficulty: _difficulty,
        slots: slots,
        availableWords: available,
        correctWords: words,
        score: _sessionScore,
        verseIndex: index,
        startTime: DateTime.now(),
      );
    });
  }

  String _randomWord() {
    const distractors = [
      'mountain', 'river', 'stone', 'tree', 'bird',
      'always', 'never', 'greatly', 'truly', 'holy',
    ];
    return distractors[_rng.nextInt(distractors.length)];
  }

  void _onWordPlaced(int slotIndex, String word) {
    final state = _gameState;
    if (state == null) return;

    final newSlots = List<String?>.from(state.slots);
    newSlots[slotIndex] = word;

    final newAvailable = List<String>.from(state.availableWords)..remove(word);

    // If slot had a word, return it to available
    if (state.slots[slotIndex] != null) {
      newAvailable.add(state.slots[slotIndex]!);
    }

    final isCorrect = word == state.correctWords[slotIndex];

    setState(() {
      _gameState = _GameState(
        verse: state.verse,
        difficulty: state.difficulty,
        slots: newSlots,
        availableWords: newAvailable,
        correctWords: state.correctWords,
        score: state.score,
        verseIndex: state.verseIndex,
        startTime: state.startTime,
        correctPlacements: isCorrect
            ? state.correctPlacements + 1
            : state.correctPlacements,
      );
      _lastSnappedSlot = slotIndex;
    });

    _snapController.forward(from: 0);

    // Check completion
    if (_gameState!.isComplete) {
      _onVerseComplete();
    }
  }

  void _onWordRemovedFromSlot(int slotIndex) {
    final state = _gameState;
    if (state == null) return;
    final word = state.slots[slotIndex];
    if (word == null) return;

    final newSlots = List<String?>.from(state.slots);
    newSlots[slotIndex] = null;
    final newAvailable = List<String>.from(state.availableWords)..add(word);

    setState(() {
      _gameState = _GameState(
        verse: state.verse,
        difficulty: state.difficulty,
        slots: newSlots,
        availableWords: newAvailable,
        correctWords: state.correctWords,
        score: state.score,
        verseIndex: state.verseIndex,
        startTime: state.startTime,
        correctPlacements: state.correctPlacements,
      );
    });
  }

  void _onVerseComplete() {
    final state = _gameState!;
    final elapsed =
        DateTime.now().difference(state.startTime!).inSeconds;
    final timeBonus = math.max(0, 30 - elapsed);
    final accuracy = state.correctPlacements / state.correctWords.length;
    final points = (accuracy * 100 + timeBonus).round();
    final coins = (points / 10).round();

    setState(() {
      _sessionScore += points;
      _faithCoinsEarned += coins;
      _versesCompleted++;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _loadNextVerse(state.verseIndex + 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_sessionComplete) return _buildSessionComplete();

    final state = _gameState;
    if (state == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A0A2E),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFFD700))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A0A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Verse ${state.verseIndex + 1} / 10',
          style: const TextStyle(
            color: Color(0xFFFFD700),
            fontFamily: 'Cinzel',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.timer, color: Colors.white54, size: 16),
                const SizedBox(width: 4),
                Text(
                  _formatTime(_secondsElapsed),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
      ),
      body: Column(
        children: [
          // Difficulty selector
          _buildDifficultySelector(),
          const SizedBox(height: 8),
          // Score
          _buildScoreBar(state),
          const SizedBox(height: 16),
          // Verse reference
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              state.verse.reference,
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontFamily: 'Cinzel',
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Word slots
          Expanded(
            child: _buildWordSlots(state),
          ),
          // Available word tiles
          _buildWordBank(state),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDifficultySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: _Difficulty.values.map((d) {
          final isSelected = _difficulty == d;
          final label = switch (d) {
            _Difficulty.easy => 'Easy',
            _Difficulty.medium => 'Medium',
            _Difficulty.hard => 'Hard',
          };
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _difficulty = d);
                _startSession();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFFD700)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF1A0A2E) : Colors.white60,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildScoreBar(_GameState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _InfoChip(icon: Icons.stars, label: '$_sessionScore pts', color: const Color(0xFFFFD700)),
          _InfoChip(icon: Icons.monetization_on, label: '$_faithCoinsEarned coins', color: const Color(0xFF27AE60)),
          _InfoChip(icon: Icons.check_circle, label: '$_versesCompleted done', color: const Color(0xFF3498DB)),
        ],
      ),
    );
  }

  Widget _buildWordSlots(_GameState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: state.slots.asMap().entries.map((entry) {
          final i = entry.key;
          final word = entry.value;
          final isBlank = word == null;
          final isLastSnapped = _lastSnappedSlot == i;

          return DragTarget<String>(
            onAcceptWithDetails: (details) => _onWordPlaced(i, details.data),
            builder: (context, candidateData, rejectedData) {
              final isHovering = candidateData.isNotEmpty;
              return GestureDetector(
                onTap: isBlank ? null : () => _onWordRemovedFromSlot(i),
                child: AnimatedBuilder(
                  animation: _snapController,
                  builder: (context, child) {
                    final scale = isLastSnapped
                        ? 1.0 + _snapController.value * 0.1 * (1 - _snapController.value) * 4
                        : 1.0;
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isHovering
                          ? const Color(0xFFFFD700).withOpacity(0.3)
                          : isBlank
                              ? Colors.white.withOpacity(0.1)
                              : const Color(0xFF2C3E50),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isHovering
                            ? const Color(0xFFFFD700)
                            : isBlank
                                ? Colors.white30
                                : const Color(0xFFFFD700).withOpacity(0.4),
                        width: isHovering ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      word ?? '_____',
                      style: TextStyle(
                        color: isBlank ? Colors.white30 : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWordBank(_GameState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Word Bank — Drag to fill the blanks',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.availableWords.map((word) {
              return Draggable<String>(
                data: word,
                feedback: _WordTile(word: word, isDragging: true),
                childWhenDragging: _WordTile(word: word, isGhost: true),
                child: _WordTile(word: word),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionComplete() {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0A2E),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Session Complete!',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontFamily: 'Cinzel',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn().scale(),
              const SizedBox(height: 24),
              _ResultRow(label: 'Verses Mastered', value: '$_versesCompleted / 10'),
              _ResultRow(label: 'Total Score', value: '$_sessionScore pts'),
              _ResultRow(label: 'FaithCoins Earned', value: '$_faithCoinsEarned'),
              _ResultRow(label: 'Time', value: _formatTime(_secondsElapsed)),
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
                onPressed: _startSession,
                child: const Text(
                  'Play Again',
                  style: TextStyle(fontFamily: 'Cinzel', fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Back to Games',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _WordTile extends StatelessWidget {
  const _WordTile({
    required this.word,
    this.isDragging = false,
    this.isGhost = false,
  });
  final String word;
  final bool isDragging;
  final bool isGhost;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isGhost
              ? Colors.white.withOpacity(0.05)
              : isDragging
                  ? const Color(0xFFFFD700)
                  : const Color(0xFF2C5282),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isGhost
                ? Colors.white12
                : isDragging
                    ? const Color(0xFFB8860B)
                    : const Color(0xFF3498DB).withOpacity(0.6),
          ),
          boxShadow: isDragging
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Text(
          word,
          style: TextStyle(
            color: isGhost
                ? Colors.white12
                : isDragging
                    ? const Color(0xFF1A0A2E)
                    : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
