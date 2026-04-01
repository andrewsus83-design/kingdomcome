import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/core/constants/game_constants.dart';

/// Animated XP progress bar showing the player's current level progress.
///
/// Computes level from [holyPoints] using [kLevelThresholds].
class XpProgressBar extends StatefulWidget {
  final int holyPoints;
  final bool showLabel;

  const XpProgressBar({
    super.key,
    required this.holyPoints,
    this.showLabel = true,
  });

  @override
  State<XpProgressBar> createState() => _XpProgressBarState();
}

class _XpProgressBarState extends State<XpProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  double _targetProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _updateTarget();
    _controller.forward();
  }

  @override
  void didUpdateWidget(XpProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.holyPoints != widget.holyPoints) {
      _updateTarget();
      _controller
        ..reset()
        ..forward();
    }
  }

  void _updateTarget() {
    _targetProgress = _computeProgress(widget.holyPoints);
    _progressAnimation = Tween<double>(
      begin: _progressAnimation.value,
      end: _targetProgress,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = _computeLevel(widget.holyPoints);
    final current = widget.holyPoints;
    final next = _xpForNextLevel(level);
    final currentLevelXp = _xpForLevel(level);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.goldDark.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level badge + label
          if (widget.showLabel)
            Row(
              children: [
                _LevelBadge(level: level),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level $level',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.goldLight,
                        ),
                      ),
                      Text(
                        '${current - currentLevelXp} / ${next - currentLevelXp} XP',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.midGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Lv.${level + 1}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.midGrey,
                  ),
                ),
              ],
            ),

          if (widget.showLabel) const SizedBox(height: AppSpacing.sm),

          // Progress bar
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, _) {
              return ClipRRect(
                borderRadius: AppSpacing.borderRadiusSm,
                child: Stack(
                  children: [
                    Container(
                      height: 14,
                      color: AppColors.darkElevated,
                    ),
                    FractionallySizedBox(
                      widthFactor: _progressAnimation.value.clamp(0.0, 1.0),
                      child: Container(
                        height: 14,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.xpStart, AppColors.xpEnd],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static int _computeLevel(int xp) {
    for (int i = kLevelThresholds.length - 1; i >= 0; i--) {
      if (xp >= kLevelThresholds[i]) return i + 1;
    }
    return 1;
  }

  static int _xpForLevel(int level) {
    final idx = (level - 1).clamp(0, kLevelThresholds.length - 1);
    return kLevelThresholds[idx];
  }

  static int _xpForNextLevel(int level) {
    final idx = level.clamp(0, kLevelThresholds.length - 1);
    return kLevelThresholds[idx];
  }

  static double _computeProgress(int xp) {
    final level = _computeLevel(xp);
    if (level >= GameConstants.maxLevel) return 1.0;
    final current = _xpForLevel(level);
    final next = _xpForNextLevel(level);
    if (next == current) return 0;
    return ((xp - current) / (next - current)).clamp(0.0, 1.0);
  }
}

// ── Level badge ───────────────────────────────────────────────────────────────

class _LevelBadge extends StatelessWidget {
  final int level;
  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gold, AppColors.goldDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$level',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.white,
            fontSize: 13,
          ),
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 2000.ms, color: AppColors.goldLight.withOpacity(0.3));
  }
}
