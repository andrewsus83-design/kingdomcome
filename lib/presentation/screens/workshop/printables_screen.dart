import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/game_constants.dart';
import 'package:kingdomcome/presentation/providers/resource_provider.dart';

// ── Printable item model ───────────────────────────────────────────────────────

enum _PrintableCategory {
  coloringPages,
  papercraft,
  activitySheets,
  rosaryGuide,
}

extension _PrintableCategoryX on _PrintableCategory {
  String get displayName {
    return switch (this) {
      _PrintableCategory.coloringPages => 'Coloring Pages',
      _PrintableCategory.papercraft => 'Papercraft',
      _PrintableCategory.activitySheets => 'Activity Sheets',
      _PrintableCategory.rosaryGuide => 'Rosary Making',
    };
  }

  Color get color {
    return switch (this) {
      _PrintableCategory.coloringPages => const Color(0xFF1A4A8B),
      _PrintableCategory.papercraft => const Color(0xFF1A6B3A),
      _PrintableCategory.activitySheets => const Color(0xFF6B4A1A),
      _PrintableCategory.rosaryGuide => const Color(0xFF4A1A6B),
    };
  }

  String get emoji {
    return switch (this) {
      _PrintableCategory.coloringPages => '🖍️',
      _PrintableCategory.papercraft => '✂️',
      _PrintableCategory.activitySheets => '📝',
      _PrintableCategory.rosaryGuide => '📿',
    };
  }
}

class _PrintableItem {
  final String id;
  final String title;
  final String emoji;
  final _PrintableCategory category;
  final String ageRecommendation;
  final String estimatedTime;
  final String pdfUrl; // stub URL

  const _PrintableItem({
    required this.id,
    required this.title,
    required this.emoji,
    required this.category,
    required this.ageRecommendation,
    required this.estimatedTime,
    required this.pdfUrl,
  });
}

const _printables = [
  // Coloring Pages
  _PrintableItem(
    id: 'saint_francis_coloring',
    title: 'Saint Francis of Assisi',
    emoji: '🌿',
    category: _PrintableCategory.coloringPages,
    ageRecommendation: 'Ages 6+',
    estimatedTime: '20–30 min',
    pdfUrl: 'https://assets.kingdomcome.app/printables/saint_francis.pdf',
  ),
  _PrintableItem(
    id: 'nativity_coloring',
    title: 'The Nativity Scene',
    emoji: '⭐',
    category: _PrintableCategory.coloringPages,
    ageRecommendation: 'Ages 5+',
    estimatedTime: '15–25 min',
    pdfUrl: 'https://assets.kingdomcome.app/printables/nativity.pdf',
  ),
  _PrintableItem(
    id: 'rosary_mysteries_coloring',
    title: 'Joyful Mysteries of the Rosary',
    emoji: '📿',
    category: _PrintableCategory.coloringPages,
    ageRecommendation: 'Ages 7+',
    estimatedTime: '30–45 min',
    pdfUrl: 'https://assets.kingdomcome.app/printables/rosary_mysteries.pdf',
  ),
  _PrintableItem(
    id: 'advent_coloring',
    title: 'Advent Season Pages',
    emoji: '🕯️',
    category: _PrintableCategory.coloringPages,
    ageRecommendation: 'Ages 5+',
    estimatedTime: '15–20 min',
    pdfUrl: 'https://assets.kingdomcome.app/printables/advent.pdf',
  ),
  // Papercraft
  _PrintableItem(
    id: 'noahs_ark_papercraft',
    title: 'Noah\'s Ark 3D Model',
    emoji: '🚢',
    category: _PrintableCategory.papercraft,
    ageRecommendation: 'Ages 8+',
    estimatedTime: '45–60 min',
    pdfUrl: 'https://assets.kingdomcome.app/printables/noahs_ark_3d.pdf',
  ),
  _PrintableItem(
    id: 'nativity_stable_papercraft',
    title: 'Nativity Stable Scene',
    emoji: '🏠',
    category: _PrintableCategory.papercraft,
    ageRecommendation: 'Ages 9+',
    estimatedTime: '60–90 min',
    pdfUrl:
        'https://assets.kingdomcome.app/printables/nativity_stable.pdf',
  ),
  _PrintableItem(
    id: 'cross_bookmark',
    title: 'Cross Bookmark',
    emoji: '✝️',
    category: _PrintableCategory.papercraft,
    ageRecommendation: 'Ages 6+',
    estimatedTime: '10–15 min',
    pdfUrl:
        'https://assets.kingdomcome.app/printables/cross_bookmark.pdf',
  ),
  // Activity Sheets
  _PrintableItem(
    id: 'catholic_wordsearch',
    title: 'Catholic Word Search',
    emoji: '🔤',
    category: _PrintableCategory.activitySheets,
    ageRecommendation: 'Ages 8+',
    estimatedTime: '15–20 min',
    pdfUrl:
        'https://assets.kingdomcome.app/printables/wordsearch.pdf',
  ),
  _PrintableItem(
    id: 'calligraphy_verse',
    title: 'Bible Verse Calligraphy Practice',
    emoji: '✍️',
    category: _PrintableCategory.activitySheets,
    ageRecommendation: 'Ages 10+',
    estimatedTime: '20–30 min',
    pdfUrl: 'https://assets.kingdomcome.app/printables/calligraphy.pdf',
  ),
  _PrintableItem(
    id: 'liturgical_calendar',
    title: 'Liturgical Calendar (Fill-In)',
    emoji: '📅',
    category: _PrintableCategory.activitySheets,
    ageRecommendation: 'Ages 9+',
    estimatedTime: '30–40 min',
    pdfUrl: 'https://assets.kingdomcome.app/printables/liturgical_calendar.pdf',
  ),
  // Rosary Guide
  _PrintableItem(
    id: 'rosary_making_guide',
    title: 'How to Make a Rosary',
    emoji: '📿',
    category: _PrintableCategory.rosaryGuide,
    ageRecommendation: 'Ages 8+',
    estimatedTime: '60–90 min',
    pdfUrl: 'https://assets.kingdomcome.app/printables/rosary_guide.pdf',
  ),
];

