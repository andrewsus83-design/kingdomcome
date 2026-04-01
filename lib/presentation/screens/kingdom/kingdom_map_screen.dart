import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/core/constants/asset_paths.dart';
import 'package:kingdomcome/data/models/kingdom/building_model.dart';
import 'package:kingdomcome/data/models/kingdom/building_type.dart';
import 'package:kingdomcome/presentation/providers/kingdom_provider.dart';
import 'package:kingdomcome/presentation/providers/saint_provider.dart';
import 'package:kingdomcome/presentation/providers/streak_provider.dart';
import 'package:kingdomcome/presentation/providers/liturgical_calendar_provider.dart';
import 'package:kingdomcome/presentation/widgets/kingdom/building_tile.dart';
import 'package:kingdomcome/presentation/widgets/common/streak_flame_widget.dart';
import 'package:kingdomcome/core/theme/liturgical_colors.dart';

class KingdomMapScreen extends ConsumerStatefulWidget {
  const KingdomMapScreen({super.key});

  @override
  ConsumerState<KingdomMapScreen> createState() => _KingdomMapScreenState();
}

class _KingdomMapScreenState extends ConsumerState<KingdomMapScreen> {
  static const int _gridSize = 5;

  @override
  Widget build(BuildContext context) {
    final kingdomAsync = ref.watch(kingdomNotifierProvider);
    final season = ref.watch(currentSeasonProvider);
    final primaryStreak = ref.watch(primaryStreakProvider);
    final activeSaint = ref.watch(activeSaintProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Background: map image
          Positioned.fill(
            child: Image.asset(
              AssetPaths.mapBackground,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.5,
                    colors: [
                      LiturgicalColors.backgroundFor(season),
                      AppColors.darkSurface,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Map fog overlay
          Positioned.fill(
            child: Image.asset(
              AssetPaths.mapFog,
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.3),
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),

          // Liturgical season banner
          Positioned(
            top: AppSpacing.md,
            left: AppSpacing.md,
            child: _SeasonBadge(season: season),
          ),

          // Active saint portrait
          if (activeSaint != null)
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.md,
              child: _SaintPortrait(saintId: activeSaint.saintId),
            ),

          // Streak flame
          Positioned(
            bottom: AppSpacing.xl + AppSpacing.md,
            right: AppSpacing.md,
            child: primaryStreak != null
                ? StreakFlameWidget(
                    count: primaryStreak.currentStreak,
                    isAtRisk: primaryStreak.isAtRisk,
                  )
                : const SizedBox.shrink(),
          ),

          // Kingdom grid
          Center(
            child: kingdomAsync.when(
              loading: () => const _LoadingGrid(),
              error: (e, _) => _ErrorView(error: e.toString()),
              data: (kingdom) => _KingdomGrid(
                buildings: kingdom.buildings,
                gridSize: _gridSize,
                onBuildingTap: (building) =>
                    context.push('/kingdom/building/${building.id}'),
                onEmptyTap: (x, y) => _showBuildMenu(context, x, y),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBuildMenu(BuildContext context, int x, int y) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BuildMenu(gridX: x, gridY: y),
    );
  }
}

// ── Kingdom Grid ──────────────────────────────────────────────────────────────

class _KingdomGrid extends StatelessWidget {
  final List<BuildingModel> buildings;
  final int gridSize;
  final void Function(BuildingModel) onBuildingTap;
  final void Function(int x, int y) onEmptyTap;

  const _KingdomGrid({
    required this.buildings,
    required this.gridSize,
    required this.onBuildingTap,
    required this.onEmptyTap,
  });

  @override
  Widget build(BuildContext context) {
    final buildingMap = {
      for (final b in buildings) '${b.gridX},${b.gridY}': b,
    };

    return InteractiveViewer(
      minScale: 0.6,
      maxScale: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(gridSize, (row) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(gridSize, (col) {
                final building = buildingMap['$col,$row'];
                return BuildingTile(
                  building: building,
                  onTap: building != null
                      ? () => onBuildingTap(building)
                      : () => onEmptyTap(col, row),
                );
              }),
            );
          }),
        ),
      ),
    );
  }
}

// ── Season Badge ──────────────────────────────────────────────────────────────

class _SeasonBadge extends StatelessWidget {
  final LiturgicalSeason season;
  const _SeasonBadge({required this.season});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: LiturgicalColors.primaryFor(season).withOpacity(0.85),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: AppColors.gold.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.gold, size: 12),
          const SizedBox(width: 4),
          Text(
            LiturgicalColors.displayNameFor(season),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }
}

// ── Saint Portrait ────────────────────────────────────────────────────────────

class _SaintPortrait extends ConsumerWidget {
  final String saintId;
  const _SaintPortrait({required this.saintId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saints = ref.watch(saintNotifierProvider).valueOrNull ?? [];
    final saint = saints.where((s) => s.id == saintId).firstOrNull;
    if (saint == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => context.push('/saints/${saint.id}'),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.gold, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            saint.portraitAssetPath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.deepPurple,
              child: const Icon(Icons.person, color: AppColors.gold, size: 28),
            ),
          ),
        ),
      ).animate().fadeIn(delay: 400.ms),
    );
  }
}

// ── Loading / Error states ────────────────────────────────────────────────────

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: AppColors.gold),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Loading your Kingdom...',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.goldLight),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.crimson, size: 48),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Could not load kingdom',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.ivory,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            error,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.midGrey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Build Menu ────────────────────────────────────────────────────────────────

class _BuildMenu extends ConsumerWidget {
  final int gridX;
  final int gridY;

  const _BuildMenu({required this.gridX, required this.gridY});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
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
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 280,
          child: GridView.count(
            crossAxisCount: 3,
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
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class _BuildingOption extends StatelessWidget {
  final BuildingType type;
  final VoidCallback onTap;

  const _BuildingOption({required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkElevated,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(color: AppColors.goldDark.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              type.iconPath,
              width: 36,
              height: 36,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.business, color: AppColors.gold, size: 32),
            ),
            const SizedBox(height: 4),
            Text(
              type.displayName,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.goldLight,
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
