import 'dart:async';

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

// ── Local game definition model ───────────────────────────────────────────────

class _GameDef {
  final String id;
  final String name;
  final String emoji;
  final String tag;
  final String tagColor; // hex string
  final String duration;
  final String rewardText;
  final bool alwaysUnlocked;
  final int? requiredLevel;
  final String routePath;
  final Color tagBg;

  const _GameDef({
    required this.id,
    required this.name,
    required this.emoji,
    required this.tag,
    required this.duration,
    required this.rewardText,
    required this.alwaysUnlocked,
    required this.routePath,
    required this.tagBg,
    this.requiredLevel,
  }) : tagColor = '';
}

const _games = [
  _GameDef(
    id: 'trivia_arena',
    name: 'Trivia Arena',
    emoji: '⚡',
    tag: 'Lingo Style',
    duration: '2–3 min',
    rewardText: '+10 ✨ per correct',
    alwaysUnlocked: true,
    routePath: RouteNames.academyTrivia,
    tagBg: Color(0xFF1A4A8A),
  ),
  _GameDef(
    id: 'scripture_builder',
    name: 'Scripture Builder',
    emoji: '📜',
    tag: 'Word Puzzle',
    duration: '3–5 min',
    rewardText: '+15 ✨ per verse',
    alwaysUnlocked: false,
    requiredLevel: 3,
    routePath: RouteNames.academyPuzzleRooms,
    tagBg: Color(0xFF1A5C2A),
  ),
  _GameDef(
    id: 'saint_memory',
    name: 'Saint Memory Match',
    emoji: '🃏',
    tag: 'Memory',
    duration: '3–4 min',
    rewardText: '+8 🪵 per match',
    alwaysUnlocked: true,
    routePath: RouteNames.academyPuzzleRooms,
    tagBg: Color(0xFF5C2A1A),
  ),
  _GameDef(
    id: 'rosary_runner',
    name: 'Rosary Runner',
    emoji: '📿',
    tag: 'Runner',
    duration: '4–6 min',
    rewardText: '+20 🪵 per run',
    alwaysUnlocked: false,
    requiredLevel: 5,
    routePath: RouteNames.academyTrivia,
    tagBg: Color(0xFF4A1A6B),
  ),
  _GameDef(
    id: 'virtue_forge',
    name: 'Virtue Forge',
    emoji: '⚗️',
    tag: 'Card Game',
    duration: '5–8 min',
    rewardText: '+25 🪨 per win',
    alwaysUnlocked: false,
    requiredLevel: 8,
    routePath: RouteNames.academyTrivia,
    tagBg: Color(0xFF6B4A1A),
  ),
  _GameDef(
    id: 'liturgy_puzzle',
    name: 'Liturgy Puzzle',
    emoji: '🗓️',
    tag: 'Puzzle',
    duration: '3–5 min',
    rewardText: '+12 ✨ per puzzle',
    alwaysUnlocked: false,
    requiredLevel: 3,
    routePath: RouteNames.academyPuzzleRooms,
    tagBg: Color(0xFF1A4A4A),
  ),
];

// ── Fake leaderboard data (replaced by real API in production) ─────────────────

const _topApostles = [
  (name: 'MariaSt', score: 1240, level: 12),
  (name: 'FrancisB', score: 980, level: 9),
  (name: 'ThomasA', score: 870, level: 8),
];

// ── Academy screen ─────────────────────────────────────────────────────────────

class AcademyScreen extends ConsumerWidget {
  const AcademyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final streaksAsync = ref.watch(streakNotifierProvider);
    final streaks = streaksAsync.valueOrNull ?? [];
    final loginStreak = streaks
        .where((s) => s.type == StreakType.dailyQuest)
        .fold(0, (_, s) => s.currentStreak);

    // Player level — derive from XP or default to 1 for demo
    const int playerLevel = 4; // TODO: wire to kingdom_provider when XP exposed

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      body: CustomScrollView(
        slivers: [
          // ── Header sliver ───────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            backgroundColor: AppColors.purpleDark,
            flexibleSpace: FlexibleSpaceBar(
              background: _AcademyHeader(topApostles: _topApostles),
            ),
            title: Text(
              'The Academy',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.goldLight,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.leaderboard_outlined,
                    color: AppColors.gold),
                onPressed: () => context.push(RouteNames.academyLeaderboard),
                tooltip: 'Top Apostles',
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Daily challenge banner
                  _DailyChallengeBanner(
                    onTap: () => context.push(RouteNames.academyTrivia),
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.1),

                  const SizedBox(height: AppSpacing.md),

                  // Streak tracker
                  _StreakTracker(quizStreak: loginStreak)
                      .animate()
                      .fadeIn(delay: 200.ms),

                  const SizedBox(height: AppSpacing.md),

                  // Section title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Games',
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: AppColors.goldLight,
                        ),
                      ),
                      Text(
                        'Level $playerLevel',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.grace,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),

