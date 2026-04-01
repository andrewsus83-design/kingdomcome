import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/data/models/kingdom/building_model.dart';
import 'package:kingdomcome/data/models/kingdom/building_type.dart';
import 'package:kingdomcome/data/models/resources/resource_model.dart';
import 'package:kingdomcome/data/models/saint/saint_model.dart';
import 'package:kingdomcome/presentation/providers/kingdom_provider.dart';
import 'package:kingdomcome/presentation/providers/saint_provider.dart';
import 'package:kingdomcome/presentation/providers/resource_provider.dart';
import 'package:kingdomcome/presentation/screens/kingdom/saint_chat_sheet.dart';
import 'package:kingdomcome/routing/route_names.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Kingdom Screen — Lego Creative Sandbox + Clash of Clans
// ─────────────────────────────────────────────────────────────────────────────

/// The Kingdom — the hero, center tab of the app.
///
/// Features:
/// - Isometric-style 5×5 expandable grid with Lego-block buildings
/// - Saint Residents wandering the grid as animated avatar dots
/// - Brick Inventory bar (Wood/Gold/Stone mapping to FaithCoins/HolyPoints/Grace)
/// - Top bar: Kingdom name + level + resident count
/// - Blueprint Mode button for famous Catholic structure overlays
/// - Tap building → BuildingDetail, Tap empty tile → Build menu
/// - Tap saint resident → SaintChatSheet
class KingdomScreen extends ConsumerStatefulWidget {
  const KingdomScreen({super.key});

  @override
  ConsumerState<KingdomScreen> createState() => _KingdomScreenState();
}

class _KingdomScreenState extends ConsumerState<KingdomScreen> {
  static const int _gridSize = 5;
  bool _blueprintMode = false;

  @override
  Widget build(BuildContext context) {
    final kingdomAsync = ref.watch(kingdomNotifierProvider);
    final resources = ref.watch(resourceNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A3320), // Dark grass green
      body: Stack(
        children: [
          // Ground texture / grass background
          Positioned.fill(child: _GroundBackground()),

          // Main column layout
          Column(
            children: [
              // Top Kingdom info bar
              kingdomAsync.when(
                loading: () => const _KingdomTopBarSkeleton(),
                error: (_, __) => const _KingdomTopBarSkeleton(),
                data: (kingdom) => _KingdomTopBar(
                  kingdomName: kingdom.name,
                  kingdomLevel: kingdom.level,
                  residentCount: _countResidents(
                      ref.read(userSaintsNotifierProvider).valueOrNull ?? []),
                  blueprintMode: _blueprintMode,
                  onBlueprintTap: () => setState(
                      () => _blueprintMode = !_blueprintMode),
                ),
              ),

              // Grid area
              Expanded(
                child: kingdomAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.gold),
                  ),
                  error: (e, _) => _ErrorView(error: e.toString()),
                  data: (kingdom) => Stack(
                    children: [
                      // Interactive grid
                      _KingdomGrid(
                        buildings: kingdom.buildings,
                        gridSize: _gridSize,
                        blueprintMode: _blueprintMode,
                        onBuildingTap: (building) =>
                            context.push(RouteNames.buildingDetailPath(building.id)),
                        onEmptyTap: (x, y) => _showBuildMenu(context, x, y),
                      ),

                      // Saint residents overlay
                      _SaintResidentsOverlay(
                        onSaintTap: (saint) => _showSaintChat(context, saint),
                      ),

                      // Blueprint mode overlay
                      if (_blueprintMode)
                        _BlueprintModeOverlay(
                          onOpenFull: () =>
                              context.push(RouteNames.blueprintMode),
                        ),
                    ],
                  ),
                ),
              ),

              // Brick Inventory bar
              _BrickInventoryBar(resources: resources),
            ],
          ),
        ],
      ),
    );
  }

  int _countResidents(List<dynamic> userSaints) => userSaints.length;

  void _showBuildMenu(BuildContext context, int x, int y) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _BuildMenuSheet(gridX: x, gridY: y),
    );
  }

  void _showSaintChat(BuildContext context, SaintModel saint) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SaintChatBottomSheet(saint: saint),
    );
  }
}

