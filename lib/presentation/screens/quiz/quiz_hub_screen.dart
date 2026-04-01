import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/data/models/quiz/quiz_model.dart';
import 'package:kingdomcome/presentation/providers/quiz_provider.dart';

class QuizHubScreen extends ConsumerWidget {
  const QuizHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizzesByCategory = ref.watch(quizzesByCategoryProvider);

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: AppColors.purpleDark,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.purpleDark, AppColors.darkCard],
                  ),
                ),
                alignment: Alignment.bottomLeft,
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                child: Text(
                  'Faith Quizzes',
                  style: AppTextStyles.displaySmall.copyWith(
                    color: AppColors.goldLight,
                  ),
                ),
              ),
            ),
          ),

          if (quizzesByCategory.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.md),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final category = quizzesByCategory.keys.toList()[i];
                    final quizzes = quizzesByCategory[category] ?? [];
                    return _CategoryCard(
                      category: category,
                      quizzes: quizzes,
                      onTap: () => ctx.push('/learn/quiz/category/${category.name}'),
                    ).animate(delay: (i * 60).ms).fadeIn().scale(
                          begin: const Offset(0.9, 0.9),
                        );
                  },
                  childCount: quizzesByCategory.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Category card ─────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final QuizCategory category;
  final List<QuizModel> quizzes;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.quizzes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _categoryColor.withOpacity(0.3),
              AppColors.darkCard,
            ],
          ),
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: _categoryColor.withOpacity(0.4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_categoryIcon, color: _categoryColor, size: 36),
              const Spacer(),
              Text(
                category.displayName,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.ivory,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${quizzes.length} quiz${quizzes.length == 1 ? '' : 'zes'}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.midGrey,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Difficulty dots
              Row(
                children: List.generate(
                    quizzes.isNotEmpty
                        ? quizzes
                                .map((q) => q.difficultyLevel)
                                .reduce((a, b) => a > b ? a : b)
                                .clamp(1, 4)
                        : 1,
                    (i) => Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 3),
                          decoration: BoxDecoration(
                            color: _categoryColor,
                            shape: BoxShape.circle,
                          ),
                        )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color get _categoryColor {
    switch (category) {
      case QuizCategory.sacraments:
        return AppColors.gold;
      case QuizCategory.saints:
        return AppColors.grace;
      case QuizCategory.bible:
        return AppColors.holyPoints;
      case QuizCategory.churchHistory:
        return AppColors.blessings;
      case QuizCategory.liturgy:
        return AppColors.liturgicalPurple;
      case QuizCategory.prayer:
        return AppColors.sage;
      case QuizCategory.catechism:
        return AppColors.crimson;
      case QuizCategory.seasonal:
        return AppColors.forestGreen;
    }
  }

  IconData get _categoryIcon {
    switch (category) {
      case QuizCategory.sacraments:
        return Icons.water_drop;
      case QuizCategory.saints:
        return Icons.star;
      case QuizCategory.bible:
        return Icons.menu_book;
      case QuizCategory.churchHistory:
        return Icons.history_edu;
      case QuizCategory.liturgy:
        return Icons.church;
      case QuizCategory.prayer:
        return Icons.self_improvement;
      case QuizCategory.catechism:
        return Icons.school;
      case QuizCategory.seasonal:
        return Icons.auto_awesome;
    }
  }
}
