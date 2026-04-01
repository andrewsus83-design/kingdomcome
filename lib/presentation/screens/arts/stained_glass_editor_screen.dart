import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../data/models/arts/artwork_model.dart';
import '../../providers/arts_provider.dart';
import '../../widgets/arts/canvas_toolbar.dart';
import '../../widgets/arts/color_palette_widget.dart';

// ── Template definitions ──────────────────────────────────────────────────────

enum _Template { cross, roseWindow, nativity }

extension _TemplateExt on _Template {
  String get displayName => switch (this) {
        _Template.cross => 'Cross',
        _Template.roseWindow => 'Rose Window',
        _Template.nativity => 'Nativity',
      };

  String get emoji => switch (this) {
        _Template.cross => '✝️',
        _Template.roseWindow => '🌹',
        _Template.nativity => '⭐',
      };
}

// ── Stained glass section ─────────────────────────────────────────────────────

class _Section {
  _Section({required this.path, required this.color});
  final Path path;
  Color color;
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _StainedGlassPainter extends CustomPainter {
  _StainedGlassPainter({
    required this.sections,
    required this.template,
    this.highlightIndex,
  });

  final List<_Section> sections;
  final _Template template;
  final int? highlightIndex;

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF1A1A1A),
    );

    // Paint sections
    for (int i = 0; i < sections.length; i++) {
      final section = sections[i];

      // Fill with translucent stained-glass colour
      final fillPaint = Paint()
        ..color = section.color.withOpacity(0.85)
        ..style = PaintingStyle.fill;

      // Simulate light shining through: lighter at top
      final shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, size.height),
        [
          section.color.withOpacity(0.95),
          section.color.withOpacity(0.65),
        ],
      );
      canvas.drawPath(section.path, Paint()..shader = shader..style = PaintingStyle.fill);

      // Lead lines (dark border)
      final leadPaint = Paint()
        ..color = const Color(0xFF1A1A1A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawPath(section.path, leadPaint);

      // Highlight selected section
      if (i == highlightIndex) {
        canvas.drawPath(
          section.path,
          Paint()
            ..color = Colors.white.withOpacity(0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_StainedGlassPainter oldDelegate) => true;
}

// ── Section generators ────────────────────────────────────────────────────────

List<_Section> _buildCrossSections(Size size) {
  final w = size.width;
  final h = size.height;
  final cx = w / 2;
  final cy = h / 2;
  final armW = w * 0.25;
  final armH = h * 0.25;

  final sections = <_Section>[];

  // Vertical arm
  sections.add(_Section(
    path: Path()
      ..addRect(Rect.fromCenter(center: Offset(cx, cy), width: armW, height: h * 0.9)),
    color: const Color(0xFF0D47A1),
  ));

  // Horizontal arm
  sections.add(_Section(
    path: Path()
      ..addRect(Rect.fromCenter(center: Offset(cx, cy), width: w * 0.9, height: armH)),
    color: const Color(0xFF0D47A1),
  ));

  // Corner sections (4)
  for (final (dx, dy) in [(-1, -1), (1, -1), (-1, 1), (1, 1)]) {
    final cx2 = cx + dx * (w * 0.3);
    final cy2 = cy + dy * (h * 0.3);
    sections.add(_Section(
      path: Path()
        ..addRect(Rect.fromCenter(center: Offset(cx2, cy2), width: w * 0.4, height: h * 0.4)),
      color: const Color(0xFFB71C1C),
    ));
  }

  // Centre circle
  sections.add(_Section(
    path: Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: armW * 0.6)),
    color: const Color(0xFFFFD700),
  ));

  return sections;
}

