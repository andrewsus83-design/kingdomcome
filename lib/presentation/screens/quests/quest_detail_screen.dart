import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/data/models/quest/quest_model.dart';
import 'package:kingdomcome/data/models/quest/quest_category.dart';
import 'package:kingdomcome/presentation/providers/quest_provider.dart';
import 'package:kingdomcome/presentation/widgets/common/kingdom_button.dart';

class QuestDetailScreen extends ConsumerStatefulWidget {
  final String questId;
  const QuestDetailScreen({super.key, required this.questId});

  @override
  ConsumerState<QuestDetailScreen> createState() => _QuestDetailScreenState();
}

class _QuestDetailScreenState extends ConsumerState<QuestDetailScreen> {
  bool _questStarted = false;
  bool _completing = false;
  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questsAsync = ref.watch(questNotifierProvider);
    final quests = questsAsync.valueOrNull ?? [];
    final quest = quests.where((q) => q.id == widget.questId).firstOrNull;

    if (quest == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.purpleDark,
          title: Text(
            'Quest',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.goldLight,
            ),
          ),
        ),
        body: const Center(
          child: Text('Quest not found.',
              style: TextStyle(color: AppColors.ivory)),
        ),
      );
    }

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
          child: Column(
            children: [
              // Header
              _QuestHeader(quest: quest, onBack: () => context.pop()),

              // Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Description
                      _InfoCard(
                        child: Text(
                          quest.description,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.parchment,
                            height: 1.7,
                          ),
                        ),
                      ).animate().fadeIn(delay: 100.ms),

                      const SizedBox(height: AppSpacing.md),

                      // Steps
                      if (quest.steps.isNotEmpty) ...[
                        Text(
                          'Steps',
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: AppColors.goldLight,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ...quest.steps.asMap().entries.map((e) {
                          return _StepTile(
                            stepNumber: e.key + 1,
                            text: e.value,
                          ).animate(delay: ((e.key + 2) * 80).ms).fadeIn().slideX(begin: -0.1);
                        }),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Rewards
                      Text(
                        'Rewards',
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: AppColors.goldLight,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _RewardCard(quest: quest)
                          .animate(delay: 300.ms)
                          .fadeIn(),

                      const SizedBox(height: AppSpacing.md),

                      // Timed quest progress
                      if (quest.verificationType ==
                              QuestVerificationType.timedSession &&
                          _questStarted) ...[
                        _TimerCard(
                          elapsedSeconds: _elapsedSeconds,
                          requiredSeconds:
                              quest.verificationRequiredSeconds,
                        ).animate().fadeIn(),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Difficulty
                      _DifficultyRow(difficulty: quest.difficulty),
                    ],
                  ),
                ),
              ),

              // CTA
              _CtaBar(
                quest: quest,
                questStarted: _questStarted,
                completing: _completing,
                onBegin: _beginQuest,
                onComplete: _completeQuest,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _beginQuest() {
    setState(() => _questStarted = true);
    if (widget.questId.isNotEmpty) {
      // Start timer for timed quests
      final quests = ref.read(questNotifierProvider).valueOrNull ?? [];
      final quest = quests.where((q) => q.id == widget.questId).firstOrNull;
      if (quest?.verificationType == QuestVerificationType.timedSession) {
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() => _elapsedSeconds++);
        });
      }
    }
  }

  Future<void> _completeQuest() async {
    setState(() => _completing = true);
    _timer?.cancel();

    try {
      await ref
          .read(questNotifierProvider.notifier)
          .completeQuest(widget.questId);

      if (mounted) {
        context.pushReplacement('/quests/complete/${widget.questId}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _completing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not complete quest: $e'),
            backgroundColor: AppColors.crimson,
          ),
        );
      }
    }
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _QuestHeader extends StatelessWidget {
  final QuestModel quest;
  final VoidCallback onBack;

  const _QuestHeader({required this.quest, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.goldDark)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.gold),
            onPressed: onBack,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.goldLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  quest.category.displayName,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.midGrey,
                  ),
                ),
              ],
            ),
          ),
          Image.asset(
            quest.iconAssetPath,
            width: 40,
            height: 40,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.assignment,
              color: AppColors.gold,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.goldDark.withOpacity(0.3)),
      ),
      child: child,
    );
  }
}