          // ── Game grid ───────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final game = _games[index];
                  final isLocked = !game.alwaysUnlocked &&
                      (game.requiredLevel != null &&
                          playerLevel < game.requiredLevel!);
                  return _GameCard(
                    game: game,
                    isLocked: isLocked,
                    onTap: isLocked
                        ? () => _showLockedDialog(
                            context, game.requiredLevel ?? 0)
                        : () => context.push(game.routePath),
                  )
                      .animate(delay: (index * 60).ms)
                      .fadeIn()
                      .scale(begin: const Offset(0.95, 0.95));
                },
                childCount: _games.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 0.78,
              ),
            ),
          ),

          // ── Leaderboard button ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _LeaderboardButton(
                onTap: () => context.push(RouteNames.academyLeaderboard),
              ).animate().fadeIn(delay: 500.ms),
            ),
          ),
        ],
      ),
    );
  }

  void _showLockedDialog(BuildContext context, int level) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape:
            RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
        title: Row(
          children: [
            const Icon(Icons.lock_outline, color: AppColors.goldDark),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Locked',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.goldLight,
              ),
            ),
          ],
        ),
        content: Text(
          'Reach Level $level to unlock this game!\nKeep completing quests and Bible readings to level up.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.parchment),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Got it',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.gold),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Academy header ────────────────────────────────────────────────────────────

class _AcademyHeader extends StatelessWidget {
  final List<({String name, int score, int level})> topApostles;

  const _AcademyHeader({required this.topApostles});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2D0F42), Color(0xFF1A0A2E)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, 56, AppSpacing.md, AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Top Apostles This Week',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.goldDark,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: topApostles.asMap().entries.map((e) {
                  final medals = ['🥇', '🥈', '🥉'];
                  return Expanded(
                    child: Container(
                      margin:
                          EdgeInsets.only(right: e.key < 2 ? AppSpacing.xs : 0),
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.darkCard.withOpacity(0.7),
                        borderRadius: AppSpacing.borderRadiusSm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(medals[e.key],
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.value.name,
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.ivory,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${e.value.score} pts',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.gold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Daily challenge banner ─────────────────────────────────────────────────────

class _DailyChallengeBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _DailyChallengeBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8B1A1A), Color(0xFFD4A017)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: AppSpacing.borderRadiusLg,
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('⚡', style: TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                    child: Text(
                      'DAILY CHALLENGE',
                      style: AppTextStyles.badge.copyWith(
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Trivia Arena — Saints Category',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Bonus: +50 ✨ for completing today',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Streak tracker ─────────────────────────────────────────────────────────────

class _StreakTracker extends StatelessWidget {
  final int quizStreak;

  const _StreakTracker({required this.quizStreak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.goldDark.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 22)),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quiz Streak',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.midGrey,
                ),
              ),
              Text(
                '$quizStreak days',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.lg),
          // Flame dots
          Row(
            children: List.generate(7, (i) {
              final active = i < quizStreak.clamp(0, 7);
              return Container(
                margin: const EdgeInsets.only(right: 4),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active
                      ? AppColors.faithCoins
                      : AppColors.darkElevated,
                ),
              );
            }),
          ),
          const Spacer(),
          Text(
            '+${(quizStreak * 5).clamp(0, 50)} bonus',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.faithCoins,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Game card ──────────────────────────────────────────────────────────────────

class _GameCard extends StatelessWidget {
  final _GameDef game;
  final bool isLocked;
  final VoidCallback onTap;

  const _GameCard({
    required this.game,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: isLocked
                ? AppColors.darkElevated
                : AppColors.goldDark.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: isLocked
              ? null
              : [
                  BoxShadow(
                    color: game.tagBg.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emoji + tag row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.emoji,
                        style: TextStyle(
                          fontSize: 32,
                          color: isLocked
                              ? null
                              : null,
                        ),
                      ).animate(
                        onPlay: (c) => c.repeat(reverse: true),
                      ).shimmer(
                        duration: 3000.ms,
                        color: isLocked
                            ? AppColors.midGrey.withOpacity(0.3)
                            : AppColors.goldLight.withOpacity(0.4),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isLocked
                              ? AppColors.darkElevated
                              : game.tagBg,
                          borderRadius: AppSpacing.borderRadiusSm,
                        ),
                        child: Text(
                          game.tag,
                          style: AppTextStyles.badge.copyWith(
                            color: isLocked
                                ? AppColors.midGrey
                                : Colors.white,
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  Text(
                    game.name,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: isLocked
                          ? AppColors.midGrey
                          : AppColors.ivory,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  Text(
                    game.duration,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.midGrey,
                    ),
                  ),

                  const Spacer(),

                  // Score row (fake high score for demo)
                  Row(
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        color: isLocked
                            ? AppColors.darkElevated
                            : AppColors.gold,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isLocked ? '---' : '0 pts',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    game.rewardText,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isLocked
                          ? AppColors.darkElevated
                          : AppColors.faithCoins,
                    ),
                  ),
                ],
              ),
            ),

            // Lock overlay
            if (isLocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface.withOpacity(0.6),
                    borderRadius: AppSpacing.borderRadiusLg,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          color: AppColors.midGrey,
                          size: AppSpacing.iconLg,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lv.${game.requiredLevel}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.midGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Leaderboard button ─────────────────────────────────────────────────────────

class _LeaderboardButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LeaderboardButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(color: AppColors.gold.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.leaderboard, color: AppColors.gold),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'View Top Apostles Leaderboard',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.goldLight,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.arrow_forward_ios,
                color: AppColors.goldDark, size: 14),
          ],
        ),
      ),
    );
  }
}
