import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/presentation/providers/auth_provider.dart';
import 'package:kingdomcome/presentation/providers/resource_provider.dart';
import 'package:kingdomcome/presentation/providers/saint_provider.dart';
import 'package:kingdomcome/presentation/providers/streak_provider.dart';
import 'package:kingdomcome/presentation/widgets/common/streak_flame_widget.dart';
import 'package:kingdomcome/presentation/widgets/common/xp_progress_bar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final resourcesAsync = ref.watch(resourceNotifierProvider);
    final streaks = ref.watch(streakNotifierProvider).valueOrNull ?? [];
    final activeSaint = ref.watch(activeSaintProvider);
    final saints = ref.watch(saintNotifierProvider).valueOrNull ?? [];

    final activeSaintModel = activeSaint != null
        ? saints.where((s) => s.id == activeSaint.saintId).firstOrNull
        : null;

    if (user == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    }

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      body: CustomScrollView(
        slivers: [
          // Profile header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.purpleDark,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: AppColors.gold),
                onPressed: () => context.push('/settings'),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _ProfileHeader(
                user: user,
                activeSaintName: activeSaintModel?.name,
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // XP Progress bar
                resourcesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (res) => Column(
                    children: [
                      XpProgressBar(
                        holyPoints: res.holyPoints,
                      ).animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),

                // Resources card
                resourcesAsync.when(
                  loading: () => const CircularProgressIndicator(
                      color: AppColors.gold),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (res) => _ResourcesCard(resources: res)
                      .animate()
                      .fadeIn(delay: 200.ms),
                ),

                const SizedBox(height: AppSpacing.md),

                // Streaks card
                if (streaks.isNotEmpty)
                  _StreaksCard(streaks: streaks)
                      .animate()
                      .fadeIn(delay: 300.ms),

                const SizedBox(height: AppSpacing.md),

                // Guardian saint card
                if (activeSaintModel != null)
                  _GuardianSaintCard(saint: activeSaintModel)
                      .animate()
                      .fadeIn(delay: 400.ms),

                const SizedBox(height: AppSpacing.md),

                // Achievement badges (placeholder)
                _AchievementsSection()
                    .animate()
                    .fadeIn(delay: 500.ms),

                const SizedBox(height: AppSpacing.md),

                // Sign out
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authNotifierProvider.notifier).signOut();
                    if (context.mounted) context.go('/login');
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.crimson),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.borderRadiusMd,
                    ),
                  ),
                  icon: const Icon(Icons.logout, color: AppColors.crimson),
                  label: Text(
                    'Sign Out',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.crimson,
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms),

                const SizedBox(height: AppSpacing.xxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile header ────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final dynamic user;
  final String? activeSaintName;

  const _ProfileHeader({required this.user, this.activeSaintName});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.purpleDark, AppColors.darkCard],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold, width: 3),
                  color: AppColors.deepPurple,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: user.avatarUrl != null
                    ? ClipOval(
                        child: Image.network(
                          user.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person,
                            color: AppColors.gold,
                            size: 40,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: AppColors.gold,
                        size: 40,
                      ),
              ),
              const SizedBox(width: AppSpacing.md),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.displayName,
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: AppColors.goldLight,
                      ),
                    ),
                    Text(
                      '@${user.username}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.midGrey,
                      ),
                    ),
                    if (activeSaintName != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          const Icon(Icons.shield,
                              color: AppColors.gold, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'Guardian: $activeSaintName',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.gold,
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
        ),
      ),
    );
  }
}

// ── Resources card ────────────────────────────────────────────────────────────

