import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/presentation/providers/auth_provider.dart';

// ── Leaderboard entry model ───────────────────────────────────────────────────

class _LeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final String? avatarUrl;
  final int level;
  final int weeklyPoints;

  const _LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.level,
    required this.weeklyPoints,
  });

  String get rankTitle {
    return switch (rank) {
      1 => 'Chief Apostle',
      2 => 'High Deacon',
      3 => 'Elder',
      4 => 'Presbyter',
      5 => 'Acolyte',
      6 => 'Reader',
      7 => 'Catechumen',
      8 => 'Pilgrim',
      9 => 'Seeker',
      _ => 'Disciple',
    };
  }
}

// ── Provider ───────────────────────────────────────────────────────────────────

enum _LeaderboardPeriod { thisWeek, allTime }

final _leaderboardPeriodProvider =
    StateProvider<_LeaderboardPeriod>((_) => _LeaderboardPeriod.thisWeek);

final _leaderboardProvider =
    FutureProvider.family<List<_LeaderboardEntry>, _LeaderboardPeriod>(
        (ref, period) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final supabase = Supabase.instance.client;
  final column = period == _LeaderboardPeriod.thisWeek
      ? 'weekly_holy_points'
      : 'total_holy_points';

  // Fetch top 10
  final data = await supabase
      .from('user_profiles')
      .select(
          'user_id, profiles!inner(username, avatar_url, level), $column')
      .order(column, ascending: false)
      .limit(10) as List<dynamic>;

  return data.asMap().entries.map((e) {
    final row = e.value as Map<String, dynamic>;
    final profile = row['profiles'] as Map<String, dynamic>? ?? {};
    return _LeaderboardEntry(
      rank: e.key + 1,
      userId: row['user_id'] as String? ?? '',
      username: profile['username'] as String? ?? 'Pilgrim',
      avatarUrl: profile['avatar_url'] as String?,
      level: profile['level'] as int? ?? 1,
      weeklyPoints: row[column] as int? ?? 0,
    );
  }).toList();
});

// ── Screen ─────────────────────────────────────────────────────────────────────

