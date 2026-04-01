import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ── Domain ────────────────────────────────────────────────────────────────────

enum _PuzzleMode { seasonsOnly, majorFeasts, minorFeasts }

class _SeasonBlock {
  const _SeasonBlock({
    required this.id,
    required this.name,
    required this.color,
    required this.startMonth,
    required this.startDay,
    required this.durationWeeks,
    required this.emoji,
  });

  final String id;
  final String name;
  final Color color;
  final int startMonth;
  final int startDay;
  final int durationWeeks;
  final String emoji;
}

class _FeastDay {
  const _FeastDay({
    required this.id,
    required this.name,
    required this.month,
    required this.day,
    required this.emoji,
    required this.isMajor,
  });

  final String id;
  final String name;
  final int month;
  final int day;
  final String emoji;
  final bool isMajor;
}

const List<_SeasonBlock> _seasons = [
  _SeasonBlock(
    id: 'advent',
    name: 'Advent',
    color: Color(0xFF6B2FA0),
    startMonth: 11,
    startDay: 27,
    durationWeeks: 4,
    emoji: '🕯️',
  ),
  _SeasonBlock(
    id: 'christmas',
    name: 'Christmas',
    color: Color(0xFFFFD700),
    startMonth: 12,
    startDay: 25,
    durationWeeks: 2,
    emoji: '⭐',
  ),
  _SeasonBlock(
    id: 'ordinary1',
    name: 'Ordinary Time I',
    color: Color(0xFF27AE60),
    startMonth: 1,
    startDay: 10,
    durationWeeks: 6,
    emoji: '🌿',
  ),
  _SeasonBlock(
    id: 'lent',
    name: 'Lent',
    color: Color(0xFF7F8C8D),
    startMonth: 2,
    startDay: 14,
    durationWeeks: 6,
    emoji: '✝️',
  ),
  _SeasonBlock(
    id: 'easter',
    name: 'Easter',
    color: Color(0xFFF1C40F),
    startMonth: 4,
    startDay: 4,
    durationWeeks: 7,
    emoji: '🌅',
  ),
  _SeasonBlock(
    id: 'ordinary2',
    name: 'Ordinary Time II',
    color: Color(0xFF27AE60),
    startMonth: 6,
    startDay: 5,
    durationWeeks: 27,
    emoji: '🌿',
  ),
];

const List<_FeastDay> _feastDays = [
  _FeastDay(id: 'immaculate_conception', name: 'Immaculate Conception', month: 12, day: 8, emoji: '💙', isMajor: true),
  _FeastDay(id: 'christmas_day', name: 'Christmas Day', month: 12, day: 25, emoji: '⭐', isMajor: true),
  _FeastDay(id: 'epiphany', name: 'Epiphany', month: 1, day: 6, emoji: '👑', isMajor: true),
  _FeastDay(id: 'ash_wednesday', name: 'Ash Wednesday', month: 2, day: 14, emoji: '🌑', isMajor: true),
  _FeastDay(id: 'palm_sunday', name: 'Palm Sunday', month: 4, day: 2, emoji: '🌿', isMajor: true),
  _FeastDay(id: 'good_friday', name: 'Good Friday', month: 4, day: 7, emoji: '✝️', isMajor: true),
  _FeastDay(id: 'easter_sunday', name: 'Easter Sunday', month: 4, day: 9, emoji: '🐣', isMajor: true),
  _FeastDay(id: 'ascension', name: 'Ascension', month: 5, day: 18, emoji: '☁️', isMajor: true),
  _FeastDay(id: 'pentecost', name: 'Pentecost', month: 5, day: 28, emoji: '🔥', isMajor: true),
  _FeastDay(id: 'corpus_christi', name: 'Corpus Christi', month: 6, day: 11, emoji: '🍞', isMajor: true),
  _FeastDay(id: 'assumption', name: 'Assumption', month: 8, day: 15, emoji: '🌹', isMajor: true),
  _FeastDay(id: 'all_saints', name: 'All Saints Day', month: 11, day: 1, emoji: '😇', isMajor: true),
  _FeastDay(id: 'st_francis', name: 'St. Francis of Assisi', month: 10, day: 4, emoji: '🕊️', isMajor: false),
  _FeastDay(id: 'st_patrick', name: 'St. Patrick', month: 3, day: 17, emoji: '☘️', isMajor: false),
  _FeastDay(id: 'st_valentine', name: 'St. Valentine', month: 2, day: 14, emoji: '❤️', isMajor: false),
  _FeastDay(id: 'st_nicholas', name: 'St. Nicholas', month: 12, day: 6, emoji: '🎁', isMajor: false),
  _FeastDay(id: 'st_joseph', name: 'St. Joseph', month: 3, day: 19, emoji: '🔨', isMajor: false),
  _FeastDay(id: 'annunciation', name: 'Annunciation', month: 3, day: 25, emoji: '👼', isMajor: false),
  _FeastDay(id: 'st_john_baptist', name: 'Birth of John the Baptist', month: 6, day: 24, emoji: '🌊', isMajor: false),
  _FeastDay(id: 'sts_peter_paul', name: 'Sts. Peter & Paul', month: 6, day: 29, emoji: '🗝️', isMajor: false),
];

