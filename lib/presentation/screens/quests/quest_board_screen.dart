import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/core/theme/liturgical_colors.dart';
import 'package:kingdomcome/presentation/providers/quest_provider.dart';
import 'package:kingdomcome/presentation/providers/liturgical_calendar_provider.dart';
import 'package:kingdomcome/presentation/widgets/quest/quest_card.dart';
import 'package:kingdomcome/data/models/quest/quest_model.dart';

class QuestBoardScreen extends ConsumerWidget {
  const QuestBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final season = ref.watch(currentSeasonProvider);
    final seasonName = LiturgicalColors.displayNameFor(season);
    final seasonColor = LiturgicalColors.primaryFor(season);

    final dailyQuests = ref.watch(dailyQuestsProvider);
    final weeklyQuests = ref.watch(weeklyQuestsProvider);
    final liturgicalQuests = ref.watch(liturgicalQuestsProvider);
    final questsAsync = ref.watch(questNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: () => ref.read(questNotifierProvider.notifier).refreshDaily(),
        child: CustomScrollView(
          slivers: [
            // App bar with liturgical season banner
            SliverAppBar(
              pinned: true,
              expandedHeight: 120,
              backgroundColor: seasonColor,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        seasonColor,
                        LiturgicalColors.surfaceFor(season),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.08,
                          child: Image.asset(
                            'assets/images/ui/parchment_texture.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md, 60, AppSpacing.md, AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Quest Board',
                              style: AppTextStyles.displaySmall.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                            Text(
                              '$seasonName Season',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Loading / error state
            if (questsAsync.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
              )
            else ...[
              // Daily quests section
              _SectionHeader(
                title: 'Daily Quests',
                subtitle: _dailyResetText(),
                icon: Icons.wb_sunny_outlined,
                color: AppColors.faithCoins,
              ),
              if (dailyQuests.isEmpty)
                const _EmptySection(
                    message: 'All daily quests complete! Come back tomorrow.')
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => QuestCard(
                      quest: dailyQuests[i],
                      onTap: () =>
                          ctx.push('/quests/${dailyQuests[i].id}'),
                    ).animate(delay: (i * 60).ms).fadeIn().slideX(begin: -0.1),
                    childCount: dailyQuests.length,
                  ),
                ),

              // Weekly quests section
              _SectionHeader(
                title: 'Weekly Quests',
                subtitle: _weeklyResetText(),
                icon: Icons.calendar_view_week_outlined,
                color: AppColors.grace,
              ),
              if (weeklyQuests.isEmpty)
                const _EmptySection(
                    message: 'All weekly quests complete! Great work.')
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => QuestCard(
                      quest: weeklyQuests[i],
                      onTap: () =>
                          ctx.push('/quests/${weeklyQuests[i].id}'),
                    ).animate(delay: (i * 60).ms).fadeIn().slideX(begin: -0.1),
                    childCount: weeklyQuests.length,
                  ),
                ),

              // Liturgical season quests
              if (liturgicalQuests.isNotEmpty) ...[
                _SectionHeader(
                  title: '$seasonName Quests',
                  subtitle: 'Special quests for this holy season',
                  icon: Icons.auto_awesome,
                  color: LiturgicalColors.accentFor(season),
                  isSeasonal: true,
                  seasonColor: seasonColor,
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => QuestCard(
                      quest: liturgicalQuests[i],
                      isLiturgical: true,
                      seasonColor: seasonColor,
                      onTap: () =>
                          ctx.push('/quests/${liturgicalQuests[i].id}'),
                    )
                        .animate(delay: (i * 60).ms)
                        .fadeIn()
                        .slideX(begin: -0.1),
                    childCount: liturgicalQuests.length,
                  ),
                ),
              ],

              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xxl),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _dailyResetText() {
    final now = DateTime.now();
    final midnight =
        DateTime(now.year, now.month, now.day + 1);
    final diff = midnight.difference(now);
    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60);
    return 'Resets in ${h}h ${m}m';
  }

  String _weeklyResetText() {
    final now = DateTime.now();
    final daysUntilMonday = (8 - now.weekday) % 7;
    final nextMonday = DateTime(
        now.year, now.month, now.day + (daysUntilMonday == 0 ? 7 : daysUntilMonday));
    return 'Resets ${DateFormat('EEEE').format(nextMonday)}';
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSeasonal;
  final Color? seasonColor;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.isSeasonal = false,
    this.seasonColor,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSeasonal
              ? (seasonColor ?? color).withOpacity(0.15)
              : AppColors.darkCard,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(
            color: (isSeasonal ? (seasonColor ?? color) : color)
                .withOpacity(0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.ivory,
                      )),
                  Text(subtitle,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.midGrey,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String message;
  const _EmptySection({required this.message});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                color: AppColors.forestGreen, size: 16),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.midGrey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
