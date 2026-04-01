import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/routing/route_names.dart';

// ── Activity section definition ────────────────────────────────────────────────

class _ActivitySection {
  final String title;
  final String subtitle;
  final String emoji;
  final Color color;
  final String routePath;

  const _ActivitySection({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.color,
    required this.routePath,
  });
}

const _sections = [
  _ActivitySection(
    title: 'Masterpiece Scanner',
    subtitle: 'Scan artwork & earn rewards',
    emoji: '📸',
    color: Color(0xFF1A6B4A),
    routePath: RouteNames.workshopScanner,
  ),
  _ActivitySection(
    title: 'Digital Arts',
    subtitle: 'Stained glass & manuscripts',
    emoji: '🖌️',
    color: Color(0xFF1A3A8B),
    routePath: RouteNames.workshopStainedGlass,
  ),
  _ActivitySection(
    title: 'Printable Magic',
    subtitle: 'Download & print activities',
    emoji: '🖨️',
    color: Color(0xFF6B4A1A),
    routePath: RouteNames.workshopPrintables,
  ),
  _ActivitySection(
    title: 'Video Tutorials',
    subtitle: 'DIY craft walkthroughs',
    emoji: '🎥',
    color: Color(0xFF6B1A3A),
    routePath: RouteNames.workshopGallery,
  ),
];

// ── Fake recent artworks ───────────────────────────────────────────────────────

const _recentArtworks = [
  (label: 'Noah\'s Ark', emoji: '🚢', color: Color(0xFF1A4A8B)),
  (label: 'Nativity', emoji: '⭐', color: Color(0xFF6B3A1A)),
  (label: 'St. Francis', emoji: '🌿', color: Color(0xFF1A6B2A)),
  (label: 'Rosary', emoji: '📿', color: Color(0xFF4A1A6B)),
  (label: 'Cross', emoji: '✝️', color: Color(0xFF6B1A1A)),
];

// ── Workshop screen ────────────────────────────────────────────────────────────

class WorkshopScreen extends ConsumerWidget {
  const WorkshopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      body: CustomScrollView(
        slivers: [
          // ── App bar ─────────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFF2A1505),
            expandedHeight: 140,
            flexibleSpace: FlexibleSpaceBar(
              background: _WorkshopHero(),
            ),
            title: Text(
              'The Workshop',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.goldLight,
              ),
            ),
          ),

          // ── Featured craft ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
              child: _FeaturedCraftCard(
                onTap: () => context.push(RouteNames.workshopScanner),
              ).animate().fadeIn(delay: 100.ms),
            ),
          ),

          // ── Section title ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
              child: Text(
                'Activities',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.goldLight,
                ),
              ).animate().fadeIn(delay: 150.ms),
            ),
          ),

          // ── 2×2 Grid ────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final section = _sections[index];
                  return _ActivityCard(
                    section: section,
                    onTap: () => context.push(section.routePath),
                  )
                      .animate(delay: (index * 80 + 200).ms)
                      .fadeIn()
                      .scale(begin: const Offset(0.95, 0.95));
                },
                childCount: _sections.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 0.95,
              ),
            ),
          ),

          // ── Recent artworks ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Artworks',
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: AppColors.goldLight,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            context.push(RouteNames.workshopGallery),
                        child: Text(
                          'See All',
                          style: AppTextStyles.labelMedium
                              .copyWith(color: AppColors.gold),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(
                        left: AppSpacing.md, right: AppSpacing.md),
                    itemCount: _recentArtworks.length,
                    itemBuilder: (ctx, i) {
                      final art = _recentArtworks[i];
                      return _ArtworkThumb(
                        label: art.label,
                        emoji: art.emoji,
                        color: art.color,
                      )
                          .animate(delay: (i * 60).ms)
                          .fadeIn()
                          .scale(begin: const Offset(0.8, 0.8));
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),

      // ── AI Generate FAB ──────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.workshopScanner),
        backgroundColor: AppColors.deepPurple,
        foregroundColor: AppColors.goldLight,
        icon: const Icon(Icons.auto_awesome),
        label: Text(
          'AI Generate',
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.goldLight),
        ),
      ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.5, 0.5)),
    );
  }
}

// ── Workshop hero ──────────────────────────────────────────────────────────────

class _WorkshopHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1505), Color(0xFF3D2010)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, 56, AppSpacing.md, AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Create & Craft',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.blessings.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      'Bring faith to life with your hands',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.parchment.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: ['🎨', '✂️', '📜', '🖌️'].map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Text(e, style: const TextStyle(fontSize: 20)),
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

// ── Featured craft card ────────────────────────────────────────────────────────

class _FeaturedCraftCard extends StatelessWidget {
  final VoidCallback onTap;

  const _FeaturedCraftCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2A4A1A), Color(0xFF1A6B3A)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: AppSpacing.borderRadiusLg,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A6B3A).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('📸', style: TextStyle(fontSize: 28)),
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
                      "TODAY'S CRAFT",
                      style: AppTextStyles.badge.copyWith(
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Scan Your Artwork',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Earn FaithCoins + Saint Badge',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Activity card ──────────────────────────────────────────────────────────────

class _ActivityCard extends StatelessWidget {
  final _ActivitySection section;
  final VoidCallback onTap;

  const _ActivityCard({required this.section, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: AppSpacing.borderRadiusLg,
          border:
              Border.all(color: section.color.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: section.color.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: section.color.withOpacity(0.2),
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(color: section.color.withOpacity(0.4)),
              ),
              child: Center(
                child: Text(section.emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const Spacer(),
            Text(
              section.title,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.ivory,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 4),
            Text(
              section.subtitle,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.midGrey),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.arrow_forward, color: section.color, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Open',
                  style: AppTextStyles.labelSmall.copyWith(color: section.color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Artwork thumbnail ──────────────────────────────────────────────────────────

class _ArtworkThumb extends StatelessWidget {
  final String label;
  final String emoji;
  final Color color;

  const _ArtworkThumb({
    required this.label,
    required this.emoji,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.ivory),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
