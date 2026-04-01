import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/data/models/bible/book_model.dart';
import 'package:kingdomcome/presentation/providers/bible_provider.dart';
import 'package:kingdomcome/presentation/providers/streak_provider.dart';
import 'package:kingdomcome/presentation/widgets/bible/verse_card.dart';
import 'package:kingdomcome/presentation/widgets/common/streak_flame_widget.dart';

class BibleHomeScreen extends ConsumerWidget {
  const BibleHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verseOfDayAsync = ref.watch(verseOfDayProvider);
    final booksAsync = ref.watch(bibleNotifierProvider);
    final progressList =
        ref.watch(readingProgressNotifierProvider).valueOrNull ?? [];
    final streaks = ref.watch(streakNotifierProvider).valueOrNull ?? [];
    final bibleStreak = streaks
        .where((s) => s.type == StreakType.bibleReading)
        .firstOrNull;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.darkSurface,
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverAppBar(
              pinned: true,
              expandedHeight: 200,
              backgroundColor: AppColors.purpleDark,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.purpleDark, AppColors.deepGreen],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          60,
                          AppSpacing.md,
                          AppSpacing.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'The Bible',
                                  style: AppTextStyles.displaySmall.copyWith(
                                    color: AppColors.goldLight,
                                  ),
                                ),
                                const Spacer(),
                                if (bibleStreak != null)
                                  StreakFlameWidget(
                                    count: bibleStreak.currentStreak,
                                    isAtRisk: bibleStreak.isAtRisk,
                                  ),
                              ],
                            ),
                            Text(
                              'Sacred Scripture',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.goldLight.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Old Testament'),
                  Tab(text: 'New Testament'),
                ],
                labelColor: AppColors.gold,
                unselectedLabelColor: AppColors.midGrey,
                indicatorColor: AppColors.gold,
              ),
            ),
          ],
          body: Column(
            children: [
              // Verse of the day card
              verseOfDayAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: LinearProgressIndicator(color: AppColors.gold),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (verse) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: VerseCard(
                    verse: verse,
                    isVerseOfDay: true,
                  ).animate().fadeIn(delay: 200.ms),
                ),
              ),

              // Continue reading
              if (progressList.isNotEmpty)
                _ContinueReading(
                  progress: progressList.first,
                ).animate().fadeIn(delay: 300.ms),

              // Books grid
              Expanded(
                child: booksAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.gold),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      e.toString(),
                      style: const TextStyle(color: AppColors.ivory),
                    ),
                  ),
                  data: (books) => TabBarView(
                    children: [
                      _BooksGrid(
                        books: books.where((b) => b.isOldTestament).toList(),
                      ),
                      _BooksGrid(
                        books: books.where((b) => b.isNewTestament).toList(),
                      ),
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

// ── Continue Reading ──────────────────────────────────────────────────────────

class _ContinueReading extends StatelessWidget {
  final dynamic progress;
  const _ContinueReading({required this.progress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
          '/learn/bible/${progress.bookAbbrev}/${progress.lastChapterRead}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.deepGreen.withOpacity(0.3),
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(color: AppColors.forestGreen.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.menu_book, color: AppColors.forestGreen, size: 24),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Continue Reading',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.goldLight,
                    ),
                  ),
                  Text(
                    '${progress.bookAbbrev} — Chapter ${progress.lastChapterRead}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.midGrey,
                    ),
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

// ── Books Grid ────────────────────────────────────────────────────────────────

class _BooksGrid extends StatelessWidget {
  final List<BookModel> books;
  const _BooksGrid({required this.books});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: books.length,
      itemBuilder: (ctx, i) {
        final book = books[i];
        return GestureDetector(
          onTap: () => ctx.push('/learn/bible/${book.abbrev}/1'),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: AppSpacing.borderRadiusMd,
              border: Border.all(color: AppColors.goldDark.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  book.abbrev,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  book.name,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.parchment,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${book.chapterCount} ch.',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.midGrey,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ).animate(delay: (i * 20).ms).fadeIn(),
        );
      },
    );
  }
}
