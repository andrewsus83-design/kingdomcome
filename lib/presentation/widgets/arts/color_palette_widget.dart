import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

// ── Preset palettes ───────────────────────────────────────────────────────────

class _Palette {
  const _Palette({required this.name, required this.colors});
  final String name;
  final List<Color> colors;
}

final List<_Palette> _palettes = [
  const _Palette(
    name: 'Stained Glass',
    colors: [
      Color(0xFFB71C1C), // Ruby red
      Color(0xFF0D47A1), // Cobalt blue
      Color(0xFF1B5E20), // Emerald
      Color(0xFFFFD700), // Gold
      Color(0xFF4A148C), // Violet
      Color(0xFFFFFFFF), // White
      Color(0xFFF57F17), // Amber
      Color(0xFF006064), // Teal
      Color(0xFF880E4F), // Deep pink
      Color(0xFF212121), // Lead/black
      Color(0xFF33691E), // Dark green
      Color(0xFF1565C0), // Royal blue
    ],
  ),
  const _Palette(
    name: 'Manuscript',
    colors: [
      Color(0xFFF5DEB3), // Wheat/parchment
      Color(0xFFD2B48C), // Tan
      Color(0xFF8B6914), // Gold leaf
      Color(0xFF8B0000), // Dark red
      Color(0xFF000080), // Navy
      Color(0xFF006400), // Dark green
      Color(0xFF8B4513), // Brown
      Color(0xFFF0E68C), // Khaki
      Color(0xFFDC143C), // Crimson
      Color(0xFF4B0082), // Indigo
      Color(0xFFFF8C00), // Dark orange
      Color(0xFF2F4F4F), // Dark slate
    ],
  ),
  const _Palette(
    name: 'Heraldic',
    colors: [
      Color(0xFFFFD700), // Or (gold)
      Color(0xFFFFFFFF), // Argent (silver/white)
      Color(0xFF0000FF), // Azure (blue)
      Color(0xFFFF0000), // Gules (red)
      Color(0xFF000000), // Sable (black)
      Color(0xFF008000), // Vert (green)
      Color(0xFF800080), // Purpure (purple)
      Color(0xFF8B4513), // Tenné (tawny)
      Color(0xFFFF7F50), // Sanguine (blood red)
      Color(0xFFD3D3D3), // Cendrée (ash)
      Color(0xFF36454F), // Dark blue-grey
      Color(0xFF704214), // Russet brown
    ],
  ),
];

// ── Widget ────────────────────────────────────────────────────────────────────

class ColorPaletteWidget extends StatefulWidget {
  const ColorPaletteWidget({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
    this.showCustomPicker = true,
    this.initialPalette = 'Stained Glass',
  });

  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  final bool showCustomPicker;
  final String initialPalette;

  @override
  State<ColorPaletteWidget> createState() => _ColorPaletteWidgetState();
}

class _ColorPaletteWidgetState extends State<ColorPaletteWidget> {
  late String _activePalette;

  @override
  void initState() {
    super.initState();
    _activePalette = widget.initialPalette;
  }

  @override
  Widget build(BuildContext context) {
    final palette = _palettes.firstWhere(
      (p) => p.name == _activePalette,
      orElse: () => _palettes.first,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Palette selector ──────────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _palettes.map((p) {
              final isActive = _activePalette == p.name;
              return GestureDetector(
                onTap: () => setState(() => _activePalette = p.name),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFFFD700)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive ? const Color(0xFFFFD700) : Colors.white24,
                    ),
                  ),
                  child: Text(
                    p.name,
                    style: TextStyle(
                      color: isActive ? const Color(0xFF1A0A2E) : Colors.white70,
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
        // ── Color swatches ────────────────────────────────────────────────
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: palette.colors.map((color) {
            final isSelected = widget.selectedColor.value == color.value;
            return GestureDetector(
              onTap: () => widget.onColorSelected(color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: isSelected ? 42 : 36,
                height: isSelected ? 42 : 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.white30,
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.6),
                            blurRadius: 8,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            );
          }).toList(),
        ),
        // ── Custom color picker ───────────────────────────────────────────
        if (widget.showCustomPicker) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _showCustomPicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: widget.selectedColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Custom Color…',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _showCustomPicker(BuildContext context) async {
    Color pickerColor = widget.selectedColor;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2A3A),
        title: const Text(
          'Choose Color',
          style: TextStyle(color: Color(0xFFFFD700), fontFamily: 'Cinzel'),
        ),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (c) => pickerColor = c,
            enableAlpha: false,
            labelTypes: const [],
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: const Color(0xFF1A0A2E),
            ),
            onPressed: () {
              widget.onColorSelected(pickerColor);
              Navigator.of(context).pop();
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }
}