class _StepTile extends StatelessWidget {
  final int stepNumber;
  final String text;

  const _StepTile({required this.stepNumber, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(right: AppSpacing.sm, top: 2),
            decoration: const BoxDecoration(
              color: AppColors.deepPurple,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$stepNumber',
                style: AppTextStyles.badge.copyWith(
                  color: AppColors.goldLight,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.parchment),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final QuestModel quest;
  const _RewardCard({required this.quest});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.08),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
      ),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: [
          if (quest.holyPointsReward > 0)
            _RewardChip(
              icon: Icons.star,
              value: quest.holyPointsReward,
              label: 'Holy Points',
              color: AppColors.holyPoints,
            ),
          if (quest.faithCoinsReward > 0)
            _RewardChip(
              icon: Icons.monetization_on,
              value: quest.faithCoinsReward,
              label: 'Faith Coins',
              color: AppColors.faithCoins,
            ),
          if (quest.graceReward > 0)
            _RewardChip(
              icon: Icons.auto_awesome,
              value: quest.graceReward,
              label: 'Grace',
              color: AppColors.grace,
            ),
          if (quest.blessingsReward > 0)
            _RewardChip(
              icon: Icons.favorite,
              value: quest.blessingsReward,
              label: 'Blessings',
              color: AppColors.blessings,
            ),
        ],
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;

  const _RewardChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs + 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            '+$value $label',
            style: AppTextStyles.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _TimerCard extends StatelessWidget {
  final int elapsedSeconds;
  final int requiredSeconds;

  const _TimerCard({
    required this.elapsedSeconds,
    required this.requiredSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        (elapsedSeconds / requiredSeconds.clamp(1, 99999)).clamp(0.0, 1.0);
    final remaining = (requiredSeconds - elapsedSeconds).clamp(0, 99999);
    final m = remaining ~/ 60;
    final s = remaining % 60;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.deepPurple.withOpacity(0.3),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.grace.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Time Remaining',
                style:
                    AppTextStyles.titleMedium.copyWith(color: AppColors.ivory),
              ),
              Text(
                '${m}m ${s}s',
                style:
                    AppTextStyles.headlineSmall.copyWith(color: AppColors.grace),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppSpacing.borderRadiusSm,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.darkElevated,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? AppColors.forestGreen : AppColors.grace,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyRow extends StatelessWidget {
  final QuestDifficulty difficulty;
  const _DifficultyRow({required this.difficulty});

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
      children: [
        Text(
          'Difficulty: ',
          style:
              AppTextStyles.labelMedium.copyWith(color: AppColors.warmGrey),
        ),
        Text(
          difficulty.displayName,
          style: AppTextStyles.labelMedium.copyWith(color: color),
        ),
        const SizedBox(width: AppSpacing.xs),
        ...List.generate(4, (i) => Icon(
              i < stars ? Icons.star : Icons.star_border,
              color: color,
              size: 14,
            )),
      ],
    );
  }
}

class _CtaBar extends StatelessWidget {
  final QuestModel quest;
  final bool questStarted;
  final bool completing;
  final VoidCallback onBegin;
  final VoidCallback onComplete;

  const _CtaBar({
    required this.quest,
    required this.questStarted,
    required this.completing,
    required this.onBegin,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isTimed =
        quest.verificationType == QuestVerificationType.timedSession;
    final canComplete = !isTimed || questStarted;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.goldDark)),
        color: AppColors.darkCard,
      ),
      child: SafeArea(
        top: false,
        child: questStarted
            ? KingdomButton(
                label: 'I Did This ✓',
                onPressed: completing ? null : onComplete,
                isLoading: completing,
                icon: Icons.check_circle_outline,
              )
            : KingdomButton(
                label: 'Begin Quest',
                onPressed: canComplete ? onBegin : null,
                icon: Icons.play_arrow,
              ),
      ),
    );
  }
}
