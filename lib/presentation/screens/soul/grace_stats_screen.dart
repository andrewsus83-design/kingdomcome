import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/presentation/providers/streak_provider.dart';
import 'package:kingdomcome/presentation/providers/soul_provider.dart';

// ── Grace stats screen ─────────────────────────────────────────────────────────

class GraceStatsScreen extends ConsumerWidget {
  const GraceStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(graceStatsNotifierProvider);
    final streaksAsync = ref.watch(streakNotifierProvider);
    final streaks = streaksAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        backgroundColor: AppColors.purpleDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Grace Stats',
          style:
              AppTextStyles.headlineMedium.copyWith(color: AppColors.goldLight),
        ),
      ),
      body: statsAsync.when(
        data: (stats) => _StatsDashboard(stats: stats, streaks: streaks),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
        error: (err, _) => Center(
          child: Text(
            'Could not load grace stats',
            style:
                AppTextStyles.bodyMedium.copyWith(color: AppColors.midGrey),
          ),
        ),
      ),
    );
  }
}

class _StatsDashboard extends StatelessWidget {
  final GraceStatsState stats;
  final List<StreakModel> streaks;

  const _StatsDashboard({required this.stats, required this.streaks});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Weekly flower
          _WeeklyFlower(weeklyDeeds: stats.weeklyDeeds)
              .animate()
              .fadeIn(delay: 100.ms),

          const SizedBox(height: AppSpacing.md),

          // Monthly bar chart
          _MonthlyChart(monthlyPoints: stats.monthlyPoints)
              .animate()
              .fadeIn(delay: 200.ms),

          const SizedBox(height: AppSpacing.md),

          // Activity breakdown
          _ActivityBreakdown(breakdown: stats.activityBreakdown)
              .animate()
              .fadeIn(delay: 300.ms),

          const SizedBox(height: AppSpacing.md),

          // Virtue progress
          _VirtueProgress(virtues: stats.virtueProgress)
              .animate()
              .fadeIn(delay: 400.ms),

          const SizedBox(height: AppSpacing.md),

          // Streaks panel
          _StreaksPanel(streaks: streaks).animate().fadeIn(delay: 500.ms),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// ── Weekly flower ──────────────────────────────────────────────────────────────

class _WeeklyFlower extends StatelessWidget {
  final int weeklyDeeds;

  const _WeeklyFlower({required this.weeklyDeeds});

