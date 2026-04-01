import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/data/models/ark/ark_node_model.dart';
import 'package:kingdomcome/presentation/providers/ark_provider.dart';
import 'package:kingdomcome/presentation/providers/streak_provider.dart';
import 'package:kingdomcome/routing/route_names.dart';

/// The Ark — Duolingo-style open world Bible journey screen.
///
/// Displays a vertically scrollable map with:
/// - A sea background with an Ark vessel aesthetic
/// - Ten themed sections organised by Bible books
/// - Interactive node circles along a winding path
/// - Progress bar, streak flame, and daily bread bell at the top
class ArkScreen extends ConsumerWidget {
  const ArkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodesAsync = ref.watch(arkNotifierProvider);
    final primaryStreak = ref.watch(primaryStreakProvider);

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      body: Stack(
        children: [
          // Sea gradient background
          Positioned.fill(
            child: _SeaBackground(),
          ),

          // Main scrollable content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Top bar: progress + streak + daily bread bell
              SliverToBoxAdapter(
                child: _ArkTopBar(
                  streakCount: primaryStreak?.currentStreak ?? 0,
                  streakAtRisk: primaryStreak?.isAtRisk ?? false,
                  nodesAsync: nodesAsync,
                ),
              ),

              // Sections + nodes
              nodesAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.gold),
                  ),
                ),
                error: (e, _) => SliverFillRemaining(
                  child: _ArkErrorView(error: e.toString()),
                ),
                data: (nodes) => SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final section = ArkSection.values[i];
                      final sectionNodes = ref
                          .read(arkNotifierProvider.notifier)
                          .getNodesBySection(section, from: nodes);
                      return _SectionBlock(
                        section: section,
                        nodes: sectionNodes,
                        sectionIndex: i,
                      );
                    },
                    childCount: ArkSection.values.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Sea Background ────────────────────────────────────────────────────────────

