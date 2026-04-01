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

// ── Room definitions ───────────────────────────────────────────────────────────

enum _PuzzleRoom { saintAttributes, brokenVerse, rosarySequence }

extension _PuzzleRoomX on _PuzzleRoom {
  String get title {
    return switch (this) {
      _PuzzleRoom.saintAttributes => 'Saint Attributes',
      _PuzzleRoom.brokenVerse => 'Broken Verse',
      _PuzzleRoom.rosarySequence => 'Rosary Sequence',
    };
  }

  String get emoji {
    return switch (this) {
      _PuzzleRoom.saintAttributes => '🏅',
      _PuzzleRoom.brokenVerse => '📜',
      _PuzzleRoom.rosarySequence => '📿',
    };
  }

  String get description {
    return switch (this) {
      _PuzzleRoom.saintAttributes =>
        'Match saints to their patronage, feast days, and famous works',
      _PuzzleRoom.brokenVerse =>
        'Reassemble Bible verses by dragging word tiles into place',
      _PuzzleRoom.rosarySequence =>
        'Tap Rosary beads in the correct mystery order',
    };
  }

  Color get color {
    return switch (this) {
      _PuzzleRoom.saintAttributes => const Color(0xFF8B1A1A),
      _PuzzleRoom.brokenVerse => const Color(0xFF1A4A8B),
      _PuzzleRoom.rosarySequence => const Color(0xFF4A1A6B),
    };
  }
}

// ── Saint data ─────────────────────────────────────────────────────────────────

class _SaintData {
  final String name;
  final String emoji;
  final String patronage;
  final String feastDay;
  final String era;
  final String famousWork;

  const _SaintData({
    required this.name,
    required this.emoji,
    required this.patronage,
    required this.feastDay,
    required this.era,
    required this.famousWork,
  });
}

const _saints = [
  _SaintData(
    name: 'St. Francis of Assisi',
    emoji: '🌿',
    patronage: 'Animals & Ecology',
    feastDay: 'October 4',
    era: '13th Century',
    famousWork: 'Canticle of the Sun',
  ),
  _SaintData(
    name: 'St. Teresa of Calcutta',
    emoji: '💙',
    patronage: 'World Youth Day',
    feastDay: 'September 5',
    era: '20th Century',
    famousWork: 'Missionaries of Charity',
  ),
  _SaintData(
    name: 'St. Thomas Aquinas',
    emoji: '📚',
    patronage: 'Students & Schools',
    feastDay: 'January 28',
    era: '13th Century',
    famousWork: 'Summa Theologiae',
  ),
];

// ── Bible verse data ───────────────────────────────────────────────────────────

class _VerseData {
  final String reference;
  final String fullVerse;
  final String context;

  const _VerseData({
    required this.reference,
    required this.fullVerse,
    required this.context,
  });

  List<String> get words => fullVerse.split(' ');
}

const _verses = [
  _VerseData(
    reference: 'John 3:16',
    fullVerse: 'For God so loved the world that he gave his only Son',
    context: 'Jesus speaking to Nicodemus about eternal life',
  ),
  _VerseData(
    reference: 'Psalm 23:1',
    fullVerse: 'The Lord is my shepherd I shall not want',
    context: 'A psalm of David expressing trust in God\'s care',
  ),
  _VerseData(
    reference: 'Matthew 5:9',
    fullVerse: 'Blessed are the peacemakers for they shall be called children of God',
    context: 'Part of the Beatitudes from the Sermon on the Mount',
  ),
];

// ── Rosary mystery data ────────────────────────────────────────────────────────

class _RosaryMystery {
  final String name;
  final String emoji;
  final int correctOrder;

  const _RosaryMystery({
    required this.name,
    required this.emoji,
    required this.correctOrder,
  });
}

