import 'package:flutter/material.dart';

// ── Tool enum ─────────────────────────────────────────────────────────────────

enum CanvasTool { fill, draw, erase, select }

extension CanvasToolExt on CanvasTool {
  String get label => switch (this) {
        CanvasTool.fill => 'Fill',
        CanvasTool.draw => 'Draw',
        CanvasTool.erase => 'Erase',
        CanvasTool.select => 'Select',
      };

  IconData get icon => switch (this) {
        CanvasTool.fill => Icons.format_color_fill,
        CanvasTool.draw => Icons.edit,
        CanvasTool.erase => Icons.auto_fix_normal,
        CanvasTool.select => Icons.select_all,
      };
}

// ── Widget ────────────────────────────────────────────────────────────────────

class CanvasToolbar extends StatelessWidget {
  const CanvasToolbar({
    super.key,
    required this.activeTool,
    required this.onToolSelected,
    required this.onUndo,
    required this.onRedo,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onSave,
    required this.onAiGenerate,
    this.onTemplateSelect,
    this.canUndo = true,
    this.canRedo = false,
    this.isSaving = false,
    this.isGenerating = false,
    this.orientation = Axis.vertical,
  });

  final CanvasTool activeTool;
  final ValueChanged<CanvasTool> onToolSelected;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onSave;
  final VoidCallback onAiGenerate;
  final VoidCallback? onTemplateSelect;
  final bool canUndo;
  final bool canRedo;
  final bool isSaving;
  final bool isGenerating;
  final Axis orientation;

  @override
  Widget build(BuildContext context) {
    final tools = [
      _buildToolButton(CanvasTool.fill),
      _buildToolButton(CanvasTool.draw),
      _buildToolButton(CanvasTool.erase),
      _buildToolButton(CanvasTool.select),
    ];

    final actions = [
      _buildDivider(),
      _buildActionButton(
        icon: Icons.undo,
        tooltip: 'Undo',
        onTap: canUndo ? onUndo : null,
        enabled: canUndo,
      ),
      _buildActionButton(
        icon: Icons.redo,
        tooltip: 'Redo',
        onTap: canRedo ? onRedo : null,
        enabled: canRedo,
      ),
      _buildDivider(),
      _buildActionButton(
        icon: Icons.zoom_in,
        tooltip: 'Zoom In',
        onTap: onZoomIn,
      ),
      _buildActionButton(
        icon: Icons.zoom_out,
        tooltip: 'Zoom Out',
        onTap: onZoomOut,
      ),
      if (onTemplateSelect != null) ...[
        _buildDivider(),
        _buildActionButton(
          icon: Icons.grid_view,
          tooltip: 'Templates',
          onTap: onTemplateSelect!,
          color: const Color(0xFF3498DB),
        ),
      ],
      _buildDivider(),
      _buildSaveButton(),
      _buildAiButton(),
    ];

    final children = [...tools, ...actions];

    if (orientation == Axis.vertical) {
      return Container(
        width: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF1A2A3A),
          border: const Border(right: BorderSide(color: Colors.white12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
            ),
          ],
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: children,
        ),
      );
    }

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A3A),
        border: const Border(top: BorderSide(color: Colors.white12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: children,
      ),
    );
  }

  Widget _buildToolButton(CanvasTool tool) {
    final isActive = activeTool == tool;

    return Tooltip(
      message: tool.label,
      child: GestureDetector(
        onTap: () => onToolSelected(tool),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: orientation == Axis.vertical ? 44 : 44,
          height: orientation == Axis.vertical ? 44 : 44,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFFFD700).withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isActive
                ? Border.all(color: const Color(0xFFFFD700), width: 1.5)
                : null,
          ),
          child: Icon(
            tool.icon,
            color: isActive ? const Color(0xFFFFD700) : Colors.white60,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onTap,
    bool enabled = true,
    Color color = Colors.white60,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          opacity: enabled ? 1.0 : 0.3,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Tooltip(
      message: 'Save',
      child: GestureDetector(
        onTap: isSaving ? null : onSave,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF27AE60).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF27AE60).withOpacity(0.5)),
          ),
          child: isSaving
              ? const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF27AE60),
                    ),
                  ),
                )
              : const Icon(Icons.save, color: Color(0xFF27AE60), size: 20),
        ),
      ),
    );
  }

  Widget _buildAiButton() {
    return Tooltip(
      message: 'Generate with AI',
      child: GestureDetector(
        onTap: isGenerating ? null : onAiGenerate,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isGenerating
                  ? [Colors.white24, Colors.white12]
                  : [
                      const Color(0xFF9B59B6),
                      const Color(0xFF3498DB),
                    ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: isGenerating
              ? const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return orientation == Axis.vertical
        ? Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.white12,
          )
        : Container(
            width: 1,
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            color: Colors.white12,
          );
  }
}