class _SeaBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0D2E4A), // Deep sea top
            Color(0xFF1A4A6E), // Mid ocean
            Color(0xFF0F3A5A), // Deep sea bottom
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: CustomPaint(
        painter: _WavePainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x15FFFFFF)
      ..style = PaintingStyle.fill;

    // Draw subtle horizontal wave lines
    for (int i = 0; i < 20; i++) {
      final path = Path();
      final y = (size.height / 20) * i;
      path.moveTo(0, y);
      for (double x = 0; x <= size.width; x += 40) {
        path.quadraticBezierTo(
          x + 20, y + (i.isEven ? 4 : -4),
          x + 40, y,
        );
      }
      path.lineTo(size.width, y + 2);
      path.lineTo(0, y + 2);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Top Bar ───────────────────────────────────────────────────────────────────

class _ArkTopBar extends StatelessWidget {
  final int streakCount;
  final bool streakAtRisk;
  final AsyncValue<List<ArkNodeModel>> nodesAsync;

  const _ArkTopBar({
    required this.streakCount,
    required this.streakAtRisk,
    required this.nodesAsync,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount =
        nodesAsync.valueOrNull?.where((n) => n.isCompleted).length ?? 0;
    final totalCount = nodesAsync.valueOrNull?.length ?? 1;
    final progress = completedCount / totalCount.clamp(1, totalCount);

    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.purpleDark.withOpacity(0.85),
        border: const Border(
          bottom: BorderSide(color: AppColors.goldDark, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Ark title
              const Text(
                'THE ARK',
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldLight,
                  letterSpacing: 3,
                ),
              ),
              const Spacer(),
              // Streak flame
              if (streakCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: streakAtRisk
                        ? AppColors.crimson.withOpacity(0.2)
                        : const Color(0xFF2A1800),
                    borderRadius: AppSpacing.borderRadiusSm,
                    border: Border.all(
                      color: streakAtRisk
                          ? AppColors.crimson.withOpacity(0.6)
                          : const Color(0xFFFF6B00).withOpacity(0.6),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: streakAtRisk
                            ? AppColors.crimson
                            : const Color(0xFFFF6B00),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$streakCount',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: streakAtRisk
                              ? AppColors.crimson
                              : const Color(0xFFFF6B00),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: AppSpacing.sm),
              // Daily bread bell
              GestureDetector(
                onTap: () => context.push(RouteNames.dailyBread),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.15),
                    borderRadius: AppSpacing.borderRadiusSm,
                    border: Border.all(
                        color: AppColors.gold.withOpacity(0.4)),
                  ),
                  child: const Icon(
                    Icons.notifications_none,
                    color: AppColors.gold,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: AppSpacing.borderRadiusSm,
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.darkCard,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.gold),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '$completedCount / $totalCount',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section Block ─────────────────────────────────────────────────────────────

class _SectionBlock extends StatelessWidget {
  final ArkSection section;
  final List<ArkNodeModel> nodes;
  final int sectionIndex;

  const _SectionBlock({
    required this.section,
    required this.nodes,
    required this.sectionIndex,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount = nodes.where((n) => n.isCompleted).length;
    final isComplete = completedCount == nodes.length && nodes.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section header / checkpoint island
          _SectionHeader(
            section: section,
            completedCount: completedCount,
            totalCount: nodes.length,
            isComplete: isComplete,
            sectionIndex: sectionIndex,
          ),
          const SizedBox(height: AppSpacing.sm),
          // Winding path of nodes
          _NodePath(nodes: nodes, sectionIndex: sectionIndex),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final ArkSection section;
  final int completedCount;
  final int totalCount;
  final bool isComplete;
  final int sectionIndex;

  const _SectionHeader({
    required this.section,
    required this.completedCount,
    required this.totalCount,
    required this.isComplete,
    required this.sectionIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isComplete
              ? [AppColors.gold.withOpacity(0.3), AppColors.goldDark.withOpacity(0.3)]
              : [AppColors.purpleDark.withOpacity(0.8), AppColors.deepPurple.withOpacity(0.6)],
        ),
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isComplete
              ? AppColors.gold.withOpacity(0.7)
              : AppColors.goldDark.withOpacity(0.3),
          width: isComplete ? 1.5 : 1,
        ),
        boxShadow: isComplete
            ? [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Landmark emoji / icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.darkCard.withOpacity(0.6),
              shape: BoxShape.circle,
              border: Border.all(
                color: isComplete
                    ? AppColors.gold.withOpacity(0.6)
                    : AppColors.goldDark.withOpacity(0.3),
              ),
            ),
            child: Center(
              child: Text(
                section.landmarkEmoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.displayName,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: isComplete ? AppColors.goldLight : AppColors.ivory,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  section.shortDescription,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.midGrey,
                  ),
                ),
              ],
            ),
          ),
          // Completion badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isComplete)
                const Icon(Icons.verified, color: AppColors.gold, size: 20),
              Text(
                '$completedCount/$totalCount',
                style: AppTextStyles.labelSmall.copyWith(
                  color: isComplete ? AppColors.gold : AppColors.midGrey,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: sectionIndex * 60)).fadeIn().slideY(begin: 0.1);
  }
}

// ── Node Path ─────────────────────────────────────────────────────────────────

class _NodePath extends StatelessWidget {
  final List<ArkNodeModel> nodes;
  final int sectionIndex;

  const _NodePath({required this.nodes, required this.sectionIndex});

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) return const SizedBox.shrink();

    // Arrange nodes in a winding serpentine pattern
    // Odd rows go right-to-left for the meandering effect
    const nodesPerRow = 3;
    final rows = (nodes.length / nodesPerRow).ceil();

    return Column(
      children: List.generate(rows, (rowIndex) {
        final start = rowIndex * nodesPerRow;
        final end = math.min(start + nodesPerRow, nodes.length);
        final rowNodes = nodes.sublist(start, end);
        final isReverseRow = rowIndex.isOdd;

        return Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: (isReverseRow ? rowNodes.reversed.toList() : rowNodes)
                .asMap()
                .entries
                .map((entry) {
              final globalIndex = start + entry.key;
              return _ArkNodeButton(
                node: entry.value,
                animationDelay:
                    Duration(milliseconds: sectionIndex * 50 + globalIndex * 40),
              );
            }).toList(),
          ),
        );
      }),
    );
  }
}

