import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/asset_paths.dart';
import 'package:kingdomcome/data/models/kingdom/building_model.dart';
import 'package:kingdomcome/data/models/kingdom/building_type.dart';

/// A single tile on the kingdom map grid.
///
/// - **Occupied**: Displays the building sprite at the appropriate level,
///   overlaid with level stars and an optional construction animation.
/// - **Empty**: Shows a "+" icon with a pulsing glow to invite placement.
///
/// Both variants respond to [onTap].
class BuildingTile extends StatelessWidget {
  /// The building occupying this tile, or `null` for an empty tile.
  final BuildingModel? building;

  /// Called when the user taps the tile (occupied or empty).
  final VoidCallback? onTap;

  const BuildingTile({
    super.key,
    required this.building,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (building == null) {
      return _EmptyTile(onTap: onTap);
    }
    return _OccupiedTile(building: building!, onTap: onTap);
  }
}

// ── Occupied tile ─────────────────────────────────────────────────────────────

class _OccupiedTile extends StatelessWidget {
  final BuildingModel building;
  final VoidCallback? onTap;

  const _OccupiedTile({required this.building, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Building sprite
          _BuildingSprite(building: building),

          // Construction overlay
          if (building.isUnderConstruction)
            _ConstructionOverlay(completesAt: building.constructionCompletesAt),

          // Level stars (bottom-centre)
          Positioned(
            bottom: 2,
            left: 0,
            right: 0,
            child: _LevelStars(level: building.level),
          ),

          // Building type label (very small, top-centre)
          Positioned(
            top: 2,
            left: 2,
            right: 2,
            child: Text(
              building.type.displayName,
              style: AppTextStyles.labelSmall.copyWith(
                fontSize: 7,
                color: AppColors.parchment.withOpacity(0.85),
                shadows: [
                  const Shadow(
                    color: Colors.black,
                    blurRadius: 4,
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Building sprite ───────────────────────────────────────────────────────────

class _BuildingSprite extends StatelessWidget {
  final BuildingModel building;
  const _BuildingSprite({required this.building});

  @override
  Widget build(BuildContext context) {
    final spritePath =
        AssetPaths.buildingSprite(building.type.name, building.level);

    return ClipRRect(
      borderRadius: AppSpacing.borderRadiusSm,
      child: Image.asset(
        spritePath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none, // pixel-art crispness
        errorBuilder: (_, __, ___) => _FallbackSprite(type: building.type),
      ),
    );
  }
}

// ── Fallback sprite (when asset is missing) ───────────────────────────────────

class _FallbackSprite extends StatelessWidget {
  final BuildingType type;
  const _FallbackSprite({required this.type});

  IconData get _icon {
    switch (type) {
      case BuildingType.cathedral:
        return Icons.church;
      case BuildingType.monastery:
        return Icons.account_balance;
      case BuildingType.school:
        return Icons.school;
      case BuildingType.workshop:
        return Icons.palette;
      case BuildingType.chapel:
        return Icons.meeting_room;
      case BuildingType.bellTower:
        return Icons.notifications;
      case BuildingType.parishHall:
        return Icons.people;
      case BuildingType.scriptorium:
        return Icons.menu_book;
      case BuildingType.oratory:
        return Icons.auto_awesome;
      case BuildingType.garden:
        return Icons.park;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkElevated,
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(
          color: AppColors.goldDark.withOpacity(0.4),
        ),
      ),
      child: Icon(
        _icon,
        color: AppColors.gold.withOpacity(0.7),
        size: 28,
      ),
    );
  }
}

// ── Level stars ───────────────────────────────────────────────────────────────

class _LevelStars extends StatelessWidget {
  final int level;
  const _LevelStars({required this.level});

  /// Shows up to 5 filled stars, cycling every 5 levels.
  int get _filled => ((level - 1) % 5) + 1;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        5,
        (i) => Icon(
          i < _filled ? Icons.star : Icons.star_border,
          size: 7,
          color: i < _filled ? AppColors.gold : AppColors.midGrey.withOpacity(0.4),
          shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
        ),
      ),
    );
  }
}

// ── Construction overlay ──────────────────────────────────────────────────────

class _ConstructionOverlay extends StatelessWidget {
  final DateTime? completesAt;
  const _ConstructionOverlay({this.completesAt});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: AppSpacing.borderRadiusSm,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Lottie construction animation
          Center(
            child: Lottie.asset(
              AssetPaths.constructionAnimation,
              width: 40,
              height: 40,
              repeat: true,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.construction,
                color: AppColors.faithCoins,
                size: 24,
              ),
            ),
          ),

          // Countdown timer
          if (completesAt != null)
            Positioned(
              bottom: 4,
              left: 0,
              right: 0,
              child: _ConstructionCountdown(completesAt: completesAt!),
            ),
        ],
      ),
    );
  }
}

// ── Construction countdown (live-ticking) ────────────────────────────────────

class _ConstructionCountdown extends StatefulWidget {
  final DateTime completesAt;
  const _ConstructionCountdown({required this.completesAt});

  @override
  State<_ConstructionCountdown> createState() => _ConstructionCountdownState();
}

class _ConstructionCountdownState extends State<_ConstructionCountdown> {
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = _computeRemaining();
  }

  Duration _computeRemaining() {
    final diff = widget.completesAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  String _format(Duration d) {
    if (d.inHours >= 1) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    if (d.inMinutes >= 1) {
      return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    }
    return '${d.inSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    // Re-compute once per second via a periodic rebuild triggered by
    // a simple AnimationController-less approach using the stream trick.
    return StreamBuilder<void>(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, _) {
        _remaining = _computeRemaining();
        if (_remaining == Duration.zero) {
          return const SizedBox.shrink();
        }
        return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _format(_remaining),
              style: AppTextStyles.labelSmall.copyWith(
                fontSize: 8,
                color: AppColors.faithCoins,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}

// ── Empty tile ────────────────────────────────────────────────────────────────

class _EmptyTile extends StatelessWidget {
  final VoidCallback? onTap;
  const _EmptyTile({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkSurface.withOpacity(0.3),
          borderRadius: AppSpacing.borderRadiusSm,
          border: Border.all(
            color: AppColors.goldDark.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.add,
            color: AppColors.goldDark.withOpacity(0.4),
            size: 20,
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(
                begin: 0.85,
                end: 1.0,
                duration: 1200.ms,
                curve: Curves.easeInOut,
              )
              .fadeIn(begin: 0.4, duration: 1200.ms),
        ),
      ),
    );
  }
}