const _rosaryMysteries = [
  _RosaryMystery(name: 'The Annunciation', emoji: '👼', correctOrder: 0),
  _RosaryMystery(name: 'The Visitation', emoji: '🤝', correctOrder: 1),
  _RosaryMystery(name: 'The Nativity', emoji: '⭐', correctOrder: 2),
  _RosaryMystery(name: 'The Presentation', emoji: '🕊️', correctOrder: 3),
  _RosaryMystery(name: 'Finding in the Temple', emoji: '⛪', correctOrder: 4),
  _RosaryMystery(name: 'Baptism of Jesus', emoji: '💧', correctOrder: 5),
  _RosaryMystery(name: 'Wedding at Cana', emoji: '🍷', correctOrder: 6),
  _RosaryMystery(name: 'Proclamation of the Kingdom', emoji: '👑', correctOrder: 7),
  _RosaryMystery(name: 'The Transfiguration', emoji: '✨', correctOrder: 8),
  _RosaryMystery(name: 'Institution of the Eucharist', emoji: '🍞', correctOrder: 9),
];

// ── Hub screen ─────────────────────────────────────────────────────────────────

class PuzzleRoomsScreen extends StatefulWidget {
  const PuzzleRoomsScreen({super.key});

  @override
  State<PuzzleRoomsScreen> createState() => _PuzzleRoomsScreenState();
}

class _PuzzleRoomsScreenState extends State<PuzzleRoomsScreen> {
  _PuzzleRoom? _activeRoom;

