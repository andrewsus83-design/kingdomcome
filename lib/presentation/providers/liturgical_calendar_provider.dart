import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:kingdomcome/core/theme/liturgical_colors.dart';

part 'liturgical_calendar_provider.g.dart';

// ── Current season ────────────────────────────────────────────────────────────

/// Computes the current [LiturgicalSeason] from today's date.
///
/// Uses approximate date ranges for the Roman Catholic calendar.
/// Easter date is computed using the anonymous Gregorian algorithm.
@riverpod
LiturgicalSeason currentSeason(Ref ref) {
  return LiturgicalCalendarUtil.currentSeason();
}

// ── Utility ───────────────────────────────────────────────────────────────────

abstract final class LiturgicalCalendarUtil {
  /// Computes the current liturgical season from [DateTime.now()].
  static LiturgicalSeason currentSeason([DateTime? date]) {
    final now = date ?? DateTime.now();
    final year = now.year;

    // ── Compute Easter (anonymous Gregorian algorithm) ─────────────────────
    final easterDate = _computeEaster(year);

    // ── Key dates derived from Easter ─────────────────────────────────────
    final ashWednesday = easterDate.subtract(const Duration(days: 46));
    final holyThursday = easterDate.subtract(const Duration(days: 3));
    final pentecost = easterDate.add(const Duration(days: 49));

    // ── Advent (4 Sundays before Christmas) ───────────────────────────────
    final christmas = DateTime(year, 12, 25);
    final adventStart = _adventStart(year);

    // ── Christmas season (Dec 25 – Baptism of the Lord, ~Jan 9–13) ────────
    // Baptism of the Lord = Sunday after Jan 6 (Epiphany)
    final epiphany = _epiphany(year);
    final baptismOfLord = _nextSunday(epiphany);
    // Christmas season for next year carries into January
    final prevChristmasEnd = _nextSunday(_epiphany(year - 1));

    // ── Evaluate ────────────────────────────────────────────────────────────

    // Christmas (last year's season, if still ongoing in January)
    if (now.isBefore(prevChristmasEnd) && now.month == 1) {
      return LiturgicalSeason.christmas;
    }

    // Ordinary Time (Jan/Feb before Ash Wednesday)
    if (now.isAfter(prevChristmasEnd) && now.isBefore(ashWednesday)) {
      return LiturgicalSeason.ordinaryTime;
    }

    // Lent (Ash Wednesday to Holy Thursday)
    if (!now.isBefore(ashWednesday) && now.isBefore(holyThursday)) {
      return LiturgicalSeason.lent;
    }

    // Easter (Holy Thursday to Pentecost)
    if (!now.isBefore(holyThursday) && now.isBefore(pentecost)) {
      // Highlight Pentecost week
      final pentecostEnd = pentecost.add(const Duration(days: 7));
      if (!now.isBefore(pentecost) && now.isBefore(pentecostEnd)) {
        return LiturgicalSeason.pentecost;
      }
      return LiturgicalSeason.easter;
    }

    // Ordinary Time (post-Pentecost to Advent)
    if (!now.isBefore(pentecost) && now.isBefore(adventStart)) {
      return LiturgicalSeason.ordinaryTime;
    }

    // Advent
    if (!now.isBefore(adventStart) && now.isBefore(christmas)) {
      return LiturgicalSeason.advent;
    }

    // Christmas (Dec 25 onwards)
    if (!now.isBefore(christmas) && now.isBefore(baptismOfLord.add(const Duration(days: 1)))) {
      return LiturgicalSeason.christmas;
    }

    // Ordinary Time (after Baptism of the Lord until next year's Ash Wednesday)
    return LiturgicalSeason.ordinaryTime;
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  /// Computes Easter Sunday for [year] using the Anonymous Gregorian algorithm.
  static DateTime _computeEaster(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime(year, month, day);
  }

  /// Returns the first Sunday of Advent (4th Sunday before Christmas).
  static DateTime _adventStart(int year) {
    final christmas = DateTime(year, 12, 25);
    // Go back to find the Sunday on or before Nov 30 (closest Sunday to Dec 1)
    // Advent begins 4 Sundays before Christmas
    final dayOfWeek = christmas.weekday; // 1=Mon, 7=Sun
    // How many days back to last Sunday from Christmas
    final daysToLastSunday = dayOfWeek % 7; // 0 if Sunday, else days back
    final lastSundayBeforeChristmas =
        christmas.subtract(Duration(days: daysToLastSunday));
    // 4 Sundays before Christmas
    return lastSundayBeforeChristmas.subtract(const Duration(days: 21));
  }

  /// Returns Epiphany (Jan 6, or nearest Sunday in countries that transfer it).
  static DateTime _epiphany(int year) {
    return DateTime(year, 1, 6);
  }

  /// Returns the next Sunday on or after [date].
  static DateTime _nextSunday(DateTime date) {
    final daysUntilSunday = (7 - date.weekday) % 7;
    return date.add(Duration(days: daysUntilSunday));
  }
}
