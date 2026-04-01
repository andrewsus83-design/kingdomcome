/// Content filter for AI chat responses in Kingdom Come.
///
/// All AI responses pass through this filter before being displayed to users.
/// The filter:
///   1. Blocks off-topic, non-Catholic content.
///   2. Detects inappropriate language for children.
///   3. Flags content that requires a higher age group.
///   4. Returns a [ContentFilterResult] with the final display text and
///      a status code so the UI can respond appropriately.
abstract final class ContentFilter {
  // ── Public entry point ────────────────────────────────────────────────────

  /// Filters [rawText] for a player in [ageGroupId].
  ///
  /// Returns a [ContentFilterResult] that either passes the (possibly cleaned)
  /// text through or provides a safe replacement message.
  static ContentFilterResult filter(
    String rawText, {
    required int ageGroupId,
  }) {
    if (rawText.trim().isEmpty) {
      return const ContentFilterResult(
        status: FilterStatus.passed,
        text: '',
      );
    }

    // Check for blocked topics
    final blockedTopic = _detectBlockedTopic(rawText);
    if (blockedTopic != null) {
      return ContentFilterResult(
        status: FilterStatus.blockedOffTopic,
        text: _offTopicReplacement(blockedTopic),
        reason: 'Topic not supported: $blockedTopic',
      );
    }

    // Check for inappropriate language (age-agnostic hard blocks)
    if (_containsInappropriateLanguage(rawText)) {
      return const ContentFilterResult(
        status: FilterStatus.blockedInappropriate,
        text: 'I\'m sorry, I can\'t share that. '
            'Let\'s talk about our faith journey instead!',
        reason: 'Inappropriate language detected',
      );
    }

    // Age-gate advanced content for younger players
    if (ageGroupId == 1 && _containsGroup3OnlyContent(rawText)) {
      return const ContentFilterResult(
        status: FilterStatus.ageGated,
        text: 'That\'s a deep question! Ask a parent, teacher, or priest '
            'to explore this topic with you.',
        reason: 'Content requires age group 3',
      );
    }

    if (ageGroupId <= 2 && _containsMartyrdomDetail(rawText)) {
      // Soften explicit violence for younger groups
      final cleaned = _softenmartyrdomDetail(rawText);
      return ContentFilterResult(
        status: FilterStatus.cleanedPassed,
        text: cleaned,
        reason: 'Martyrdom detail softened for age group $ageGroupId',
      );
    }

    // Check for anti-Catholic content or comparative religion attacks
    if (_containsAntiCatholicBias(rawText)) {
      return const ContentFilterResult(
        status: FilterStatus.blockedInappropriate,
        text: 'Let\'s keep our conversation focused on the beauty '
            'of our Catholic faith. What would you like to learn today?',
        reason: 'Anti-Catholic content detected',
      );
    }

    // Passed all checks
    return ContentFilterResult(
      status: FilterStatus.passed,
      text: _sanitiseText(rawText),
    );
  }

  // ── Blocked topic detection ───────────────────────────────────────────────

  /// Returns the detected blocked topic category, or null if none found.
  static String? _detectBlockedTopic(String text) {
    final lower = text.toLowerCase();

    final blockedKeywords = <String, String>{
      // Violence / harm
      'how to make a bomb': 'violence',
      'how to hurt': 'violence',
      'how to kill': 'violence',

      // Politics (non-Church)
      'vote for': 'politics',
      'political party': 'politics',
      'election results': 'politics',

      // Gambling
      'gambling': 'gambling',
      'casino': 'gambling',
      'betting odds': 'gambling',

      // Adult content
      'pornography': 'adult_content',
      'explicit content': 'adult_content',
      'sexual content': 'adult_content',

      // Occult
      'witchcraft': 'occult',
      'satanism': 'occult',
      'ouija board': 'occult',
      'black magic': 'occult',
      'tarot cards': 'occult',

      // Self-harm
      'how to self-harm': 'self_harm',
      'suicide method': 'self_harm',

      // Drugs
      'drug recipe': 'drugs',
      'how to get high': 'drugs',
    };

    for (final entry in blockedKeywords.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return null;
  }

  /// Returns a safe, faith-redirecting replacement for a blocked topic.
  static String _offTopicReplacement(String topicCategory) {
    switch (topicCategory) {
      case 'violence':
        return 'I\'m here to help you grow in faith and virtue. '
            'Would you like to learn about the courage of the saints?';
      case 'politics':
        return 'Political opinions are best discussed with your family. '
            'I can share how Catholic Social Teaching guides us — '
            'would you like to know more?';
      case 'gambling':
        return 'The Church teaches us to be good stewards of what God '
            'has given us. Let\'s explore that together!';
      case 'adult_content':
        return 'That\'s not something I can help with. '
            'Let\'s talk about our faith journey instead!';
      case 'occult':
        return 'The Church teaches us to avoid the occult and trust only '
            'in God. Would you like to learn a prayer for protection?';
      case 'self_harm':
        return 'If you or someone you know is struggling, please talk to '
            'a trusted adult right away. You are precious to God. '
            'For immediate help, call or text 988 (US).';
      case 'drugs':
        return 'Our bodies are temples of the Holy Spirit (1 Cor 6:19). '
            'Let\'s talk about how to care for them well!';
      default:
        return 'Let\'s keep our conversation focused on faith, '
            'prayer, and growing closer to God. What would you like to explore?';
    }
  }

  // ── Inappropriate language ────────────────────────────────────────────────

  static bool _containsInappropriateLanguage(String text) {
    final lower = text.toLowerCase();
    const patterns = [
      r'\bf[*u]ck',
      r'\bsh[*i]t',
      r'\b[a@]ss\b',
      r'\bb[*i]tch',
      r'\bd[*a]mn\b',
      r'\bhell\b(?!\s+(Mary|fire|bound|bent|hole))', // allow "Hell" in theology
    ];
    for (final pattern in patterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(lower)) return true;
    }
    return false;
  }