  @override
  Widget build(BuildContext context) {
    if (_activeRoom != null) {
      return _RoomContent(
        room: _activeRoom!,
        onBack: () => setState(() => _activeRoom = null),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        backgroundColor: AppColors.purpleDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Puzzle Rooms',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.goldLight,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a room to enter:',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.midGrey,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ..._PuzzleRoom.values.asMap().entries.map((e) {
              return _RoomCard(
                room: e.value,
                onEnter: () => setState(() => _activeRoom = e.value),
              )
                  .animate(delay: (e.key * 100).ms)
                  .fadeIn()
                  .slideX(begin: -0.1);
            }),
          ],
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final _PuzzleRoom room;
  final VoidCallback onEnter;

  const _RoomCard({required this.room, required this.onEnter});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEnter,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(color: room.color.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: room.color.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: room.color.withOpacity(0.2),
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(color: room.color.withOpacity(0.5)),
              ),
              child: Center(
                child: Text(room.emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.title,
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.ivory,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    room.description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.midGrey,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: room.color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Room content router ────────────────────────────────────────────────────────

class _RoomContent extends StatelessWidget {
  final _PuzzleRoom room;
  final VoidCallback onBack;

  const _RoomContent({required this.room, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return switch (room) {
      _PuzzleRoom.saintAttributes => _SaintAttributesRoom(onBack: onBack),
      _PuzzleRoom.brokenVerse => _BrokenVerseRoom(onBack: onBack),
      _PuzzleRoom.rosarySequence => _RosarySequenceRoom(onBack: onBack),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ROOM 1: Saint Attributes
// ─────────────────────────────────────────────────────────────────────────────

class _SaintAttributesRoom extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const _SaintAttributesRoom({required this.onBack});

  @override
  ConsumerState<_SaintAttributesRoom> createState() =>
      _SaintAttributesRoomState();
}

class _SaintAttributesRoomState
    extends ConsumerState<_SaintAttributesRoom> {
  int _currentSaintIndex = 0;
  final Map<String, bool?> _revealed = {};
  int _score = 0;
  bool _roundComplete = false;

  _SaintData get _saint => _saints[_currentSaintIndex];

  List<Map<String, String>> get _attributeCards => [
        {'label': 'Patronage', 'value': _saint.patronage},
        {'label': 'Feast Day', 'value': _saint.feastDay},
        {'label': 'Era', 'value': _saint.era},
        {'label': 'Famous Work', 'value': _saint.famousWork},
      ];

  void _revealCard(String label) {
    setState(() {
      _revealed[label] = true;
      _score += 5;
    });
    final allRevealed =
        _attributeCards.every((c) => _revealed[c['label']] == true);
    if (allRevealed) {
      setState(() => _roundComplete = true);
    }
  }

  void _nextSaint() {
    if (_currentSaintIndex < _saints.length - 1) {
      setState(() {
        _currentSaintIndex++;
        _revealed.clear();
        _roundComplete = false;
      });
    } else {
      _awardAndFinish();
    }
  }

  void _awardAndFinish() {
    ref.read(resourceNotifierProvider.notifier).optimisticAdd(
      ResourceReward(
        faithCoins: _score,
        holyPoints: 0,
        blessings: 0,
        grace: 0,
      ),
    );
    widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        backgroundColor: AppColors.purpleDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: widget.onBack,
        ),
        title: Text(
          '${_PuzzleRoom.saintAttributes.emoji} Saint Attributes',
          style:
              AppTextStyles.headlineSmall.copyWith(color: AppColors.goldLight),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars, color: AppColors.faithCoins, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '$_score',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.faithCoins,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Saint card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: const Color(0xFF8B1A1A).withOpacity(0.2),
                borderRadius: AppSpacing.borderRadiusLg,
                border: Border.all(
                    color: const Color(0xFF8B1A1A).withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B1A1A).withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gold, width: 2),
                    ),
                    child: Center(
                      child:
                          Text(_saint.emoji, style: const TextStyle(fontSize: 30)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _saint.name,
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: AppColors.goldLight,
                        ),
                      ),
                      Text(
                        '${_currentSaintIndex + 1} of ${_saints.length}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.midGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            Text(
              'Tap each card to reveal the attribute:',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.midGrey),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Attribute cards grid
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.4,
              children: _attributeCards.map((card) {
                final isRevealed = _revealed[card['label']] == true;
                return GestureDetector(
                  onTap: isRevealed
                      ? null
                      : () => _revealCard(card['label']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    decoration: BoxDecoration(
                      color: isRevealed
                          ? AppColors.forestGreen.withOpacity(0.15)
                          : AppColors.darkCard,
                      borderRadius: AppSpacing.borderRadiusMd,
                      border: Border.all(
                        color: isRevealed
                            ? AppColors.forestGreen
                            : AppColors.darkElevated,
                        width: 1.5,
                      ),
                    ),
                    child: isRevealed
                        ? Padding(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  card['label']!,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.gold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  card['value']!,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.ivory,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ).animate().flipH(duration: 350.ms)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.help_outline,
                                  color: AppColors.midGrey, size: 28),
                              const SizedBox(height: 4),
                              Text(
                                card['label']!,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.midGrey,
                                ),
                              ),
                            ],
                          ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.lg),

            if (_roundComplete)
              KingdomButton(
                label: _currentSaintIndex < _saints.length - 1
                    ? 'Next Saint'
                    : 'Finish & Claim Reward',
                onPressed: _nextSaint,
                icon: _currentSaintIndex < _saints.length - 1
                    ? Icons.arrow_forward
                    : Icons.celebration,
              ).animate().fadeIn(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ROOM 2: Broken Verse
// ─────────────────────────────────────────────────────────────────────────────

class _BrokenVerseRoom extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const _BrokenVerseRoom({required this.onBack});

  @override
  ConsumerState<_BrokenVerseRoom> createState() => _BrokenVerseRoomState();
}

class _BrokenVerseRoomState extends ConsumerState<_BrokenVerseRoom> {
  int _verseIndex = 0;
  late List<String> _shuffledWords;
  late List<String?> _placedWords;
  bool _completed = false;
  int _score = 0;

  _VerseData get _verse => _verses[_verseIndex];

  @override
  void initState() {
    super.initState();
    _setupVerse();
  }

  void _setupVerse() {
    final words = _verse.words;
    final shuffled = List<String>.from(words)..shuffle(Random());
    setState(() {
      _shuffledWords = shuffled;
      _placedWords = List.filled(words.length, null);
      _completed = false;
    });
  }

  void _placeWord(String word, int slotIndex) {
    if (_placedWords[slotIndex] != null) return;
    setState(() {
      _placedWords[slotIndex] = word;
      _shuffledWords.remove(word);
    });
    _checkCompletion();
  }

  void _removeWord(int slotIndex) {
    final word = _placedWords[slotIndex];
    if (word == null) return;
    setState(() {
      _placedWords[slotIndex] = null;
      _shuffledWords.add(word);
    });
    setState(() => _completed = false);
  }

  void _checkCompletion() {
    final words = _verse.words;
    final isCorrect = _placedWords.asMap().entries.every(
          (e) => e.value == words[e.key],
        );
    if (isCorrect) {
      setState(() {
        _completed = true;
        _score += 20;
      });
    }
  }

  void _nextVerse() {
    if (_verseIndex < _verses.length - 1) {
      setState(() => _verseIndex++);
      _setupVerse();
    } else {
      ref.read(resourceNotifierProvider.notifier).optimisticAdd(
        ResourceReward(holyPoints: _score, faithCoins: 0, blessings: 0, grace: 0),
      );
      widget.onBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = _verse.words;

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        backgroundColor: AppColors.purpleDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: widget.onBack,
        ),
        title: Text(
          '${_PuzzleRoom.brokenVerse.emoji} Broken Verse',
          style:
              AppTextStyles.headlineSmall.copyWith(color: AppColors.goldLight),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: AppColors.holyPoints, size: 14),
                const SizedBox(width: 4),
                Text(
                  '$_score',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.holyPoints,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Reference
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFF1A4A8B).withOpacity(0.2),
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(
                    color: const Color(0xFF1A4A8B).withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu_book, color: AppColors.gold, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _verse.reference,
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.goldLight,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${_verseIndex + 1}/${_verses.length}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.midGrey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Slots
            Text(
              'Build the verse:',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.midGrey),
            ),
            const SizedBox(height: AppSpacing.sm),

            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: List.generate(words.length, (i) {
                final placed = _placedWords[i];
                final isCorrect =
                    _completed || placed == words[i];
                return GestureDetector(
                  onTap: placed != null ? () => _removeWord(i) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    constraints:
                        const BoxConstraints(minWidth: 60, minHeight: 36),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: placed != null
                          ? (isCorrect
                              ? AppColors.forestGreen.withOpacity(0.25)
                              : AppColors.deepPurple.withOpacity(0.3))
                          : AppColors.darkCard,
                      borderRadius: AppSpacing.borderRadiusSm,
                      border: Border.all(
                        color: placed != null
                            ? (isCorrect
                                ? AppColors.forestGreen
                                : AppColors.deepPurple)
                            : AppColors.darkElevated,
                        width: 1.5,
                      ),
                    ),
                    child: placed != null
                        ? Text(
                            placed,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.ivory,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : Text(
                            '_ _ _',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.midGrey,
                            ),
                          ),
                  ),
                );
              }),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Word bank
            Text(
              'Word bank — tap to place:',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.midGrey),
            ),
            const SizedBox(height: AppSpacing.sm),

            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _shuffledWords.map((word) {
                // Place in the first empty slot
                final firstEmpty = _placedWords.indexOf(null);
                return GestureDetector(
                  onTap: firstEmpty >= 0
                      ? () => _placeWord(word, firstEmpty)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.deepPurple.withOpacity(0.35),
                      borderRadius: AppSpacing.borderRadiusSm,
                      border:
                          Border.all(color: AppColors.purpleLight.withOpacity(0.6)),
                    ),
                    child: Text(
                      word,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.goldLight,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const Spacer(),

            if (_completed) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.forestGreen.withOpacity(0.15),
                  borderRadius: AppSpacing.borderRadiusMd,
                  border: Border.all(color: AppColors.forestGreen),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: AppColors.forestGreen),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Verse Complete! +20 ✨',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.forestGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _verse.context,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.parchment,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(),
              const SizedBox(height: AppSpacing.sm),
              KingdomButton(
                label: _verseIndex < _verses.length - 1
                    ? 'Next Verse'
                    : 'Finish & Claim',
                onPressed: _nextVerse,
                icon: Icons.arrow_forward,
              ).animate().fadeIn(delay: 200.ms),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ROOM 3: Rosary Sequence
// ─────────────────────────────────────────────────────────────────────────────

class _RosarySequenceRoom extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const _RosarySequenceRoom({required this.onBack});

  @override
  ConsumerState<_RosarySequenceRoom> createState() =>
      _RosarySequenceRoomState();
}

class _RosarySequenceRoomState extends ConsumerState<_RosarySequenceRoom> {
  late List<_RosaryMystery> _shuffledMysteries;
  final List<int> _tappedOrder = [];
  bool _completed = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _shuffledMysteries = List<_RosaryMystery>.from(_rosaryMysteries)
      ..shuffle(Random());
  }

  void _tapMystery(_RosaryMystery mystery) {
    if (_completed) return;
    final expectedOrder = _tappedOrder.length;
    if (mystery.correctOrder == expectedOrder) {
      setState(() {
        _tappedOrder.add(mystery.correctOrder);
        _hasError = false;
        if (_tappedOrder.length == _rosaryMysteries.length) {
          _completed = true;
          _awardReward();
        }
      });
    } else {
      setState(() {
        _hasError = true;
        Future.delayed(
          const Duration(seconds: 1),
          () {
            if (mounted) setState(() => _hasError = false);
          },
        );
      });
    }
  }

  void _awardReward() {
    ref.read(resourceNotifierProvider.notifier).optimisticAdd(
      const ResourceReward(
        faithCoins: 15,
        holyPoints: 10,
        blessings: 0,
        grace: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        backgroundColor: AppColors.purpleDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: widget.onBack,
        ),
        title: Text(
          '${_PuzzleRoom.rosarySequence.emoji} Rosary Sequence',
          style:
              AppTextStyles.headlineSmall.copyWith(color: AppColors.goldLight),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Text(
              '${_tappedOrder.length}/${_rosaryMysteries.length}',
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.gold),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Text(
                'Tap the Joyful Mysteries in the correct order\n(The Annunciation first → Finding in the Temple last)',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.parchment,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            if (_hasError)
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.crimson.withOpacity(0.15),
                  borderRadius: AppSpacing.borderRadiusSm,
                  border: Border.all(color: AppColors.crimson.withOpacity(0.5)),
                ),
                child: Text(
                  'Not quite — that\'s not the next mystery!',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.crimson,
                  ),
                  textAlign: TextAlign.center,
                ),
              ).animate().shake(),

            const SizedBox(height: AppSpacing.md),

            if (_completed)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.forestGreen.withOpacity(0.15),
                  borderRadius: AppSpacing.borderRadiusMd,
                  border: Border.all(color: AppColors.forestGreen),
                ),
                child: Column(
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 32)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Perfect! You know the Joyful Mysteries!',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.forestGreen,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+15 🪵 +10 ✨ earned!',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.faithCoins,
                      ),
                    ),
                  ],
                ),
              ).animate().scale(),

            const SizedBox(height: AppSpacing.sm),

            Expanded(
              child: GridView.builder(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 1.5,
                ),
                itemCount: _shuffledMysteries.length,
                itemBuilder: (context, index) {
                  final mystery = _shuffledMysteries[index];
                  final isCompleted =
                      _tappedOrder.contains(mystery.correctOrder);
                  final position = _tappedOrder.indexOf(mystery.correctOrder);

                  return GestureDetector(
                    onTap: isCompleted ? null : () => _tapMystery(mystery),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.forestGreen.withOpacity(0.2)
                            : AppColors.darkCard,
                        borderRadius: AppSpacing.borderRadiusMd,
                        border: Border.all(
                          color: isCompleted
                              ? AppColors.forestGreen
                              : AppColors.darkElevated,
                          width: 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Text(mystery.emoji,
                                  style: const TextStyle(fontSize: 26)),
                              if (isCompleted)
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: const BoxDecoration(
                                    color: AppColors.forestGreen,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${position + 1}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mystery.name,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: isCompleted
                                  ? AppColors.forestGreen
                                  : AppColors.ivory,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_completed)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: KingdomButton(
                  label: 'Back to Rooms',
                  onPressed: widget.onBack,
                  icon: Icons.arrow_back,
                ).animate().fadeIn(),
              ),
          ],
        ),
      ),
    );
  }
}
