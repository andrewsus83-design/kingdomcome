import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';

/// Identifies which resource type this badge displays.
enum ResourceBadgeType {
  holyPoints,
  faithCoins,
  grace,
  blessings,
}

extension _ResourceBadgeTypeX on ResourceBadgeType {
  Color get color {
    switch (this) {
      case ResourceBadgeType.holyPoints:
        return AppColors.holyPoints;
      case ResourceBadgeType.faithCoins:
        return AppColors.faithCoins;
      case ResourceBadgeType.grace:
        return AppColors.grace;
      case ResourceBadgeType.blessings:
        return AppColors.blessings;
    }
  }

  IconData get icon {
    switch (this) {
      case ResourceBadgeType.holyPoints:
        return Icons.star;
      case ResourceBadgeType.faithCoins:
        return Icons.monetization_on;
      case ResourceBadgeType.grace:
        return Icons.auto_awesome;
      case ResourceBadgeType.blessings:
        return Icons.favorite;
    }
  }

  String get label {
    switch (this) {
      case ResourceBadgeType.holyPoints:
        return 'HP';
      case ResourceBadgeType.faithCoins:
        return 'FC';
      case ResourceBadgeType.grace:
        return 'GR';
      case ResourceBadgeType.blessings:
        return 'BL';
    }
  }
}

/// Compact HUD badge showing a resource icon and value.
///
/// Animates the number when [value] changes (count-up effect).
class ResourceBadge extends StatefulWidget {
  final ResourceBadgeType type;
  final int value;
  final bool compact;

  const ResourceBadge({
    super.key,
    required this.type,
    required this.value,
    this.compact = true,
  });

  @override
  State<ResourceBadge> createState() => _ResourceBadgeState();
}

class _ResourceBadgeState extends State<ResourceBadge> {
  int _displayValue = 0;

  @override
  void initState() {
    super.initState();
    _displayValue = widget.value;
  }

  @override
  void didUpdateWidget(ResourceBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      setState(() => _displayValue = widget.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.type.color;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? AppSpacing.sm : AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.type.icon, color: color, size: AppSpacing.iconSm),
          const SizedBox(width: AppSpacing.xs),
          Text(
            _formatValue(_displayValue),
            style: AppTextStyles.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ).animate(key: ValueKey(_displayValue)).shimmer(
          duration: 500.ms,
          color: color.withOpacity(0.4),
          delay: 0.ms,
        );
  }

  String _formatValue(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toString();
  }
}
