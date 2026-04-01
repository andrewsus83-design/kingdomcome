import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/presentation/providers/kingdom_provider.dart';
import 'package:kingdomcome/data/models/kingdom/building_type.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Blueprint data model
// ─────────────────────────────────────────────────────────────────────────────

enum _BlueprintStatus { available, inProgress, locked, comingSoon }

class _Blueprint {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final int requiredKingdomLevel;
  final Map<BuildingType, int> requiredBuildings; // type → required level
  final int woodCost; // FaithCoins
  final int goldCost; // HolyPoints
  final int stoneCost; // Grace
  final _BlueprintStatus status;
  final String? lore;

  const _Blueprint({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.requiredKingdomLevel,
    required this.requiredBuildings,
    required this.woodCost,
    required this.goldCost,
    required this.stoneCost,
    required this.status,
    this.lore,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Blueprint data
// ─────────────────────────────────────────────────────────────────────────────

const _blueprints = [
  _Blueprint(
    id: 'temple_of_solomon',
    name: 'Temple of Solomon',
    description:
        'Build the magnificent Temple described in 1 Kings. The heart of ancient Israelite worship, adorned with gold and cedar.',
    emoji: '🏛️',
    requiredKingdomLevel: 5,
    requiredBuildings: {
      BuildingType.church: 5,
      BuildingType.library: 3,
      BuildingType.tower: 2,
    },
    woodCost: 500,
    goldCost: 1000,
    stoneCost: 750,
    status: _BlueprintStatus.locked,
    lore:
        '"He built the House of the Lord." — 1 Kings 6:2 (NABRE)',
  ),
  _Blueprint(
    id: 'nativity_stable',
    name: 'Nativity Stable',
    description:
        'The humble stable in Bethlehem where the King of Kings was born. Available during the Christmas season.',
    emoji: '⭐',
    requiredKingdomLevel: 1,
    requiredBuildings: {BuildingType.church: 1},
    woodCost: 50,
    goldCost: 100,
    stoneCost: 30,
    status: _BlueprintStatus.available,
    lore:
        '"She gave birth to her firstborn son and wrapped him in swaddling clothes." — Luke 2:7',
  ),
  _Blueprint(
    id: 'st_peters_basilica',
    name: "St. Peter's Basilica",
    description:
        'The greatest church in Christendom, built over the tomb of Saint Peter the Apostle. The ultimate endgame structure.',
    emoji: '⛪',
    requiredKingdomLevel: 10,
    requiredBuildings: {
      BuildingType.church: 5,
      BuildingType.monastery: 5,
      BuildingType.library: 5,
      BuildingType.tower: 5,
    },
    woodCost: 2000,
    goldCost: 5000,
    stoneCost: 3000,
    status: _BlueprintStatus.comingSoon,
    lore:
        '"You are Peter, and upon this rock I will build my church." — Matthew 16:18',
  ),
  _Blueprint(
    id: 'noahs_ark_replica',
    name: "Noah's Ark Replica",
    description:
        'Build a replica of Noah\'s great Ark. Connects to The Ark tab and unlocks special Bible journey nodes.',
    emoji: '⛵',
    requiredKingdomLevel: 3,
    requiredBuildings: {
      BuildingType.library: 2,
      BuildingType.tower: 1,
    },
    woodCost: 300,
    goldCost: 200,
    stoneCost: 150,
    status: _BlueprintStatus.available,
    lore:
        '"Make yourself an ark of gopherwood." — Genesis 6:14 (NABRE)',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Blueprint Mode Screen
// ─────────────────────────────────────────────────────────────────────────────

/// Full-screen Blueprint Mode showing available Catholic structure blueprints.
///
/// Features:
/// - Semi-transparent blueprint card grid
/// - Each blueprint: name, emoji, required level, resource cost, progress tracker
/// - "Build This" button for available blueprints
/// - Coming Soon locked cards
/// - Progress: how many required buildings are already placed + at required level
class BlueprintModeScreen extends ConsumerWidget {
  const BlueprintModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kingdomAsync = ref.watch(kingdomNotifierProvider);
    final kingdomLevel = kingdomAsync.valueOrNull?.level ?? 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628), // Blueprint dark blue
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: AppColors.holyPoints),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Blueprint Mode',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.holyPoints,
            fontFamily: 'Cinzel',
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.md),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.holyPoints.withOpacity(0.1),
              borderRadius: AppSpacing.borderRadiusSm,
              border: Border.all(
                  color: AppColors.holyPoints.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.architecture,
                    color: AppColors.holyPoints, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Lv. $kingdomLevel',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.holyPoints,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header description
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.holyPoints.withOpacity(0.05),
              border: const Border(
                bottom: BorderSide(
                    color: Color(0x30FFFFFF), width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.holyPoints, size: 16),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Place famous Catholic structures in your Kingdom. '
                    'Blueprints require specific buildings at minimum levels.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.holyPoints.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Blueprint list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _blueprints.length,
              itemBuilder: (ctx, i) {
                final bp = _blueprints[i];
                return _BlueprintCard(
                  blueprint: bp,
                  kingdomLevel: kingdomLevel,
                  kingdomBuildings:
                      kingdomAsync.valueOrNull?.buildings ?? [],
                  animationIndex: i,
                ).animate(delay: Duration(milliseconds: i * 100)).fadeIn().slideY(begin: 0.1);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Blueprint Card ────────────────────────────────────────────────────────────

class _BlueprintCard extends ConsumerWidget {
  final _Blueprint blueprint;
  final int kingdomLevel;
  final List buildings; // List<BuildingModel>
  final int animationIndex;

  const _BlueprintCard({
    required this.blueprint,
    required this.kingdomLevel,
    required this.buildings,
    required this.animationIndex,
  });

  bool get _meetsLevelRequirement =>
      kingdomLevel >= blueprint.requiredKingdomLevel;

  /// Returns a map of BuildingType → achieved level (0 if not placed).
  Map<BuildingType, int> _achievedBuildingLevels() {
    final result = <BuildingType, int>{};
    for (final b in buildings) {
      try {
        final type = b.type as BuildingType;
        final level = b.level as int;
        if (!result.containsKey(type) || result[type]! < level) {
          result[type] = level;
        }
      } catch (_) {}
    }
    return result;
  }

  int _completedRequirements() {
    final achieved = _achievedBuildingLevels();
    int count = 0;
    for (final entry in blueprint.requiredBuildings.entries) {
      final achievedLevel = achieved[entry.key] ?? 0;
      if (achievedLevel >= entry.value) count++;
    }
    return count;
  }

  Color get _statusColor {
    switch (blueprint.status) {
      case _BlueprintStatus.available:
        return AppColors.sage;
      case _BlueprintStatus.inProgress:
        return AppColors.faithCoins;
      case _BlueprintStatus.locked:
        return AppColors.midGrey;
      case _BlueprintStatus.comingSoon:
        return AppColors.purpleLight;
    }
  }

  String get _statusLabel {
    switch (blueprint.status) {
      case _BlueprintStatus.available:
        return 'AVAILABLE';
      case _BlueprintStatus.inProgress:
        return 'IN PROGRESS';
      case _BlueprintStatus.locked:
        return 'LOCKED';
      case _BlueprintStatus.comingSoon:
        return 'COMING SOON';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achieved = _achievedBuildingLevels();
    final completedReqs = _completedRequirements();
    final totalReqs = blueprint.requiredBuildings.length;
    final isLocked = blueprint.status == _BlueprintStatus.locked ||
        blueprint.status == _BlueprintStatus.comingSoon ||
        !_meetsLevelRequirement;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: isLocked
            ? const Color(0xFF0D1F3A)
            : const Color(0xFF0D2A3A),
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isLocked
              ? AppColors.holyPoints.withOpacity(0.1)
              : AppColors.holyPoints.withOpacity(0.4),
          width: isLocked ? 1 : 1.5,
        ),
        boxShadow: isLocked
            ? null
            : [
                BoxShadow(
                  color: AppColors.holyPoints.withOpacity(0.1),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Blueprint emoji in circle
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isLocked
                        ? const Color(0xFF0D1628)
                        : AppColors.holyPoints.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isLocked
                          ? AppColors.holyPoints.withOpacity(0.1)
                          : AppColors.holyPoints.withOpacity(0.4),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      blueprint.emoji,
                      style: TextStyle(
                        fontSize: 24,
                        color: isLocked ? null : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        blueprint.name,
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: isLocked
                              ? AppColors.midGrey
                              : const Color(0xFFB8D4FF),
                          fontFamily: 'Cinzel',
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _statusColor.withOpacity(0.1),
                              borderRadius: AppSpacing.borderRadiusSm,
                              border: Border.all(
                                  color:
                                      _statusColor.withOpacity(0.3)),
                            ),
                            child: Text(
                              _statusLabel,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: _statusColor,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Lv. ${blueprint.requiredKingdomLevel}+ required',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: _meetsLevelRequirement
                                  ? AppColors.sage
                                  : AppColors.midGrey,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              blueprint.description,
              style: AppTextStyles.bodySmall.copyWith(
                color: isLocked
                    ? AppColors.midGrey
                    : AppColors.parchmentDark,
                height: 1.5,
              ),
            ),
          ),

          if (blueprint.lore != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                blueprint.lore!,
                style: AppTextStyles.scriptureQuote.copyWith(
                  color: isLocked
                      ? AppColors.midGrey.withOpacity(0.5)
                      : AppColors.holyPoints.withOpacity(0.7),
                  fontSize: 11,
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          // Requirements section
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Requirements:',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isLocked
                            ? AppColors.midGrey
                            : const Color(0xFFB8D4FF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$completedReqs / $totalReqs',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: completedReqs == totalReqs
                            ? AppColors.sage
                            : AppColors.midGrey,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: blueprint.requiredBuildings.entries
                      .map((entry) {
                    final achievedLevel = achieved[entry.key] ?? 0;
                    final met = achievedLevel >= entry.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: met
                            ? AppColors.forestGreen.withOpacity(0.15)
                            : const Color(0xFF0D1628),
                        borderRadius: AppSpacing.borderRadiusSm,
                        border: Border.all(
                          color: met
                              ? AppColors.sage.withOpacity(0.4)
                              : AppColors.holyPoints.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (met)
                            const Icon(Icons.check,
                                color: AppColors.sage, size: 10)
                          else
                            Icon(Icons.close,
                                color: AppColors.midGrey
                                    .withOpacity(0.5),
                                size: 10),
                          const SizedBox(width: 3),
                          Text(
                            '${entry.key.displayName} Lv.${entry.value}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: met
                                  ? AppColors.sage
                                  : AppColors.midGrey,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Resource cost
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                _CostChip(
                    emoji: '🪵',
                    value: blueprint.woodCost,
                    isLocked: isLocked),
                const SizedBox(width: AppSpacing.xs),
                _CostChip(
                    emoji: '✨',
                    value: blueprint.goldCost,
                    isLocked: isLocked),
                const SizedBox(width: AppSpacing.xs),
                _CostChip(
                    emoji: '🪨',
                    value: blueprint.stoneCost,
                    isLocked: isLocked),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Build button
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
            child: ElevatedButton(
              onPressed: isLocked ||
                      blueprint.status == _BlueprintStatus.comingSoon
                  ? null
                  : () => _startBuild(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    blueprint.status == _BlueprintStatus.comingSoon
                        ? AppColors.darkCard
                        : isLocked
                            ? AppColors.darkCard
                            : AppColors.holyPoints.withOpacity(0.2),
                foregroundColor:
                    blueprint.status == _BlueprintStatus.comingSoon
                        ? AppColors.purpleLight
                        : isLocked
                            ? AppColors.midGrey
                            : AppColors.holyPoints,
                side: BorderSide(
                  color:
                      blueprint.status == _BlueprintStatus.comingSoon
                          ? AppColors.purpleLight.withOpacity(0.3)
                          : isLocked
                              ? AppColors.midGrey.withOpacity(0.2)
                              : AppColors.holyPoints.withOpacity(0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
              ),
              child: Text(
                blueprint.status == _BlueprintStatus.comingSoon
                    ? 'Coming Soon'
                    : isLocked
                        ? 'Locked — Level ${blueprint.requiredKingdomLevel}+ Required'
                        : completedReqs == totalReqs
                            ? 'Build "${blueprint.name}"'
                            : 'Start Building (${completedReqs}/${totalReqs} ready)',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startBuild(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
          side: const BorderSide(color: AppColors.holyPoints),
        ),
        title: Text(
          'Build ${blueprint.name}?',
          style: AppTextStyles.headlineMedium.copyWith(
            color: const Color(0xFFB8D4FF),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              blueprint.emoji,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'This will use:\n'
              '🪵 ${blueprint.woodCost} Wood\n'
              '✨ ${blueprint.goldCost} Gold\n'
              '🪨 ${blueprint.stoneCost} Stone',
              style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.parchment),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.midGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '${blueprint.name} construction started!'),
                  backgroundColor: AppColors.forestGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  AppColors.holyPoints.withOpacity(0.2),
              foregroundColor: AppColors.holyPoints,
            ),
            child: const Text('Build'),
          ),
        ],
      ),
    );
  }
}

class _CostChip extends StatelessWidget {
  final String emoji;
  final int value;
  final bool isLocked;

  const _CostChip({
    required this.emoji,
    required this.value,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLocked
            ? const Color(0xFF0D1628)
            : AppColors.holyPoints.withOpacity(0.05),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(
          color: isLocked
              ? AppColors.holyPoints.withOpacity(0.1)
              : AppColors.holyPoints.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 3),
          Text(
            value >= 1000
                ? '${(value / 1000).toStringAsFixed(1)}K'
                : value.toString(),
            style: AppTextStyles.labelSmall.copyWith(
              color: isLocked
                  ? AppColors.midGrey
                  : const Color(0xFFB8D4FF),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
