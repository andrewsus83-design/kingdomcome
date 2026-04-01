import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/core/constants/asset_paths.dart';
import 'package:kingdomcome/core/constants/game_constants.dart';
import 'package:kingdomcome/data/models/kingdom/building_model.dart';
import 'package:kingdomcome/data/models/kingdom/building_type.dart';
import 'package:kingdomcome/presentation/providers/kingdom_provider.dart';
import 'package:kingdomcome/presentation/widgets/common/kingdom_button.dart';
import 'package:kingdomcome/routing/route_names.dart';

class BuildingDetailScreen extends ConsumerWidget {
  final String buildingId;

  const BuildingDetailScreen({super.key, required this.buildingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kingdomAsync = ref.watch(kingdomNotifierProvider);

    return kingdomAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text(e.toString())),
      ),
      data: (kingdom) {
        final building = kingdom.buildings
            .where((b) => b.id == buildingId)
            .firstOrNull;
        if (building == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Building')),
            body: const Center(child: Text('Building not found')),
          );
        }
        return _BuildingDetailView(building: building);
      },
    );
  }
}

class _BuildingDetailView extends ConsumerStatefulWidget {
  final BuildingModel building;
  const _BuildingDetailView({required this.building});

  @override
  ConsumerState<_BuildingDetailView> createState() =>
      _BuildingDetailViewState();
}

class _BuildingDetailViewState extends ConsumerState<_BuildingDetailView>
    with SingleTickerProviderStateMixin {
  bool _upgrading = false;

  @override
  Widget build(BuildContext context) {
    final building = widget.building;
    final type = building.type;
    final isUnderConstruction = building.isUnderConstruction &&
        !building.isConstructionComplete;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.purpleDark, AppColors.darkSurface],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App bar
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: AppColors.purpleDark,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: AppColors.gold),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Building image
                      Image.asset(
                        AssetPaths.buildingSprite(type.name, building.level),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(
                            Icons.business,
                            size: 100,
                            color: AppColors.gold.withOpacity(0.6),
                          ),
                        ),
                      ),
                      // Construction overlay
                      if (isUnderConstruction)
                        Container(
                          color: AppColors.darkSurface.withOpacity(0.6),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: Lottie.asset(
                                    AssetPaths.constructionAnimation,
                                    repeat: true,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.construction,
                                      color: AppColors.gold,
                                      size: 48,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Under Construction',
                                  style: AppTextStyles.headlineSmall.copyWith(
                                    color: AppColors.gold,
                                  ),
                                ),
                                if (building.constructionCompletesAt != null)
                                  _CountdownText(
                                    completesAt:
                                        building.constructionCompletesAt!,
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.md),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Name + level
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            type.displayName,
                            style: AppTextStyles.displaySmall.copyWith(
                              color: AppColors.goldLight,
                            ),
                          ),
                        ),
                        _LevelStars(level: building.level),
                      ],
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: AppSpacing.md),

                    // Description
                    Text(
                      type.description,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.parchment,
                        height: 1.7,
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: AppSpacing.lg),

                    // Unlocks feature
                    _UnlocksCard(type: type),

                    const SizedBox(height: AppSpacing.lg),

                    // Upgrade section
                    if (building.level < 5 && !isUnderConstruction)
                      _UpgradeSection(
                        building: building,
                        isLoading: _upgrading,
                        onUpgrade: _upgrade,
                      ),

                    const SizedBox(height: AppSpacing.xl),

                    // Enter building CTA
                    if (!isUnderConstruction)
                      KingdomButton(
                        label: 'Enter ${type.displayName}',
                        onPressed: () => _enterBuilding(context, type),
                        icon: Icons.login,
                      ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: AppSpacing.xl),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _upgrade() async {
    setState(() => _upgrading = true);
    try {
      await ref
          .read(kingdomNotifierProvider.notifier)
          .upgradeBuilding(widget.building.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upgrade failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _upgrading = false);
    }
  }

  void _enterBuilding(BuildContext context, BuildingType type) {
    switch (type) {
      case BuildingType.cathedral:
      case BuildingType.chapel:
      case BuildingType.oratory:
        context.push(RouteNames.ark);
        break;
      case BuildingType.monastery:
        context.push(RouteNames.soul);
        break;
      case BuildingType.school:
        context.push(RouteNames.academy);
        break;
      case BuildingType.workshop:
        context.push(RouteNames.workshop);
        break;
      case BuildingType.scriptorium:
        context.push(RouteNames.ark);
        break;
      case BuildingType.bellTower:
      case BuildingType.parishHall:
      case BuildingType.garden:
        context.push(RouteNames.soul);
        break;
    }
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _LevelStars extends StatelessWidget {
  final int level;
  const _LevelStars({required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < level ? Icons.star : Icons.star_border,
          color: AppColors.gold,
          size: 18,
        );
      }),
    );
  }
}

class _UnlocksCard extends StatelessWidget {
  final BuildingType type;
  const _UnlocksCard({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.deepPurple.withOpacity(0.4),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.goldDark.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_open, color: AppColors.gold, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Unlocks: ${_featureLabel(type)}',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.goldLight,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  String _featureLabel(BuildingType type) => type.description;
}

class _UpgradeSection extends StatelessWidget {
  final BuildingModel building;
  final bool isLoading;
  final VoidCallback onUpgrade;

  const _UpgradeSection({
    required this.building,
    required this.isLoading,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final costs = kBuildingCosts[building.type.databaseValue];
    final nextLevelCost =
        costs != null && building.level < costs.length ? costs[building.level] : null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upgrade to Level ${building.level + 1}',
            style:
                AppTextStyles.headlineSmall.copyWith(color: AppColors.goldLight),
          ),
          if (nextLevelCost != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _CostChip(
                    icon: Icons.star,
                    value: nextLevelCost.holyPoints,
                    color: AppColors.holyPoints),
                const SizedBox(width: AppSpacing.sm),
                _CostChip(
                    icon: Icons.monetization_on,
                    value: nextLevelCost.faithCoins,
                    color: AppColors.faithCoins),
                const SizedBox(width: AppSpacing.sm),
                _CostChip(
                    icon: Icons.auto_awesome,
                    value: nextLevelCost.grace,
                    color: AppColors.grace),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          KingdomButton(
            label: 'Upgrade',
            onPressed: isLoading ? null : onUpgrade,
            isLoading: isLoading,
            icon: Icons.arrow_upward,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }
}

class _CostChip extends StatelessWidget {
  final IconData icon;
  final int value;
  final Color color;

  const _CostChip({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            value.toString(),
            style:
                AppTextStyles.labelMedium.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _CountdownText extends StatefulWidget {
  final DateTime completesAt;
  const _CountdownText({required this.completesAt});

  @override
  State<_CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<_CountdownText> {
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    // Tick every second
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(_updateRemaining);
      return _remaining.inSeconds > 0;
    });
  }

  void _updateRemaining() {
    _remaining = widget.completesAt.difference(DateTime.now());
    if (_remaining.isNegative) _remaining = Duration.zero;
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining == Duration.zero) {
      return Text(
        'Ready to collect!',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.forestGreen),
      );
    }
    final h = _remaining.inHours;
    final m = _remaining.inMinutes.remainder(60);
    final s = _remaining.inSeconds.remainder(60);
    return Text(
      '${h}h ${m}m ${s}s remaining',
      style: AppTextStyles.bodySmall.copyWith(color: AppColors.goldLight),
    );
  }
}
