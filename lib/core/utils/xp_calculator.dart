import 'package:kingdomcome/core/constants/game_constants.dart';

/// XP calculation utilities.
///
/// Handles:
/// — Mapping total XP → current level and progress within that level.
/// — Saint ability XP multipliers.
/// — Login streak bonuses.
/// — Liturgical season bonus multipliers.
abstract final class XpCalculator {
  // ── Level from XP ─────────────────────────────────────────────────────────

  /// Returns the player's current level (1–100) given [totalXp].
  ///
  /// Performs a binary search over [kLevelThresholds] for O(log n) performance.
  static int levelFromXp(int totalXp) {
    if (totalXp <= 0) return 1;

    var lo = 0;
    var hi = kLevelThresholds.length - 1;

    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (kLevelThresholds[mid] <= totalXp) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }

    return lo + 1; // thresholds index 0 = level 1
  }

  /// Returns total XP required to reach [level] (1-indexed).
  ///
  /// [level] must be between 1 and [GameConstants.maxLevel].
  static int xpRequiredForLevel(int level) {
    assert(level >= 1 && level <= GameConstants.maxLevel,
        'Level must be 1–${GameConstants.maxLevel}');
    return kLevelThresholds[level - 1];
  }

  /// Returns XP needed for the *next* level from the player's perspective.
  ///
  /// At max level, returns 0.
  static int xpToNextLevel(int totalXp) {
    final currentLevel = levelFromXp(totalXp);
    if (currentLevel >= GameConstants.maxLevel) return 0;
    return xpRequiredForLevel(currentLevel + 1) - totalXp;
  }

  /// Returns XP required within the current level (i.e. span of the level).
  ///
  /// Used to draw XP progress bars.
  static int xpSpanForCurrentLevel(int totalXp) {
    final currentLevel = levelFromXp(totalXp);
    if (currentLevel >= GameConstants.maxLevel) return 0;
    return xpRequiredForLevel(currentLevel + 1) -
        xpRequiredForLevel(currentLevel);
  }

  /// Returns XP earned within the current level.
  ///
  /// Used alongside [xpSpanForCurrentLevel] to compute progress fraction.
  static int xpInCurrentLevel(int totalXp) {
    final currentLevel = levelFromXp(totalXp);
    if (currentLevel >= GameConstants.maxLevel) return 0;
    return totalXp - xpRequiredForLevel(currentLevel);
  }

  /// Returns a progress fraction [0.0, 1.0] within the current level.
  static double levelProgressFraction(int totalXp) {
    final span = xpSpanForCurrentLevel(totalXp);
    if (span == 0) return 1.0;
    return (xpInCurrentLevel(totalXp) / span).clamp(0.0, 1.0);
  }

  // ── Multiplier calculation ────────────────────────────────────────────────

  /// Applies a saint patron ability XP multiplier.
  ///
  /// [baseXp] — raw XP from the quest/action.
  /// [saintMultiplier] — e.g. 1.15 for a 15% saint bonus.
  static int applySaintMultiplier(int baseXp, double saintMultiplier) {
    assert(saintMultiplier >= 1.0, 'Multiplier must be >= 1.0');
    return (baseXp * saintMultiplier).round();
  }

  /// Returns the streak bonus multiplier for [streakDays].
  ///
  /// — 7+ days: 1.25×
  /// — 30+ days: 1.50×
  /// — 100+ days: 2.00×
  static double streakMultiplier(int streakDays) {
    if (streakDays >= 100) return GameConstants.streakBonusCentenary;
    if (streakDays >= 30) return GameConstants.streakBonusMonth;
    if (streakDays >= 7) return GameConstants.streakBonusWeek;
    return 1.0;
  }

  /// Returns the liturgical season XP bonus multiplier.
  ///
  /// Special seasons grant extra XP for thematic quests:
  /// — Lent / Advent: penance quests give 1.3×
  /// — Easter / Christmas: celebration quests give 1.4×
  /// — Ordinary Time: no bonus (1.0×)
  static double liturgicalSeasonMultiplier(String seasonName) {
    switch (seasonName.toLowerCase()) {
      case 'lent':
      case 'advent':
        return 1.3;
      case 'easter':
      case 'christmas':
        return 1.4;
      case 'pentecost':
        return 1.2;
      default:
        return 1.0;
    }
  }

  /// Computes the final XP to award, stacking all multipliers.
  ///
  /// Parameters:
  /// — [baseXp]: raw XP value from the quest/action.
  /// — [saintMultiplier]: patron saint bonus (default 1.0).
  /// — [streakDays]: current login streak (default 0).
  /// — [seasonName]: current liturgical season name (default '').
  static int computeAwardedXp({
    required int baseXp,
    double saintMultiplier = 1.0,
    int streakDays = 0,
    String seasonName = '',
  }) {
    final withSaint = applySaintMultiplier(baseXp, saintMultiplier);
    final streak = streakMultiplier(streakDays);
    final season = liturgicalSeasonMultiplier(seasonName);
    return (withSaint * streak * season).round();
  }
}
