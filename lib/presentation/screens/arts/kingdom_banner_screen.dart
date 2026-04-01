import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../data/models/arts/artwork_model.dart';
import '../../providers/arts_provider.dart';
import '../../widgets/arts/color_palette_widget.dart';

// ── Shield shapes ─────────────────────────────────────────────────────────────

enum _ShieldShape { heater, kite, roundTop, lozenge, french }

extension _ShieldShapeExt on _ShieldShape {
  String get displayName => switch (this) {
        _ShieldShape.heater => 'Heater',
        _ShieldShape.kite => 'Kite',
        _ShieldShape.roundTop => 'Round Top',
        _ShieldShape.lozenge => 'Lozenge',
        _ShieldShape.french => 'French',
      };
}

// ── Heraldic symbols ──────────────────────────────────────────────────────────

class _Symbol {
  const _Symbol({required this.id, required this.label, required this.emoji});
  final String id;
  final String label;
  final String emoji;
}

const List<_Symbol> _symbols = [
  _Symbol(id: 'cross', label: 'Cross', emoji: '✝️'),
  _Symbol(id: 'fleurdelis', label: 'Fleur-de-lis', emoji: '⚜️'),
  _Symbol(id: 'fish', label: 'Fish', emoji: '🐟'),
  _Symbol(id: 'lamb', label: 'Lamb', emoji: '🐑'),
  _Symbol(id: 'dove', label: 'Dove', emoji: '🕊️'),
  _Symbol(id: 'lily', label: 'Lily', emoji: '🌸'),
  _Symbol(id: 'crown', label: 'Crown', emoji: '👑'),
  _Symbol(id: 'keys', label: 'Keys', emoji: '🗝️'),
  _Symbol(id: 'star', label: 'Star', emoji: '⭐'),
  _Symbol(id: 'sword', label: 'Sword', emoji: '⚔️'),
  _Symbol(id: 'chalice', label: 'Chalice', emoji: '🏆'),
  _Symbol(id: 'rose', label: 'Rose', emoji: '🌹'),
];

const List<String> _saintPatrons = [
  'St. Michael',
  'St. Patrick',
  'St. George',
  'St. Francis',
  'St. Joan of Arc',
  'St. Dominic',
  'St. Thomas Aquinas',
  'St. Thérèse',
  'St. Benedict',
  'St. Joseph',
  'St. Mary (Our Lady)',
  'St. Peter',
  'St. Paul',
  'St. Nicholas',
  'St. Catherine',
];

// ── Shield painter ────────────────────────────────────────────────────────────

class _ShieldPainter extends CustomPainter {
  _ShieldPainter({
    required this.shape,
    required this.topLeftColor,
    required this.topRightColor,
    required this.bottomLeftColor,
    required this.bottomRightColor,
    required this.divisionCount,
    required this.topLeftSymbol,
    required this.topRightSymbol,
    required this.bottomLeftSymbol,
    required this.bottomRightSymbol,
  });

  final _ShieldShape shape;
  final Color topLeftColor;
  final Color topRightColor;
  final Color bottomLeftColor;
  final Color bottomRightColor;
  final int divisionCount; // 2 or 4
  final String? topLeftSymbol;
  final String? topRightSymbol;
  final String? bottomLeftSymbol;
  final String? bottomRightSymbol;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildShieldPath(size);

    // Clip to shield shape
    canvas.save();
    canvas.clipPath(path);

