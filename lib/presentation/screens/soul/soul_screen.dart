import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/presentation/providers/auth_provider.dart';
import 'package:kingdomcome/presentation/providers/streak_provider.dart';
import 'package:kingdomcome/routing/route_names.dart';

// ── Daily reflections ─────────────────────────────────────────────────────────

const _dailyReflections = [
  'What is one kind thing I can do for someone today?',
  'How did I see God\'s love in my day so far?',
  'Which virtue do I want to practice more?',
  'Who can I pray for today?',
  'What am I most grateful for right now?',
  'How can I be a peacemaker in my family today?',
  'What does it mean to love as Jesus loves?',
];

// ── Guardian saints (one per day of week) ─────────────────────────────────────

const _guardianSaints = [
  (name: 'St. Michael', emoji: '⚔️'),
  (name: 'St. Joseph', emoji: '🪵'),
  (name: 'Our Lady', emoji: '💙'),
  (name: 'St. Francis', emoji: '🌿'),
  (name: 'St. Therese', emoji: '🌹'),
  (name: 'St. Peter', emoji: '🔑'),
  (name: 'St. John', emoji: '✍️'),
];

// ── Soul screen ────────────────────────────────────────────────────────────────

class SoulScreen extends ConsumerWidget {
  const SoulScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final streaksAsync = ref.watch(streakNotifierProvider);
    final streaks = streaksAsync.valueOrNull ?? [];
    final prayerStreak = streaks
        .where((s) => s.type == StreakType.prayer)
        .fold(0, (_, s) => s.currentStreak);

    final dayOfWeek = DateTime.now().weekday - 1;
    final guardian = _guardianSaints[dayOfWeek % _guardianSaints.length];
    final reflection =
        _dailyReflections[dayOfWeek % _dailyReflections.length];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2A1A05),
              Color(0xFF1A0A00),
              Color(0xFF0D0008),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ─────────────────────────────────────────────────
                _SoulHeader(
                  username: user?.displayName ?? user?.username ?? 'Pilgrim',
                  guardian: guardian,
                  onSettings: () => context.push(RouteNames.settings),
                  onParentGate: () => context.push(RouteNames.parentGate),
                ).animate().fadeIn(),

                const SizedBox(height: AppSpacing.xl),

                // ── Guardian float ─────────────────────────────────────────
                _GuardianAvatar(guardian: guardian)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(begin: 0, end: -8, duration: 2000.ms, curve: Curves.easeInOut),

                const SizedBox(height: AppSpacing.xl),

                // ── Talk to Prayer Companion CTA ───────────────────────────
                _PrayerCompanionButton(
                  onTap: () => context.push(RouteNames.prayerChat),
                ).animate().fadeIn(delay: 200.ms).scale(
                      begin: const Offset(0.95, 0.95),
                      delay: 200.ms,
                    ),

                const SizedBox(height: AppSpacing.lg),

                // ── Daily reflection card ──────────────────────────────────
                _DailyReflectionCard(text: reflection)
                    .animate()
                    .fadeIn(delay: 300.ms),

                const SizedBox(height: AppSpacing.md),

                // ── Grace stats preview ────────────────────────────────────
                _GraceStatsPreview(
                  prayerStreak: prayerStreak,
                  onViewAll: () => context.push(RouteNames.graceStats),
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: AppSpacing.md),

                // ── Quick links ────────────────────────────────────────────
                _QuickLinks(
                  onGraceStats: () => context.push(RouteNames.graceStats),
                  onParentGate: () => context.push(RouteNames.parentGate),
                  onSettings: () => context.push(RouteNames.settings),
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Soul header ────────────────────────────────────────────────────────────────

class _SoulHeader extends StatelessWidget {
  final String username;
  final ({String name, String emoji}) guardian;
  final VoidCallback onSettings;
  final VoidCallback onParentGate;

  const _SoulHeader({
    required this.username,
    required this.guardian,
    required this.onSettings,
    required this.onParentGate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Soul',
                style: AppTextStyles.displaySmall.copyWith(
                  color: AppColors.goldLight,
                ),
              ),
              Text(
                '$username  •  Guardian: ${guardian.name}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.blessings.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.lock_outline, color: AppColors.midGrey),
          onPressed: onParentGate,
          tooltip: 'Parent Gate',
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: AppColors.midGrey),
          onPressed: onSettings,
          tooltip: 'Settings',
        ),
      ],
    );
  }
}

