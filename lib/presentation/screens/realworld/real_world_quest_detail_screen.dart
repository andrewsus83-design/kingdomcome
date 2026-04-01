import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/data/models/quest/real_world_quest_model.dart';
import 'package:kingdomcome/data/models/quest/real_world_completion_model.dart';
import 'package:kingdomcome/presentation/providers/real_world_quest_provider.dart';
import 'package:kingdomcome/presentation/widgets/common/kingdom_button.dart';

class RealWorldQuestDetailScreen extends ConsumerStatefulWidget {
  final String questId;
  const RealWorldQuestDetailScreen({super.key, required this.questId});

  @override
  ConsumerState<RealWorldQuestDetailScreen> createState() =>
      _RealWorldQuestDetailScreenState();
}

class _RealWorldQuestDetailScreenState
    extends ConsumerState<RealWorldQuestDetailScreen> {
  bool _questStarted = false;

  @override
  void initState() {
    super.initState();
    // Check if already started
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final questState = ref.read(realWorldQuestNotifierProvider);
      setState(() {
        _questStarted =
            questState.activeQuestIds.contains(widget.questId);
      });
    });
  }

  RealWorldQuestModel? _findQuest(RealWorldQuestState state) {
    try {
      return state.quests.firstWhere((q) => q.id == widget.questId);
    } catch (_) {
      return null;
    }
  }

  bool _isPending(RealWorldQuestState state) {
    return state.myCompletions.any(
      (c) =>
          c.questId == widget.questId &&
          c.status == CompletionStatus.pendingValidation,
    );
  }

  @override
  Widget build(BuildContext context) {
    final questState = ref.watch(realWorldQuestNotifierProvider);
    final quest = _findQuest(questState);
    final isPending = _isPending(questState);

    if (quest == null) {
      return Scaffold(
        backgroundColor: AppColors.darkSurface,
        appBar: AppBar(
          backgroundColor: AppColors.purpleDark,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.ivory),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Quest',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.goldLight,
            ),
          ),
        ),
        body: const Center(
          child: Text(
            'Quest not found.',
            style: TextStyle(color: AppColors.ivory),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
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
              _DetailHeader(quest: quest, onBack: () => context.pop()),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Virtue & quote card
                      _VirtueCard(quest: quest)
                          .animate()
                          .fadeIn(delay: 100.ms)
                          .slideY(begin: 0.05),

                      const SizedBox(height: AppSpacing.md),

                      // How to complete
                      _HowToCard(quest: quest)
                          .animate()
                          .fadeIn(delay: 150.ms)
                          .slideY(begin: 0.05),

                      const SizedBox(height: AppSpacing.md),

                      // Verification explanation
                      _VerificationCard(quest: quest)
                          .animate()
                          .fadeIn(delay: 200.ms)
                          .slideY(begin: 0.05),

                      const SizedBox(height: AppSpacing.md),

                      // Reward preview
                      _RewardPreviewCard(quest: quest)
                          .animate()
                          .fadeIn(delay: 250.ms)
                          .slideY(begin: 0.05),

                      // Digital Fast timer
                      if (quest.verification ==
                          RealWorldVerification.appTimer) ...[
                        const SizedBox(height: AppSpacing.md),
                        _EmbeddedTimerCard(quest: quest)
                            .animate()
                            .fadeIn(delay: 300.ms)
                            .slideY(begin: 0.05),
                      ],

                      const SizedBox(height: AppSpacing.xl),

                      // CTA buttons
                      if (isPending) ...[
                        _PendingStatusCard(),
                      ] else if (!_questStarted) ...[
                        KingdomButton(
                          label: "I'm Doing This Quest!",
                          icon: Icons.rocket_launch_rounded,
                          onPressed: () {
                            ref
                                .read(
                                    realWorldQuestNotifierProvider.notifier)
                                .startQuest(quest.id);
                            setState(() => _questStarted = true);
                          },
                        ),
                      ] else ...[
                        KingdomButton(
                          label: 'Complete Quest',
                          icon: Icons.check_circle_rounded,
                          onPressed: () {
                            context.push(
                              '/realworld/complete/${quest.id}',
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        KingdomButton(
                          label: 'Not ready yet',
                          isPrimary: false,
                          onPressed: () => context.pop(),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.xxl),
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

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _DetailHeader extends StatelessWidget {
  final RealWorldQuestModel quest;
  final VoidCallback onBack;

  const _DetailHeader({required this.quest, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.purpleDark.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: AppColors.darkElevated,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.ivory),
            onPressed: onBack,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            quest.iconEmoji,
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title,
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.goldLight,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      quest.category.emoji,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      quest.category.displayName,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.midGrey,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '~${quest.estimatedMinutes} min',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.midGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Virtue card
// ---------------------------------------------------------------------------

class _VirtueCard extends StatelessWidget {
  final RealWorldQuestModel quest;
  const _VirtueCard({required this.quest});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.purpleLight.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Text(
            quest.description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.ivory,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Virtue
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.deepPurple.withOpacity(0.4),
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Text(
              '✨ Virtue: ${quest.relatedVirtue}',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.purpleLight,
              ),
            ),
          ),
          if (quest.inspirationalQuote.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            // Catholic quote
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.purpleDark.withOpacity(0.4),
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(
                  color: AppColors.purpleLight.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📖',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    quest.inspirationalQuote,
                    style: AppTextStyles.scriptureQuote.copyWith(
                      color: AppColors.ivory.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// How to complete
// ---------------------------------------------------------------------------

class _HowToCard extends StatelessWidget {
  final RealWorldQuestModel quest;
  const _HowToCard({required this.quest});

  List<String> _stepsFor(RealWorldQuestModel q) {
    switch (q.verification) {
      case RealWorldVerification.parentValidate:
        return [
          'Choose a good time to do this quest.',
          'Complete the activity in real life.',
          'Tell your parent what you did.',
          'Ask them to open Kingdom Come and go to the Parent Gate.',
          'Your parent confirms it — and you earn your reward!',
        ];
      case RealWorldVerification.photoScan:
        return [
          'Complete the activity in real life.',
          'Take a photo as evidence.',
          'Open the Masterpiece Scanner in the app.',
          'Scan or upload your photo as proof.',
          'Submit for review!',
        ];
      case RealWorldVerification.appTimer:
        return [
          'Tap "Start Timer" below to begin tracking.',
          'Put down your device and complete the activity.',
          'Return and stop the timer when done.',
          'The app automatically checks if the challenge is complete.',
          'Your reward is granted instantly!',
        ];
      case RealWorldVerification.honorSystem:
        return [
          'Complete the activity in real life — no one is watching but God!',
          'Reflect honestly: did you truly do this?',
          'Tap "Complete Quest" and confirm on your honor.',
          'Your reward is granted right away.',
          'Remember: honesty is part of the virtue too!',
        ];
      case RealWorldVerification.churchCheckin:
        return [
          'Attend the church activity or event.',
          'Show your parent or a trusted adult.',
          'Have your parent confirm attendance in the Parent Gate.',
          'Or use the GPS check-in if available at your parish.',
          'Earn your reward for being part of the community!',
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = _stepsFor(quest);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.darkElevated),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How to Complete',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.ivory,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...steps.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.deepPurple,
                          border: Border.all(
                              color:
                                  AppColors.purpleLight.withOpacity(0.5)),
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.goldLight,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.ivory.withOpacity(0.85),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Verification card
// ---------------------------------------------------------------------------

class _VerificationCard extends StatelessWidget {
  final RealWorldQuestModel quest;
  const _VerificationCard({required this.quest});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.darkElevated),
      ),
      child: Row(
        children: [
          Text(
            quest.verification.emoji,
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verification: ${quest.verification.displayName}',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.ivory,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  quest.verification.explanation,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.midGrey,
                  ),
                ),
                if (quest.verification == RealWorldVerification.photoScan) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Text('📸', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        'Use Masterpiece Scanner to prove it!',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.holyPoints,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reward preview
// ---------------------------------------------------------------------------

class _RewardPreviewCard extends StatelessWidget {
  final RealWorldQuestModel quest;
  const _RewardPreviewCard({required this.quest});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.goldDark.withOpacity(0.2),
            AppColors.darkCard,
          ],
        ),
        borderRadius: AppSpacing.borderRadiusMd,
        border:
            Border.all(color: AppColors.goldDark.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Reward',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.goldLight,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              if (quest.holyPointsReward > 0)
                _BigRewardChip(
                  value: quest.holyPointsReward,
                  label: 'Holy Points',
                  emoji: '✨',
                  color: AppColors.holyPoints,
                ),
              if (quest.faithCoinsReward > 0)
                _BigRewardChip(
                  value: quest.faithCoinsReward,
                  label: 'Faith Coins',
                  emoji: '🪙',
                  color: AppColors.faithCoins,
                ),
              if (quest.graceReward > 0)
                _BigRewardChip(
                  value: quest.graceReward,
                  label: 'Grace',
                  emoji: '🌟',
                  color: AppColors.grace,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BigRewardChip extends StatelessWidget {
  final int value;
  final String label;
  final String emoji;
  final Color color;
  const _BigRewardChip({
    required this.value,
    required this.label,
    required this.emoji,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '+$value',
                style: AppTextStyles.statNumber.copyWith(
                  fontSize: 20,
                  color: color,
                ),
              ),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Embedded timer (Digital Fast quests)
// ---------------------------------------------------------------------------

class _EmbeddedTimerCard extends ConsumerWidget {
  final RealWorldQuestModel quest;
  const _EmbeddedTimerCard({required this.quest});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fastState = ref.watch(digitalFastNotifierProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1E2E),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: fastState.isTimerRunning
              ? AppColors.holyPoints.withOpacity(0.6)
              : AppColors.darkElevated,
          width: fastState.isTimerRunning ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Timer',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.ivory,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Big circular timer
          _CircularTimer(
            seconds: fastState.currentSessionSeconds,
            isRunning: fastState.isTimerRunning,
            targetSeconds: quest.estimatedMinutes * 60,
          ),
          const SizedBox(height: AppSpacing.md),
          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (!fastState.isTimerRunning)
                ElevatedButton.icon(
                  onPressed: () => ref
                      .read(digitalFastNotifierProvider.notifier)
                      .startSession(challengeId: quest.id),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Timer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forestGreen,
                  ),
                )
              else ...[
                ElevatedButton.icon(
                  onPressed: () => ref
                      .read(digitalFastNotifierProvider.notifier)
                      .pauseSession(),
                  icon: const Icon(Icons.pause),
                  label: const Text('Pause'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.inkBlack,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => ref
                      .read(digitalFastNotifierProvider.notifier)
                      .stopSession(),
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.crimson,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CircularTimer extends StatelessWidget {
  final int seconds;
  final bool isRunning;
  final int targetSeconds;

  const _CircularTimer({
    required this.seconds,
    required this.isRunning,
    required this.targetSeconds,
  });

  String _formatTime(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        targetSeconds > 0 ? (seconds / targetSeconds).clamp(0.0, 1.0) : 0.0;

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 8,
            backgroundColor: AppColors.darkElevated,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0
                  ? AppColors.forestGreen
                  : isRunning
                      ? AppColors.holyPoints
                      : AppColors.midGrey,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatTime(seconds),
                style: AppTextStyles.headlineMedium.copyWith(
                  color: isRunning ? AppColors.holyPoints : AppColors.midGrey,
                  fontFamily: 'Cinzel',
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
              if (targetSeconds > 0)
                Text(
                  'of ${_formatTime(targetSeconds)}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.midGrey,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pending status card
// ---------------------------------------------------------------------------

class _PendingStatusCard extends StatelessWidget {
  const _PendingStatusCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.goldDark.withOpacity(0.15),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.gold.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          const Text('⏳', style: TextStyle(fontSize: 36))
              .animate(onPlay: (c) => c.repeat())
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.1, 1.1),
                duration: 1000.ms,
              )
              .then()
              .scale(
                begin: const Offset(1.1, 1.1),
                end: const Offset(1, 1),
                duration: 1000.ms,
              ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Waiting for your parent to confirm...',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.goldLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Ask them to check the Parent Gate!',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.midGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'While you wait, check The Ark for more adventures!',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.midGrey,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
