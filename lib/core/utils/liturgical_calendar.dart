import 'package:kingdomcome/core/theme/liturgical_colors.dart';

/// Calculates the current Catholic liturgical season for any Gregorian date.
///
/// Algorithm sources:
/// — Easter date via the Meeus/Jones/Butcher algorithm (valid 1900–2099).
/// — Advent start: 4th Sunday before Christmas (Dec 25).
/// — Ash Wednesday: 46 days before Easter.
/// — Pentecost: 49 days after Easter (7th Sunday of Easter Season).
abstract final class LiturgicalCalendar {
  // ── Public API ────────────────────────────────────────────────────────────

  /// Returns the [LiturgicalSeason] for the given [date].
  ///
  /// All comparisons are made using calendar date only (time is ignored).
  static LiturgicalSeason seasonFor(DateTime date) {
    final d = _dateOnly(date);
    final year = d.year;

    final christmas = DateTime(year, 12, 25);
    final adventStart = _adventStart(year);
    final easterSunday = _easterDate(year);
    final ashWednesday = easterSunday.subtract(const Duration(days: 46));
    final pentecost = easterSunday.add(const Duration(days: 49));
    final pentecostEnd = pentecost.add(const Duration(days: 7));

    // Christmas Season: Dec 25 → Jan 12 (Baptism of the Lord, ~2nd Sunday)
    // Span: Dec 25 of previous year through Baptism of the Lord of this year.
    final epiphany = _epiphany(year); // Jan 6 or nearest Sunday
    final baptismOfLord = _baptismOfLord(year, epiphany);

    // Handle Christmas season that started last year
    final lastYearChristmas = DateTime(year - 1, 12, 25);
    final lastYearBaptism = _baptismOfLord(year, epiphany);
    if (d.isBefore(lastYearBaptism) &&
        !d.isBefore(lastYearChristmas)) {
      return LiturgicalSeason.christmas;
    }

    // Advent: adventStart → Dec 24
    if (!d.isBefore(adventStart) &&
        d.isBefore(christmas)) {
      return LiturgicalSeason.advent;
    }

    // Christmas: Dec 25 → Baptism of the Lord
    if (!d.isBefore(christmas) ||
        (!d.isBefore(DateTime(year, 1, 1)) &&
            d.isBefore(baptismOfLord))) {
      if (!d.isBefore(christmas) || d.isBefore(baptismOfLord)) {
        return LiturgicalSeason.christmas;
      }
    }

    // Lent: Ash Wednesday → Holy Saturday (day before Easter)
    final holySaturday = easterSunday.subtract(const Duration(days: 1));
    if (!d.isBefore(ashWednesday) && !d.isAfter(holySaturday)) {
      return LiturgicalSeason.lent;
    }

    // Easter Season: Easter Sunday → day before Pentecost
    final dayBeforePentecost =
        pentecost.subtract(const Duration(days: 1));
    if (!d.isBefore(easterSunday) && !d.isAfter(dayBeforePentecost)) {
      return LiturgicalSeason.easter;
    }

    // Pentecost week: Pentecost Sunday → Saturday after Pentecost
    if (!d.isBefore(pentecost) && d.isBefore(pentecostEnd)) {
      return LiturgicalSeason.pentecost;
    }

    // Default — Ordinary Time
    return LiturgicalSeason.ordinaryTime;
  }

  /// Returns the [LiturgicalSeason] for today.
  static LiturgicalSeason get currentSeason =>
      seasonFor(DateTime.now());

  /// Returns true if [date] falls on Gaudete Sunday (3rd Sunday of Advent).
  static bool isGaudeteSunday(DateTime date) {
    final d = _dateOnly(date);
    if (d.weekday != DateTime.sunday) return false;
    final adventStart = _adventStart(d.year);
    final thirdSunday = adventStart.add(const Duration(days: 14));
    return d == thirdSunday;
  }

  /// Returns true if [date] falls on Laetare Sunday (4th Sunday of Lent).
  static bool isLaetareSunday(DateTime date) {
    final d = _dateOnly(date);
    if (d.weekday != DateTime.sunday) return false;
    final easter = _easterDate(d.year);
    final laetare = easter.subtract(const Duration(days: 21));
    return d == laetare;
  }

  /// Returns the Easter date for [year].
  static DateTime easterForYear(int year) => _easterDate(year);

  /// Returns the Ash Wednesday date for [year].
  static DateTime ashWednesdayForYear(int year) =>
      _easterDate(year).subtract(const Duration(days: 46));

  /// Returns the Pentecost date for [year].
  static DateTime pentecostForYear(int year) =>
      _easterDate(year).add(const Duration(days: 49));

  /// Returns the Advent start date for [year].
  static DateTime adventStartForYear(int year) => _adventStart(year);

  // ── Easter calculation — Meeus/Jones/Butcher algorithm ───────────────────

  static DateTime _easterDate(int year) {
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

  // ── Advent start — 4th Sunday before Christmas ────────────────────────────

  static DateTime _adventStart(int year) {
    final christmas = DateTime(year, 12, 25);
    // Find the Sunday on or before Nov 27 (earliest Advent Sunday)
    // Advent starts on the Sunday that falls 4 Sundays before Christmas.
    final christmasWeekday = christmas.weekday; // 1=Mon … 7=Sun
    // Days back to the nearest Sunday on or before Nov 30
    final daysBackToSunday = christmasWeekday % 7; // 0 if already Sunday
    // The 4th Sunday before Christmas:
    final fourSundaysBefore = daysBackToSunday + 21; // 3 more weeks
    return christmas.subtract(Duration(days: fourSundaysBefore));
  }

  // ── Epiphany — Jan 6 (transferred to nearest Sunday in some territories) ──

  static DateTime _epiphany(int year) {
    // Use the fixed Jan 6 date (Roman Rite general calendar).
    return DateTime(year, 1, 6);
  }

  // ── Baptism of the Lord — Sunday after Epiphany (or Jan 13 if Epiphany ──
  //    is on Sunday Jan 7/8, then the Baptism is the following Sunday)

  static DateTime _baptismOfLord(int year, DateTime epiphany) {
    final epiphanyWeekday = epiphany.weekday;
    if (epiphanyWeekday == DateTime.sunday) {
      // Baptism of the Lord is the following Sunday
      return epiphany.add(const Duration(days: 7));
    }
    // Next Sunday after Epiphany
    final daysUntilSunday = DateTime.sunday - epiphanyWeekday;
    return epiphany.add(Duration(days: daysUntilSunday));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static DateTime _dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);
}