  @override
  Widget build(BuildContext context) {
    const maxDeeds = 7;
    final filled = weeklyDeeds.clamp(0, maxDeeds);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.forestGreen.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Good Deeds This Week',
            style:
                AppTextStyles.headlineSmall.copyWith(color: AppColors.gold),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: 160,
            height: 160,
            child: CustomPaint(
              painter: _FlowerPainter(
                filledPetals: filled,
                totalPetals: maxDeeds,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$filled',
                      style: AppTextStyles.statNumber.copyWith(
                        color: AppColors.forestGreen,
                      ),
                    ),
                    Text(
                      'deeds',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.midGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            filled >= maxDeeds
                ? 'Perfect week! Amazing! 🌸'
                : '${maxDeeds - filled} more deed${maxDeeds - filled != 1 ? 's' : ''} to fill the flower',
            style: AppTextStyles.bodySmall.copyWith(
              color: filled >= maxDeeds
                  ? AppColors.forestGreen
                  : AppColors.midGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FlowerPainter extends CustomPainter {
  final int filledPetals;
  final int totalPetals;

  _FlowerPainter({required this.filledPetals, required this.totalPetals});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.36;
    final petalRadius = size.width * 0.16;

    for (int i = 0; i < totalPetals; i++) {
      final angle = (i / totalPetals) * 2 * pi - pi / 2;
      final petalCenter = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );

      final paint = Paint()
        ..color = i < filledPetals
            ? const Color(0xFF2C6E49)
            : AppColors.darkElevated
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = i < filledPetals
            ? const Color(0xFF1A4A31)
            : AppColors.darkCard
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(petalCenter, petalRadius, paint);
      canvas.drawCircle(petalCenter, petalRadius, borderPaint);
    }

    // Center circle
    final centerPaint = Paint()
      ..color = AppColors.gold.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.width * 0.12, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _FlowerPainter oldDelegate) =>
      oldDelegate.filledPetals != filledPetals;
}

// ── Monthly chart ──────────────────────────────────────────────────────────────

class _MonthlyChart extends StatelessWidget {
  final List<int> monthlyPoints; // 30 values

  const _MonthlyChart({required this.monthlyPoints});

  @override
  Widget build(BuildContext context) {
    final maxVal = monthlyPoints.fold(0, (a, b) => a > b ? a : b);
    const barCount = 30;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.goldDark.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HolyPoints — Past 30 Days',
            style:
                AppTextStyles.headlineSmall.copyWith(color: AppColors.gold),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: monthlyPoints.take(barCount).toList().asMap().entries.map((e) {
                final val = e.value;
                final barHeight = maxVal > 0 ? (val / maxVal) * 90 : 4.0;
                final isToday = e.key == barCount - 1;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300 + e.key * 8),
                      height: barHeight.clamp(4, 90),
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppColors.gold
                            : AppColors.holyPoints.withOpacity(0.55),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(2),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '30 days ago',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.midGrey,
                ),
              ),
              Text(
                'Today',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Activity breakdown ─────────────────────────────────────────────────────────

class _ActivityBreakdown extends StatelessWidget {
  final Map<String, double> breakdown;

  const _ActivityBreakdown({required this.breakdown});

  static const _colors = {
    'Prayer': AppColors.grace,
    'Bible': AppColors.holyPoints,
    'Good Deeds': AppColors.forestGreen,
    'Quizzes': AppColors.faithCoins,
    'Arts': AppColors.blessings,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.darkElevated),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Breakdown',
            style:
                AppTextStyles.headlineSmall.copyWith(color: AppColors.gold),
          ),
          const SizedBox(height: AppSpacing.md),
          ...breakdown.entries.map((e) {
            final color = _colors[e.key] ?? AppColors.midGrey;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      e.key,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.parchment),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: AppSpacing.borderRadiusSm,
                      child: LinearProgressIndicator(
                        value: e.value,
                        backgroundColor: AppColors.darkElevated,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${(e.value * 100).round()}%',
                    style: AppTextStyles.labelSmall.copyWith(color: color),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Virtue progress ────────────────────────────────────────────────────────────

class _VirtueProgress extends StatelessWidget {
  final Map<String, double> virtues;

  const _VirtueProgress({required this.virtues});

  static const _virtueEmojis = {
    'Kindness': '💛',
    'Courage': '🦁',
    'Patience': '⏳',
    'Humility': '🙇',
    'Faith': '✝️',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.deepPurple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Virtue Progress',
            style:
                AppTextStyles.headlineSmall.copyWith(color: AppColors.gold),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Grows through quest completions',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.midGrey),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: virtues.entries.map((e) {
              final emoji = _virtueEmojis[e.key] ?? '⭐';
              return _VirtueChip(
                name: e.key,
                emoji: emoji,
                progress: e.value,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _VirtueChip extends StatelessWidget {
  final String name;
  final String emoji;
  final double progress; // 0.0 to 1.0

  const _VirtueChip({
    required this.name,
    required this.emoji,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.darkElevated,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.deepPurple.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            name,
            style:
                AppTextStyles.labelSmall.copyWith(color: AppColors.ivory),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: AppSpacing.borderRadiusSm,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.darkCard,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.grace),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${(progress * 100).round()}%',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.grace),
          ),
        ],
      ),
    );
  }
}

// ── Streaks panel ──────────────────────────────────────────────────────────────

class _StreaksPanel extends StatelessWidget {
  final List<StreakModel> streaks;

  const _StreaksPanel({required this.streaks});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.goldDark.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Streaks',
            style:
                AppTextStyles.headlineSmall.copyWith(color: AppColors.gold),
          ),
          const SizedBox(height: AppSpacing.md),
          if (streaks.isEmpty)
            Text(
              'No streaks yet — complete daily activities to build your first streak!',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.midGrey),
            )
          else
            ...streaks.map((s) => _StreakRow(streak: s)),
        ],
      ),
    );
  }
}

class _StreakRow extends StatelessWidget {
  final StreakModel streak;

  const _StreakRow({required this.streak});

  @override
  Widget build(BuildContext context) {
    final isActive = streak.isActiveToday;
    final isAtRisk = streak.isAtRisk && streak.currentStreak > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Text(
            isActive ? '🔥' : isAtRisk ? '⚠️' : '💤',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  streak.type.displayName,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.ivory,
                  ),
                ),
                if (isAtRisk)
                  Text(
                    'Complete today\'s activity to keep your streak!',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.faithCoins,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${streak.currentStreak} days',
            style: AppTextStyles.headlineSmall.copyWith(
              color: isActive ? AppColors.faithCoins : AppColors.midGrey,
            ),
          ),
        ],
      ),
    );
  }
}
