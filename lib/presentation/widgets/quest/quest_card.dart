import 'package:flutter/material.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/data/models/quest/quest_model.dart';
import 'package:kingdomcome/data/models/quest/quest_category.dart';

/// Card widget for displaying a quest in the quest board list.
class QuestCard extends StatelessWidget {
  final QuestModel quest;
  final VoidCallback? onTap;
  final bool isCompleted;
  final bool isLiturgical;
  final Color? seasonColor;

  const QuestCard({
    super.key,
    required this.quest,
    this.onTap,
    this.isCompleted = false,
    this.isLiturgical = false,
    this.seasonColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isCompleted ? null : onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isCompleted
              ? AppColors.darkCard.withOpacity(0.5)
              : AppColors.darkCard,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(
            color: isLiturgical && seasonColor != null
                ? seasonColor!.withOpacity(0.5)
                : AppColors.goldDark.withOpacity(0.3),
            width: isLiturgical ? 1.5 : 1,
          ),
          boxShadow: isLiturgical && seasonColor != null
              ? [
                  BoxShadow(
                    color: seasonColor!.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            _QuestIcon(
              iconPath: quest.iconAssetPath,
              isCompleted: isCompleted,
              isLiturgical: isLiturgical,
              seasonColor: seasonColor,
            ),

            const SizedBox(width: AppSpacing.md),

            // Title + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          quest.title,
                          style: AppTextStyles.titleLarge.copyWith(
                            color: isCompleted
                                ? AppColors.midGrey
                                : AppColors.ivory,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCompleted)
                        const Icon(Icons.check_circle,
                            color: AppColors.forestGreen, size: 20),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    quest.category.displayName,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.midGrey,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Difficulty + rewards row
                  Row(
                    children: [
                      _DifficultyStars(difficulty: quest.difficulty),
                      const Spacer(),
                      if (quest.holyPointsReward > 0)
                        _RewardBadge(
                          icon: Icons.star,
                          value: quest.holyPointsReward,
                          color: AppColors.holyPoints,
                        ),
                      if (quest.faithCoinsReward > 0) ...[
                        const SizedBox(width: AppSpacing.xs),
                        _RewardBadge(
                          icon: Icons.monetization_on,
                          value: quest.faithCoinsReward,
                          color: AppColors.faithCoins,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Arrow
            if (!isCompleted)
              const Padding(
                padding: EdgeInsets.only(left: AppSpacing.sm),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.midGrey,
                  size: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _QuestIcon extends StatelessWidget {
  final String iconPath;
  final bool isCompleted;
  final bool isLiturgical;
  final Color? seasonColor;

  const _QuestIcon({
    required this.iconPath,
    required this.isCompleted,
    required this.isLiturgical,
    this.seasonColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isLiturgical && seasonColor != null
            ? seasonColor!.withOpacity(0.15)
            : AppColors.darkElevated,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: isLiturgical && seasonColor != null
              ? seasonColor!.withOpacity(0.4)
              : AppColors.goldDark.withOpacity(0.2),
        ),
      ),
      child: Opacity(
        opacity: isCompleted ? 0.4 : 1.0,
        child: ClipRRect(
          borderRadius: AppSpacing.borderRadiusMd,
          child: Image.asset(
            iconPath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(
              Icons.assignment,
              color: isLiturgical && seasonColor != null
                  ? seasonColor!
                  : AppColors.gold,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _DifficultyStars extends StatelessWidget {
  final QuestDifficulty difficulty;
  const _DifficultyStars({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final stars = difficulty.index + 1;
    final color = [
      AppColors.sage,
      AppColors.faithCoins,
      AppColors.blessings,
      AppColors.gold,
    ][difficulty.index.clamp(0, 3)];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        4,
        (i) => Icon(
          i < stars ? Icons.star : Icons.star_border,
          color: i < stars ? color : AppColors.darkElevated,
          size: 12,
        ),
      ),
    );
  }
}

class _RewardBadge extends StatelessWidget {
  final IconData icon;
  final int value;
  final Color color;

  const _RewardBadge({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 2),
        Text(
          '+$value',
          style: AppTextStyles.labelSmall.copyWith(color: color),
        ),
      ],
    );
  }
}
