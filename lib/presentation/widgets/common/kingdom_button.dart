import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';

/// Primary CTA button with a medieval gold/parchment theme.
///
/// States:
///   - **Normal** — gradient gold border, deep purple fill
///   - **Loading** — shows a circular progress indicator inside the button
///   - **Disabled** — muted color, no interaction
class KingdomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool isPrimary;
  final double? minWidth;

  const KingdomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isPrimary = true,
    this.minWidth,
  });

  bool get _isDisabled => onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return _PrimaryButton(
        label: label,
        onPressed: onPressed,
        isLoading: isLoading,
        icon: icon,
        minWidth: minWidth,
      );
    }
    return _SecondaryButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      minWidth: minWidth,
    );
  }
}

// ── Primary ───────────────────────────────────────────────────────────────────

class _PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? minWidth;

  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    required this.isLoading,
    this.icon,
    this.minWidth,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  bool get _isDisabled => widget.onPressed == null || widget.isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _isDisabled ? null : (_) => _pressController.forward(),
      onTapUp: _isDisabled
          ? null
          : (_) {
              _pressController.reverse();
              widget.onPressed?.call();
            },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (ctx, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: BoxConstraints(
            minWidth: widget.minWidth ?? double.infinity,
            minHeight: 52,
          ),
          decoration: BoxDecoration(
            gradient: _isDisabled
                ? null
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.deepPurple, Color(0xFF2D0F60)],
                  ),
            color: _isDisabled ? AppColors.darkElevated : null,
            borderRadius: AppSpacing.borderRadiusMd,
            border: Border.all(
              color: _isDisabled
                  ? AppColors.midGrey.withOpacity(0.3)
                  : AppColors.gold.withOpacity(0.7),
              width: 1.5,
            ),
            boxShadow: _isDisabled
                ? null
                : [
                    BoxShadow(
                      color: AppColors.gold.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: AppColors.gold,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          color: _isDisabled
                              ? AppColors.midGrey
                              : AppColors.goldLight,
                          size: AppSpacing.iconSm,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Text(
                        widget.label.toUpperCase(),
                        style: AppTextStyles.buttonPrimary.copyWith(
                          color: _isDisabled
                              ? AppColors.midGrey
                              : AppColors.goldLight,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Secondary ─────────────────────────────────────────────────────────────────

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? minWidth;

  const _SecondaryButton({
    required this.label,
    required this.onPressed,
    required this.isLoading,
    this.icon,
    this.minWidth,
  });

  bool get _isDisabled => onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: _isDisabled ? null : onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: _isDisabled
              ? AppColors.midGrey.withOpacity(0.3)
              : AppColors.gold.withOpacity(0.6),
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        minimumSize: minWidth != null
            ? Size(minWidth!, 52)
            : const Size(double.infinity, 52),
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: AppColors.gold,
                strokeWidth: 2,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: _isDisabled ? AppColors.midGrey : AppColors.gold,
                    size: AppSpacing.iconSm,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(
                  label.toUpperCase(),
                  style: AppTextStyles.buttonSecondary.copyWith(
                    color: _isDisabled ? AppColors.midGrey : AppColors.gold,
                  ),
                ),
              ],
            ),
    );
  }
}
