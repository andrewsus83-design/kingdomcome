/// Age-group helper for Kingdom Come.
///
/// The app supports three age groups:
///   Group 1 — Junior Knights (ages 8–11)
///   Group 2 — Squires      (ages 12–15)
///   Group 3 — Crusaders    (ages 16–18)
///
/// Content gating is layered — group 3 sees everything, group 1 sees the
/// most restricted content. All ages require parental consent to access
/// AI chat features.
abstract final class AgeGroupHelper {
  // ── Constants ─────────────────────────────────────────────────────────────

  static const int minAge = 8;
  static const int maxAge = 18;

  static const int group1Min = 8;
  static const int group1Max = 11;
  static const int group1Id = 1;

  static const int group2Min = 12;
  static const int group2Max = 15;
  static const int group2Id = 2;

  static const int group3Min = 16;
  static const int group3Max = 18;
  static const int group3Id = 3;

  // ── Group names ───────────────────────────────────────────────────────────

  static const Map<int, String> groupNames = {
    group1Id: 'Junior Knight',
    group2Id: 'Squire',
    group3Id: 'Crusader',
  };

  static const Map<int, String> groupAgeRangeLabels = {
    group1Id: 'Ages 8–11',
    group2Id: 'Ages 12–15',
    group3Id: 'Ages 16–18',
  };

  // ── Group resolution ──────────────────────────────────────────────────────

  /// Returns the group ID (1, 2, or 3) for the given [age].
  ///
  /// Returns -1 if [age] is outside the supported range.
  static int groupIdForAge(int age) {
    if (age >= group1Min && age <= group1Max) return group1Id;
    if (age >= group2Min && age <= group2Max) return group2Id;
    if (age >= group3Min && age <= group3Max) return group3Id;
    return -1; // Out of range — should be caught during onboarding
  }

  /// Returns true if [age] is within the supported range [8, 18].
  static bool isAgeSupported(int age) =>
      age >= minAge && age <= maxAge;

  /// Returns the display name for [groupId].
  static String groupName(int groupId) =>
      groupNames[groupId] ?? 'Unknown';

  /// Returns the age-range label string for [groupId].
  static String ageRangeLabel(int groupId) =>
      groupAgeRangeLabels[groupId] ?? '';

  // ── Content gating ────────────────────────────────────────────────────────

  /// Returns true if the player's [groupId] is allowed to access AI chat.
  ///
  /// All groups require parental consent. Additional [hasParentalConsent]
  /// flag must be checked separately.
  static bool canAccessAiChat(int groupId) => groupId >= group1Id;

  /// Returns true if group can access advanced theological content.
  ///
  /// Group 3 (16–18) unlocks deeper theological reading, Church history,
  /// and nuanced moral theology discussions.
  static bool canAccessAdvancedTheology(int groupId) =>
      groupId >= group3Id;

  /// Returns true if group can participate in saint-story videos.
  static bool canAccessStoryVideos(int groupId) => groupId >= group1Id;

  /// Returns true if the group can create / share community content.
  ///
  /// Requires group 2+ and parental consent for group 2.
  static bool canCreateCommunityContent(int groupId) =>
      groupId >= group2Id;

  /// Returns true if group can see mature saint martyrdom narratives
  /// (e.g. detailed descriptions of persecution). Reserved for group 3.
  static bool canSeeMartyrdomDetail(int groupId) =>
      groupId >= group3Id;

  /// Returns the daily AI chat message limit for [groupId].
  static int dailyChatLimit(int groupId) {
    switch (groupId) {
      case group1Id:
        return 15;
      case group2Id:
        return 25;
      case group3Id:
        return 40;
      default:
        return 0;
    }
  }

  /// Returns the reading-level descriptor used when prompting the AI.
  ///
  /// Passed as part of the system prompt so AI calibrates language complexity.
  static String readingLevelDescriptor(int groupId) {
    switch (groupId) {
      case group1Id:
        return 'simple language suitable for a child aged 8–11, '
            'use short sentences and friendly tone';
      case group2Id:
        return 'clear language suitable for a young teenager aged 12–15, '
            'explain concepts but avoid overly academic jargon';
      case group3Id:
        return 'thoughtful language appropriate for a teenager aged 16–18, '
            'engage with theological nuance and encourage critical thinking';
      default:
        return 'clear and age-appropriate language';
    }
  }

  /// Returns the maximum quest difficulty tier accessible to [groupId].
  ///
  /// Group 1: easy only.
  /// Group 2: easy + medium.
  /// Group 3: all tiers including hard.
  static String maxQuestDifficulty(int groupId) {
    switch (groupId) {
      case group1Id:
        return 'easy';
      case group2Id:
        return 'medium';
      case group3Id:
        return 'hard';
      default:
        return 'easy';
    }
  }

  /// Returns true if [difficulty] is accessible for [groupId].
  static bool canAccessDifficulty(int groupId, String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return true;
      case 'medium':
        return groupId >= group2Id;
      case 'hard':
        return groupId >= group3Id;
      default:
        return false;
    }
  }
}
