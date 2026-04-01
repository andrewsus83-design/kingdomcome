import 'package:flutter/material.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';

/// The six liturgical seasons recognised by the Roman Catholic calendar.
enum LiturgicalSeason {
  advent,
  christmas,
  ordinaryTime,
  lent,
  easter,
  pentecost, // The week of Pentecost (red); part of Easter Season
}

/// Static colour palettes for each liturgical season.
///
/// The Church assigns liturgical colours to seasons to evoke their spiritual
/// character. This class maps each season to primary, accent, and background
/// colours suitable for theming the UI.
abstract final class LiturgicalColors {
  // ── Advent ────────────────────────────────────────────────────────────────
  // Purple / violet — penance, longing, preparation.
  // Gaudete Sunday: rose.

  static const Color adventPrimary = Color(0xFF6B2FA0);    // Deep violet
  static const Color adventSecondary = Color(0xFF9B59B6);  // Lighter violet
  static const Color adventAccent = AppColors.liturgicalRose; // Gaudete rose
  static const Color adventBackground = Color(0xFF1A0A2E); // Dark violet bg
  static const Color adventSurface = Color(0xFF2D1248);

  // ── Christmas ─────────────────────────────────────────────────────────────
  // White & gold — joy, purity, the divine light of the Incarnation.

  static const Color christmasPrimary = Color(0xFFFAF8F2);   // White
  static const Color christmasSecondary = AppColors.gold;    // Gold
  static const Color christmasAccent = Color(0xFFE8C84E);    // Bright gold
  static const Color christmasBackground = Color(0xFF1A1200); // Rich dark
  static const Color christmasSurface = Color(0xFF2A1F00);

  // ── Ordinary Time ────────────────────────────────────────────────────────
  // Green — growth, hope, the living Church.

  static const Color ordinaryPrimary = AppColors.forestGreen;
  static const Color ordinarySecondary = AppColors.sage;
  static const Color ordinaryAccent = Color(0xFF5DBB63);      // Bright leaf
  static const Color ordinaryBackground = Color(0xFF0A1A0E);  // Dark forest
  static const Color ordinarySurface = Color(0xFF122A18);

  // ── Lent ─────────────────────────────────────────────────────────────────
  // Violet / purple — penance, fasting, conversion.
  // Laetare Sunday: rose.

  static const Color lentPrimary = Color(0xFF5C2A82);          // Dark violet
  static const Color lentSecondary = Color(0xFF7B3FA0);        // Violet
  static const Color lentAccent = AppColors.liturgicalRose;    // Laetare rose
  static const Color lentBackground = Color(0xFF120820);       // Very dark
  static const Color lentSurface = Color(0xFF1E1030);

  // ── Easter ───────────────────────────────────────────────────────────────
  // White & gold — resurrection glory, joy.

  static const Color easterPrimary = Color(0xFFF9F6EE);        // Warm white
  static const Color easterSecondary = AppColors.gold;
  static const Color easterAccent = Color(0xFFFFE082);         // Bright gold
  static const Color easterBackground = Color(0xFF1A1600);     // Deep amber
  static const Color easterSurface = Color(0xFF2A2200);

  // ── Pentecost ────────────────────────────────────────────────────────────
  // Red — fire of the Holy Spirit, zeal, martyrs.

  static const Color pentecostPrimary = Color(0xFFC0392B);     // Crimson
  static const Color pentecostSecondary = Color(0xFFE74C3C);   // Red
  static const Color pentecostAccent = Color(0xFFFF8A65);      // Flame orange
  static const Color pentecostBackground = Color(0xFF1A0404);  // Dark red
  static const Color pentecostSurface = Color(0xFF2A0808);

  // ── Convenience getters ───────────────────────────────────────────────────

  /// Returns the primary colour for a given [LiturgicalSeason].
  static Color primaryFor(LiturgicalSeason season) {
    switch (season) {
      case LiturgicalSeason.advent:
        return adventPrimary;
      case LiturgicalSeason.christmas:
        return christmasPrimary;
      case LiturgicalSeason.ordinaryTime:
        return ordinaryPrimary;
      case LiturgicalSeason.lent:
        return lentPrimary;
      case LiturgicalSeason.easter:
        return easterPrimary;
      case LiturgicalSeason.pentecost:
        return pentecostPrimary;
    }
  }

  /// Returns the accent colour for a given [LiturgicalSeason].
  static Color accentFor(LiturgicalSeason season) {
    switch (season) {
      case LiturgicalSeason.advent:
        return adventAccent;
      case LiturgicalSeason.christmas:
        return christmasAccent;
      case LiturgicalSeason.ordinaryTime:
        return ordinaryAccent;
      case LiturgicalSeason.lent:
        return lentAccent;
      case LiturgicalSeason.easter:
        return easterAccent;
      case LiturgicalSeason.pentecost:
        return pentecostAccent;
    }
  }

  /// Returns the background colour for a given [LiturgicalSeason].
  static Color backgroundFor(LiturgicalSeason season) {
    switch (season) {
      case LiturgicalSeason.advent:
        return adventBackground;
      case LiturgicalSeason.christmas:
        return christmasBackground;
      case LiturgicalSeason.ordinaryTime:
        return ordinaryBackground;
      case LiturgicalSeason.lent:
        return lentBackground;
      case LiturgicalSeason.easter:
        return easterBackground;
      case LiturgicalSeason.pentecost:
        return pentecostBackground;
    }
  }

  /// Returns the surface colour for a given [LiturgicalSeason].
  static Color surfaceFor(LiturgicalSeason season) {
    switch (season) {
      case LiturgicalSeason.advent:
        return adventSurface;
      case LiturgicalSeason.christmas:
        return christmasSurface;
      case LiturgicalSeason.ordinaryTime:
        return ordinarySurface;
      case LiturgicalSeason.lent:
        return lentSurface;
      case LiturgicalSeason.easter:
        return easterSurface;
      case LiturgicalSeason.pentecost:
        return pentecostSurface;
    }
  }

  /// Human-readable display name for a liturgical season.
  static String displayNameFor(LiturgicalSeason season) {
    switch (season) {
      case LiturgicalSeason.advent:
        return 'Advent';
      case LiturgicalSeason.christmas:
        return 'Christmas';
      case LiturgicalSeason.ordinaryTime:
        return 'Ordinary Time';
      case LiturgicalSeason.lent:
        return 'Lent';
      case LiturgicalSeason.easter:
        return 'Easter';
      case LiturgicalSeason.pentecost:
        return 'Pentecost';
    }
  }

  /// The traditional liturgical colour name displayed in the UI.
  static String vestmentColorFor(LiturgicalSeason season) {
    switch (season) {
      case LiturgicalSeason.advent:
        return 'Violet';
      case LiturgicalSeason.christmas:
        return 'White';
      case LiturgicalSeason.ordinaryTime:
        return 'Green';
      case LiturgicalSeason.lent:
        return 'Violet';
      case LiturgicalSeason.easter:
        return 'White';
      case LiturgicalSeason.pentecost:
        return 'Red';
    }
  }
}
