import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/data/models/saint/saint_model.dart';
import 'package:kingdomcome/presentation/providers/saint_provider.dart';
import 'package:kingdomcome/presentation/widgets/saint/saint_card.dart';

class SaintsGalleryScreen extends ConsumerStatefulWidget {
  const SaintsGalleryScreen({super.key});

  @override
  ConsumerState<SaintsGalleryScreen> createState() =>
      _SaintsGalleryScreenState();
}

class _SaintsGalleryScreenState extends ConsumerState<SaintsGalleryScreen> {
  String _selectedFilter = 'All';
  final _searchController = TextEditingController();
  String _searchQuery = '';

  static const _filterOptions = [
    'All',
    'Common',
    'Uncommon',
    'Rare',
    'Epic',
    'Legendary',
    'Feast Day',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saintsAsync = ref.watch(saintNotifierProvider);
    final unlockedIds = ref.watch(unlockedSaintIdsProvider);
    final activeSaint = ref.watch(activeSaintProvider);

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 140,
            backgroundColor: AppColors.purpleDark,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.purpleDark, AppColors.darkCard],
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Saints Gallery',
                          style: AppTextStyles.displaySmall.copyWith(
                            color: AppColors.goldLight,
                          ),
                        ),
                        saintsAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (saints) {
                            final unlocked = saints
                                .where((s) => unlockedIds.contains(s.id))
                                .length;
                            return Text(
                              '$unlocked / ${saints.length} unlocked',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.midGrey,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                0,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.ivory,
                ),
                decoration: InputDecoration(
                  hintText: 'Search saints...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.midGrey,
                  ),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.midGrey),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon:
                              const Icon(Icons.clear, color: AppColors.midGrey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.darkCard,
                  border: OutlineInputBorder(
                    borderRadius: AppSpacing.borderRadiusMd,
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
            ),

            // Filter chips
            SizedBox(
              height: 52,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                scrollDirection: Axis.horizontal,
                itemCount: _filterOptions.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (ctx, i) {
                  final filter = _filterOptions[i];
                  final selected = _selectedFilter == filter;
                  return FilterChip(
                    label: Text(filter),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _selectedFilter = filter),
                    selectedColor: AppColors.deepPurple,
                    backgroundColor: AppColors.darkCard,
                    labelStyle: AppTextStyles.labelMedium.copyWith(
                      color: selected ? AppColors.goldLight : AppColors.midGrey,
                    ),
                    side: BorderSide(
                      color: selected
                          ? AppColors.gold.withOpacity(0.5)
                          : AppColors.darkElevated,
                    ),
                    checkmarkColor: AppColors.gold,
                  );
                },
              ),
            ),

            // Grid
            Expanded(
              child: saintsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
                error: (e, _) => Center(
                  child: Text(e.toString(),
                      style: const TextStyle(color: AppColors.ivory)),
                ),
                data: (saints) {
                  final filtered = _filterSaints(saints, unlockedIds);
                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        'No saints found',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.midGrey),
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: AppSpacing.sm,
                      mainAxisSpacing: AppSpacing.sm,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final saint = filtered[i];
                      final unlocked = unlockedIds.contains(saint.id);
                      final isActive = activeSaint?.saintId == saint.id;

                      return SaintCard(
                        saint: saint,
                        isUnlocked: unlocked,
                        isActive: isActive,
                        onTap: () => ctx.push('/saints/${saint.id}'),
                      ).animate(delay: (i * 30).ms).fadeIn();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<SaintModel> _filterSaints(
      List<SaintModel> saints, Set<String> unlockedIds) {
    var filtered = saints;

    // Search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((s) =>
              s.name.toLowerCase().contains(_searchQuery) ||
              s.patronage.toLowerCase().contains(_searchQuery))
          .toList();
    }

    // Rarity / filter
    if (_selectedFilter != 'All') {
      if (_selectedFilter == 'Feast Day') {
        // Today's feast day
        final today =
            '${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
        filtered = filtered.where((s) => s.feastDay == today).toList();
      } else {
        filtered = filtered
            .where((s) => s.rarity.toLowerCase() ==
                _selectedFilter.toLowerCase())
            .toList();
      }
    }

    return filtered;
  }
}
