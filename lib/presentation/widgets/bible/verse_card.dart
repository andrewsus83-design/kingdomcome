import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';
import 'package:kingdomcome/core/constants/asset_paths.dart';
import 'package:kingdomcome/data/models/bible/verse_model.dart';

/// Beautiful verse display card with book:chapter:verse reference.
///
/// When [isVerseOfDay] is true, the card renders in an expanded "hero" style
/// with gold decorations. Otherwise it renders as a compact list card.
class VerseCard extends StatelessWidget {
  final VerseModel verse;
  final bool isVerseOfDay;
  final VoidCallback? onTap;

  const VerseCard({
    super.key,
    required this.verse,
    this.isVerseOfDay = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return isVerseOfDay ? _HeroVerseCard(verse: verse) : _CompactVerseCard(verse: verse, onTap: onTap);
  }
}

// ── Hero card (verse of the day) ──────────────────────────────────────────────

class _HeroVerseCard extends StatelessWidget {
  final VerseModel verse;
  const _HeroVerseCard({required this.verse});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _copyToClipboard(context, verse),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2D0F42),
              Color(0xFF0A1A0E),
            ],
          ),
          borderRadius: AppSpacing.borderRadiusXl,
          border: Border.all(color: AppColors.gold.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withOpacity(0.1),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
          image: const DecorationImage(
            image: AssetImage(AssetPaths.parchmentTexture),
            fit: BoxFit.cover,
            opacity: 0.06,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Verse of the Day" header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.15),
                    borderRadius: AppSpacing.borderRadiusSm,
                    border:
                        Border.all(color: AppColors.gold.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: AppColors.gold, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Verse of the Day',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Opening decorative quote mark
            Text(
              '\u201C',
              style: TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 72,
                color: AppColors.gold.withOpacity(0.2),
                height: 0.5,
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Verse text
            Text(
              verse.text,
              style: AppTextStyles.scriptureQuote.copyWith(
                color: AppColors.parchment,
                fontSize: 17,
                height: 1.8,
              ),
            ).animate(delay: 200.ms).fadeIn(),

            const SizedBox(height: AppSpacing.md),

            // Citation
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '— ${verse.citation}',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.goldLight,
                  fontStyle: FontStyle.italic,
                ),
              ).animate(delay: 400.ms).fadeIn(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Compact card ──────────────────────────────────────────────────────────────

class _CompactVerseCard extends StatelessWidget {
  final VerseModel verse;
  final VoidCallback? onTap;

  const _CompactVerseCard({required this.verse, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _copyToClipboard(context, verse),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(color: AppColors.goldDark.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.deepPurple.withOpacity(0.3),
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                  child: Text(
                    verse.citation,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.goldLight,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.copy_outlined,
                    color: AppColors.midGrey, size: 14),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              verse.text,
              style: AppTextStyles.scriptureQuote.copyWith(
                color: AppColors.parchment,
                fontSize: 14,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

void _copyToClipboard(BuildContext context, VerseModel verse) {
  Clipboard.setData(
    ClipboardData(text: '"${verse.text}" — ${verse.citation}'),
  );
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Verse copied: ${verse.citation}',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.goldLight),
      ),
      backgroundColor: AppColors.darkCard,
      duration: const Duration(seconds: 2),
    ),
  );
}
