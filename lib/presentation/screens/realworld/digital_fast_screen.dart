import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/presentation/providers/real_world_quest_provider.dart';
import 'package:kingdomcome/presentation/widgets/common/kingdom_button.dart';

// ---------------------------------------------------------------------------
// Challenge definition
// ---------------------------------------------------------------------------

class _DigitalChallenge {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final int durationMinutes;
  final int holyPointsReward;
  final int faithCoinsReward;
  final bool isWeekly;

  const _DigitalChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.durationMinutes,
    required this.holyPointsReward,
    this.faithCoinsReward = 0,
    this.isWeekly = false,
  });
}

const _challenges = [
  _DigitalChallenge(
    id: 'gadget_free_meal',
    title: 'Gadget-Free Meal',
    description: 'Enjoy a meal without any screens — be present with family.',
    emoji: '🍽️',
    durationMinutes: 30,
    holyPointsReward: 0,
    faithCoinsReward: 50,
  ),
  _DigitalChallenge(
    id: 'morning_prayer_first',
    title: 'Morning Prayer First',
    description: 'Open the app and pray before checking social media.',
    emoji: '🙏',
    durationMinutes: 5,
    holyPointsReward: 40,
  ),
  _DigitalChallenge(
    id: 'two_hour_break',
    title: '2-Hour Break',
    description: 'Two full hours without any screen — go outside!',
    emoji: '🌿',
    durationMinutes: 120,
    holyPointsReward: 100,
  ),
  _DigitalChallenge(
    id: 'screen_free_bedtime',
    title: 'Screen-Free Bedtime',
    description: 'No screens for one hour before sleep.',
    emoji: '🌙',
    durationMinutes: 60,
    holyPointsReward: 30,
  ),
  _DigitalChallenge(
    id: 'digital_sabbath',
    title: 'Digital Sabbath',
    description:
        'A full day challenge — no social media or entertainment screens.',
    emoji: '✝️',
    durationMinutes: 480,
    holyPointsReward: 500,
    isWeekly: true,
  ),
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class DigitalFastScreen extends ConsumerWidget {
  const DigitalFastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fastState = ref.watch(digitalFastNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF050D1A), AppColors.darkSurface],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App bar
              SliverAppBar(
                pinned: true,
                backgroundColor: const Color(0xFF050D1A),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.ivory),
                  onPressed: () => context.pop(),
                ),
                title: Text(
                  '📵 Digital Fast',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.ivory,
                  ),
                ),
              ),

              // Active session display
              SliverToBoxAdapter(
                child: _ActiveSessionCard(fastState: fastState)
                    .animate()
                    .fadeIn(duration: 400.ms),
              ),

              // Today's stats
              SliverToBoxAdapter(
                child: _TodayStatsCard(fastState: fastState)
                    .animate(delay: 100.ms)
                    .fadeIn(),
              ),

              // Candle holder visualisation
              SliverToBoxAdapter(
                child: _CandleHolderCard(fastState: fastState)
                    .animate(delay: 150.ms)
                    .fadeIn(),
              ),

              // Challenges header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Text(
                    'Available Challenges',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.goldLight,
                    ),
                  ).animate(delay: 200.ms).fadeIn(),
                ),
              ),

              // Challenge cards
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _ChallengeCard(
                      challenge: _challenges[i],
                      fastState: fastState,
                    )
                        .animate(delay: (200 + i * 60).ms)
                        .fadeIn(duration: 300.ms)
                        .slideX(begin: -0.05),
                    childCount: _challenges.length,
                  ),
                ),
              ),

              // Streak section
              SliverToBoxAdapter(
                child: _StreakCard(fastState: fastState)
                    .animate(delay: 400.ms)
                    .fadeIn(),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xxl),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Active session card
// ---------------------------------------------------------------------------

class _ActiveSessionCard extends ConsumerWidget {
  final DigitalFastState fastState;
  const _ActiveSessionCard({required this.fastState});