// ── Guardian avatar ────────────────────────────────────────────────────────────

class _GuardianAvatar extends StatelessWidget {
  final ({String name, String emoji}) guardian;

  const _GuardianAvatar({required this.guardian});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.deepPurple.withOpacity(0.3),
              border: Border.all(
                color: AppColors.gold.withOpacity(0.4),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.15),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Text(
                guardian.emoji,
                style: const TextStyle(fontSize: 52),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            guardian.name,
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.goldLight,
            ),
          ),
          Text(
            'Your Guardian Today',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.midGrey,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Prayer companion button ────────────────────────────────────────────────────

class _PrayerCompanionButton extends StatelessWidget {
  final VoidCallback onTap;

  const _PrayerCompanionButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: const RadialGradient(
            center: Alignment.center,
            radius: 0.8,
            colors: [
              Color(0xFF3D1A60),
              Color(0xFF2A0F40),
            ],
          ),
          borderRadius: AppSpacing.borderRadiusXl,
          border: Border.all(
            color: AppColors.gold.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withOpacity(0.15),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.15),
                shape: BoxShape.circle,
                border:
                    Border.all(color: AppColors.gold.withOpacity(0.5), width: 1.5),
              ),
              child: const Center(
                child: Icon(Icons.auto_stories, color: AppColors.gold, size: 26),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .shimmer(duration: 2500.ms, color: AppColors.goldLight.withOpacity(0.3)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Talk to your Prayer Companion',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.goldLight,
                    ),
                  ),
                  Text(
                    'Ask questions, write prayers, learn about saints',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.parchment.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: AppColors.goldDark, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Daily reflection card ──────────────────────────────────────────────────────

class _DailyReflectionCard extends StatelessWidget {
  final String text;

  const _DailyReflectionCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0A00).withOpacity(0.6),
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.blessings.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.blessings.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wb_sunny_outlined,
                color: AppColors.blessings, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Reflection',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.blessings.withOpacity(0.7),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: AppTextStyles.scriptureQuote.copyWith(
                    color: AppColors.parchment,
                    fontSize: 14,
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

// ── Grace stats preview ────────────────────────────────────────────────────────

class _GraceStatsPreview extends StatelessWidget {
  final int prayerStreak;
  final VoidCallback onViewAll;

  const _GraceStatsPreview({
    required this.prayerStreak,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onViewAll,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.darkCard.withOpacity(0.7),
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(color: AppColors.darkElevated),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Grace Stats',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.grace,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      _StatMini(
                        label: 'Prayer\nStreak',
                        value: '$prayerStreak days',
                        emoji: '🔥',
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _StatMini(
                        label: 'Good\nDeeds',
                        value: 'View →',
                        emoji: '✅',
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _StatMini(
                        label: 'Virtues',
                        value: 'Track →',
                        emoji: '⭐',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: AppColors.darkElevated, size: 14),
          ],
        ),
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;

  const _StatMini({
    required this.label,
    required this.value,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.ivory),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.midGrey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Quick links ────────────────────────────────────────────────────────────────

class _QuickLinks extends StatelessWidget {
  final VoidCallback onGraceStats;
  final VoidCallback onParentGate;
  final VoidCallback onSettings;

  const _QuickLinks({
    required this.onGraceStats,
    required this.onParentGate,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final links = [
      (icon: Icons.bar_chart_outlined, label: 'Grace Stats', onTap: onGraceStats),
      (icon: Icons.family_restroom, label: 'Parent Area', onTap: onParentGate),
      (icon: Icons.settings_outlined, label: 'Settings', onTap: onSettings),
    ];

    return Row(
      children: links.map((link) {
        return Expanded(
          child: GestureDetector(
            onTap: link.onTap,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.darkCard.withOpacity(0.6),
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(color: AppColors.darkElevated),
              ),
              child: Column(
                children: [
                  Icon(link.icon, color: AppColors.grace, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    link.label,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.midGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
