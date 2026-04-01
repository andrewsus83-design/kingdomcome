import 'package:flutter/material.dart';

/// Kingdom Come — Medieval Catholic colour palette.
///
/// All colours are 8-digit hex literals (ARGB) so they are fully opaque
/// unless otherwise noted.  Liturgical season colours are defined separately
/// in [LiturgicalColors] but re-exported here for convenience.
abstract final class AppColors {
  // ── Primary brand colours ─────────────────────────────────────────────────

  /// Royal / pontifical purple — primary brand colour.
  static const Color deepPurple = Color(0xFF4A1A6B);

  /// Lighter purple tint for surfaces and cards.
  static const Color purpleLight = Color(0xFF7B3FA0);

  /// Darkest purple — used for deep backgrounds in dark mode.
  static const Color purpleDark = Color(0xFF2D0F42);

  // ── Gold / Metallic ───────────────────────────────────────────────────────

  /// Brilliant gold — accents, crowns, XP indicators.
  static const Color gold = Color(0xFFD4A017);

  /// Pale gold / champagne — secondary highlight.
  static const Color goldLight = Color(0xFFF5D76E);

  /// Deep antique gold — borders, dividers.
  static const Color goldDark = Color(0xFF8B6914);

  // ── Crimson / Red ─────────────────────────────────────────────────────────

  /// Martyr's crimson — danger, health, Pentecost accent.
  static const Color crimson = Color(0xFFC0392B);

  /// Bright red — error states, urgent badges.
  static const Color red = Color(0xFFE74C3C);

  /// Deep burgundy — secondary cards in dark mode.
  static const Color burgundy = Color(0xFF7B1B2A);

  // ── Ivory / Parchment ─────────────────────────────────────────────────────

  /// Warm ivory — primary background in light mode.
  static const Color ivory = Color(0xFFFDF6E3);

  /// Parchment — card backgrounds in light mode.
  static const Color parchment = Color(0xFFF5E6C8);

  /// Aged parchment — subtle dividers and borders.
  static const Color parchmentDark = Color(0xFFD4C5A0);

  // ── Forest Green ──────────────────────────────────────────────────────────

  /// Forest green — Ordinary Time, nature elements.
  static const Color forestGreen = Color(0xFF2C6E49);

  /// Light sage — secondary green for badges and tags.
  static const Color sage = Color(0xFF74A87A);

  /// Deep forest — dark-mode green accent.
  static const Color deepGreen = Color(0xFF1A4A31);

  // ── Neutrals ──────────────────────────────────────────────────────────────

  /// Near-black — primary text in light mode.
  static const Color inkBlack = Color(0xFF1C1108);

  /// Warm dark grey — secondary text.
  static const Color warmGrey = Color(0xFF5C5346);

  /// Mid grey — disabled states.
  static const Color midGrey = Color(0xFF9E9590);

  /// Light grey — backgrounds, dividers.
  static const Color lightGrey = Color(0xFFE8E4DE);

  /// Pure white — surface overlays.
  static const Color white = Color(0xFFFFFFFF);

  // ── Dark mode surfaces ────────────────────────────────────────────────────

  /// Dark surface — main background in dark mode.
  static const Color darkSurface = Color(0xFF12091E);

  /// Dark card — card surface in dark mode.
  static const Color darkCard = Color(0xFF1E1030);

  /// Dark elevated — dialogs, bottom sheets in dark mode.
  static const Color darkElevated = Color(0xFF2A1845);

  // ── Liturgical season colours ──────────────────────────────────────────────
  // (See liturgical_colors.dart for the full semantic class)

  /// Advent & Lent violet/purple.
  static const Color liturgicalPurple = Color(0xFF6B2FA0);

  /// Christmas & Easter white.
  static const Color liturgicalWhite = Color(0xFFFAF8F2);

  /// Ordinary Time green.
  static const Color liturgicalGreen = Color(0xFF2C6E49);

  /// Pentecost & Martyrs red.
  static const Color liturgicalRed = Color(0xFFC0392B);

  /// Gaudete & Laetare rose.
  static const Color liturgicalRose = Color(0xFFD4699E);

  /// Christmas & Easter gold accent.
  static const Color liturgicalGold = Color(0xFFD4A017);

  // ── Faith / game-mechanic colours ─────────────────────────────────────────

  /// Holy Points — luminous blue-white.
  static const Color holyPoints = Color(0xFF5DADE2);

  /// Faith Coins — golden yellow.
  static const Color faithCoins = Color(0xFFF1C40F);

  /// Grace — soft lavender.
  static const Color grace = Color(0xFFBB8FCE);

  /// Blessings — warm amber.
  static const Color blessings = Color(0xFFE59866);

  /// XP bar fill gradient start.
  static const Color xpStart = Color(0xFF8E44AD);

  /// XP bar fill gradient end.
  static const Color xpEnd = Color(0xFFD4A017);
}