List<_Section> _buildRoseWindowSections(Size size) {
  final cx = size.width / 2;
  final cy = size.height / 2;
  final r = size.width.clamp(0.0, size.height) / 2 - 10;
  final sections = <_Section>[];
  const petalCount = 8;
  final colors = [
    const Color(0xFFB71C1C),
    const Color(0xFF0D47A1),
    const Color(0xFF1B5E20),
    const Color(0xFF4A148C),
  ];

  // Outer ring petals
  for (int i = 0; i < petalCount; i++) {
    final angle = (i / petalCount) * 2 * 3.14159;
    final nextAngle = ((i + 1) / petalCount) * 2 * 3.14159;
    final path = Path()
      ..moveTo(cx, cy)
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        angle,
        2 * 3.14159 / petalCount,
        false,
      )
      ..close();
    sections.add(_Section(path: path, color: colors[i % colors.length]));
  }

  // Middle ring
  for (int i = 0; i < 6; i++) {
    final angle = (i / 6) * 2 * 3.14159;
    final nextAngle = ((i + 1) / 6) * 2 * 3.14159;
    final path = Path()
      ..moveTo(cx, cy)
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.55),
        angle,
        2 * 3.14159 / 6,
        false,
      )
      ..close();
    sections.add(_Section(path: path, color: colors[(i + 2) % colors.length]));
  }

  // Centre
  sections.add(_Section(
    path: Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.2)),
    color: const Color(0xFFFFD700),
  ));

  return sections;
}

