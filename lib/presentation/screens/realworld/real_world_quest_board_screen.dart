import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/data/models/quest/real_world_quest_model.dart';
import 'package:kingdomcome/data/models/quest/real_world_completion_model.dart';
import 'package:kingdomcome/presentation/providers/real_world_quest_provider.dart';
import 'package:kingdomcome/presentation/providers/auth_provider.dart';

class RealWorldQuestBoardScreen extends ConsumerStatefulWidget {
  const RealWorldQuestBoardScreen({super.key});

  @override
  ConsumerState<RealWorldQuestBoardScreen> createState() =>
      _RealWorldQuestBoardScreenState();
}

class _RealWorldQuestBoardScreenState
    extends ConsumerState<RealWorldQuestBoardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _categories = RealWorldCategory.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref
            .read(realWorldQuestNotifierProvider.notifier)
            .selectCategory(_categories[_tabController.index]);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questState = ref.watch(realWorldQuestNotifierProvider);
    final pendingCount = ref.watch(pendingRealWorldCountProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 130,
            backgroundColor: AppColors.purpleDark,
            forceElevated: innerBoxIsScrolled,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1A0A2E),
                      AppColors.purpleDark,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, 56, AppSpacing.md, AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Real World Quests 🌍',
                        style: AppTextStyles.displaySmall.copyWith(
                          color: AppColors.goldLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Do good in real life, earn rewards!',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.ivory.withOpacity(0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: _CategoryTabBar(
                tabController: _tabController,
                categories: _categories,
              ),
            ),
          ),
        ],
        body: questState.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              )
            : RefreshIndicator(
                color: AppColors.gold,
                backgroundColor: AppColors.darkCard,
                onRefresh: () =>
                    ref.read(realWorldQuestNotifierProvider.notifier).refresh(),
                child: TabBarView(
                  controller: _tabController,
                  children: _categories
                      .map(
                        (cat) => _CategoryQuestList(
                          category: cat,
                          pendingCount: pendingCount,
                          questState: questState,
                          userName: user?.displayName ?? 'You',
                        ),
                      )
                      .toList(),
                ),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category tab bar
// ---------------------------------------------------------------------------

class _CategoryTabBar extends StatelessWidget {
  final TabController tabController;
  final List<RealWorldCategory> categories;

  const _CategoryTabBar({
    required this.tabController,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.purpleDark,
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: AppColors.gold,
        indicatorWeight: 3,
        labelColor: AppColors.goldLight,
        unselectedLabelColor: AppColors.midGrey,
        labelStyle: AppTextStyles.labelMedium.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: AppTextStyles.labelMedium,
        tabs: categories
            .map(
              (cat) => Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(cat.emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(cat.displayName),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Per-category quest list
// ---------------------------------------------------------------------------

class _CategoryQuestList extends ConsumerWidget {
  final RealWorldCategory category;
  final int pendingCount;
  final RealWorldQuestState questState;
  final String userName;

  const _CategoryQuestList({
    required this.category,
    required this.pendingCount,
    required this.questState,
    required this.userName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryQuests =
        questState.quests.where((q) => q.category == category).toList();
    final customQuests = questState.customQuests;

    return CustomScrollView(
      slivers: [
        // Pending validation banner
        if (pendingCount > 0)
          SliverToBoxAdapter(
            child: _PendingBanner(count: pendingCount)
                .animate()
                .fadeIn(duration: 300.ms),
          ),

        // Digital Fast quick-access card
        if (category == RealWorldCategory.digitalFast)
          SliverToBoxAdapter(
            child: _DigitalFastQuickCard()
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: -0.1),
          ),

        // Quest cards
        if (categoryQuests.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      category.emoji,
                      style: const TextStyle(fontSize: 48),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No quests yet in this category.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.midGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _QuestCard(
                  quest: categoryQuests[i],
                  isActive: questState.activeQuestIds
                      .contains(categoryQuests[i].id),
                  isPending: questState.myCompletions.any(
                    (c) =>
                        c.questId == categoryQuests[i].id &&
                        c.status == CompletionStatus.pendingValidation,
                  ),
                )
                    .animate(delay: (i * 50).ms)
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: -0.05),
                childCount: categoryQuests.length,
              ),
            ),
          ),

        // Parent's custom quests
        if (customQuests.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _SectionDivider(
                title: "Parent's Special Quests", emoji: '⭐'),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _QuestCard(
                  quest: customQuests[i],
                  isActive: questState.activeQuestIds
                      .contains(customQuests[i].id),
                  isPending: questState.myCompletions.any(
                    (c) =>
                        c.questId == customQuests[i].id &&
                        c.status == CompletionStatus.pendingValidation,
                  ),
                  isCustom: true,
                )
                    .animate(delay: (i * 50).ms)
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: -0.05),
                childCount: customQuests.length,
              ),
            ),
          ),
        ],

        const SliverToBoxAdapter(
          child: SizedBox(height: AppSpacing.xxl),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pending banner
// ---------------------------------------------------------------------------

class _PendingBanner extends StatelessWidget {
  final int count;
  const _PendingBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.goldDark.withOpacity(0.2),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.gold.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Text('⏳', style: TextStyle(fontSize: 18)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '$count quest${count == 1 ? '' : 's'} waiting for parent approval',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.goldLight,
              ),
            ),
          ),
          Text(
            'See status →',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Digital Fast quick-access card
// ---------------------------------------------------------------------------

class _DigitalFastQuickCard extends ConsumerWidget {
  const _DigitalFastQuickCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fastState = ref.watch(digitalFastNotifierProvider);

    return GestureDetector(
      onTap: () => context.push('/realworld/digital-fast'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D2137), Color(0xFF0A1929)],
          ),
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: fastState.isTimerRunning
                ? AppColors.holyPoints.withOpacity(0.8)
                : AppColors.darkElevated,
            width: fastState.isTimerRunning ? 2 : 1,
          ),
          boxShadow: fastState.isTimerRunning
              ? [
                  BoxShadow(
                    color: AppColors.holyPoints.withOpacity(0.25),
                    blurRadius: 16,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            // Timer circle
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: fastState.isTimerRunning
                      ? AppColors.holyPoints
                      : AppColors.darkElevated,
                  width: 3,
                ),
                color: AppColors.darkSurface,
              ),
              child: Center(
                child: fastState.isTimerRunning
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatTime(
                                fastState.currentSessionSeconds),
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.holyPoints,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      )
                    : const Text('📵',
                        style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fastState.isTimerRunning
                        ? 'Digital Fast — Active!'
                        : 'Digital Fast Tracker',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.ivory,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fastState.isTimerRunning
                        ? 'Gadget-free session running'
                        : 'Tap to start a gadget-free challenge',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.midGrey,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Candle display
                  Row(
                    children: List.generate(
                      8,
                      (i) => Padding(
                        padding:
                            const EdgeInsets.only(right: 2),
                        child: Text(
                          i < fastState.candlesLit
                              ? '🕯️'
                              : '○',
                          style: TextStyle(
                            fontSize: i < fastState.candlesLit
                                ? 12
                                : 10,
                            color: AppColors.midGrey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.midGrey,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

// ---------------------------------------------------------------------------
// Quest card
// ---------------------------------------------------------------------------

class _QuestCard extends ConsumerWidget {
  final RealWorldQuestModel quest;
  final bool isActive;
  final bool isPending;
  final bool isCustom;

  const _QuestCard({
    required this.quest,
    this.isActive = false,
    this.isPending = false,
    this.isCustom = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/realworld/quest/${quest.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isCustom
              ? AppColors.goldDark.withOpacity(0.15)
              : AppColors.darkCard,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(
            color: isPending
                ? AppColors.gold.withOpacity(0.6)
                : isActive
                    ? AppColors.holyPoints.withOpacity(0.6)
                    : isCustom
                        ? AppColors.goldDark.withOpacity(0.4)
                        : AppColors.darkElevated,
            width: (isPending || isActive) ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Emoji icon
                Text(quest.iconEmoji,
                    style: const TextStyle(fontSize: 28)),
                const SizedBox(width: AppSpacing.sm),
                // Title + status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest.title,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.ivory,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isPending)
                        Text(
                          '⏳ Waiting for parent approval',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.gold,
                          ),
                        )
                      else if (isActive)
                        Text(
                          '🔥 Quest in progress',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.holyPoints,
                          ),
                        ),
                    ],
                  ),
                ),
                // Verification icon
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.darkElevated,
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                  child: Text(
                    quest.verification.emoji,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              quest.description,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.midGrey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                // Virtue tag
                _VirtueTag(virtue: quest.relatedVirtue),
                const Spacer(),
                // Rewards
                if (quest.holyPointsReward > 0)
                  _RewardBadge(
                    value: quest.holyPointsReward,
                    label: 'HP',
                    color: AppColors.holyPoints,
                  ),
                if (quest.faithCoinsReward > 0) ...[
                  const SizedBox(width: AppSpacing.xs),
                  _RewardBadge(
                    value: quest.faithCoinsReward,
                    label: 'FC',
                    color: AppColors.faithCoins,
                  ),
                ],
                if (quest.graceReward > 0) ...[
                  const SizedBox(width: AppSpacing.xs),
                  _RewardBadge(
                    value: quest.graceReward,
                    label: 'GR',
                    color: AppColors.grace,
                  ),
                ],
                const SizedBox(width: AppSpacing.sm),
                // Start / View button
                if (!isPending)
                  _StartButton(quest: quest, isActive: isActive),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VirtueTag extends StatelessWidget {
  final String virtue;
  const _VirtueTag({required this.virtue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.deepPurple.withOpacity(0.4),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(
          color: AppColors.purpleLight.withOpacity(0.4),
        ),
      ),
      child: Text(
        virtue,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.purpleLight,
        ),
      ),
    );
  }
}

class _RewardBadge extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _RewardBadge({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        '+$value $label',
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StartButton extends ConsumerWidget {
  final RealWorldQuestModel quest;
  final bool isActive;
  const _StartButton({required this.quest, required this.isActive});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        if (!isActive) {
          ref
              .read(realWorldQuestNotifierProvider.notifier)
              .startQuest(quest.id);
        }
        context.push('/realworld/quest/${quest.id}');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          gradient: isActive
              ? null
              : const LinearGradient(
                  colors: [AppColors.deepPurple, Color(0xFF2D0F60)],
                ),
          color: isActive ? AppColors.holyPoints.withOpacity(0.2) : null,
          borderRadius: AppSpacing.borderRadiusSm,
          border: Border.all(
            color:
                isActive ? AppColors.holyPoints : AppColors.gold.withOpacity(0.6),
          ),
        ),
        child: Text(
          isActive ? 'Continue' : 'Start Quest',
          style: AppTextStyles.labelSmall.copyWith(
            color: isActive ? AppColors.holyPoints : AppColors.goldLight,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section divider
// ---------------------------------------------------------------------------

class _SectionDivider extends StatelessWidget {
  final String title;
  final String emoji;
  const _SectionDivider({required this.title, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.goldLight,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.goldDark.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}