// ── Puzzle state ──────────────────────────────────────────────────────────────

class _PuzzleState {
  const _PuzzleState({
    required this.mode,
    required this.placedSeasons,
    required this.placedFeasts,
    required this.totalItems,
    required this.correctItems,
    this.isComplete = false,
    this.holyPointsEarned = 0,
  });

  final _PuzzleMode mode;
  final Map<String, bool> placedSeasons; // id -> correct
  final Map<String, bool> placedFeasts;
  final int totalItems;
  final int correctItems;
  final bool isComplete;
  final int holyPointsEarned;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class LiturgyCalendarPuzzleGameScreen extends ConsumerStatefulWidget {
  const LiturgyCalendarPuzzleGameScreen({super.key});

  @override
  ConsumerState<LiturgyCalendarPuzzleGameScreen> createState() =>
      _LiturgyCalendarPuzzleGameScreenState();
}

class _LiturgyCalendarPuzzleGameScreenState
    extends ConsumerState<LiturgyCalendarPuzzleGameScreen>
    with SingleTickerProviderStateMixin {
  _PuzzleMode _mode = _PuzzleMode.seasonsOnly;
  late AnimationController _wheelController;
  Map<String, bool> _placedSeasons = {};
  Map<String, bool> _placedFeasts = {};
  int _holyPoints = 0;
  bool _isComplete = false;
  String? _draggingId;

  @override
  void initState() {
    super.initState();
    _wheelController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _wheelController.dispose();
    super.dispose();
  }

  List<_FeastDay> get _activeFeasts {
    return _feastDays.where((f) {
      if (_mode == _PuzzleMode.seasonsOnly) return false;
      if (_mode == _PuzzleMode.majorFeasts) return f.isMajor;
      return true; // minorFeasts = all
    }).toList();
  }

  void _placeSeason(String id, bool correct) {
    setState(() {
      _placedSeasons[id] = correct;
      if (correct) _holyPoints += 20;
      _checkCompletion();
    });
  }

  void _placeFeast(String id, bool correct) {
    setState(() {
      _placedFeasts[id] = correct;
      if (correct) _holyPoints += 10;
      _checkCompletion();
    });
  }

  void _checkCompletion() {
    final totalSeasons = _seasons.length;
    final totalFeasts = _activeFeasts.length;
    final total = totalSeasons + totalFeasts;
    final correct = _placedSeasons.values.where((v) => v).length +
        _placedFeasts.values.where((v) => v).length;

    if (_placedSeasons.length == totalSeasons &&
        _placedFeasts.length == totalFeasts) {
      setState(() => _isComplete = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Liturgy Calendar',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontFamily: 'Cinzel',
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
      ),
      body: Column(
        children: [
          _buildModeSelector(),
          _buildStats(),
          Expanded(
            child: Row(
              children: [
                // Liturgical wheel (left half)
                Expanded(flex: 2, child: _buildLiturgicalWheel()),
                // Item bank (right half)
                Expanded(flex: 1, child: _buildItemBank()),
              ],
            ),
          ),
          if (_isComplete) _buildCompletionBanner(),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: _PuzzleMode.values.map((m) {
          final label = switch (m) {
            _PuzzleMode.seasonsOnly => 'Seasons',
            _PuzzleMode.majorFeasts => '+ Major Feasts',
            _PuzzleMode.minorFeasts => 'All Feasts',
          };
          final isSelected = _mode == m;
          final unlocked = switch (m) {
            _PuzzleMode.seasonsOnly => true,
            _PuzzleMode.majorFeasts => _placedSeasons.length == _seasons.length &&
                _placedSeasons.values.every((v) => v),
            _PuzzleMode.minorFeasts => _placedFeasts.isNotEmpty &&
                _activeFeasts.every((f) => _placedFeasts[f.id] == true),
          };

          return Expanded(
            child: GestureDetector(
              onTap: unlocked ? () => setState(() { _mode = m; _placedFeasts = {}; }) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFFD700)
                      : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: unlocked ? Colors.white24 : Colors.white12,
                  ),
                ),
                child: Text(
                  unlocked ? label : '🔒 $label',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF1A0A2E)
                        : unlocked
                            ? Colors.white70
                            : Colors.white24,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStats() {
    final totalSeasons = _seasons.length;
    final totalFeasts = _activeFeasts.length;
    final correctSeasons = _placedSeasons.values.where((v) => v).length;
    final correctFeasts = _placedFeasts.values.where((v) => v).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Seasons: $correctSeasons / $totalSeasons',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          if (totalFeasts > 0)
            Text(
              'Feasts: $correctFeasts / $totalFeasts',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '⭐ $_holyPoints pts',
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiturgicalWheel() {
    return AnimatedBuilder(
      animation: _wheelController,
      builder: (context, child) {
        return CustomPaint(
          painter: _LiturgicalWheelPainter(
            seasons: _seasons,
            placedSeasons: _placedSeasons,
            rotation: _wheelController.value * 2 * math.pi * 0.05,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Drop targets for each season
              ..._buildSeasonDropTargets(),
              // Centre label
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF0D1B2A),
                ),
                child: const Center(
                  child: Text('✝️', style: TextStyle(fontSize: 24)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildSeasonDropTargets() {
    return _seasons.asMap().entries.map((entry) {
      final i = entry.key;
      final season = entry.value;
      final angle = (i / _seasons.length) * 2 * math.pi - math.pi / 2;
      final radius = 90.0;

      return Positioned(
        left: 120 + radius * math.cos(angle) - 20,
        top: 120 + radius * math.sin(angle) - 20,
        child: DragTarget<String>(
          onAcceptWithDetails: (details) {
            final correct = details.data == season.id;
            _placeSeason(season.id, correct);
          },
          builder: (context, candidates, rejected) {
            final placed = _placedSeasons.containsKey(season.id);
            final isCorrect = _placedSeasons[season.id] == true;
            final isHovering = candidates.isNotEmpty;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: placed
                    ? (isCorrect ? season.color : Colors.redAccent.withOpacity(0.3))
                    : isHovering
                        ? season.color.withOpacity(0.4)
                        : Colors.white.withOpacity(0.1),
                border: Border.all(
                  color: placed
                      ? (isCorrect ? season.color : Colors.redAccent)
                      : isHovering
                          ? season.color
                          : Colors.white30,
                  width: isHovering ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  placed ? season.emoji : '?',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            );
          },
        ),
      );
    }).toList();
  }

  Widget _buildItemBank() {
    final unplacedSeasons = _seasons.where((s) => !_placedSeasons.containsKey(s.id)).toList();
    final unplacedFeasts = _activeFeasts.where((f) => !_placedFeasts.containsKey(f.id)).toList();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A2A3A),
        border: Border(left: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              'Drag to place →',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                if (unplacedSeasons.isNotEmpty) ...[
                  const Text(
                    'SEASONS',
                    style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1),
                  ),
                  const SizedBox(height: 4),
                  ...unplacedSeasons.map((s) => _DraggableItem(
                        id: s.id,
                        name: s.name,
                        emoji: s.emoji,
                        color: s.color,
                      )),
                  const SizedBox(height: 8),
                ],
                if (unplacedFeasts.isNotEmpty) ...[
                  const Text(
                    'FEASTS',
                    style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1),
                  ),
                  const SizedBox(height: 4),
                  ...unplacedFeasts.map((f) => _DraggableItem(
                        id: f.id,
                        name: f.name,
                        emoji: f.emoji,
                        color: f.isMajor
                            ? const Color(0xFFFFD700)
                            : const Color(0xFF9B59B6),
                      )),
                ],
                if (unplacedSeasons.isEmpty && unplacedFeasts.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'All items\nplaced!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFFFFD700), fontSize: 14),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionBanner() {
    final correct = _placedSeasons.values.where((v) => v).length +
        _placedFeasts.values.where((v) => v).length;
    final total = _placedSeasons.length + _placedFeasts.length;

    return Container(
      color: const Color(0xFFFFD700),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Complete! $correct/$total correct — $_holyPoints pts',
            style: const TextStyle(
              color: Color(0xFF1A0A2E),
              fontFamily: 'Cinzel',
              fontWeight: FontWeight.bold,
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A0A2E),
              foregroundColor: const Color(0xFFFFD700),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

// ── Draggable item ────────────────────────────────────────────────────────────

class _DraggableItem extends StatelessWidget {
  const _DraggableItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
  });

  final String id;
  final String name;
  final String emoji;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 10),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    return Draggable<String>(
      data: id,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(opacity: 0.9, child: SizedBox(width: 120, child: tile)),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: tile),
      child: tile,
    );
  }
}

// ── Liturgical wheel painter ──────────────────────────────────────────────────

class _LiturgicalWheelPainter extends CustomPainter {
  _LiturgicalWheelPainter({
    required this.seasons,
    required this.placedSeasons,
    required this.rotation,
  });

  final List<_SeasonBlock> seasons;
  final Map<String, bool> placedSeasons;
  final double rotation;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2 - 20;
    final innerRadius = outerRadius * 0.4;

    final sweepAngle = 2 * math.pi / seasons.length;

    for (int i = 0; i < seasons.length; i++) {
      final season = seasons[i];
      final startAngle = i * sweepAngle - math.pi / 2 + rotation;

      final placed = placedSeasons.containsKey(season.id);
      final correct = placedSeasons[season.id] == true;

      final paint = Paint()
        ..color = placed
            ? (correct
                ? season.color.withOpacity(0.7)
                : Colors.redAccent.withOpacity(0.3))
            : season.color.withOpacity(0.2)
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(
          centre.dx + innerRadius * math.cos(startAngle),
          centre.dy + innerRadius * math.sin(startAngle),
        )
        ..arcTo(
          Rect.fromCircle(center: centre, radius: outerRadius),
          startAngle,
          sweepAngle,
          false,
        )
        ..arcTo(
          Rect.fromCircle(center: centre, radius: innerRadius),
          startAngle + sweepAngle,
          -sweepAngle,
          false,
        )
        ..close();

      canvas.drawPath(path, paint);

      // Border
      canvas.drawPath(
        path,
        Paint()
          ..color = season.color.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Outer ring
    canvas.drawCircle(
      centre,
      outerRadius,
      Paint()
        ..color = Colors.white24
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Inner ring
    canvas.drawCircle(
      centre,
      innerRadius,
      Paint()
        ..color = Colors.white24
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_LiturgicalWheelPainter oldDelegate) =>
      oldDelegate.rotation != rotation ||
      oldDelegate.placedSeasons.length != placedSeasons.length;
}