  // ── Age-gated content ─────────────────────────────────────────────────────

  static bool _containsGroup3OnlyContent(String text) {
    final lower = text.toLowerCase();
    final advanced = [
      'existentialism',
      'theodicy',
      'concupiscence',
      'magisterial infallibility',
      'hermeneutic of continuity',
      'apophatic theology',
    ];
    return advanced.any(lower.contains);
  }

  static bool _containsMartyrdomDetail(String text) {
    final lower = text.toLowerCase();
    final patterns = [
      'beheaded',
      'tortured',
      'burned alive',
      'crucified upside down',
      'flayed alive',
      'disembowelled',
      'racked',
      'stretched on',
    ];
    return patterns.any(lower.contains);
  }

  /// Replaces graphic martyrdom descriptions with age-appropriate equivalents.
  static String _softenmartyrdomDetail(String text) {
    final replacements = <String, String>{
      'beheaded': 'gave their life for the faith',
      'tortured': 'suffered greatly for Christ',
      'burned alive': 'died courageously for their faith',
      'crucified upside down': 'crucified as a martyr',
      'flayed alive': 'suffered greatly as a martyr',
      'disembowelled': 'died a martyr\'s death',
      'racked': 'endured great suffering',
      'stretched on': 'was made to suffer',
    };
    var result = text;
    for (final entry in replacements.entries) {
      result = result.replaceAll(
        RegExp(entry.key, caseSensitive: false),
        entry.value,
      );
    }
    return result;
  }

  // ── Anti-Catholic bias ────────────────────────────────────────────────────

  static bool _containsAntiCatholicBias(String text) {
    final lower = text.toLowerCase();
    const biasedPhrases = [
      'catholicism is wrong',
      'the pope is evil',
      'catholic church is corrupt',
      'mary worship is idolatry',
      'catholics are not christians',
    ];
    return biasedPhrases.any(lower.contains);
  }

  // ── Text sanitisation ─────────────────────────────────────────────────────

  /// Remove leading/trailing whitespace, collapse excessive blank lines.
  static String _sanitiseText(String text) {
    final lines = text.split('\n');
    final result = StringBuffer();
    var blankCount = 0;
    for (final line in lines) {
      if (line.trim().isEmpty) {
        blankCount++;
        if (blankCount <= 2) result.writeln();
      } else {
        blankCount = 0;
        result.writeln(line);
      }
    }
    return result.toString().trim();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Result types
// ─────────────────────────────────────────────────────────────────────────────

/// Status codes returned by [ContentFilter.filter].
enum FilterStatus {
  /// Content passed all checks unchanged.
  passed,

  /// Content passed after minor cleaning (e.g. martyrdom softening).
  cleanedPassed,

  /// Blocked: topic is off-topic for a Catholic children's app.
  blockedOffTopic,

  /// Blocked: inappropriate language or content for children.
  blockedInappropriate,

  /// Blocked / replaced: content requires a higher age group.
  ageGated,
}

/// Result of running text through [ContentFilter].
final class ContentFilterResult {
  const ContentFilterResult({
    required this.status,
    required this.text,
    this.reason,
  });

  /// The filter decision.
  final FilterStatus status;

  /// The safe text to display (may differ from input if cleaned or replaced).
  final String text;

  /// Optional human-readable reason for logging / debugging.
  final String? reason;

  /// Returns true if the content may be shown to the user as-is.
  bool get isAllowed =>
      status == FilterStatus.passed || status == FilterStatus.cleanedPassed;
}