  String _formatTime(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: fastState.isTimerRunning
              ? [
                  const Color(0xFF0D2137),
                  const Color(0xFF051525),
                ]
              : [
                  AppColors.darkCard,
                  AppColors.darkSurface,
                ],
        ),
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: fastState.isTimerRunning
              ? AppColors.holyPoints.withOpacity(0.7)
              : AppColors.darkElevated,
          width: fastState.isTimerRunning ? 2 : 1,
        ),
        boxShadow: fastState.isTimerRunning
            ? [
                BoxShadow(
                  color: AppColors.holyPoints.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 3,
                )
              ]
            : null,
      ),
      child: Column(
        children: [
          Text(
            fastState.isTimerRunning
                ? 'Gadget-Free Session Active'
                : 'Start a Gadget-Free Session',
            style: AppTextStyles.headlineSmall.copyWith(
              color: fastState.isTimerRunning
                  ? AppColors.holyPoints
                  : AppColors.ivory,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          // Big circular timer
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer ring
                CircularProgressIndicator(
                  value: fastState.isTimerRunning
                      ? null // indeterminate when running (no target yet)
                      : 0,
                  strokeWidth: 6,
                  backgroundColor: AppColors.darkElevated,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    fastState.isTimerRunning
                        ? AppColors.holyPoints
                        : AppColors.midGrey,
                  ),
                ),
                // Inner content
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (fastState.isTimerRunning) ...[
                      Text(
                        _formatTime(fastState.currentSessionSeconds),
                        style: AppTextStyles.statNumber.copyWith(
                          color: AppColors.holyPoints,
                          fontFeatures: [
                            const FontFeature.tabularFigures()
                          ],
                        ),
                      ),
                      Text(
                        'current session',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.midGrey,
                        ),
                      ),
                    ] else ...[
                      const Text('📵',
                          style: TextStyle(fontSize: 48)),
                      Text(
                        'Tap to begin',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.midGrey,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Controls
          if (!fastState.isTimerRunning)
            KingdomButton(
              label: 'Start Session',
              icon: Icons.play_arrow_rounded,
              onPressed: () =>
                  ref.read(digitalFastNotifierProvider.notifier).startSession(),
            )
          else
            Row(
              children: [
                Expanded(
                  child: KingdomButton(
                    label: 'Pause',
                    icon: Icons.pause_rounded,
                    isPrimary: false,
                    onPressed: () => ref
                        .read(digitalFastNotifierProvider.notifier)
                        .pauseSession(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: KingdomButton(
                    label: 'Stop',
                    icon: Icons.stop_rounded,
                    onPressed: () => ref
                        .read(digitalFastNotifierProvider.notifier)
                        .stopSession(),
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
// Today's stats card
// ---------------------------------------------------------------------------

class _TodayStatsCard extends StatelessWidget {
  final DigitalFastState fastState;
  const _TodayStatsCard({required this.fastState});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
            "Today's Stats",
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.ivory,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _StatItem(
                emoji: '📵',
                label: 'Gadget-Free',
                value:
                    '${fastState.totalGadgetFreeMinutesToday} min',
                color: AppColors.holyPoints,
              ),
              const SizedBox(width: AppSpacing.md),
              _StatItem(
                emoji: '🕯️',
                label: 'Candles Lit',
                value: '${fastState.candlesLit}/8',
                color: AppColors.faithCoins,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.midGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTextStyles.titleLarge.copyWith(
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Candle holder visualization
// ---------------------------------------------------------------------------

class _CandleHolderCard extends StatelessWidget {
  final DigitalFastState fastState;
  const _CandleHolderCard({required this.fastState});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.darkElevated),
      ),
      child: Column(
        children: [
          Text(
            'Every 30 min gadget-free = one candle lit',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.midGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              8,
              (i) => _Candle(
                isLit: i < fastState.candlesLit,
                index: i,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Candle extends StatelessWidget {
  final bool isLit;
  final int index;
  const _Candle({required this.isLit, required this.index});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Flame
        AnimatedContainer(
          duration: Duration(milliseconds: 300 + index * 50),
          child: isLit
              ? Text(
                  '🔥',
                  style: TextStyle(
                    fontSize: 16,
                    shadows: [
                      Shadow(
                        color: Colors.orange.withOpacity(0.6),
                        blurRadius: 8,
                      )
                    ],
                  ),
                ).animate(onPlay: (c) => c.repeat()).shimmer(
                    color: Colors.orange.withOpacity(0.3),
                    duration: 1500.ms,
                  )
              : const Text('  ',
                  style: TextStyle(fontSize: 16)),
        ),
        // Candle body
        Container(
          width: 12,
          height: 28,
          decoration: BoxDecoration(
            color: isLit ? AppColors.ivory : AppColors.darkElevated,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(2),
            ),
            boxShadow: isLit
                ? [
                    BoxShadow(
                      color: AppColors.faithCoins.withOpacity(0.3),
                      blurRadius: 6,
                    )
                  ]
                : null,
          ),
        ),
        // Base
        Container(
          width: 18,
          height: 4,
          decoration: BoxDecoration(
            color: isLit ? AppColors.parchmentDark : AppColors.darkElevated,
            borderRadius: AppSpacing.borderRadiusSm,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Challenge card
// ---------------------------------------------------------------------------

class _ChallengeCard extends ConsumerWidget {
  final _DigitalChallenge challenge;
  final DigitalFastState fastState;
  const _ChallengeCard({
    required this.challenge,
    required this.fastState,
  });

  bool get _isActive =>
      fastState.isTimerRunning &&
      fastState.activeChallengeId == challenge.id;

  bool get _isCompleted {
    // Check if enough time has elapsed for this challenge
    final minutesNeeded = challenge.durationMinutes;
    return fastState.totalGadgetFreeMinutesToday >= minutesNeeded;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _isActive
            ? const Color(0xFF0D2137)
            : _isCompleted
                ? AppColors.forestGreen.withOpacity(0.1)
                : AppColors.darkCard,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: _isActive
              ? AppColors.holyPoints.withOpacity(0.7)
              : _isCompleted
                  ? AppColors.forestGreen.withOpacity(0.5)
                  : AppColors.darkElevated,
          width: _isActive ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Text(challenge.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      challenge.title,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: _isCompleted
                            ? AppColors.forestGreen
                            : AppColors.ivory,
                      ),
                    ),
                    if (challenge.isWeekly) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.grace.withOpacity(0.2),
                          borderRadius: AppSpacing.borderRadiusSm,
                        ),
                        child: Text(
                          'Weekly',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.grace,
                          ),
                        ),
                      ),
                    ],
                    if (_isCompleted) ...[
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.forestGreen,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                Text(
                  challenge.description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.midGrey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Text(
                      '⏱️ ${challenge.durationMinutes >= 60 ? '${challenge.durationMinutes ~/ 60}h' : '${challenge.durationMinutes}m'}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.midGrey,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (challenge.holyPointsReward > 0)
                      Text(
                        '+${challenge.holyPointsReward} HP',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.holyPoints,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (challenge.faithCoinsReward > 0) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '+${challenge.faithCoinsReward} FC',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.faithCoins,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Start / active button
          if (!_isCompleted)
            GestureDetector(
              onTap: _isActive
                  ? null
                  : () {
                      ref
                          .read(digitalFastNotifierProvider.notifier)
                          .startSession(challengeId: challenge.id);
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: _isActive
                      ? AppColors.holyPoints.withOpacity(0.2)
                      : AppColors.deepPurple,
                  borderRadius: AppSpacing.borderRadiusSm,
                  border: Border.all(
                    color: _isActive
                        ? AppColors.holyPoints
                        : AppColors.gold.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  _isActive ? 'Active' : 'Start',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: _isActive
                        ? AppColors.holyPoints
                        : AppColors.goldLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            Text('Done!',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.forestGreen,
                  fontWeight: FontWeight.w700,
                )),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Streak card
// ---------------------------------------------------------------------------

class _StreakCard extends StatelessWidget {
  final DigitalFastState fastState;
  const _StreakCard({required this.fastState});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.crimson.withOpacity(0.2),
            AppColors.darkCard,
          ],
        ),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: AppColors.crimson.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Text(
            '🔥',
            style: TextStyle(
              fontSize: 40,
              shadows: [
                Shadow(
                  color: Colors.orange.withOpacity(0.6),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Digital Fasting Streak',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.ivory,
                  ),
                ),
                Text(
                  '${fastState.streakDays} day${fastState.streakDays == 1 ? '' : 's'} in a row',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.faithCoins,
                  ),
                ),
                Text(
                  'Keep going — virtue grows through practice!',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.midGrey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
