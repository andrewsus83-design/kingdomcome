import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/core/constants/asset_paths.dart';
import 'package:kingdomcome/data/models/quest/quest_model.dart';
import 'package:kingdomcome/presentation/providers/quest_provider.dart';
import 'package:kingdomcome/presentation/providers/streak_provider.dart';
import 'package:kingdomcome/presentation/widgets/common/kingdom_button.dart';

class QuestCompletionScreen extends ConsumerStatefulWidget {
  final String questId;
  const QuestCompletionScreen({super.key, required this.questId});

  @override
  ConsumerState<QuestCompletionScreen> createState() =>
      _QuestCompletionScreenState();
}

class _QuestCompletionScreenState
    extends ConsumerState<QuestCompletionScreen> {
  bool _animationComplete = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _animationComplete = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Try to find the completed quest in recent quest data
    // (it may have been removed from active quests list after completion)
    final allQuests = ref.watch(questNotifierProvider).valueOrNull ?? [];
    final quest = allQuests.where((q) => q.id == widget.questId).firstOrNull;

    final primaryStreak = ref.watch(primaryStreakProvider);
    final streakCount = primaryStreak?.currentStreak ?? 0;
    final isStreakMilestone =
        streakCount == 7 || streakCount == 30 || streakCount == 100;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFF2D0F42),
              AppColors.darkSurface,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Celebration lottie
              Positioned.fill(
                child: Lottie.asset(
                  AssetPaths.celebrationAnimation,
                  repeat: false,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),

              // Content
              Center(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Quest complete animation
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: Lottie.asset(
                          AssetPaths.questCompleteAnimation,
                          repeat: false,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.check_circle,
                            color: AppColors.gold,
                            size: 100,
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      Text(
                        'Quest Complete!',
                        style: AppTextStyles.displayMedium.copyWith(
                          color: AppColors.goldLight,
                          shadows: const [
                            Shadow(
                              blurRadius: 20,
                              color: AppColors.gold,
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                      ).animate(delay: 300.ms).fadeIn().scale(
                            begin: const Offset(0.7, 0.7),
                          ),

                      if (quest != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          quest.title,
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: AppColors.ivory,
                          ),
                          textAlign: TextAlign.center,
                        ).animate(delay: 500.ms).fadeIn(),
                      ],

                      const SizedBox(height: AppSpacing.xl),

                      // Rewards
                      if (quest != null)
                        _RewardsDisplay(quest: quest)
                            .animate(delay: 700.ms)
                            .fadeIn()
                            .slideY(begin: 0.3),

                      const SizedBox(height: AppSpacing.lg),

                      // Streak milestone
                      if (isStreakMilestone)
                        _StreakMilestone(count: streakCount)
                            .animate(delay: 900.ms)
                            .fadeIn()
                            .scale(begin: const Offset(0.8, 0.8)),

                      const SizedBox(height: AppSpacing.xl),

                      // Continue button
                      if (_animationComplete)
                        KingdomButton(
                          label: 'Continue',
                          onPressed: () => context.go('/kingdom'),
                          icon: Icons.arrow_forward,
                        ).animate().fadeIn(duration: 400.ms),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reward display ────────────────────────────────────────────────────────────

class _RewardsDisplay extends StatelessWidget {
  final QuestModel quest;
  const _RewardsDisplay({required this.quest});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.darkCard.withOpacity(0.8),
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.gold.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.1),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Rewards Earned',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (quest.holyPointsReward > 0)
                _RewardItem(
                  icon: Icons.star,
                  value: '+${quest.holyPointsReward}',
                  label: 'Holy Points',
                  color: AppColors.holyPoints,
                ),
              if (quest.faithCoinsReward > 0)
                _RewardItem(
                  icon: Icons.monetization_on,
                  value: '+${quest.faithCoinsReward}',
                  label: 'Faith Coins',
                  color: AppColors.faithCoins,
                ),
              if (quest.graceReward > 0)
                _RewardItem(
                  icon: Icons.auto_awesome,
                  value: '+${quest.graceReward}',
                  label: 'Grace',
                  color: AppColors.grace,
                ),
              if (quest.blessingsReward > 0)
                _RewardItem(
                  icon: Icons.favorite,
                  value: '+${quest.blessingsReward}',
                  label: 'Blessings',
                  color: AppColors.blessings,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RewardItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _RewardItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.5), width: 2),
          ),
          child: Icon(icon, color: color, size: 22),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(
              end: 1.1,
              duration: 800.ms,
              curve: Curves.easeInOut,
            ),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTextStyles.statNumber.copyWith(
            fontSize: 18,
            color: color,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.midGrey),
        ),
      ],
    );
  }
}

// ── Streak milestone ──────────────────────────────────────────────────────────

class _StreakMilestone extends StatelessWidget {
  final int count;
  const _StreakMilestone({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFFD700)],
        ),
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.4),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Lottie.asset(
              AssetPaths.streakFireAnimation,
              repeat: true,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.local_fire_department,
                      color: Colors.white, size: 32),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count Day Streak!',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _milestoneLabel(count),
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _milestoneLabel(int count) {
    if (count >= 100) return 'Incredible! You\'ve earned a 2× bonus!';
    if (count >= 30) return 'Amazing! You\'ve earned a 1.5× bonus!';
    return 'Great work! You\'ve earned a 1.25× bonus!';
  }
}
