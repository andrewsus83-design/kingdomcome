/// String utility extensions for Kingdom Come.
extension StringExtension on String {
  // ── Capitalisation ────────────────────────────────────────────────────────

  /// Returns the string with its first character in uppercase.
  ///
  /// Example: `'hello world'.capitalize()` → `'Hello world'`
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Returns the string in Title Case (each word capitalised).
  ///
  /// Example: `'the lord's prayer'.toTitleCase()` → `'The Lord\'s Prayer'`
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ')
        .map((word) => word.isEmpty ? word : word.capitalize())
        .join(' ');
  }

  /// Returns the string in Sentence case (first word capitalised).
  String toSentenceCase() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  // ── Truncation ────────────────────────────────────────────────────────────

  /// Returns the string truncated to [maxLength] characters.
  ///
  /// Appends [ellipsis] (default `'…'`) when truncated.
  String truncate(int maxLength, {String ellipsis = '…'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// Truncates to [maxWords] words.
  String truncateWords(int maxWords, {String ellipsis = '…'}) {
    final words = split(' ');
    if (words.length <= maxWords) return this;
    return '${words.take(maxWords).join(' ')}$ellipsis';
  }

  // ── Validation ────────────────────────────────────────────────────────────

  /// Returns true if the string is a valid email address.
  bool get isValidEmail {
    final regex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+'
      r'@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?'
      r'(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*\.'
      r'[a-zA-Z]{2,}$',
    );
    return regex.hasMatch(trim());
  }

  /// Returns true if the string is not empty after trimming.
  bool get isNotBlank => trim().isNotEmpty;

  /// Returns true if the string is empty after trimming.
  bool get isBlank => trim().isEmpty;

  /// Returns true if the string is a valid URL (http or https).
  bool get isValidUrl {
    final uri = Uri.tryParse(this);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  /// Returns true if the string consists only of digits.
  bool get isNumeric => RegExp(r'^\d+$').hasMatch(this);

  // ── Formatting ────────────────────────────────────────────────────────────

  /// Removes all HTML tags from the string.
  String stripHtml() => replaceAll(RegExp(r'<[^>]*>'), '');

  /// Removes extra whitespace (multiple spaces, leading/trailing).
  String normaliseWhitespace() =>
      trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Returns a URL-safe slug (lowercase, hyphens for spaces, stripped punctuation).
  String toSlug() => toLowerCase()
      .replaceAll(RegExp(r"['\u2019]"), '') // remove apostrophes
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), '-');

  /// Wraps the string in single quotes.
  String get quoted => "'$this'";

  // ── Parsing helpers ───────────────────────────────────────────────────────

  /// Tries to parse the string as an [int], returning null on failure.
  int? toIntOrNull() => int.tryParse(trim());

  /// Tries to parse the string as a [double], returning null on failure.
  double? toDoubleOrNull() => double.tryParse(trim());

  /// Tries to parse the string as a [DateTime], returning null on failure.
  DateTime? toDateTimeOrNull() => DateTime.tryParse(trim());

  // ── Catholic / game specific ──────────────────────────────────────────────

  /// Returns the ordinal suffix for a number string (e.g. '1' → 'st').
  String get ordinalSuffix {
    final n = toIntOrNull();
    if (n == null) return '';
    if (n % 100 >= 11 && n % 100 <= 13) return 'th';
    switch (n % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  /// Returns the string with its ordinal suffix appended.
  ///
  /// Example: `'1'.withOrdinal()` → `'1st'`
  String withOrdinal() => '$this${ordinalSuffix}';
}

/// Nullable string extensions.
extension NullableStringExtension on String? {
  /// Returns the string, or [fallback] if null or empty.
  String orDefault(String fallback) {
    final val = this;
    if (val == null || val.isEmpty) return fallback;
    return val;
  }

  /// Returns true if the string is null or blank.
  bool get isNullOrBlank {
    final val = this;
    return val == null || val.trim().isEmpty;
  }
}
