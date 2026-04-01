import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/game_constants.dart';
import 'package:kingdomcome/presentation/providers/resource_provider.dart';
import 'package:kingdomcome/presentation/widgets/common/kingdom_button.dart';

// ── Difficulty enum ────────────────────────────────────────────────────────────

enum _Difficulty { easy, medium, hard }

extension _DifficultyX on _Difficulty {
  String get label {
    return switch (this) {
      _Difficulty.easy => 'Easy',
      _Difficulty.medium => 'Medium',
      _Difficulty.hard => 'Hard',
    };
  }

  Color get color {
    return switch (this) {
      _Difficulty.easy => const Color(0xFF1A6B3A),
      _Difficulty.medium => const Color(0xFF6B4A1A),
      _Difficulty.hard => const Color(0xFF6B1A1A),
    };
  }
}

// ── Video tutorial model ───────────────────────────────────────────────────────

class _VideoTutorial {
  final String id;
  final String title;
  final String emoji;
  final String duration;
  final _Difficulty difficulty;
  final List<String> materials;
  final int faithCoinReward;
  final String youtubeVideoId; // YouTube placeholder ID

  const _VideoTutorial({
    required this.id,
    required this.title,
    required this.emoji,
    required this.duration,
    required this.difficulty,
    required this.materials,
    required this.faithCoinReward,
    required this.youtubeVideoId,
  });
}

const _tutorials = [
  _VideoTutorial(
    id: 'rosary_making',
    title: 'How to Make a Rosary',
    emoji: '📿',
    duration: '12 min',
    difficulty: _Difficulty.medium,
    materials: ['Beads (59)', 'String or wire', 'Crucifix pendant', 'Jump rings'],
    faithCoinReward: 20,
    youtubeVideoId: 'dQw4w9WgXcQ', // placeholder
  ),
  _VideoTutorial(
    id: 'noah_ark_origami',
    title: 'Paper Origami Noah\'s Ark',
    emoji: '🚢',
    duration: '8 min',
    difficulty: _Difficulty.easy,
    materials: ['Blue & brown paper', 'Scissors', 'Glue stick'],
    faithCoinReward: 15,
    youtubeVideoId: 'dQw4w9WgXcQ',
  ),
  _VideoTutorial(
    id: 'saint_prayer_card',
    title: 'Make a Saint Prayer Card',
    emoji: '🙏',
    duration: '10 min',
    difficulty: _Difficulty.easy,
    materials: ['Card stock', 'Markers', 'Scissors', 'Optional: stickers'],
    faithCoinReward: 15,
    youtubeVideoId: 'dQw4w9WgXcQ',
  ),
  _VideoTutorial(
    id: 'advent_wreath',
    title: 'Advent Wreath DIY',
    emoji: '🕯️',
    duration: '15 min',
    difficulty: _Difficulty.medium,
    materials: [
      'Evergreen branches',
      '4 candles (3 purple, 1 pink)',
      'Wire wreath frame',
      'Ribbon',
    ],
    faithCoinReward: 25,
    youtubeVideoId: 'dQw4w9WgXcQ',
  ),
  _VideoTutorial(
    id: 'easter_egg_symbols',
    title: 'Easter Egg Biblical Symbols',
    emoji: '🥚',
    duration: '18 min',
    difficulty: _Difficulty.medium,
    materials: ['Hard-boiled eggs', 'Natural dyes', 'Wax crayons', 'Vinegar'],
    faithCoinReward: 20,
    youtubeVideoId: 'dQw4w9WgXcQ',
  ),
  _VideoTutorial(
    id: 'nativity_paper_rolls',
    title: 'Nativity Scene from Paper Rolls',
    emoji: '⭐',
    duration: '20 min',
    difficulty: _Difficulty.hard,
    materials: [
      'Toilet paper rolls',
      'Paint',
      'Felt scraps',
      'Googly eyes',
      'Gold glitter',
    ],
    faithCoinReward: 30,
    youtubeVideoId: 'dQw4w9WgXcQ',
  ),
];

// ── Provider for watched videos ────────────────────────────────────────────────

final _watchedVideosProvider = StateProvider<Set<String>>((_) => {});

// ── Screen ─────────────────────────────────────────────────────────────────────

