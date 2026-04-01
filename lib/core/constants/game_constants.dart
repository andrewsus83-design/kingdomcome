import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data classes
// ─────────────────────────────────────────────────────────────────────────────

/// Cost to construct or upgrade a building to the next level.
final class BuildingCost extends Equatable {
  const BuildingCost({
    required this.holyPoints,
    required this.faithCoins,
    required this.grace,
  });

  final int holyPoints;
  final int faithCoins;
  final int grace;

  @override
  List<Object?> get props => [holyPoints, faithCoins, grace];

  @override
  String toString() =>
      'BuildingCost(hp:$holyPoints, fc:$faithCoins, gr:$grace)';
}

/// Resource reward granted upon completing an action.
final class ResourceReward extends Equatable {
  const ResourceReward({
    required this.holyPoints,
    required this.faithCoins,
    required this.grace,
    required this.blessings,
    this.xp = 0,
  });

  final int holyPoints;
  final int faithCoins;
  final int grace;
  final int blessings;
  final int xp;

  @override
  List<Object?> get props => [holyPoints, faithCoins, grace, blessings, xp];

  ResourceReward operator *(double multiplier) => ResourceReward(
        holyPoints: (holyPoints * multiplier).round(),
        faithCoins: (faithCoins * multiplier).round(),
        grace: (grace * multiplier).round(),
        blessings: (blessings * multiplier).round(),
        xp: (xp * multiplier).round(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Building types
// ─────────────────────────────────────────────────────────────────────────────

/// All 10 building type identifiers used as map keys.
abstract final class BuildingType {
  static const String cathedral = 'cathedral';
  static const String monastery = 'monastery';
  static const String library = 'library';
  static const String chapel = 'chapel';
  static const String garden = 'garden';
  static const String scriptorium = 'scriptorium';
  static const String almsHouse = 'alms_house';
  static const String belltower = 'belltower';
  static const String fountain = 'fountain';
  static const String pilgrimageRoute = 'pilgrimage_route';

  static const List<String> all = [
    cathedral,
    monastery,
    library,
    chapel,
    garden,
    scriptorium,
    almsHouse,
    belltower,
    fountain,
    pilgrimageRoute,
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Building costs — [buildingType][level 1-5]
// ─────────────────────────────────────────────────────────────────────────────

/// Maps each building type to a 5-element list of [BuildingCost].
///
/// Index 0 = Level 1 construction cost.
/// Index 4 = Level 5 upgrade cost.
const Map<String, List<BuildingCost>> kBuildingCosts = {
  BuildingType.cathedral: [
    BuildingCost(holyPoints: 0, faithCoins: 100, grace: 20),      // L1
    BuildingCost(holyPoints: 50, faithCoins: 250, grace: 50),     // L2
    BuildingCost(holyPoints: 150, faithCoins: 500, grace: 100),   // L3
    BuildingCost(holyPoints: 350, faithCoins: 900, grace: 200),   // L4
    BuildingCost(holyPoints: 700, faithCoins: 1600, grace: 400),  // L5
  ],
  BuildingType.monastery: [
    BuildingCost(holyPoints: 0, faithCoins: 80, grace: 15),
    BuildingCost(holyPoints: 40, faithCoins: 200, grace: 40),
    BuildingCost(holyPoints: 120, faithCoins: 420, grace: 80),
    BuildingCost(holyPoints: 280, faithCoins: 750, grace: 160),
    BuildingCost(holyPoints: 560, faithCoins: 1350, grace: 320),
  ],
  BuildingType.library: [
    BuildingCost(holyPoints: 0, faithCoins: 60, grace: 10),
    BuildingCost(holyPoints: 30, faithCoins: 150, grace: 30),
    BuildingCost(holyPoints: 90, faithCoins: 320, grace: 60),
    BuildingCost(holyPoints: 210, faithCoins: 580, grace: 120),
    BuildingCost(holyPoints: 420, faithCoins: 1050, grace: 240),
  ],
  BuildingType.chapel: [
    BuildingCost(holyPoints: 0, faithCoins: 40, grace: 8),
    BuildingCost(holyPoints: 20, faithCoins: 100, grace: 20),
    BuildingCost(holyPoints: 60, faithCoins: 220, grace: 40),
    BuildingCost(holyPoints: 140, faithCoins: 400, grace: 80),
    BuildingCost(holyPoints: 280, faithCoins: 720, grace: 160),
  ],
  BuildingType.garden: [
    BuildingCost(holyPoints: 0, faithCoins: 30, grace: 5),
    BuildingCost(holyPoints: 15, faithCoins: 75, grace: 15),
    BuildingCost(holyPoints: 45, faithCoins: 160, grace: 30),
    BuildingCost(holyPoints: 105, faithCoins: 290, grace: 60),
    BuildingCost(holyPoints: 210, faithCoins: 520, grace: 120),
  ],
  BuildingType.scriptorium: [
    BuildingCost(holyPoints: 0, faithCoins: 70, grace: 12),
    BuildingCost(holyPoints: 35, faithCoins: 175, grace: 35),
    BuildingCost(holyPoints: 105, faithCoins: 375, grace: 70),
    BuildingCost(holyPoints: 245, faithCoins: 675, grace: 140),
    BuildingCost(holyPoints: 490, faithCoins: 1200, grace: 280),
  ],
  BuildingType.almsHouse: [
    BuildingCost(holyPoints: 0, faithCoins: 50, grace: 10),
    BuildingCost(holyPoints: 25, faithCoins: 125, grace: 25),
    BuildingCost(holyPoints: 75, faithCoins: 270, grace: 50),
    BuildingCost(holyPoints: 175, faithCoins: 490, grace: 100),
    BuildingCost(holyPoints: 350, faithCoins: 880, grace: 200),
  ],
  BuildingType.belltower: [
    BuildingCost(holyPoints: 0, faithCoins: 45, grace: 8),
    BuildingCost(holyPoints: 22, faithCoins: 112, grace: 22),
    BuildingCost(holyPoints: 66, faithCoins: 240, grace: 44),
    BuildingCost(holyPoints: 154, faithCoins: 432, grace: 88),
    BuildingCost(holyPoints: 308, faithCoins: 776, grace: 176),
  ],
  BuildingType.fountain: [
    BuildingCost(holyPoints: 0, faithCoins: 35, grace: 6),
    BuildingCost(holyPoints: 18, faithCoins: 88, grace: 18),
    BuildingCost(holyPoints: 54, faithCoins: 188, grace: 36),
    BuildingCost(holyPoints: 126, faithCoins: 338, grace: 72),
    BuildingCost(holyPoints: 252, faithCoins: 608, grace: 144),
  ],
  BuildingType.pilgrimageRoute: [
    BuildingCost(holyPoints: 0, faithCoins: 120, grace: 25),
    BuildingCost(holyPoints: 60, faithCoins: 300, grace: 60),
    BuildingCost(holyPoints: 180, faithCoins: 640, grace: 120),
    BuildingCost(holyPoints: 420, faithCoins: 1150, grace: 240),
    BuildingCost(holyPoints: 840, faithCoins: 2060, grace: 480),
  ],
};

// ─────────────────────────────────────────────────────────────────────────────
// Quest categories
// ─────────────────────────────────────────────────────────────────────────────

abstract final class QuestCategory {
  static const String dailyPrayer = 'daily_prayer';
  static const String scripture = 'scripture';
  static const String sacraments = 'sacraments';
  static const String corporal = 'corporal_works';
  static const String spiritual = 'spiritual_works';
  static const String trivia = 'trivia';
  static const String craft = 'craft';
  static const String pilgrimage = 'pilgrimage';
  static const String liturgicalSeason = 'liturgical_season';
  static const String heroicVirtue = 'heroic_virtue';
}

// ─────────────────────────────────────────────────────────────────────────────
// Quest rewards — per category and difficulty tier (easy / medium / hard)
// ─────────────────────────────────────────────────────────────────────────────

const Map<String, Map<String, ResourceReward>> kQuestRewards = {
  QuestCategory.dailyPrayer: {
    'easy': ResourceReward(
        holyPoints: 10, faithCoins: 5, grace: 2, blessings: 1, xp: 20),
    'medium': ResourceReward(
        holyPoints: 20, faithCoins: 10, grace: 4, blessings: 2, xp: 40),
    'hard': ResourceReward(
        holyPoints: 40, faithCoins: 20, grace: 8, blessings: 4, xp: 80),
  },
  QuestCategory.scripture: {
    'easy': ResourceReward(
        holyPoints: 15, faithCoins: 8, grace: 3, blessings: 1, xp: 25),
    'medium': ResourceReward(
        holyPoints: 30, faithCoins: 15, grace: 6, blessings: 3, xp: 50),
    'hard': ResourceReward(
        holyPoints: 60, faithCoins: 30, grace: 12, blessings: 6, xp: 100),
  },
  QuestCategory.sacraments: {
    'easy': ResourceReward(
        holyPoints: 20, faithCoins: 10, grace: 5, blessings: 2, xp: 30),
    'medium': ResourceReward(
        holyPoints: 40, faithCoins: 20, grace: 10, blessings: 4, xp: 60),
    'hard': ResourceReward(
        holyPoints: 80, faithCoins: 40, grace: 20, blessings: 8, xp: 120),
  },
  QuestCategory.corporal: {
    'easy': ResourceReward(
        holyPoints: 12, faithCoins: 6, grace: 3, blessings: 2, xp: 22),
    'medium': ResourceReward(
        holyPoints: 25, faithCoins: 12, grace: 6, blessings: 4, xp: 45),
    'hard': ResourceReward(
        holyPoints: 50, faithCoins: 25, grace: 12, blessings: 8, xp: 90),
  },
  QuestCategory.spiritual: {
    'easy': ResourceReward(
        holyPoints: 12, faithCoins: 6, grace: 3, blessings: 2, xp: 22),
    'medium': ResourceReward(
        holyPoints: 25, faithCoins: 12, grace: 6, blessings: 4, xp: 45),
    'hard': ResourceReward(
        holyPoints: 50, faithCoins: 25, grace: 12, blessings: 8, xp: 90),
  },
  QuestCategory.trivia: {
    'easy': ResourceReward(
        holyPoints: 8, faithCoins: 4, grace: 1, blessings: 1, xp: 15),
    'medium': ResourceReward(
        holyPoints: 18, faithCoins: 9, grace: 3, blessings: 2, xp: 30),
    'hard': ResourceReward(
        holyPoints: 35, faithCoins: 18, grace: 6, blessings: 4, xp: 65),
  },
  QuestCategory.craft: {
    'easy': ResourceReward(
        holyPoints: 10, faithCoins: 5, grace: 2, blessings: 2, xp: 20),
    'medium': ResourceReward(
        holyPoints: 22, faithCoins: 11, grace: 5, blessings: 4, xp: 42),
    'hard': ResourceReward(
        holyPoints: 45, faithCoins: 22, grace: 10, blessings: 8, xp: 85),
  },
  QuestCategory.pilgrimage: {
    'easy': ResourceReward(
        holyPoints: 25, faithCoins: 12, grace: 5, blessings: 3, xp: 40),
    'medium': ResourceReward(
        holyPoints: 55, faithCoins: 28, grace: 12, blessings: 7, xp: 85),
    'hard': ResourceReward(
        holyPoints: 110, faithCoins: 55, grace: 25, blessings: 15, xp: 175),
  },
  QuestCategory.liturgicalSeason: {
    'easy': ResourceReward(
        holyPoints: 15, faithCoins: 8, grace: 4, blessings: 3, xp: 28),
    'medium': ResourceReward(
        holyPoints: 35, faithCoins: 18, grace: 8, blessings: 6, xp: 60),
    'hard': ResourceReward(
        holyPoints: 70, faithCoins: 35, grace: 15, blessings: 12, xp: 120),
  },
  QuestCategory.heroicVirtue: {
    'easy': ResourceReward(
        holyPoints: 30, faithCoins: 15, grace: 8, blessings: 5, xp: 50),
    'medium': ResourceReward(
        holyPoints: 65, faithCoins: 32, grace: 16, blessings: 10, xp: 110),
    'hard': ResourceReward(
        holyPoints: 130, faithCoins: 65, grace: 32, blessings: 20, xp: 220),
  },
};

// ─────────────────────────────────────────────────────────────────────────────
// Level thresholds — XP required to REACH each level (cumulative)
// ─────────────────────────────────────────────────────────────────────────────

/// [kLevelThresholds[n]] is the cumulative XP required to be AT level n.
///
/// Level 1 starts at 0 XP. 100 levels total.
/// Formula: XP(n) = 100 * n^1.6  (rounded), with a floor for early levels.
const List<int> kLevelThresholds = [
  0,      // Level 1  — starting level
  100,    // Level 2
  232,    // Level 3
  396,    // Level 4
  586,    // Level 5
  800,    // Level 6
  1035,   // Level 7
  1289,   // Level 8
  1561,   // Level 9
  1848,   // Level 10
  2151,   // Level 11
  2469,   // Level 12
  2801,   // Level 13
  3148,   // Level 14
  3508,   // Level 15
  3881,   // Level 16
  4267,   // Level 17
  4666,   // Level 18
  5077,   // Level 19
  5500,   // Level 20
  5935,   // Level 21
  6381,   // Level 22
  6839,   // Level 23
  7307,   // Level 24
  7787,   // Level 25
  8277,   // Level 26
  8778,   // Level 27
  9289,   // Level 28
  9810,   // Level 29
  10341,  // Level 30
  10882,  // Level 31
  11433,  // Level 32
  11993,  // Level 33
  12563,  // Level 34
  13143,  // Level 35
  13732,  // Level 36
  14330,  // Level 37
  14937,  // Level 38
  15554,  // Level 39
  16180,  // Level 40
  16815,  // Level 41
  17459,  // Level 42
  18112,  // Level 43
  18773,  // Level 44
  19443,  // Level 45
  20122,  // Level 46
  20809,  // Level 47
  21505,  // Level 48
  22209,  // Level 49
  22922,  // Level 50
  23643,  // Level 51
  24373,  // Level 52
  25111,  // Level 53
  25856,  // Level 54
  26610,  // Level 55
  27372,  // Level 56
  28142,  // Level 57
  28920,  // Level 58
  29706,  // Level 59
  30500,  // Level 60
  31302,  // Level 61
  32112,  // Level 62
  32930,  // Level 63
  33756,  // Level 64
  34589,  // Level 65
  35430,  // Level 66
  36279,  // Level 67
  37136,  // Level 68
  38000,  // Level 69
  38872,  // Level 70
  39751,  // Level 71
  40638,  // Level 72
  41532,  // Level 73
  42434,  // Level 74
  43343,  // Level 75
  44260,  // Level 76
  45184,  // Level 77
  46115,  // Level 78
  47054,  // Level 79
  48000,  // Level 80
  48953,  // Level 81
  49913,  // Level 82
  50880,  // Level 83
  51854,  // Level 84
  52836,  // Level 85
  53824,  // Level 86
  54820,  // Level 87
  55822,  // Level 88
  56831,  // Level 89
  57848,  // Level 90
  58871,  // Level 91
  59901,  // Level 92
  60938,  // Level 93
  61982,  // Level 94
  63033,  // Level 95
  64090,  // Level 96
  65154,  // Level 97
  66225,  // Level 98
  67302,  // Level 99
  68387,  // Level 100
];

// ─────────────────────────────────────────────────────────────────────────────
// Building unlock levels — player level required to unlock each building type
// ─────────────────────────────────────────────────────────────────────────────

/// Maps building type → minimum player level required to begin construction.
const Map<String, int> kBuildingUnlockLevels = {
  BuildingType.chapel: 1,            // Available from the start
  BuildingType.garden: 2,            // Unlocked very early
  BuildingType.fountain: 3,
  BuildingType.belltower: 5,
  BuildingType.almsHouse: 7,
  BuildingType.library: 10,
  BuildingType.scriptorium: 13,
  BuildingType.monastery: 17,
  BuildingType.cathedral: 22,
  BuildingType.pilgrimageRoute: 30,  // Late-game prestige building
};

// ─────────────────────────────────────────────────────────────────────────────
// Miscellaneous game-wide constants
// ─────────────────────────────────────────────────────────────────────────────

abstract final class GameConstants {
  /// Maximum player level.
  static const int maxLevel = 100;

  /// Daily login streak bonus multiplier at 7 days.
  static const double streakBonusWeek = 1.25;

  /// Daily login streak bonus multiplier at 30 days.
  static const double streakBonusMonth = 1.5;

  /// Daily login streak bonus multiplier at 100 days.
  static const double streakBonusCentenary = 2.0;

  /// Maximum number of active quests a player can hold simultaneously.
  static const int maxActiveQuests = 5;

  /// Maximum number of saints a player can have as patrons.
  static const int maxPatronSaints = 3;

  /// Daily prayer reminder default hour (7 AM).
  static const int defaultPrayerHour = 7;

  /// Daily prayer reminder default minute.
  static const int defaultPrayerMinute = 0;

  /// Construction complete notification advance notice (minutes).
  static const int constructionNotifyMinutesBefore = 5;

  /// Base construction time per level (seconds). Multiply by level number.
  static const int baseConstructionTimeSeconds = 3600; // 1 hour per level

  /// AI chat message rate limit — messages per day for each age group.
  static const Map<int, int> chatDailyLimit = {
    1: 15, // Ages 8–11
    2: 25, // Ages 12–15
    3: 40, // Ages 16–18
  };
}
