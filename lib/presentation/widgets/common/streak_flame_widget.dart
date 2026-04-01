import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/core/constants/asset_paths.dart';

/// Animated flame icon showing the player's current streak count.
///
/// When [isAtRisk] is true, the flame pulses urgently to warn the player
/// that their streak will break if they don't complete an activity today.
class StreakFlameWidget extends StatelessWidget {
  final int count;
  final bool isAtRisk;
  final bool showCount;
  final double size;

  const StreakFlameWidget({
    super.key,
    required this.count,
    this.isAtRisk = false,
    this.showCount = true,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    final flameColor = isAtRisk ? AppColors.midGrey : Colors.orange;

    return GestureDetector(
      onTap: () {
        if (!showCount) return;
        final overlay = Overlay.of(context);
        final entry = OverlayEntry(
          builder: (ctx) => _StreakTooltip(
            count: count,
            isAtRisk: isAtRisk,
          ),
        );
        overlay.insert(entry);
        Future.delayed(const Duration(seconds: 2), entry.remove);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Flame
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Lottie animation (preferred)
                Lottie.asset(
                  AssetPaths.streakFireAnimation,
                  width: size,
                  height: size,
                  repeat: true,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.local_fire_department,
                    color: flameColor,
                    size: size * 0.8,
                  ),
                ),
                // At-risk pulsing overlay
                if (isAtRisk)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.crimson.withOpacity(0.2),
                      ),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(
                        begin: 0.9,
                        end: 1.1,
                        duration: 600.ms,
                        curve: Curves.easeInOut,
                      )
                      .fadeIn(duration: 300.ms),
              ],
            ),
          ),

          // Count
          if (showCount) ...[
            const SizedBox(width: 2),
            Text(
              '$count',
              style: AppTextStyles.labelLarge.copyWith(
                color: isAtRisk ? AppColors.midGrey : Colors.orange,
                fontWeight: FontWeight.w700,
              ),
            )
                .animate(
                  onPlay: isAtRisk ? (c) => c.repeat(reverse: true) : null,
                )
                .then()
                .shimmer(
                  duration: 1200.ms,
                  color: isAtRisk
                      ? AppColors.crimson.withOpacity(0.6)
                      : Colors.yellow.withOpacity(0.6),
                ),
          ],
        ],
      ),
    );
  }
}

// ── Tooltip ───────────────────────────────────────────────────────────────────

class _StreakTooltip extends StatelessWidget {
  final int count;
  final bool isAtRisk;

  const _StreakTooltip({required this.count, required this.isAtRisk});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 80,
      right: AppSpacing.md,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: AppSpacing.borderRadiusMd,
            border: Border.all(
              color:
                  isAtRisk ? AppColors.crimson.withOpacity(0.5) : Colors.orange.withOpacity(0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 12,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count Day Streak',
                style: AppTextStyles.titleMedium.copyWith(
                  color: isAtRisk ? AppColors.crimson : Colors.orange,
                ),
              ),
              if (isAtRisk) ...[
                const SizedBox(height: 4),
                Text(
                  'Complete an activity today\nto keep your streak!',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.midGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ).animate().fadeIn(duration: 200.ms),
    );
  }
}