class VideoTutorialsScreen extends ConsumerWidget {
  const VideoTutorialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watched = ref.watch(_watchedVideosProvider);

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        backgroundColor: AppColors.purpleDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Video Tutorials',
          style:
              AppTextStyles.headlineMedium.copyWith(color: AppColors.goldLight),
        ),
      ),
      body: Column(
        children: [
          // Subtitle banner
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: AppColors.darkCard,
            child: Row(
              children: [
                const Icon(Icons.play_circle_outline,
                    color: AppColors.faithCoins, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Watch tutorials → Craft → Scan for bonus rewards!',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.parchment,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _tutorials.length,
              itemBuilder: (ctx, index) {
                final tutorial = _tutorials[index];
                return _VideoCard(
                  tutorial: tutorial,
                  isWatched: watched.contains(tutorial.id),
                  onWatch: () =>
                      _showVideoDialog(context, ref, tutorial),
                )
                    .animate(delay: (index * 80).ms)
                    .fadeIn()
                    .slideY(begin: 0.05);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showVideoDialog(
      BuildContext context, WidgetRef ref, _VideoTutorial tutorial) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      isScrollControlled: true,
      builder: (ctx) => _VideoDetailSheet(
        tutorial: tutorial,
        onMarkWatched: () {
          ref
              .read(_watchedVideosProvider.notifier)
              .update((s) => {...s, tutorial.id});
          ref.read(resourceNotifierProvider.notifier).optimisticAdd(
            ResourceReward(
              faithCoins: tutorial.faithCoinReward,
              holyPoints: 0,
              blessings: 0,
              grace: 0,
            ),
          );
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.forestGreen,
              content: Text(
                '+${tutorial.faithCoinReward} 🪵 earned for watching!',
                style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }
}

// ── Video card ─────────────────────────────────────────────────────────────────

class _VideoCard extends StatelessWidget {
  final _VideoTutorial tutorial;
  final bool isWatched;
  final VoidCallback onWatch;

  const _VideoCard({
    required this.tutorial,
    required this.isWatched,
    required this.onWatch,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onWatch,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: isWatched
                ? AppColors.forestGreen.withOpacity(0.4)
                : AppColors.darkElevated,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail
            Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: tutorial.difficulty.color.withOpacity(0.2),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppSpacing.radiusLg),
                      bottomLeft: Radius.circular(AppSpacing.radiusLg),
                    ),
                  ),
                  child: Center(
                    child: Text(tutorial.emoji,
                        style: const TextStyle(fontSize: 40)),
                  ),
                ),
                // Play overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppSpacing.radiusLg),
                        bottomLeft: Radius.circular(AppSpacing.radiusLg),
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow,
                            color: Colors.black, size: 20),
                      ),
                    ),
                  ),
                ),
                if (isWatched)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: AppColors.forestGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 12),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: AppSpacing.sm),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tutorial.title,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.ivory,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined,
                            color: AppColors.midGrey, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          tutorial.duration,
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.midGrey),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: tutorial.difficulty.color.withOpacity(0.15),
                            borderRadius: AppSpacing.borderRadiusSm,
                            border: Border.all(
                                color:
                                    tutorial.difficulty.color.withOpacity(0.4)),
                          ),
                          child: Text(
                            tutorial.difficulty.label,
                            style: AppTextStyles.badge.copyWith(
                              color: tutorial.difficulty.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: AppColors.faithCoins, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '+${tutorial.faithCoinReward} 🪵 for watching',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.faithCoins),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Icon(
                Icons.arrow_forward_ios,
                color: AppColors.darkElevated,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Video detail sheet ─────────────────────────────────────────────────────────

class _VideoDetailSheet extends StatelessWidget {
  final _VideoTutorial tutorial;
  final VoidCallback onMarkWatched;

  const _VideoDetailSheet({
    required this.tutorial,
    required this.onMarkWatched,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.darkElevated,
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Video player placeholder
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: AppSpacing.borderRadiusLg,
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(tutorial.emoji,
                                style: const TextStyle(fontSize: 56)),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Video Player',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.midGrey,
                              ),
                            ),
                            Text(
                              '(YouTube embed in production)',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.darkElevated,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2),
                          ),
                          child: const Icon(Icons.play_arrow,
                              color: Colors.white, size: 32),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                Text(
                  tutorial.title,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.goldLight,
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        color: AppColors.midGrey, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      tutorial.duration,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.midGrey,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: tutorial.difficulty.color.withOpacity(0.15),
                        borderRadius: AppSpacing.borderRadiusSm,
                        border: Border.all(
                            color: tutorial.difficulty.color.withOpacity(0.4)),
                      ),
                      child: Text(
                        tutorial.difficulty.label,
                        style: AppTextStyles.badge
                            .copyWith(color: tutorial.difficulty.color),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Materials
                Text(
                  'Materials Needed',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.goldLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...tutorial.materials.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_box_outline_blank,
                            color: AppColors.grace, size: 14),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          m,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.parchment,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Reward info
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.faithCoins.withOpacity(0.1),
                    borderRadius: AppSpacing.borderRadiusMd,
                    border: Border.all(
                        color: AppColors.faithCoins.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: AppColors.faithCoins),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Watch this tutorial to earn ${tutorial.faithCoinReward} 🪵 FaithCoins!',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.faithCoins,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                KingdomButton(
                  label: 'Mark as Watched  (+${tutorial.faithCoinReward} 🪵)',
                  onPressed: onMarkWatched,
                  icon: Icons.check_circle_outline,
                ),

                const SizedBox(height: AppSpacing.sm),

                Text(
                  'Tip: Complete the craft and scan it with Masterpiece Scanner for bonus rewards!',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.midGrey,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        );
      },
    );
  }
}
