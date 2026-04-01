import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/data/models/bible/verse_model.dart';
import 'package:kingdomcome/presentation/providers/bible_provider.dart';
import 'package:kingdomcome/presentation/providers/streak_provider.dart';
import 'package:kingdomcome/presentation/widgets/common/kingdom_button.dart';
import 'package:kingdomcome/presentation/widgets/common/xp_progress_bar.dart';

class ChapterScreen extends ConsumerStatefulWidget {
  final String bookAbbrev;
  final int chapterNum;

  const ChapterScreen({
    super.key,
    required this.bookAbbrev,
    required this.chapterNum,
  });

  @override
  ConsumerState<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends ConsumerState<ChapterScreen> {
  double _fontSize = 16.0;
  final Set<int> _highlightedVerses = {};
  bool _completing = false;

  @override
  Widget build(BuildContext context) {
    final chapterAsync =
        ref.watch(chapterProvider(widget.bookAbbrev, widget.chapterNum));

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      body: chapterAsync.when(
        loading: () => const _ChapterLoading(),
        error: (e, _) => _ChapterError(error: e.toString()),
        data: (chapter) {
          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // App bar
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: AppColors.purpleDark,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          color: AppColors.gold),
                      onPressed: () => context.pop(),
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chapter.bookName,
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: AppColors.goldLight,
                          ),
                        ),
                        Text(
                          'Chapter ${chapter.chapterNumber}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.midGrey,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      // Font size controls
                      IconButton(
                        icon: const Icon(Icons.text_decrease,
                            color: AppColors.gold, size: 20),
                        onPressed: () => setState(() {
                          _fontSize = (_fontSize - 1).clamp(12.0, 28.0);
                        }),
                      ),
                      IconButton(
                        icon: const Icon(Icons.text_increase,
                            color: AppColors.gold, size: 20),
                        onPressed: () => setState(() {
                          _fontSize = (_fontSize + 1).clamp(12.0, 28.0);
                        }),
                      ),
                    ],
                  ),

                  // XP reward banner
                  const SliverToBoxAdapter(
                    child: _XpRewardBanner(),
                  ),

                  // Verses
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, AppSpacing.md, AppSpacing.md, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final verse = chapter.verses[i];
                          final highlighted =
                              _highlightedVerses.contains(verse.verseNumber);
                          return _VerseRow(
                            verse: verse,
                            fontSize: _fontSize,
                            isHighlighted: highlighted,
                            onTap: () => setState(() {
                              if (highlighted) {
                                _highlightedVerses.remove(verse.verseNumber);
                              } else {
                                _highlightedVerses.add(verse.verseNumber);
                              }
                            }),
                          ).animate(delay: (i * 15).ms).fadeIn();
                        },
                        childCount: chapter.verses.length,
                      ),
                    ),
                  ),
                ],
              ),

              // Complete Chapter button
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _CompleteBar(
                  bookAbbrev: widget.bookAbbrev,
                  chapterNum: widget.chapterNum,
                  isLoading: _completing,
                  onComplete: () => _completeChapter(chapter.verses),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _completeChapter(List<VerseModel> verses) async {
    setState(() => _completing = true);

    try {
      // Record reading progress
      await ref.read(readingProgressNotifierProvider.notifier).updateProgress(
            widget.bookAbbrev,
            widget.chapterNum,
            verses.length,
          );

      // Record bible reading streak
      await ref
          .read(streakNotifierProvider.notifier)
          .recordActivity(StreakType.bibleReading);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.star, color: AppColors.gold, size: 16),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '+25 Holy Points earned!',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.goldLight,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.darkCard,
          ),
        );
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) context.pop();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _completing = false);
      }
    }
  }
}

// ── Verse Row ─────────────────────────────────────────────────────────────────

class _VerseRow extends StatelessWidget {
  final VerseModel verse;
  final double fontSize;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _VerseRow({
    required this.verse,
    required this.fontSize,
    required this.isHighlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isHighlighted
              ? AppColors.gold.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: AppSpacing.borderRadiusSm,
          border: isHighlighted
              ? Border.all(color: AppColors.gold.withOpacity(0.3))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '${verse.verseNumber}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Text(
                verse.text,
                style: TextStyle(
                  fontSize: fontSize,
                  color: isHighlighted ? AppColors.goldLight : AppColors.ivory,
                  height: 1.7,
                  fontFamily: 'serif',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── XP reward banner ──────────────────────────────────────────────────────────

class _XpRewardBanner extends StatelessWidget {
  const _XpRewardBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.holyPoints.withOpacity(0.1),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: AppColors.holyPoints.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: AppColors.holyPoints, size: 16),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Complete this chapter to earn +25 Holy Points',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.holyPoints,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Complete bar ──────────────────────────────────────────────────────────────

class _CompleteBar extends StatelessWidget {
  final String bookAbbrev;
  final int chapterNum;
  final bool isLoading;
  final VoidCallback onComplete;

  const _CompleteBar({
    required this.bookAbbrev,
    required this.chapterNum,
    required this.isLoading,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.darkCard,
        border: Border(top: BorderSide(color: AppColors.goldDark)),
      ),
      child: SafeArea(
        top: false,
        child: KingdomButton(
          label: 'Complete Chapter (+25 HP)',
          onPressed: isLoading ? null : onComplete,
          isLoading: isLoading,
          icon: Icons.check,
        ),
      ),
    );
  }
}

// ── Loading / Error ───────────────────────────────────────────────────────────

class _ChapterLoading extends StatelessWidget {
  const _ChapterLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.darkSurface,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      ),
    );
  }
}

class _ChapterError extends StatelessWidget {
  final String error;
  const _ChapterError({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.crimson, size: 48),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Could not load chapter',
                style: AppTextStyles.headlineSmall
                    .copyWith(color: AppColors.ivory),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                error,
                style:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.midGrey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back',
                    style: TextStyle(color: AppColors.gold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
