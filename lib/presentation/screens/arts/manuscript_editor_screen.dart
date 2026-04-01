import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../data/models/arts/artwork_model.dart';
import '../../providers/arts_provider.dart';
import '../../providers/bible_provider.dart';
import '../../widgets/arts/color_palette_widget.dart';

// ── Border style ──────────────────────────────────────────────────────────────

enum _BorderStyle { celticKnot, floral, geometric, animal }

extension _BorderStyleExt on _BorderStyle {
  String get displayName => switch (this) {
        _BorderStyle.celticKnot => 'Celtic Knot',
        _BorderStyle.floral => 'Floral',
        _BorderStyle.geometric => 'Geometric',
        _BorderStyle.animal => 'Bestiary',
      };
  String get emoji => switch (this) {
        _BorderStyle.celticKnot => '☘️',
        _BorderStyle.floral => '🌸',
        _BorderStyle.geometric => '🔷',
        _BorderStyle.animal => '🦁',
      };
}

// ── Drop cap style ────────────────────────────────────────────────────────────

enum _DropCapStyle { gothic, uncial, roman, blackletter, illuminated }

extension _DropCapStyleExt on _DropCapStyle {
  String get displayName => switch (this) {
        _DropCapStyle.gothic => 'Gothic',
        _DropCapStyle.uncial => 'Uncial',
        _DropCapStyle.roman => 'Roman',
        _DropCapStyle.blackletter => 'Blackletter',
        _DropCapStyle.illuminated => 'Illuminated',
      };
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _ManuscriptPainter extends CustomPainter {
  _ManuscriptPainter({
    required this.borderStyle,
    required this.goldLeaf,
    required this.accentColor,
  });

  final _BorderStyle borderStyle;
  final bool goldLeaf;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final parchmentPaint = Paint()..color = const Color(0xFFF5DEB3);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), parchmentPaint);

    final borderPaint = Paint()
      ..color = goldLeaf ? const Color(0xFF8B6914) : accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = goldLeaf ? 3.0 : 2.0;

    const margin = 16.0;
    final rect = Rect.fromLTWH(
      margin, margin,
      size.width - margin * 2,
      size.height - margin * 2,
    );

    // Outer border
    canvas.drawRect(rect, borderPaint);

    // Inner border
    const innerMargin = 24.0;
    final innerRect = Rect.fromLTWH(
      innerMargin, innerMargin,
      size.width - innerMargin * 2,
      size.height - innerMargin * 2,
    );
    canvas.drawRect(
      innerRect,
      Paint()
        ..color = (goldLeaf ? const Color(0xFF8B6914) : accentColor).withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Corner decorations based on style
    switch (borderStyle) {
      case _BorderStyle.celticKnot:
        _drawCelticCorners(canvas, rect, borderPaint);
      case _BorderStyle.floral:
        _drawFloralCorners(canvas, rect, accentColor);
      case _BorderStyle.geometric:
        _drawGeometricBorder(canvas, rect, borderPaint);
      case _BorderStyle.animal:
        _drawAnimalCorners(canvas, rect, borderPaint);
    }

    // Gold leaf shimmer
    if (goldLeaf) {
      final shimmerPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFF8DC), Color(0xFFB8860B)],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      canvas.drawRect(rect, shimmerPaint);
    }
  }

  void _drawCelticCorners(Canvas canvas, Rect rect, Paint paint) {
    for (final corner in [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ]) {
      canvas.drawCircle(corner, 8, paint);
      canvas.drawCircle(corner, 4, Paint()..color = const Color(0xFFFFD700));
    }
    // Simple knot lines along borders
    for (double x = rect.left + 20; x < rect.right - 20; x += 16) {
      canvas.drawLine(
        Offset(x, rect.top),
        Offset(x + 8, rect.top + 4),
        paint..strokeWidth = 1,
      );
    }
  }

  void _drawFloralCorners(Canvas canvas, Rect rect, Color color) {
    final petalPaint = Paint()..color = color.withOpacity(0.7);
    for (final corner in [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ]) {
      for (int i = 0; i < 6; i++) {
        final angle = i * 3.14159 / 3;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(
              corner.dx + 10 * (angle).truncateToDouble(),
              corner.dy,
            ),
            width: 12,
            height: 6,
          ),
          petalPaint,
        );
      }
      canvas.drawCircle(corner, 6, Paint()..color = const Color(0xFFFFD700));
    }
  }

  void _drawGeometricBorder(Canvas canvas, Rect rect, Paint paint) {
    const step = 20.0;
    for (double x = rect.left; x < rect.right; x += step) {
      canvas.drawLine(Offset(x, rect.top), Offset(x + step / 2, rect.top - 5), paint);
      canvas.drawLine(Offset(x + step / 2, rect.top - 5), Offset(x + step, rect.top), paint);
    }
  }

  void _drawAnimalCorners(Canvas canvas, Rect rect, Paint paint) {
    // Simple lion-like silhouette at each corner using paths
    for (final offset in [
      rect.topLeft,
      rect.topRight + const Offset(-20, 0),
      rect.bottomLeft + const Offset(0, -20),
      rect.bottomRight + const Offset(-20, -20),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(center: offset, width: 18, height: 14),
        Paint()..color = paint.color.withOpacity(0.6),
      );
      canvas.drawCircle(offset, 5, Paint()..color = paint.color);
    }
  }

  @override
  bool shouldRepaint(_ManuscriptPainter oldDelegate) =>
      oldDelegate.borderStyle != borderStyle ||
      oldDelegate.goldLeaf != goldLeaf ||
      oldDelegate.accentColor != accentColor;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ManuscriptEditorScreen extends ConsumerStatefulWidget {
  const ManuscriptEditorScreen({super.key});

  @override
  ConsumerState<ManuscriptEditorScreen> createState() => _ManuscriptEditorScreenState();
}