// ── Provider for downloaded items ─────────────────────────────────────────────

final _downloadedProvider = StateProvider<Set<String>>((_) => {});

// ── Screen ─────────────────────────────────────────────────────────────────────

class PrintablesScreen extends ConsumerStatefulWidget {
  const PrintablesScreen({super.key});

  @override
  ConsumerState<PrintablesScreen> createState() => _PrintablesScreenState();
}

class _PrintablesScreenState extends ConsumerState<PrintablesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _categories = _PrintableCategory.values;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        backgroundColor: AppColors.purpleDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Printable Magic',
          style:
              AppTextStyles.headlineMedium.copyWith(color: AppColors.goldLight),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.gold,
          labelStyle:
              AppTextStyles.labelMedium.copyWith(color: AppColors.goldLight),
          unselectedLabelStyle:
              AppTextStyles.labelMedium.copyWith(color: AppColors.midGrey),
          tabs: _categories.map((c) {
            return Tab(text: '${c.emoji} ${c.displayName}');
          }).toList(),
        ),
      ),
      body: Column(
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: AppColors.darkCard,
            child: Row(
              children: [
                const Icon(Icons.download_outlined,
                    color: AppColors.faithCoins, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Download → Print → Scan for bonus FaithCoins!',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.parchment,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((cat) {
                final items =
                    _printables.where((p) => p.category == cat).toList();
                return _PrintableList(
                  items: items,
                  category: cat,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrintableList extends ConsumerWidget {
  final List<_PrintableItem> items;
  final _PrintableCategory category;

  const _PrintableList({required this.items, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloaded = ref.watch(_downloadedProvider);

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: items.length,
      itemBuilder: (ctx, index) {
        final item = items[index];
        return _PrintableCard(
          item: item,
          isDownloaded: downloaded.contains(item.id),
          onDownload: () => _handleDownload(context, ref, item),
        )
            .animate(delay: (index * 80).ms)
            .fadeIn()
            .slideX(begin: 0.05);
      },
    );
  }

  void _handleDownload(
      BuildContext context, WidgetRef ref, _PrintableItem item) {
    ref.read(_downloadedProvider.notifier).update((s) => {...s, item.id});

    // Award FaithCoins for downloading
    ref.read(resourceNotifierProvider.notifier).optimisticAdd(
      const ResourceReward(
        faithCoins: 10,
        holyPoints: 0,
        blessings: 0,
        grace: 0,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.forestGreen,
        content: Row(
          children: [
            const Icon(Icons.download_done, color: Colors.white, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${item.title} downloaded! +10 🪵',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _PrintableCard extends StatelessWidget {
  final _PrintableItem item;
  final bool isDownloaded;
  final VoidCallback onDownload;

  const _PrintableCard({
    required this.item,
    required this.isDownloaded,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final color = item.category.color;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: AppSpacing.borderRadiusLg,
        border:
            Border.all(color: color.withOpacity(0.35), width: 1.5),
      ),
      child: Row(
        children: [
          // Preview thumb
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: AppSpacing.borderRadiusMd,
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Center(
              child: Text(item.emoji, style: const TextStyle(fontSize: 32)),
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.ivory,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _MetaChip(
                        label: item.ageRecommendation,
                        color: AppColors.holyPoints),
                    const SizedBox(width: AppSpacing.xs),
                    _MetaChip(
                        label: item.estimatedTime,
                        color: AppColors.blessings),
                  ],
                ),
                if (isDownloaded) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppColors.forestGreen, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Downloaded',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.forestGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Download button
          GestureDetector(
            onTap: onDownload,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDownloaded
                    ? AppColors.forestGreen.withOpacity(0.2)
                    : color.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDownloaded ? AppColors.forestGreen : color,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Icon(
                  isDownloaded ? Icons.check : Icons.download_outlined,
                  color: isDownloaded ? AppColors.forestGreen : color,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MetaChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.badge.copyWith(color: color),
      ),
    );
  }
}