class _ResourcesCard extends StatelessWidget {
  final dynamic resources;
  const _ResourcesCard({required this.resources});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.goldDark.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resources',
            style:
                AppTextStyles.headlineSmall.copyWith(color: AppColors.goldLight),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ResourceStat(
                  icon: Icons.star,
                  label: 'Holy Points',
                  value: resources.holyPoints,
                  color: AppColors.holyPoints),
              _ResourceStat(
                  icon: Icons.monetization_on,
                  label: 'Faith Coins',
                  value: resources.faithCoins,
                  color: AppColors.faithCoins),
              _ResourceStat(
                  icon: Icons.auto_awesome,
                  label: 'Grace',
                  value: resources.grace,
                  color: AppColors.grace),
              _ResourceStat(
                  icon: Icons.favorite,
                  label: 'Blessings',
                  value: resources.blessings,
                  color: AppColors.blessings),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResourceStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _ResourceStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          _formatValue(value),
          style: AppTextStyles.headlineSmall.copyWith(color: color),
        ),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.midGrey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatValue(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toString();
  }
}

// ── Streaks card ──────────────────────────────────────────────────────────────

class _StreaksCard extends StatelessWidget {
  final List<StreakModel> streaks;
  const _StreaksCard({required this.streaks});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.goldDark.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Streaks',
            style:
                AppTextStyles.headlineSmall.copyWith(color: AppColors.goldLight),
          ),
          const SizedBox(height: AppSpacing.md),
          ...streaks.map((streak) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _StreakRow(streak: streak),
              )),
        ],
      ),
    );
  }
}

class _StreakRow extends StatelessWidget {
  final StreakModel streak;
  const _StreakRow({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        StreakFlameWidget(
          count: streak.currentStreak,
          isAtRisk: streak.isAtRisk,
          showCount: false,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                streak.type.displayName,
                style:
                    AppTextStyles.titleMedium.copyWith(color: AppColors.ivory),
              ),
              Text(
                '${streak.currentStreak} days current · ${streak.longestStreak} days best',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.midGrey,
                ),
              ),
            ],
          ),
        ),
        if (streak.shieldActive)
          const Icon(Icons.shield, color: AppColors.holyPoints, size: 20),
      ],
    );
  }
}

// ── Guardian saint card ───────────────────────────────────────────────────────

class _GuardianSaintCard extends StatelessWidget {
  final dynamic saint;
  const _GuardianSaintCard({required this.saint});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/saints/${saint.id}'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.gold.withOpacity(0.15),
              AppColors.darkCard,
            ],
          ),
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(color: AppColors.gold.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold, width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  saint.portraitAssetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.person,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Guardian Saint',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.gold,
                    ),
                  ),
                  Text(
                    saint.name,
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.ivory,
                    ),
                  ),
                  Text(
                    saint.patronage,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.midGrey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: AppColors.gold, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Achievements section ──────────────────────────────────────────────────────

class _AchievementsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Placeholder achievement badges
    final badges = [
      _Badge(icon: Icons.auto_stories, label: 'First Prayer', color: AppColors.holyPoints),
      _Badge(icon: Icons.church, label: 'Mass Goer', color: AppColors.gold),
      _Badge(icon: Icons.star, label: 'Saint Seeker', color: AppColors.grace),
      _Badge(icon: Icons.local_fire_department, label: '7-Day Streak', color: Colors.orange),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.goldDark.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Achievements',
            style: AppTextStyles.headlineSmall
                .copyWith(color: AppColors.goldLight),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: badges.map((b) => _AchievementBadge(badge: b)).toList(),
          ),
        ],
      ),
    );
  }
}

class _Badge {
  final IconData icon;
  final String label;
  final Color color;
  const _Badge({required this.icon, required this.label, required this.color});
}

class _AchievementBadge extends StatelessWidget {
  final _Badge badge;
  const _AchievementBadge({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs + 2),
      decoration: BoxDecoration(
        color: badge.color.withOpacity(0.12),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: badge.color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badge.icon, color: badge.color, size: 14),
          const SizedBox(width: 4),
          Text(
            badge.label,
            style: AppTextStyles.labelSmall.copyWith(color: badge.color),
          ),
        ],
      ),
    );
  }
}