class _ManuscriptEditorScreenState extends ConsumerState<ManuscriptEditorScreen> {
  final _textController = TextEditingController();
  _BorderStyle _borderStyle = _BorderStyle.celticKnot;
  _DropCapStyle _dropCapStyle = _DropCapStyle.gothic;
  bool _goldLeaf = false;
  Color _accentColor = const Color(0xFF8B0000);
  bool _isSaving = false;
  bool _isGenerating = false;

  static const _verseOfDay = 'For God so loved the world that he gave his only Son, '
      'so that everyone who believes in him might not perish '
      'but might have eternal life.';
  static const _verseRef = 'John 3:16';

  @override
  void initState() {
    super.initState();
    _textController.text = _verseOfDay;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final notifier = ref.read(artsNotifierProvider.notifier);
    await notifier.saveArtwork(
      type: ArtworkType.manuscript,
      canvasData: {
        'verseText': _textController.text,
        'borderStyle': _borderStyle.name,
        'dropCapStyle': _dropCapStyle.name,
        'goldLeaf': _goldLeaf,
        'accentColor': '${_accentColor.red},${_accentColor.green},${_accentColor.blue}',
      },
    );

    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Manuscript saved to your gallery!'),
          backgroundColor: Color(0xFF27AE60),
        ),
      );
    }
  }

  Future<void> _generateBorderArt() async {
    setState(() => _isGenerating = true);
    final prompt =
        '${_borderStyle.displayName} border for illuminated manuscript page, '
        'medieval Catholic art, gold leaf, ornate calligraphy, parchment texture';

    final notifier = ref.read(artsNotifierProvider.notifier);
    await notifier.generateAiArtwork(
      prompt: prompt,
      type: ArtworkType.manuscript,
    );

    setState(() => _isGenerating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5DEB3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B6914),
        elevation: 0,
        title: const Text(
          'Illuminated Manuscript',
          style: TextStyle(
            color: Color(0xFFF5DEB3),
            fontFamily: 'Cinzel',
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFF5DEB3)),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFF5DEB3),
                    ),
                  )
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Manuscript preview ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: CustomPaint(
                size: const Size(double.infinity, 340),
                painter: _ManuscriptPainter(
                  borderStyle: _borderStyle,
                  goldLeaf: _goldLeaf,
                  accentColor: _accentColor,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drop cap
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _goldLeaf
                                  ? const Color(0xFFFFD700)
                                  : _accentColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: _accentColor),
                            ),
                            child: Text(
                              _textController.text.isNotEmpty
                                  ? _textController.text[0].toUpperCase()
                                  : 'F',
                              style: TextStyle(
                                color: _accentColor,
                                fontSize: 40,
                                fontFamily: 'Cinzel',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _textController.text.isNotEmpty
                                  ? _textController.text.substring(1)
                                  : '',
                              style: const TextStyle(
                                color: Color(0xFF4B2800),
                                fontSize: 13,
                                height: 1.6,
                              ),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '— $_verseRef',
                          style: TextStyle(
                            color: _accentColor,
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                            fontFamily: 'Cinzel',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(),

            // ── Controls ──────────────────────────────────────────────────
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      color: const Color(0xFF2C1810),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verse text
          const Text(
            'Verse Text',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontFamily: 'Cinzel',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _textController,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white, fontSize: 13),
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
              hintText: 'Enter a Bible verse…',
              hintStyle: const TextStyle(color: Colors.white38),
            ),
          ),
          const SizedBox(height: 16),

          // Border style
          const Text(
            'Border Style',
            style: TextStyle(color: Color(0xFFFFD700), fontFamily: 'Cinzel'),
          ),
          const SizedBox(height: 8),
          Row(
            children: _BorderStyle.values.map((s) {
              final isSelected = _borderStyle == s;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _borderStyle = s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFFD700).withOpacity(0.2)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFFFD700) : Colors.white24,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(s.emoji, style: const TextStyle(fontSize: 18)),
                        Text(
                          s.displayName,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFFFFD700)
                                : Colors.white60,
                            fontSize: 9,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Gold leaf toggle
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gold Leaf Effect',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Adds shimmer to borders',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _goldLeaf,
                onChanged: (v) => setState(() => _goldLeaf = v),
                activeColor: const Color(0xFFFFD700),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Accent color
          const Text(
            'Accent Color',
            style: TextStyle(color: Color(0xFFFFD700), fontFamily: 'Cinzel'),
          ),
          const SizedBox(height: 8),
          ColorPaletteWidget(
            selectedColor: _accentColor,
            onColorSelected: (c) => setState(() => _accentColor = c),
            initialPalette: 'Manuscript',
          ),
          const SizedBox(height: 20),

          // AI Generate button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateBorderArt,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B6914),
                foregroundColor: const Color(0xFFF5DEB3),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isGenerating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFF5DEB3),
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                _isGenerating ? 'Generating Border Art…' : 'Generate Border with AI',
                style: const TextStyle(fontFamily: 'Cinzel', fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