// ── Ground Background ─────────────────────────────────────────────────────────

class _GroundBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A3320),
            Color(0xFF243D28),
            Color(0xFF1A3320),
          ],
        ),
      ),
      child: CustomPaint(
        painter: _GridDotPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _GridDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x15FFFFFF)
      ..strokeWidth = 1;
    const spacing = 24.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Kingdom Top Bar ───────────────────────────────────────────────────────────

class _KingdomTopBar extends StatelessWidget {
  final String kingdomName;
  final int kingdomLevel;
  final int residentCount;
  final bool blueprintMode;
  final VoidCallback onBlueprintTap;

  const _KingdomTopBar({
    required this.kingdomName,
    required this.kingdomLevel,
    required this.residentCount,
    required this.blueprintMode,
    required this.onBlueprintTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.purpleDark.withOpacity(0.9),
        border: const Border(
            bottom: BorderSide(color: AppColors.goldDark, width: 1)),
      ),
      child: Row(
        children: [
          // Kingdom name + level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kingdomName,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.goldLight,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.2),
                        borderRadius: AppSpacing.borderRadiusSm,
                        border: Border.all(
                            color: AppColors.gold.withOpacity(0.4)),
                      ),
                      child: Text(
                        'Lv. $kingdomLevel',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(Icons.person,
                        color: AppColors.midGrey, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      '$residentCount residents',
                      style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.midGrey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Blueprint mode toggle
          GestureDetector(
            onTap: onBlueprintTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: blueprintMode
                    ? AppColors.holyPoints.withOpacity(0.2)
                    : AppColors.darkCard,
                borderRadius: AppSpacing.borderRadiusSm,
                border: Border.all(
                  color: blueprintMode
                      ? AppColors.holyPoints
                      : AppColors.goldDark.withOpacity(0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.architecture,
                    color: blueprintMode
                        ? AppColors.holyPoints
                        : AppColors.goldLight,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Blueprint',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: blueprintMode
                          ? AppColors.holyPoints
                          : AppColors.goldLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KingdomTopBarSkeleton extends StatelessWidget {
  const _KingdomTopBarSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: AppColors.purpleDark.withOpacity(0.9),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
              color: AppColors.gold, strokeWidth: 2),
        ),
      ),
    );
  }
}

// ── Kingdom Grid ──────────────────────────────────────────────────────────────

class _KingdomGrid extends StatelessWidget {
  final List<BuildingModel> buildings;
  final int gridSize;
  final bool blueprintMode;
  final void Function(BuildingModel) onBuildingTap;
  final void Function(int x, int y) onEmptyTap;

  const _KingdomGrid({
    required this.buildings,
    required this.gridSize,
    required this.blueprintMode,
    required this.onBuildingTap,
    required this.onEmptyTap,
  });

  @override
  Widget build(BuildContext context) {
    final buildingMap = {
      for (final b in buildings) '${b.gridX},${b.gridY}': b,
    };

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 2.5,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(gridSize, (row) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(gridSize, (col) {
                  final building = buildingMap['$col,$row'];
                  return _GridTile(
                    building: building,
                    blueprintMode: blueprintMode,
                    onTap: building != null
                        ? () => onBuildingTap(building)
                        : () => onEmptyTap(col, row),
                  );
                }),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Grid Tile ─────────────────────────────────────────────────────────────────

class _GridTile extends StatelessWidget {
  final BuildingModel? building;
  final bool blueprintMode;
  final VoidCallback onTap;

  const _GridTile({
    required this.building,
    required this.blueprintMode,
    required this.onTap,
  });

  static const double _tileSize = 68.0;

  Color get _buildingColor {
    if (building == null) return Colors.transparent;
    switch (building!.type) {
      case BuildingType.chapel:
        return const Color(0xFF8B4DB8);
      case BuildingType.monastery:
        return const Color(0xFF5A6E4A);
      case BuildingType.school:
        return const Color(0xFF4A6E8B);
      case BuildingType.garden:
        return const Color(0xFF4A8B5A);
      case BuildingType.scriptorium:
        return const Color(0xFF8B6B4A);
      case BuildingType.bellTower:
        return const Color(0xFF6B4A4A);
      case BuildingType.oratory:
        return const Color(0xFF4A7B8B);
      case BuildingType.workshop:
        return const Color(0xFF8B7A4A);
      case BuildingType.cathedral:
        return const Color(0xFF6B3A8B);
      case BuildingType.parishHall:
        return const Color(0xFF4A5A6E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasBuilding = building != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _tileSize,
        height: _tileSize,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: blueprintMode
              ? AppColors.holyPoints.withOpacity(0.05)
              : hasBuilding
                  ? _buildingColor.withOpacity(0.2)
                  : const Color(0xFF243D28),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: blueprintMode
                ? AppColors.holyPoints.withOpacity(0.3)
                : hasBuilding
                    ? _buildingColor.withOpacity(0.6)
                    : AppColors.sage.withOpacity(0.2),
            width: hasBuilding ? 1.5 : 1,
          ),
          boxShadow: hasBuilding && !blueprintMode
              ? [
                  BoxShadow(
                    color: _buildingColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: hasBuilding
            ? _LegoBuilding(building: building!, blueprintMode: blueprintMode)
            : _EmptyTile(blueprintMode: blueprintMode),
      ),
    );
  }
}

class _LegoBuilding extends StatelessWidget {
  final BuildingModel building;
  final bool blueprintMode;

  const _LegoBuilding(
      {required this.building, required this.blueprintMode});

  Color get _primaryColor {
    switch (building.type) {
      case BuildingType.chapel:
        return const Color(0xFFB87FD4);
      case BuildingType.monastery:
        return const Color(0xFF82A872);
      case BuildingType.school:
        return const Color(0xFF6FA4C8);
      case BuildingType.garden:
        return const Color(0xFF72C882);
      case BuildingType.scriptorium:
        return const Color(0xFFC8A47A);
      case BuildingType.bellTower:
        return const Color(0xFFC87272);
      case BuildingType.oratory:
        return const Color(0xFF72B4C8);
      case BuildingType.workshop:
        return const Color(0xFFC8BA72);
      case BuildingType.cathedral:
        return const Color(0xFF9B6FD4);
      case BuildingType.parishHall:
        return const Color(0xFF6FA4C8);
    }
  }

  String get _buildingEmoji => building.type.emoji;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Lego block body
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Studs row (top of lego block)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                building.level.clamp(1, 3),
                (i) => Container(
                  width: 10,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: blueprintMode
                        ? AppColors.holyPoints.withOpacity(0.5)
                        : _primaryColor,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(3)),
                    border: Border.all(
                      color: blueprintMode
                          ? AppColors.holyPoints
                          : _primaryColor.withOpacity(0.4),
                      width: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            // Block body
            Container(
              height: 34,
              width: 56,
              decoration: BoxDecoration(
                color: blueprintMode
                    ? AppColors.holyPoints.withOpacity(0.1)
                    : _primaryColor.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(2),
                  topRight: Radius.circular(2),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
                border: Border.all(
                  color: blueprintMode
                      ? AppColors.holyPoints.withOpacity(0.5)
                      : _primaryColor.withOpacity(0.6),
                ),
                boxShadow: blueprintMode
                    ? null
                    : [
                        BoxShadow(
                          color: _primaryColor.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(2, 4),
                        ),
                      ],
              ),
              child: Center(
                child: Text(
                  _buildingEmoji,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
        // Under construction spinner
        if (building.isUnderConstruction)
          Positioned(
            top: 4,
            right: 4,
            child: SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                color: AppColors.faithCoins,
                strokeWidth: 1.5,
              ),
            ),
          ),
        // Level indicator
        Positioned(
          bottom: 2,
          right: 4,
          child: Text(
            'L${building.level}',
            style: AppTextStyles.labelSmall.copyWith(
              color: blueprintMode
                  ? AppColors.holyPoints
                  : _primaryColor,
              fontSize: 7,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyTile extends StatelessWidget {
  final bool blueprintMode;
  const _EmptyTile({required this.blueprintMode});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.add,
        color: blueprintMode
            ? AppColors.holyPoints.withOpacity(0.4)
            : AppColors.sage.withOpacity(0.4),
        size: 20,
      ),
    );
  }
}

// ── Saint Residents Overlay ───────────────────────────────────────────────────

class _SaintResidentsOverlay extends ConsumerStatefulWidget {
  final void Function(SaintModel) onSaintTap;
  const _SaintResidentsOverlay({required this.onSaintTap});

  @override
  ConsumerState<_SaintResidentsOverlay> createState() =>
      _SaintResidentsOverlayState();
}

class _SaintResidentsOverlayState
    extends ConsumerState<_SaintResidentsOverlay> {
  final Map<String, Offset> _saintPositions = {};
  final math.Random _rng = math.Random();
  Timer? _moveTimer;

  @override
  void initState() {
    super.initState();
    _moveTimer = Timer.periodic(
      const Duration(seconds: 6),
      (_) => _shufflePositions(),
    );
  }

  @override
  void dispose() {
    _moveTimer?.cancel();
    super.dispose();
  }

  void _shufflePositions() {
    final userSaints =
        ref.read(userSaintsNotifierProvider).valueOrNull ?? [];
    if (!mounted) return;
    setState(() {
      for (final us in userSaints) {
        _saintPositions[us.saintId] = Offset(
          0.05 + _rng.nextDouble() * 0.85,
          0.1 + _rng.nextDouble() * 0.75,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userSaintsAsync = ref.watch(userSaintsNotifierProvider);
    final allSaints = ref.watch(saintNotifierProvider).valueOrNull ?? [];
    final userSaints = userSaintsAsync.valueOrNull ?? [];

    if (userSaints.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(builder: (ctx, constraints) {
      return Stack(
        children: userSaints.map((us) {
          final saint = allSaints.firstWhereOrNull((s) => s.id == us.saintId);
          if (saint == null) return const SizedBox.shrink();

          // Initialize position if not set
          if (!_saintPositions.containsKey(us.saintId)) {
            _saintPositions[us.saintId] = Offset(
              0.05 + _rng.nextDouble() * 0.85,
              0.1 + _rng.nextDouble() * 0.75,
            );
          }

          final frac = _saintPositions[us.saintId]!;
          final left = frac.dx * constraints.maxWidth - 16;
          final top = frac.dy * constraints.maxHeight - 16;

          return AnimatedPositioned(
            duration: Duration(
                milliseconds: 4000 + _rng.nextInt(2000)),
            curve: Curves.easeInOutSine,
            left: left.clamp(0, constraints.maxWidth - 32),
            top: top.clamp(0, constraints.maxHeight - 32),
            child: GestureDetector(
              onTap: () => widget.onSaintTap(saint),
              child: _SaintAvatarDot(
                saint: saint,
                rarity: saint.rarity,
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}

class _SaintAvatarDot extends StatelessWidget {
  final SaintModel saint;
  final String rarity;

  const _SaintAvatarDot({required this.saint, required this.rarity});

  Color get _rarityColor {
    switch (rarity.toLowerCase()) {
      case 'legendary':
        return AppColors.faithCoins;
      case 'epic':
        return AppColors.purpleLight;
      case 'rare':
        return AppColors.holyPoints;
      case 'uncommon':
        return AppColors.sage;
      default:
        return AppColors.parchmentDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _rarityColor, width: 1.5),
        color: AppColors.darkCard,
        boxShadow: [
          BoxShadow(
            color: _rarityColor.withOpacity(0.4),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          saint.portraitAssetPath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(
            child: Text(
              saint.name[0],
              style: TextStyle(
                color: _rarityColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 500.ms);
  }
}

// ── Blueprint Mode Quick Overlay ──────────────────────────────────────────────

class _BlueprintModeOverlay extends StatelessWidget {
  final VoidCallback onOpenFull;
  const _BlueprintModeOverlay({required this.onOpenFull});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: false,
      child: Positioned(
        bottom: AppSpacing.md,
        left: AppSpacing.md,
        right: AppSpacing.md,
        child: GestureDetector(
          onTap: onOpenFull,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.holyPoints.withOpacity(0.15),
              borderRadius: AppSpacing.borderRadiusMd,
              border: Border.all(color: AppColors.holyPoints.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.holyPoints.withOpacity(0.2),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.architecture,
                    color: AppColors.holyPoints, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Blueprint Mode — Tap to open famous structures',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.holyPoints,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    color: AppColors.holyPoints, size: 14),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.2),
        ),
      ),
    );
  }
}

// ── Brick Inventory Bar ───────────────────────────────────────────────────────

class _BrickInventoryBar extends StatelessWidget {
  final AsyncValue<ResourceModel> resources;

  const _BrickInventoryBar({required this.resources});

  @override
  Widget build(BuildContext context) {
    final res = resources.valueOrNull;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.purpleDark,
        border: Border(top: BorderSide(color: AppColors.goldDark, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BrickItem(
            emoji: '🪵',
            label: 'Wood',
            sublabel: 'FaithCoins',
            value: res?.faithCoins ?? 0,
            color: const Color(0xFF8B6914),
          ),
          _InventoryDivider(),
          _BrickItem(
            emoji: '✨',
            label: 'Gold',
            sublabel: 'HolyPoints',
            value: res?.holyPoints ?? 0,
            color: AppColors.faithCoins,
          ),
          _InventoryDivider(),
          _BrickItem(
            emoji: '🪨',
            label: 'Stone',
            sublabel: 'Grace',
            value: res?.grace ?? 0,
            color: AppColors.midGrey,
          ),
        ],
      ),
    );
  }
}

class _BrickItem extends StatelessWidget {
  final String emoji;
  final String label;
  final String sublabel;
  final int value;
  final Color color;

  const _BrickItem({
    required this.emoji,
    required this.label,
    required this.sublabel,
    required this.value,
    required this.color,
  });

  String _format(int v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(
              _format(value),
              style: AppTextStyles.labelLarge.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: color.withOpacity(0.8),
            fontWeight: FontWeight.w600,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

class _InventoryDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: AppColors.goldDark.withOpacity(0.3),
    );
  }
}

// ── Build Menu Sheet ──────────────────────────────────────────────────────────

class _BuildMenuSheet extends ConsumerWidget {
  final int gridX;
  final int gridY;

  const _BuildMenuSheet({required this.gridX, required this.gridY});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.md),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.warmGrey,
              borderRadius: AppSpacing.borderRadiusSm,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Choose a Building',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.goldLight,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Place on grid position ($gridX, $gridY)',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.midGrey),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 260,
            child: GridView.count(
              crossAxisCount: 4,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              children: BuildingType.values.map((type) {
                return _BuildingOption(
                  type: type,
                  onTap: () async {
                    Navigator.of(context).pop();
                    await ref
                        .read(kingdomNotifierProvider.notifier)
                        .buildStructure(type, gridX, gridY);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildingOption extends StatelessWidget {
  final BuildingType type;
  final VoidCallback onTap;

  const _BuildingOption({required this.type, required this.onTap});

  String get _emoji => type.emoji;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkElevated,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(color: AppColors.goldDark.withOpacity(0.4)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              type.displayName,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.goldLight,
                fontSize: 8,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error View ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.castle, color: AppColors.crimson, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Could not load your Kingdom',
              style: AppTextStyles.headlineSmall.copyWith(color: AppColors.ivory),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.midGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Extension ─────────────────────────────────────────────────────────────────

extension _ListExt<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
