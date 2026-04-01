import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/data/models/arts/artwork_model.dart';
import 'package:kingdomcome/presentation/providers/arts_provider.dart';
import 'package:kingdomcome/presentation/widgets/common/kingdom_button.dart';

class ArtsStudioScreen extends ConsumerStatefulWidget {
  const ArtsStudioScreen({super.key});

  @override
  ConsumerState<ArtsStudioScreen> createState() => _ArtsStudioScreenState();
}

class _ArtsStudioScreenState extends ConsumerState<ArtsStudioScreen> {
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final artworksAsync = ref.watch(artsNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 130,
            backgroundColor: AppColors.purpleDark,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.purpleDark, Color(0xFF2A0A44)],
                  ),
                ),
                alignment: Alignment.bottomLeft,
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Art Studio',
                      style: AppTextStyles.displaySmall.copyWith(
                        color: AppColors.goldLight,
                      ),
                    ),
                    Text(
                      'Create sacred art for your kingdom',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.midGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Art type selector
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Your Art',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.goldLight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1.3,
                    children: ArtworkType.values.asMap().entries.map((e) {
                      return _ArtTypeCard(
                        type: e.value,
                        onTap: () =>
                            context.push('/learn/arts/create/${e.value.name}'),
                        onAiGenerate: () =>
                            _showAiGenerateDialog(context, e.value),
                      ).animate(delay: (e.key * 80).ms).fadeIn().scale(
                            begin: const Offset(0.9, 0.9),
                          );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Gallery
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Text(
                    'My Gallery',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.goldLight,
                    ),
                  ),
                  const Spacer(),
                  artworksAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (arts) => Text(
                      '${arts.length} artworks',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.midGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          artworksAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Center(
                child: Text(e.toString(),
                    style: const TextStyle(color: AppColors.ivory)),
              ),
            ),
            data: (artworks) {
              if (artworks.isEmpty) {
                return const SliverToBoxAdapter(
                  child: _EmptyGallery(),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.md),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _ArtworkTile(
                      artwork: artworks[i],
                      onToggleDisplay: () => ref
                          .read(artsNotifierProvider.notifier)
                          .displayInKingdom(artworks[i].id),
                    ).animate(delay: (i * 40).ms).fadeIn(),
                    childCount: artworks.length,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 1.0,
                  ),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xxl),
          ),
        ],
      ),
    );
  }

  Future<void> _showAiGenerateDialog(
      BuildContext context, ArtworkType type) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: Text(
          'AI ${type.displayName}',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.goldLight,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Describe what you\'d like to create:',
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.midGrey),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              maxLines: 3,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.ivory,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. "Jesus walking on water", "Saint Francis with birds"',
                hintStyle: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.midGrey,
                ),
                filled: true,
                fillColor: AppColors.darkSurface,
                border: OutlineInputBorder(
                  borderRadius: AppSpacing.borderRadiusMd,
                  borderSide:
                      const BorderSide(color: AppColors.darkElevated),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.midGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Generate',
                style: TextStyle(color: AppColors.gold)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      setState(() => _isGenerating = true);
      try {
        await ref.read(artsNotifierProvider.notifier).generateAiArtwork(
              prompt: result,
              type: type,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Artwork generated!'),
              backgroundColor: AppColors.forestGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Generation failed: $e'),
              backgroundColor: AppColors.crimson,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isGenerating = false);
      }
    }
  }
}

// ── Art type card ─────────────────────────────────────────────────────────────

class _ArtTypeCard extends StatelessWidget {
  final ArtworkType type;
  final VoidCallback onTap;
  final VoidCallback onAiGenerate;

  const _ArtTypeCard({
    required this.type,
    required this.onTap,
    required this.onAiGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.goldDark.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _typeColor.withOpacity(0.3),
                      AppColors.darkCard,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppSpacing.radiusLg),
                    topRight: Radius.circular(AppSpacing.radiusLg),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_typeIcon, color: _typeColor, size: 32),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      type.displayName,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.ivory,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // AI generate button
          GestureDetector(
            onTap: onAiGenerate,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
              decoration: BoxDecoration(
                color: AppColors.deepPurple.withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppSpacing.radiusLg),
                  bottomRight: Radius.circular(AppSpacing.radiusLg),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome,
                      color: AppColors.gold, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'AI Generate',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.goldLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color get _typeColor {
    switch (type) {
      case ArtworkType.stainedGlass:
        return AppColors.holyPoints;
      case ArtworkType.manuscript:
        return AppColors.gold;
      case ArtworkType.mosaic:
        return AppColors.grace;
      case ArtworkType.banner:
        return AppColors.blessings;
    }
  }

  IconData get _typeIcon {
    switch (type) {
      case ArtworkType.stainedGlass:
        return Icons.window;
      case ArtworkType.manuscript:
        return Icons.auto_stories;
      case ArtworkType.mosaic:
        return Icons.grid_view;
      case ArtworkType.banner:
        return Icons.flag;
    }
  }
}

// ── Artwork tile ──────────────────────────────────────────────────────────────

class _ArtworkTile extends StatelessWidget {
  final ArtworkModel artwork;
  final VoidCallback onToggleDisplay;

  const _ArtworkTile({required this.artwork, required this.onToggleDisplay});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: AppSpacing.borderRadiusMd,
            border: Border.all(
              color: artwork.isDisplayedInKingdom
                  ? AppColors.gold.withOpacity(0.6)
                  : AppColors.goldDark.withOpacity(0.2),
              width: artwork.isDisplayedInKingdom ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: AppSpacing.borderRadiusMd,
            child: artwork.thumbnailUrl != null
                ? CachedNetworkImage(
                    imageUrl: artwork.thumbnailUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.gold,
                        strokeWidth: 2,
                      ),
                    ),
                    errorWidget: (_, __, ___) => _ArtworkPlaceholder(
                      type: artwork.artworkType,
                    ),
                  )
                : _ArtworkPlaceholder(type: artwork.artworkType),
          ),
        ),

        // Display toggle
        Positioned(
          bottom: AppSpacing.xs,
          right: AppSpacing.xs,
          child: GestureDetector(
            onTap: onToggleDisplay,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.darkCard.withOpacity(0.85),
                shape: BoxShape.circle,
                border: Border.all(
                  color: artwork.isDisplayedInKingdom
                      ? AppColors.gold
                      : AppColors.midGrey,
                ),
              ),
              child: Icon(
                artwork.isDisplayedInKingdom
                    ? Icons.castle
                    : Icons.castle_outlined,
                color: artwork.isDisplayedInKingdom
                    ? AppColors.gold
                    : AppColors.midGrey,
                size: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ArtworkPlaceholder extends StatelessWidget {
  final ArtworkType type;
  const _ArtworkPlaceholder({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkElevated,
      child: Center(
        child: Icon(
          Icons.palette,
          color: AppColors.gold.withOpacity(0.4),
          size: 40,
        ),
      ),
    );
  }
}

// ── Empty gallery ─────────────────────────────────────────────────────────────

class _EmptyGallery extends StatelessWidget {
  const _EmptyGallery();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Icon(
            Icons.palette_outlined,
            size: 64,
            color: AppColors.gold.withOpacity(0.4),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Your Gallery is Empty',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.ivory,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Choose an art type above to create your first masterpiece!',
            style:
                AppTextStyles.bodyMedium.copyWith(color: AppColors.midGrey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