class TopApostlesScreen extends ConsumerWidget {
  const TopApostlesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(_leaderboardPeriodProvider);
    final entriesAsync = ref.watch(_leaderboardProvider(period));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        backgroundColor: AppColors.purpleDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Top Apostles',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.goldLight,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined, color: AppColors.gold),
            onPressed: () => _showChallengeDialog(context),
            tooltip: 'Challenge a Friend',
          ),
        ],
      ),
      body: Column(
        children: [
          // Period toggle
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: AppColors.purpleDark,
            child: Row(
              children: [
                Expanded(
                  child: _PeriodToggle(
                    selected: period,
                    onChanged: (p) =>
                        ref.read(_leaderboardPeriodProvider.notifier).state = p,
                  ),
                ),
              ],
            ),
          ),

          // Podium for top 3
          entriesAsync.when(
            data: (entries) {
              if (entries.length >= 3) {
                return _Podium(
                  first: entries[0],
                  second: entries[1],
                  third: entries[2],
                ).animate().fadeIn(delay: 100.ms);
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox(
              height: 160,
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.gold)),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Full list
          Expanded(
            child: entriesAsync.when(
              data: (entries) {
                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: entries.length,
                  itemBuilder: (ctx, index) {
                    final entry = entries[index];
                    final isCurrentUser =
                        entry.userId == (currentUser?.id ?? '');
                    return _LeaderboardRow(
                      entry: entry,
                      isCurrentUser: isCurrentUser,
                    )
                        .animate(delay: (index * 50).ms)
                        .fadeIn()
                        .slideX(begin: 0.05);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off, color: AppColors.midGrey, size: 40),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Could not load leaderboard',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.midGrey),
                    ),
                    TextButton(
                      onPressed: () =>
                          ref.refresh(_leaderboardProvider(period)),
                      child: const Text('Retry',
                          style: TextStyle(color: AppColors.gold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChallengeDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusLg),
        title: Text(
          'Challenge a Friend',
          style:
              AppTextStyles.headlineSmall.copyWith(color: AppColors.goldLight),
        ),
        content: Text(
          'Share this week\'s top score with your friends and invite them to the Academy!\n\nThis feature is coming soon.',
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.parchment, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('OK', style: TextStyle(color: AppColors.gold)),
          ),
        ],
      ),
    );
  }
}

// ── Period toggle ──────────────────────────────────────────────────────────────

class _PeriodToggle extends StatelessWidget {
  final _LeaderboardPeriod selected;
  final void Function(_LeaderboardPeriod) onChanged;

  const _PeriodToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Row(
        children: [
          _ToggleButton(
            label: 'This Week',
            isSelected: selected == _LeaderboardPeriod.thisWeek,
            onTap: () => onChanged(_LeaderboardPeriod.thisWeek),
          ),
          _ToggleButton(
            label: 'All Time',
            isSelected: selected == _LeaderboardPeriod.allTime,
            onTap: () => onChanged(_LeaderboardPeriod.allTime),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.deepPurple : Colors.transparent,
            borderRadius: AppSpacing.borderRadiusMd,
            border: isSelected
                ? Border.all(color: AppColors.gold.withOpacity(0.5))
                : null,
          ),
          child: Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: isSelected ? AppColors.goldLight : AppColors.midGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// ── Podium ─────────────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  final _LeaderboardEntry first;
  final _LeaderboardEntry second;
  final _LeaderboardEntry third;

  const _Podium({
    required this.first,
    required this.second,
    required this.third,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.purpleDark,
            AppColors.darkSurface,
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 2nd place
          _PodiumColumn(
            entry: second,
            height: 80,
            medalEmoji: '🥈',
            color: const Color(0xFFC0C0C0),
          ),
          const SizedBox(width: AppSpacing.sm),
          // 1st place
          _PodiumColumn(
            entry: first,
            height: 110,
            medalEmoji: '🥇',
            color: AppColors.gold,
          ),
          const SizedBox(width: AppSpacing.sm),
          // 3rd place
          _PodiumColumn(
            entry: third,
            height: 60,
            medalEmoji: '🥉',
            color: const Color(0xFFCD7F32),
          ),
        ],
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final _LeaderboardEntry entry;
  final double height;
  final String medalEmoji;
  final Color color;

  const _PodiumColumn({
    required this.entry,
    required this.height,
    required this.medalEmoji,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(medalEmoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 2),
          Text(
            entry.username,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.ivory),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            '${entry.weeklyPoints}',
            style: AppTextStyles.labelSmall.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Container(
            height: height,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.radiusMd),
                topRight: Radius.circular(AppSpacing.radiusMd),
              ),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Center(
              child: Text(
                '${entry.rank}',
                style: AppTextStyles.headlineSmall.copyWith(color: color),
              ),
            ),
          ).animate().slideY(begin: 0.3, duration: 600.ms, curve: Curves.easeOutBack),
        ],
      ),
    );
  }
}

// ── Leaderboard row ────────────────────────────────────────────────────────────

class _LeaderboardRow extends StatelessWidget {
  final _LeaderboardEntry entry;
  final bool isCurrentUser;

  const _LeaderboardRow({
    required this.entry,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final rankColor = entry.rank == 1
        ? AppColors.gold
        : entry.rank == 2
            ? const Color(0xFFC0C0C0)
            : entry.rank == 3
                ? const Color(0xFFCD7F32)
                : AppColors.midGrey;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.deepPurple.withOpacity(0.4)
            : AppColors.darkCard,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: isCurrentUser
              ? AppColors.gold.withOpacity(0.5)
              : AppColors.darkElevated,
          width: isCurrentUser ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 32,
            child: Text(
              entry.rank <= 3
                  ? ['🥇', '🥈', '🥉'][entry.rank - 1]
                  : '${entry.rank}',
              style: AppTextStyles.headlineSmall.copyWith(color: rankColor),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          // Avatar
          Container(
            width: AppSpacing.avatarSm,
            height: AppSpacing.avatarSm,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.deepPurple,
              border: Border.all(color: rankColor.withOpacity(0.5)),
            ),
            child: Center(
              child: Text(
                entry.username.isNotEmpty
                    ? entry.username[0].toUpperCase()
                    : '?',
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.ivory),
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          // Name + title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.username,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: isCurrentUser
                            ? AppColors.goldLight
                            : AppColors.ivory,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.2),
                          borderRadius: AppSpacing.borderRadiusSm,
                        ),
                        child: Text(
                          'You',
                          style: AppTextStyles.badge.copyWith(
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${entry.rankTitle} • Lv.${entry.level}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.midGrey,
                  ),
                ),
              ],
            ),
          ),

          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.weeklyPoints}',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: rankColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '✨ pts',
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
