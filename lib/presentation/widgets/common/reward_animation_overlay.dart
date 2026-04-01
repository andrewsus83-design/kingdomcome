import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/core/constants/asset_paths.dart';
import 'package:kingdomcome/core/constants/game_constants.dart';

/// Full-screen overlay that plays a celebration animation and shows
/// a resource reward breakdown.
///
/// Designed to be shown with [showGeneralDialog] or as a Riverpod-triggered
/// overlay. Call [RewardAnimationOverlay.show] for convenience.
class RewardAnimationOverlay extends StatefulWidget {
  final ResourceReward reward;
  final String? title;
  final VoidCallback? onDismiss;

  const RewardAnimationOverlay({
    super.key,
    required this.reward,
    this.title,
    this.onDismiss,
  });

  /// Shows the reward overlay as a full-screen modal dialog.
  static Future<void> show(
    BuildContext context, {
    required ResourceReward reward,
    String? title,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim, _) {
        return RewardAnimationOverlay(
          reward: reward,
          title: title,
          onDismiss: () => Navigator.of(ctx).pop(),
        );
      },
      transitionBuilder: (ctx, anim, _, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutBack,
          ),
          child: child,
        );
      },
    );
  }

  @override
  State<RewardAnimationOverlay> createState() =>
      _RewardAnimationOverlayState();
}

class _RewardAnimationOverlayState extends State<RewardAnimationOverlay> {
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _showContent = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _showContent ? widget.onDismiss : null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [
                    Color(0x99300A50),
                    Color(0xDD050010),
                  ],
                ),
              ),
            ),

            // Lottie celebration burst
            Lottie.asset(
              AssetPaths.celebrationAnimation,
              fit: BoxFit.cover,
              repeat: false,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),

            // Content
            Center(
              child: AnimatedOpacity(
                opacity: _showContent ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: _RewardCard(
                  reward: widget.reward,
                  title: widget.title ?? 'Rewards!',
                  onContinue: widget.onDismiss,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reward card ───────────────────────────────────────────────────────────────

class _RewardCard extends StatelessWidget {
  final ResourceReward reward;
  final String title;
  final VoidCallback? onContinue;

  const _RewardCard({
    required this.reward,
    required this.title,
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(color: AppColors.gold.withOpacity(0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.2),
            blurRadius: 32,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Star burst icon
          SizedBox(
            width: 72,
            height: 72,
            child: Lottie.asset(
              AssetPaths.questCompleteAnimation,
              repeat: false,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.emoji_events,
                color: AppColors.gold,
                size: 56,
              ),
            ),
          ).animate().scale(begin: const Offset(0.5, 0.5)),

          const SizedBox(height: AppSpacing.sm),

          Text(
            title,
            style: AppTextStyles.goldHeading,
            textAlign: TextAlign.center,
          ).animate(delay: 100.ms).fadeIn(),

          const SizedBox(height: AppSpacing.lg),

          // Resource rows
          ..._buildRewardRows(reward),

          const SizedBox(height: AppSpacing.lg),

          // Tap to continue
          Text(
            'Tap anywhere to continue',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.midGrey,
              fontStyle: FontStyle.italic,
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(
                duration: 1000.ms,
              ),
        ],
      ),
    );
  }

  List<Widget> _buildRewardRows(ResourceReward reward) {
    final items = <_RewardItem>[];

    if (reward.holyPoints > 0) {
      items.add(_RewardItem(
        icon: Icons.star,
        label: 'Holy Points',
        value: reward.holyPoints,
        color: AppColors.holyPoints,
      ));
    }
    if (reward.faithCoins > 0) {
      items.add(_RewardItem(
        icon: Icons.monetization_on,
        label: 'Faith Coins',
        value: reward.faithCoins,
        color: AppColors.faithCoins,
      ));
    }
    if (reward.grace > 0) {
      items.add(_RewardItem(
        icon: Icons.auto_awesome,
        label: 'Grace',
        value: reward.grace,
        color: AppColors.grace,
      ));
    }
    if (reward.blessings > 0) {
      items.add(_RewardItem(
        icon: Icons.favorite,
        label: 'Blessings',
        value: reward.blessings,
        color: AppColors.blessings,
      ));
    }
    if (reward.xp > 0) {
      items.add(_RewardItem(
        icon: Icons.trending_up,
        label: 'XP',
        value: reward.xp,
        color: AppColors.xpEnd,
      ));
    }

    return items
        .asMap()
        .entries
        .map((e) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _RewardRowWidget(item: e.value)
                  .animate(delay: ((e.key + 2) * 100).ms)
                  .fadeIn()
                  .slideX(begin: 0.2),
            ))
        .toList();
  }
}

class _RewardItem {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _RewardItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _RewardRowWidget extends StatelessWidget {
  final _RewardItem item;
  const _RewardRowWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(item.icon, color: item.color, size: 16),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            item.label,
            style:
                AppTextStyles.bodyMedium.copyWith(color: AppColors.parchment),
          ),
        ),
        Text(
          '+${item.value}',
          style: AppTextStyles.headlineSmall.copyWith(color: item.color),
        ),
      ],
    );
  }
}