    if (divisionCount == 4) {
      // Quarter divisions
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width / 2, size.height / 2),
        Paint()..color = topLeftColor,
      );
      canvas.drawRect(
        Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height / 2),
        Paint()..color = topRightColor,
      );
      canvas.drawRect(
        Rect.fromLTWH(0, size.height / 2, size.width / 2, size.height / 2),
        Paint()..color = bottomLeftColor,
      );
      canvas.drawRect(
        Rect.fromLTWH(size.width / 2, size.height / 2, size.width / 2, size.height / 2),
        Paint()..color = bottomRightColor,
      );
    } else {
      // Horizontal bisect
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height / 2),
        Paint()..color = topLeftColor,
      );
      canvas.drawRect(
        Rect.fromLTWH(0, size.height / 2, size.width, size.height / 2),
        Paint()..color = bottomLeftColor,
      );
    }

    canvas.restore();

    // Shield border
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF1A1A1A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Division lines
    if (divisionCount == 4) {
      canvas.save();
      canvas.clipPath(path);
      canvas.drawLine(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        Paint()..color = const Color(0xFF1A1A1A)..strokeWidth = 2,
      );
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        Paint()..color = const Color(0xFF1A1A1A)..strokeWidth = 2,
      );
      canvas.restore();
    } else {
      canvas.save();
      canvas.clipPath(path);
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        Paint()..color = const Color(0xFF1A1A1A)..strokeWidth = 2,
      );
      canvas.restore();
    }

    // Symbols
    void drawSymbol(String? emoji, Offset center) {
      if (emoji == null) return;
      final tp = TextPainter(
        text: TextSpan(text: emoji, style: const TextStyle(fontSize: 28)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    }

    if (divisionCount == 4) {
      drawSymbol(topLeftSymbol, Offset(size.width * 0.25, size.height * 0.25));
      drawSymbol(topRightSymbol, Offset(size.width * 0.75, size.height * 0.25));
      drawSymbol(bottomLeftSymbol, Offset(size.width * 0.25, size.height * 0.65));
      drawSymbol(bottomRightSymbol, Offset(size.width * 0.75, size.height * 0.65));
    } else {
      drawSymbol(topLeftSymbol, Offset(size.width / 2, size.height * 0.25));
      drawSymbol(bottomLeftSymbol, Offset(size.width / 2, size.height * 0.65));
    }
  }

  Path _buildShieldPath(Size size) {
    final w = size.width;
    final h = size.height;

    return switch (shape) {
      _ShieldShape.heater => Path()
        ..moveTo(w * 0.05, 0)
        ..lineTo(w * 0.95, 0)
        ..lineTo(w * 0.95, h * 0.65)
        ..quadraticBezierTo(w * 0.95, h * 0.85, w * 0.5, h)
        ..quadraticBezierTo(w * 0.05, h * 0.85, w * 0.05, h * 0.65)
        ..close(),
      _ShieldShape.kite => Path()
        ..moveTo(w / 2, 0)
        ..lineTo(w * 0.95, h * 0.3)
        ..lineTo(w * 0.95, h * 0.7)
        ..lineTo(w / 2, h)
        ..lineTo(w * 0.05, h * 0.7)
        ..lineTo(w * 0.05, h * 0.3)
        ..close(),
      _ShieldShape.roundTop => Path()
        ..addArc(
          Rect.fromLTWH(w * 0.05, 0, w * 0.9, w * 0.9),
          math.pi,
          math.pi,
        )
        ..lineTo(w * 0.95, h * 0.65)
        ..quadraticBezierTo(w / 2, h * 1.1, w * 0.05, h * 0.65)
        ..close(),
      _ShieldShape.lozenge => Path()
        ..moveTo(w / 2, 0)
        ..lineTo(w, h / 2)
        ..lineTo(w / 2, h)
        ..lineTo(0, h / 2)
        ..close(),
      _ShieldShape.french => Path()
        ..moveTo(w * 0.05, 0)
        ..lineTo(w * 0.95, 0)
        ..lineTo(w * 0.95, h * 0.75)
        ..cubicTo(w * 0.95, h * 0.9, w * 0.7, h, w / 2, h)
        ..cubicTo(w * 0.3, h, w * 0.05, h * 0.9, w * 0.05, h * 0.75)
        ..close(),
    };
  }

  @override
  bool shouldRepaint(_ShieldPainter old) => true;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class KingdomBannerScreen extends ConsumerStatefulWidget {
  const KingdomBannerScreen({super.key});

  @override
  ConsumerState<KingdomBannerScreen> createState() => _KingdomBannerScreenState();
}

class _KingdomBannerScreenState extends ConsumerState<KingdomBannerScreen> {
  _ShieldShape _shape = _ShieldShape.heater;
  int _divisionCount = 4;
  Color _topLeftColor = const Color(0xFF0000FF);
  Color _topRightColor = const Color(0xFFFFD700);
  Color _bottomLeftColor = const Color(0xFFFFD700);
  Color _bottomRightColor = const Color(0xFF0000FF);
  String? _topLeftSymbol = '✝️';
  String? _topRightSymbol = '⚜️';
  String? _bottomLeftSymbol = '🕊️';
  String? _bottomRightSymbol = '👑';
  String _motto = 'In God We Trust';
  String _patron = 'St. Michael';
  bool _isSaving = false;

  int _activeSectionIndex = 0; // which section's color we're editing

  Color get _activeColor => switch (_activeSectionIndex) {
        0 => _topLeftColor,
        1 => _topRightColor,
        2 => _bottomLeftColor,
        _ => _bottomRightColor,
      };

  void _setActiveColor(Color c) {
    setState(() {
      switch (_activeSectionIndex) {
        case 0:
          _topLeftColor = c;
        case 1:
          _topRightColor = c;
        case 2:
          _bottomLeftColor = c;
        default:
          _bottomRightColor = c;
      }
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final notifier = ref.read(artsNotifierProvider.notifier);
    await notifier.saveArtwork(
      type: ArtworkType.banner,
      canvasData: {
        'shape': _shape.name,
        'divisionCount': _divisionCount,
        'topLeftColor': _topLeftColor.value,
        'topRightColor': _topRightColor.value,
        'bottomLeftColor': _bottomLeftColor.value,
        'bottomRightColor': _bottomRightColor.value,
        'topLeftSymbol': _topLeftSymbol,
        'topRightSymbol': _topRightSymbol,
        'bottomLeftSymbol': _bottomLeftSymbol,
        'bottomRightSymbol': _bottomRightSymbol,
        'motto': _motto,
        'patron': _patron,
      },
      title: '$_motto — Kingdom Banner',
    );
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kingdom Banner saved!'),
          backgroundColor: Color(0xFF27AE60),
        ),
      );
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
          'Kingdom Banner',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontFamily: 'Cinzel',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFFD700),
                    ),
                  )
                : const Icon(Icons.save, color: Color(0xFFFFD700)),
            onPressed: _isSaving ? null : _save,
          ),
        ],
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Preview ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Banner on flagpole
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Flagpole
                      Column(
                        children: [
                          Container(
                            width: 8,
                            height: 20,
                            color: const Color(0xFF8B6914),
                          ),
                          Container(
                            width: 4,
                            height: 180,
                            color: const Color(0xFF8B6914),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      // Shield
                      Column(
                        children: [
                          const SizedBox(height: 20),
                          CustomPaint(
                            size: const Size(160, 190),
                            painter: _ShieldPainter(
                              shape: _shape,
                              topLeftColor: _topLeftColor,
                              topRightColor: _topRightColor,
                              bottomLeftColor: _bottomLeftColor,
                              bottomRightColor: _bottomRightColor,
                              divisionCount: _divisionCount,
                              topLeftSymbol: _topLeftSymbol,
                              topRightSymbol: _topRightSymbol,
                              bottomLeftSymbol: _bottomLeftSymbol,
                              bottomRightSymbol: _bottomRightSymbol,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
                  const SizedBox(height: 12),
                  // Motto scroll
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5DEB3),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF8B6914), width: 2),
                    ),
                    child: Text(
                      _motto,
                      style: const TextStyle(
                        color: Color(0xFF4B2800),
                        fontFamily: 'Cinzel',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Patron: $_patron',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),

            // ── Controls ──────────────────────────────────────────────────
            Container(
              color: const Color(0xFF1A2A3A),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shield shape
                  _SectionHeader('Shield Shape'),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _ShieldShape.values.map((s) {
                        final isSelected = _shape == s;
                        return GestureDetector(
                          onTap: () => setState(() => _shape = s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFFD700)
                                  : Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? const Color(0xFFFFD700) : Colors.white24,
                              ),
                            ),
                            child: Text(
                              s.displayName,
                              style: TextStyle(
                                color: isSelected ? const Color(0xFF1A0A2E) : Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),
                  // Divisions
                  _SectionHeader('Sections'),
                  Row(
                    children: [2, 4].map((count) {
                      final isSelected = _divisionCount == count;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _divisionCount = count),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8, top: 8),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFFD700).withOpacity(0.2)
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? const Color(0xFFFFD700) : Colors.white24,
                              ),
                            ),
                            child: Text(
                              '$count Sections',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected ? const Color(0xFFFFD700) : Colors.white60,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),
                  // Section color picker
                  _SectionHeader('Section Colors'),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(
                      _divisionCount == 4 ? 4 : 2,
                      (i) {
                        final colors = [
                          _topLeftColor,
                          _topRightColor,
                          _bottomLeftColor,
                          _bottomRightColor,
                        ];
                        final labels = ['Top Left', 'Top Right', 'Bot Left', 'Bot Right'];
                        final isActive = _activeSectionIndex == i;

                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _activeSectionIndex = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 48,
                              decoration: BoxDecoration(
                                color: colors[i],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isActive ? Colors.white : Colors.transparent,
                                  width: isActive ? 3 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  labels[i],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  ColorPaletteWidget(
                    selectedColor: _activeColor,
                    onColorSelected: _setActiveColor,
                    initialPalette: 'Heraldic',
                  ),

                  const SizedBox(height: 16),
                  // Symbols
                  _SectionHeader('Section Symbols'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _symbols.map((sym) {
                      return GestureDetector(
                        onTap: () => _assignSymbol(sym.emoji),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(sym.emoji, style: const TextStyle(fontSize: 20)),
                              Text(
                                sym.label,
                                style: const TextStyle(color: Colors.white54, fontSize: 8),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),
                  // Motto
                  _SectionHeader('Kingdom Motto (max 20 chars)'),
                  const SizedBox(height: 8),
                  TextField(
                    maxLength: 20,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      counterStyle: const TextStyle(color: Colors.white54),
                    ),
                    controller: TextEditingController(text: _motto),
                    onChanged: (v) => setState(() => _motto = v),
                  ),

                  const SizedBox(height: 16),
                  // Patron
                  _SectionHeader('Saint Patron'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _patron,
                    dropdownColor: const Color(0xFF1A2A3A),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                    ),
                    items: _saintPatrons
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => _patron = v ?? _patron),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _assignSymbol(String emoji) {
    setState(() {
      switch (_activeSectionIndex) {
        case 0:
          _topLeftSymbol = emoji;
        case 1:
          _topRightSymbol = emoji;
        case 2:
          _bottomLeftSymbol = emoji;
        default:
          _bottomRightSymbol = emoji;
      }
    });
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFFFD700),
        fontFamily: 'Cinzel',
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
  }
}
