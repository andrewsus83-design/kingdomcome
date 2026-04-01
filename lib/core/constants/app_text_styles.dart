import 'package:flutter/material.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';

/// Kingdom Come — Typography system.
///
/// Headings use the [Cinzel] serif font (medieval/Roman aesthetic).
/// Body text uses the system sans-serif stack (clean readability for children).
abstract final class AppTextStyles {
  // ── Font family constants ─────────────────────────────────────────────────

  static const String _cinzel = 'Cinzel';

  // ── Display — hero headings ───────────────────────────────────────────────

  /// Kingdom / screen title — largest display text.
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _cinzel,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: 2,
    height: 1.1,
    color: AppColors.inkBlack,
  );

  /// Section hero heading.
  static const TextStyle displayMedium = TextStyle(
    fontFamily: _cinzel,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    height: 1.15,
    color: AppColors.inkBlack,
  );

  /// Smaller hero / banner text.
  static const TextStyle displaySmall = TextStyle(
    fontFamily: _cinzel,
    fontSize: 26,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    height: 1.2,
    color: AppColors.inkBlack,
  );

  // ── Headlines — screen and section titles ─────────────────────────────────

  /// Primary screen headline.
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: _cinzel,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    height: 1.25,
    color: AppColors.inkBlack,
  );

  /// Card / section headline.
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _cinzel,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.3,
    color: AppColors.inkBlack,
  );

  /// Sub-section heading.
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: _cinzel,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    height: 1.35,
    color: AppColors.inkBlack,
  );

  // ── Title — list items, labels ────────────────────────────────────────────

  static const TextStyle titleLarge = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.4,
    color: AppColors.inkBlack,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
    color: AppColors.inkBlack,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
    color: AppColors.warmGrey,
  );

  // ── Body — readable prose for children ───────────────────────────────────

  /// Primary body text — used for quests, stories, chat.
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    height: 1.6,
    color: AppColors.inkBlack,
  );

  /// Standard body text.
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.55,
    color: AppColors.inkBlack,
  );

  /// Small descriptive text.
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.5,
    color: AppColors.warmGrey,
  );

  // ── Label / Caption ───────────────────────────────────────────────────────

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    height: 1.3,
    color: AppColors.inkBlack,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    height: 1.3,
    color: AppColors.warmGrey,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.3,
    color: AppColors.midGrey,
  );

  // ── Specialised ───────────────────────────────────────────────────────────

  /// Gold accent heading — used for rewards, achievements.
  static const TextStyle goldHeading = TextStyle(
    fontFamily: _cinzel,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
    color: AppColors.gold,
    shadows: [
      Shadow(
        blurRadius: 4,
        color: Color(0x80D4A017),
        offset: Offset(0, 2),
      ),
    ],
  );

  /// Button label — uppercase Cinzel for primary buttons.
  static const TextStyle buttonPrimary = TextStyle(
    fontFamily: _cinzel,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    color: AppColors.white,
  );

  /// Button label — secondary / ghost buttons.
  static const TextStyle buttonSecondary = TextStyle(
    fontFamily: _cinzel,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    color: AppColors.deepPurple,
  );

  /// Chat bubble text — slightly larger for readability.
  static const TextStyle chatText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.6,
    color: AppColors.inkBlack,
  );

  /// Badge / tag label.
  static const TextStyle badge = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
    color: AppColors.white,
  );

  /// Scripture / quote in italic serif.
  static const TextStyle scriptureQuote = TextStyle(
    fontFamily: _cinzel,
    fontSize: 14,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.7,
    color: AppColors.deepPurple,
  );

  /// Stat number — large numerals for XP, coins, etc.
  static const TextStyle statNumber = TextStyle(
    fontFamily: _cinzel,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    color: AppColors.gold,
  );
}
