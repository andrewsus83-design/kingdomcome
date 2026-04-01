import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../data/models/arts/artwork_model.dart';
import '../../providers/arts_provider.dart';
import '../../providers/auth_provider.dart';

class ArtsGalleryScreen extends ConsumerStatefulWidget {
  const ArtsGalleryScreen({super.key});

  @override
  ConsumerState<ArtsGalleryScreen> createState() => _ArtsGalleryScreenState();
}

class _ArtsGalleryScreenState extends ConsumerState<ArtsGalleryScreen> {
  ArtworkType? _filterType;

  @override
  Widget build(BuildContext context) {
    final artworksAsync = ref.watch(artsNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Arts Gallery',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontFamily: 'Cinzel',
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
      ),
      body: Column(
        children: [
          // ── Filter bar ────────────────────────────────────────────────────
          _buildFilterBar(),
          // ── Artwork grid ──────────────────────────────────────────────────
          Expanded(
            child: artworksAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFD700)),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Failed to load artworks: $e',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
              data: (artworks) {
                final filtered = _filterType == null
                    ? artworks
                    : artworks.where((a) => a.artworkType == _filterType).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) =>
                      _ArtworkCard(artwork: filtered[i])
                          .animate()
                          .fadeIn(delay: (i * 50).ms),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            isSelected: _filterType == null,
            onTap: () => setState(() => _filterType = null),
          ),
          ...ArtworkType.values.map((t) => _FilterChip(
                label: t.displayName,
                isSelected: _filterType == t,
                onTap: () => setState(() => _filterType = t),
              )),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎨', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            'No Artworks Yet',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontFamily: 'Cinzel',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first stained glass\nor illuminated manuscript!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFD700)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD700) : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF1A0A2E) : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Artwork card ──────────────────────────────────────────────────────────────

class _ArtworkCard extends ConsumerWidget {
  const _ArtworkCard({required this.artwork});
  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showDetail(context, ref),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A2A3A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: artwork.isDisplayedInKingdom
                ? const Color(0xFFFFD700).withOpacity(0.5)
                : Colors.white12,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                child: artwork.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: artwork.thumbnailUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (_, __) => _TypeIcon(type: artwork.artworkType),
                        errorWidget: (_, __, ___) => _TypeIcon(type: artwork.artworkType),
                      )
                    : _TypeIcon(type: artwork.artworkType),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artwork.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        artwork.artworkType.displayName,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      if (artwork.holyPointsEarned > 0)
                        Text(
                          '+${artwork.holyPointsEarned} HP',
                          style: const TextStyle(
                            color: Color(0xFF9B59B6),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  if (artwork.isDisplayedInKingdom)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        '🏰 In Kingdom',
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A2A3A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ArtworkDetail(artwork: artwork),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  const _TypeIcon({required this.type});
  final ArtworkType type;

  @override
  Widget build(BuildContext context) {
    final emoji = switch (type) {
      ArtworkType.stainedGlass => '🪟',
      ArtworkType.manuscript => '📜',
      ArtworkType.mosaic => '🔲',
      ArtworkType.banner => '🚩',
    };
    return Container(
      color: const Color(0xFF2C3E50),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 48)),
      ),
    );
  }
}

// ── Artwork detail sheet ──────────────────────────────────────────────────────

class _ArtworkDetail extends ConsumerWidget {
  const _ArtworkDetail({required this.artwork});
  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollCtrl) {
        return SingleChildScrollView(
          controller: scrollCtrl,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Thumbnail large
                if (artwork.thumbnailUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: artwork.thumbnailUrl!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  artwork.title,
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontFamily: 'Cinzel',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  artwork.artworkType.displayName,
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 20),
                // Actions
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _DetailButton(
                      icon: Icons.share,
                      label: 'Share',
                      onTap: () {},
                    ),
                    _DetailButton(
                      icon: artwork.isDisplayedInKingdom
                          ? Icons.visibility_off
                          : Icons.castle,
                      label: artwork.isDisplayedInKingdom
                          ? 'Remove from Kingdom'
                          : 'Display in Kingdom',
                      onTap: () async {
                        final notifier = ref.read(artsNotifierProvider.notifier);
                        await notifier.displayInKingdom(artwork.id, location: {'position': 'auto'});
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                    _DetailButton(
                      icon: Icons.people,
                      label: 'Inspire Others',
                      onTap: () {},
                    ),
                  ],
                ),
                if (artwork.holyPointsEarned > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9B59B6).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFF9B59B6).withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars, color: Color(0xFF9B59B6)),
                        const SizedBox(width: 8),
                        Text(
                          'Earned ${artwork.holyPointsEarned} Holy Points for creating this artwork',
                          style: const TextStyle(
                              color: Color(0xFF9B59B6), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DetailButton extends StatelessWidget {
  const _DetailButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.1),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}