// ── Ark Node Button ───────────────────────────────────────────────────────────

class _ArkNodeButton extends StatelessWidget {
  final ArkNodeModel node;
  final Duration animationDelay;

  const _ArkNodeButton({
    required this.node,
    required this.animationDelay,
  });

  Color get _nodeColor {
    if (node.nodeType == ArkNodeType.locked) return AppColors.midGrey;
    if (node.nodeType == ArkNodeType.dailyBread) return AppColors.faithCoins;
    if (node.isCompleted) return AppColors.forestGreen;
    switch (node.nodeType) {
      case ArkNodeType.story:
        return AppColors.purpleLight;
      case ArkNodeType.verse:
        return AppColors.holyPoints;
      case ArkNodeType.quiz:
        return AppColors.blessings;
      case ArkNodeType.chapter:
        return AppColors.deepPurple;
      default:
        return AppColors.deepPurple;
    }
  }

  Color get _borderColor {
    if (node.nodeType == ArkNodeType.dailyBread) {
      return AppColors.gold;
    }
    if (node.isCompleted) return AppColors.sage;
    return _nodeColor.withOpacity(0.8);
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = node.nodeType == ArkNodeType.locked;
    final isDailyBread = node.nodeType == ArkNodeType.dailyBread;

    return GestureDetector(
      onTap: isLocked
          ? () => _showLockedDialog(context)
          : () => context.push(RouteNames.arkNodeDetailPath(node.id),
              extra: node),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Node circle
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isDailyBread ? 72 : 60,
            height: isDailyBread ? 72 : 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLocked
                  ? AppColors.darkCard
                  : _nodeColor.withOpacity(0.2),
              border: Border.all(
                color: _borderColor,
                width: isDailyBread ? 2.5 : 2,
              ),
              boxShadow: [
                if (!isLocked)
                  BoxShadow(
                    color: _nodeColor.withOpacity(isDailyBread ? 0.6 : 0.3),
                    blurRadius: isDailyBread ? 20 : 10,
                    spreadRadius: isDailyBread ? 4 : 1,
                  ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Type emoji / icon
                Text(
                  isLocked ? '🔒' : _nodeIcon,
                  style: TextStyle(fontSize: isDailyBread ? 24 : 20),
                ),
                // Completion checkmark overlay
                if (node.isCompleted)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: AppColors.forestGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: AppColors.white,
                        size: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Node label
          SizedBox(
            width: 72,
            child: Text(
              node.title,
              style: AppTextStyles.labelSmall.copyWith(
                color: isLocked
                    ? AppColors.midGrey
                    : node.isCompleted
                        ? AppColors.sage
                        : AppColors.parchment,
                fontSize: 8,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    )
        .animate(delay: animationDelay)
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.7, 0.7), end: const Offset(1, 1));
  }

  String get _nodeIcon {
    switch (node.nodeType) {
      case ArkNodeType.story:
        return '📖';
      case ArkNodeType.verse:
        return '✨';
      case ArkNodeType.quiz:
        return '🎯';
      case ArkNodeType.dailyBread:
        return '🍞';
      case ArkNodeType.chapter:
        return '📜';
      case ArkNodeType.locked:
        return '🔒';
    }
  }

  void _showLockedDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
          side: const BorderSide(color: AppColors.goldDark),
        ),
        title: Text(
          'Locked',
          style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.goldLight),
        ),
        content: Text(
          node.unlockCondition ??
              'Complete earlier nodes to unlock this one.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.parchment),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'OK',
              style: TextStyle(color: AppColors.gold),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error View ────────────────────────────────────────────────────────────────

class _ArkErrorView extends StatelessWidget {
  final String error;
  const _ArkErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: AppColors.crimson, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Could not load The Ark',
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
