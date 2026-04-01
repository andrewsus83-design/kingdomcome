import 'package:intl/intl.dart';

import 'package:kingdomcome/core/theme/liturgical_colors.dart';
import 'package:kingdomcome/core/utils/liturgical_calendar.dart';

/// DateTime utility extensions for Kingdom Come.
extension DateTimeExtension on DateTime {
  // ── Today checks ──────────────────────────────────────────────────────────

  /// Returns true if this DateTime falls on today (local time).
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Returns true if this DateTime falls on yesterday.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Returns true if this DateTime falls on tomorrow.
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  // ── Relative days ─────────────────────────────────────────────────────────

  /// Returns the number of full calendar days since this date.
  ///
  /// Returns 0 if [this] is today, 1 if yesterday, negative if in the future.
  int get daysSinceToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final self = DateTime(year, month, day);
    return today.difference(self).inDays;
  }

  /// Returns the number of full calendar days since [other].
  int daysSince(DateTime other) {
    final self = DateTime(year, month, day);
    final otherDay = DateTime(other.year, other.month, other.day);
    return self.difference(otherDay).inDays;
  }

  /// Returns the number of full calendar days until [other].
  int daysUntil(DateTime other) => -daysSince(other);

  // ── Date-only helpers ─────────────────────────────────────────────────────

  /// Returns a new [DateTime] with only date components (time stripped).
  DateTime get dateOnly => DateTime(year, month, day);

  /// Returns a new [DateTime] set to midnight at the start of this day.
  DateTime get startOfDay => DateTime(year, month, day);

  /// Returns a new [DateTime] set to the last moment of this day.
  DateTime get endOfDay =>
      DateTime(year, month, day, 23, 59, 59, 999);

  /// Returns a new [DateTime] for the first day of this month.
  DateTime get startOfMonth => DateTime(year, month);

  /// Returns a new [DateTime] for the last day of this month.
  DateTime get endOfMonth =>
      DateTime(year, month + 1).subtract(const Duration(days: 1));

  // ── Comparison ────────────────────────────────────────────────────────────

  /// Returns true if this date is on the same calendar day as [other].
  bool isSameDayAs(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  /// Returns true if this date is strictly before (not same day as) [other].
  bool isBeforeDay(DateTime other) {
    final self = DateTime(year, month, day);
    final otherDay = DateTime(other.year, other.month, other.day);
    return self.isBefore(otherDay);
  }

  /// Returns true if this date is strictly after (not same day as) [other].
  bool isAfterDay(DateTime other) {
    final self = DateTime(year, month, day);
    final otherDay = DateTime(other.year, other.month, other.day);
    return self.isAfter(otherDay);
  }

  // ── Liturgical calendar ───────────────────────────────────────────────────

  /// Returns the [LiturgicalSeason] for this date.
  LiturgicalSeason get liturgicalSeason =>
      LiturgicalCalendar.seasonFor(this);

  /// Returns true if this date is Easter Sunday.
  bool get isEasterSunday {
    final easter = LiturgicalCalendar.easterForYear(year);
    return isSameDayAs(easter);
  }

  /// Returns true if this date is Ash Wednesday.
  bool get isAshWednesday {
    final ash = LiturgicalCalendar.ashWednesdayForYear(year);
    return isSameDayAs(ash);
  }

  /// Returns true if this date is Pentecost Sunday.
  bool get isPentecost {
    final pentecost = LiturgicalCalendar.pentecostForYear(year);
    return isSameDayAs(pentecost);
  }

  /// Returns true if this date is Christmas Day (Dec 25).
  bool get isChristmasDay => month == 12 && day == 25;

  /// Returns true if this date is the Solemnity of Mary (Jan 1).
  bool get isSolemnityOfMary => month == 1 && day == 1;

  /// Returns true if this date is the Feast of the Immaculate Conception
  /// (Dec 8).
  bool get isImmaculateConception => month == 12 && day == 8;

  /// Returns true if this date is the Solemnity of All Saints (Nov 1).
  bool get isAllSaints => month == 11 && day == 1;

  /// Returns true if this date is the Solemnity of All Souls (Nov 2).
  bool get isAllSouls => month == 11 && day == 2;

  /// Returns true if this date is the Assumption of Mary (Aug 15).
  bool get isAssumption => month == 8 && day == 15;

  /// Returns true if this date falls on a major Catholic solemnity that
  /// grants a bonus liturgical multiplier in the game.
  bool get isFeastDay =>
      isEasterSunday ||
      isAshWednesday ||
      isPentecost ||
      isChristmasDay ||
      isSolemnityOfMary ||
      isImmaculateConception ||
      isAllSaints ||
      isAllSouls ||
      isAssumption;

  // ── Formatting ────────────────────────────────────────────────────────────

  /// Returns the date formatted as `'MMMM d, yyyy'` (e.g. `April 1, 2026`).
  String get displayDate => DateFormat.yMMMMd().format(this);

  /// Returns the date formatted as `'MMM d'` (e.g. `Apr 1`).
  String get shortDisplayDate => DateFormat.MMMd().format(this);

  /// Returns `'Today'`, `'Yesterday'`, `'Tomorrow'`, or [displayDate].
  String get relativeLabel {
    if (isToday) return 'Today';
    if (isYesterday) return 'Yesterday';
    if (isTomorrow) return 'Tomorrow';
    return shortDisplayDate;
  }

  /// Returns a time string in `'h:mm a'` format (e.g. `7:00 AM`).
  String get displayTime => DateFormat.jm().format(this);

  /// Returns the ISO 8601 date string (`yyyy-MM-dd`).
  String get isoDate =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}