List<_Section> _buildNativitySections(Size size) {
  final w = size.width;
  final h = size.height;
  final sections = <_Section>[];

  // Sky background
  sections.add(_Section(
    path: Path()..addRect(Rect.fromLTWH(0, 0, w, h * 0.55)),
    color: const Color(0xFF0D47A1),
  ));

  // Ground
  sections.add(_Section(
    path: Path()..addRect(Rect.fromLTWH(0, h * 0.7, w, h * 0.3)),
    color: const Color(0xFF1B5E20),
  ));

  // Star
  sections.add(_Section(
    path: Path()..addOval(Rect.fromCircle(center: Offset(w / 2, h * 0.12), radius: 20)),
    color: const Color(0xFFFFD700),
  ));

  // Manger (rectangle)
  sections.add(_Section(
    path: Path()..addRect(Rect.fromLTWH(w * 0.35, h * 0.6, w * 0.3, h * 0.15)),
    color: const Color(0xFF8B6914),
  ));

  // Left figure (Mary)
  sections.add(_Section(
    path: Path()
      ..addOval(Rect.fromLTWH(w * 0.18, h * 0.5, w * 0.16, h * 0.22))
      ..addOval(Rect.fromCircle(center: Offset(w * 0.26, h * 0.48), radius: 14)),
    color: const Color(0xFF4A148C),
  ));

  // Right figure (Joseph)
  sections.add(_Section(
    path: Path()
      ..addOval(Rect.fromLTWH(w * 0.66, h * 0.48, w * 0.16, h * 0.24))
      ..addOval(Rect.fromCircle(center: Offset(w * 0.74, h * 0.46), radius: 14)),
    color: const Color(0xFF8B4513),
  ));

  return sections;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class StainedGlassEditorScreen extends ConsumerStatefulWidget {
  const StainedGlassEditorScreen({super.key});

  @override
  ConsumerState<StainedGlassEditorScreen> createState() =>
      _StainedGlassEditorScreenState();
}

class _StainedGlassEditorScreenState
    extends ConsumerState<StainedGlassEditorScreen> {
  _Template _template = _Template.cross;
  List<_Section> _sections = [];
  Color _selectedColor = const Color(0xFFB71C1C);
  CanvasTool _activeTool = CanvasTool.fill;
  int? _highlightedSection;
  bool _isSaving = false;
  bool _isGenerating = false;
  final List<List<Color>> _undoStack = [];
  int _zoom = 100;

  @override
  void initState() {
    super.initState();
    _initSections();
  }

  void _initSections() {
    const size = Size(300, 300);
    _sections = switch (_template) {
      _Template.cross => _buildCrossSections(size),
      _Template.roseWindow => _buildRoseWindowSections(size),
      _Template.nativity => _buildNativitySections(size),
    };
  }

  void _onCanvasTap(Offset localPos, Size canvasSize) {
    if (_activeTool != CanvasTool.fill) return;

    // Find which section was tapped
    for (int i = 0; i < _sections.length; i++) {
      if (_sections[i].path.contains(localPos)) {
        _pushUndo();
        setState(() => _sections[i].color = _selectedColor);
        return;
      }
    }
  }

  void _pushUndo() {
    _undoStack.add(_sections.map((s) => s.color).toList());
    if (_undoStack.length > 30) _undoStack.removeAt(0);
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    final colors = _undoStack.removeLast();
    setState(() {
      for (int i = 0; i < _sections.length && i < colors.length; i++) {
        _sections[i].color = colors[i];
      }
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final canvasData = {
      'template': _template.name,
      'sections': _sections
          .map((s) => {
                'color':
                    '${s.color.red},${s.color.green},${s.color.blue}',
              })
          .toList(),
    };

    final notifier = ref.read(artsNotifierProvider.notifier);
    await notifier.saveArtwork(
      type: ArtworkType.stainedGlass,
      canvasData: canvasData,
    );

    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stained glass saved to your gallery!'),
          backgroundColor: Color(0xFF27AE60),
        ),
      );
    }
  }

  Future<void> _generateWithAi() async {
    setState(() => _isGenerating = true);
    final prompt =
        'Beautiful ${_template.displayName} stained glass window, '
        'vibrant colors, lead lines, Catholic cathedral, sacred art';

    final notifier = ref.read(artsNotifierProvider.notifier);
    await notifier.generateAiArtwork(
      prompt: prompt,
      type: ArtworkType.stainedGlass,
    );

    setState(() => _isGenerating = false);
  }

  void _selectTemplate() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A2A3A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Template',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontFamily: 'Cinzel',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _Template.values.map((t) {
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _template = t;
                      _initSections();
                      _undoStack.clear();
                    });
                  },
                  child: Column(
                    children: [
                      Text(t.emoji, style: const TextStyle(fontSize: 36)),
                      const SizedBox(height: 6),
                      Text(
                        t.displayName,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Stained Glass Creator',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontFamily: 'Cinzel',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view, color: Color(0xFFFFD700)),
            tooltip: 'Templates',
            onPressed: _selectTemplate,
          ),
        ],
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
      ),
      body: Row(
        children: [
          // ── Toolbar ───────────────────────────────────────────────────────
          CanvasToolbar(
            activeTool: _activeTool,
            onToolSelected: (t) => setState(() => _activeTool = t),
            onUndo: _undo,
            onRedo: () {},
            onZoomIn: () => setState(() => _zoom = (_zoom + 10).clamp(50, 200)),
            onZoomOut: () => setState(() => _zoom = (_zoom - 10).clamp(50, 200)),
            onSave: _save,
            onAiGenerate: _generateWithAi,
            onTemplateSelect: _selectTemplate,
            canUndo: _undoStack.isNotEmpty,
            isSaving: _isSaving,
            isGenerating: _isGenerating,
          ),
          // ── Canvas ────────────────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = constraints.biggest * (_zoom / 100);

                        return GestureDetector(
                          onTapDown: (d) {
                            final scale = _zoom / 100;
                            final canvasSize = constraints.biggest;
                            final dx =
                                (d.localPosition.dx - (canvasSize.width - size.width) / 2) /
                                    scale;
                            final dy =
                                (d.localPosition.dy -
                                        (canvasSize.height - size.height) / 2) /
                                    scale;
                            _onCanvasTap(Offset(dx, dy), const Size(300, 300));
                          },
                          child: CustomPaint(
                            size: const Size(300, 300),
                            painter: _StainedGlassPainter(
                              sections: _sections,
                              template: _template,
                              highlightIndex: _highlightedSection,
                            ),
                          ).animate().fadeIn(),
                        );
                      },
                    ),
                  ),
                ),
                // ── Color palette ─────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2A3A),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: ColorPaletteWidget(
                    selectedColor: _selectedColor,
                    onColorSelected: (c) => setState(() => _selectedColor = c),
                    initialPalette: 'Stained Glass',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
