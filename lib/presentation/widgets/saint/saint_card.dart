import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/data/models/saint/saint_model.dart';

/// Card widget for the saints gallery grid.
///
/// - **Unlocked**: Shows the saint's portrait, name, and rarity border.
/// - **Locked**: Shows a silhouette with a "?" and unlock cost.
/// - **Active** (guardian): Shows a glowing golden border.
class SaintCard extends StatelessWidget {
  final SaintModel saint;
  final bool isUnlocked;
  final bool isActive;
  final VoidCallback? onTap;

  const SaintCard({
    super.key,
    required this.saint,
    required this.isUnlocked,
    required this.isActive,
    this.onTap,
  });

  Color get _rarityColor {
    switch (saint.rarity.toLowerCase()) {
      case 'legendary':
        return AppColors.gold;
      case 'epic':
        return AppColors.grace;
      case 'rare':
        return AppColors.holyPoints;
      case 'uncommon':
        return AppColors.sage;
      default:
        return AppColors.midGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = isActive ? AppColors.gold : _rarityColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(
            color: isActive
                ? AppColors.gold
                : _rarityColor.withOpacity(0.5),
            width: isActive ? 2.5 : 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.gold.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Portrait / silhouette
            Positioned.fill(
              child: ClipRRect(
                borderRadius: AppSpacing.borderRadiusMd,
                child: isUnlocked
                    ? Image.asset(
                        saint.portraitAssetPath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _LockedPlaceholder(rarity: saint.rarity),
                      )
                    : _LockedPlaceholder(rarity: saint.rarity),
              ),
            ),

            // Gradient overlay at bottom for text legibility
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xs + 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.85),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppSpacing.radiusMd),
                    bottomRight: Radius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isUnlocked ? saint.name : '???',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    if (!isUnlocked) ...[
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star,
                              color: AppColors.holyPoints, size: 10),
                          const SizedBox(width: 2),
                          Text(
                            '${saint.holyPointsCost}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.holyPoints,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Active badge
            if (isActive)
              Positioned(
                top: AppSpacing.xs,
                right: AppSpacing.xs,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shield,
                    color: AppColors.white,
                    size: 10,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(begin: 0.9, end: 1.1, duration: 1000.ms),
              ),

            // Rarity indicator
            Positioned(
              top: AppSpacing.xs,
              left: AppSpacing.xs,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: borderColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: borderColor.withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Locked placeholder ────────────────────────────────────────────────────────

class _LockedPlaceholder extends StatelessWidget {
  final String rarity;
  const _LockedPlaceholder({required this.rarity});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkElevated,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            color: AppColors.midGrey.withOpacity(0.5),
            size: 40,
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.darkCard,
              border: Border.all(color: AppColors.midGrey.withOpacity(0.3)),
            ),
            child: const Center(
              child: Text(
                '?',
                style: TextStyle(
                  color: AppColors.midGrey,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
