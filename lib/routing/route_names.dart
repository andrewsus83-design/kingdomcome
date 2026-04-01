/// Kingdom Come — All route path constants.
///
/// Use these constants everywhere routes are referenced to prevent typo bugs.
/// Parameterised segments use `:paramName` convention (GoRouter style).
abstract final class RouteNames {
  // ── Root ──────────────────────────────────────────────────────────────────

  static const String root = '/';

  // ── Auth ──────────────────────────────────────────────────────────────────

  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';
  static const String ageSetup = '/age-setup';
  static const String parentalConsent = '/parental-consent';
  static const String parentalConsentVerify =
      '/parental-consent/verify/:token';

  // ── Shell / Tab navigation ────────────────────────────────────────────────

  /// The Ark tab (tab 0) — Duolingo-style Bible journey
  static const String ark = '/ark';

  /// The Kingdom tab (tab 1) — hero, center tab
  static const String kingdom = '/kingdom';

  /// The Academy tab (tab 2) — games, trivia, puzzles
  static const String academy = '/academy';

  /// The Workshop tab (tab 3) — arts & crafts
  static const String workshop = '/workshop';

  /// My Soul tab (tab 4) — prayer, grace stats, settings
  static const String soul = '/soul';

  // ── Legacy tab aliases (kept for backwards compatibility in guards) ────────

  /// @deprecated Use [ark] or [kingdom].
  static const String quests = '/quests';

  /// @deprecated Use [soul].
  static const String prayer = '/prayer';

  /// @deprecated Use [academy] or [workshop].
  static const String learn = '/learn';

  /// @deprecated Use [soul].
  static const String profile = '/profile';

  // ── Ark sub-routes ────────────────────────────────────────────────────────

  /// Bible journey node detail (bottom sheet / full screen).
  static const String arkNodeDetail = '/ark/node/:nodeId';

  /// Story viewer for HeyGen video or Suno audio stories.
  static const String arkStoryViewer = '/ark/story/:nodeId';

  /// Daily Bread — daily verse experience.
  static const String dailyBread = '/ark/daily-bread';

  /// Interactive karaoke-style Bible reading.
  static const String interactiveReading = '/ark/reading/:nodeId';

  // ── Kingdom sub-routes ────────────────────────────────────────────────────

  static const String kingdomBuildMenu = '/kingdom/build';
  static const String buildingDetail = '/kingdom/building/:buildingId';
  static const String buildingUpgrade =
      '/kingdom/building/:buildingId/upgrade';
  static const String blueprintMode = '/kingdom/blueprints';
  static const String saintChatKingdom = '/kingdom/saint/:saintId/chat';

  // ── Academy sub-routes ────────────────────────────────────────────────────

  static const String academyTrivia = '/academy/trivia';
  static const String academyPuzzleRooms = '/academy/puzzles';
  static const String academyLeaderboard = '/academy/leaderboard';
  static const String academyGameDetail = '/academy/game/:gameId';

  // ── Workshop sub-routes ───────────────────────────────────────────────────

  static const String workshopScanner = '/workshop/scanner';
  static const String workshopStainedGlass = '/workshop/stained-glass';
  static const String workshopManuscript = '/workshop/manuscript';
  static const String workshopBanner = '/workshop/banner';
  static const String workshopGallery = '/workshop/gallery';
  static const String workshopPrintables = '/workshop/printables';

  // ── Soul sub-routes ───────────────────────────────────────────────────────

  static const String prayerChat = '/soul/prayer-chat';
  static const String graceStats = '/soul/grace-stats';
  static const String parentGate = '/soul/parent-gate';
  static const String settings = '/soul/settings';
  static const String notificationSettings = '/soul/settings/notifications';
  static const String themeSettings = '/soul/settings/theme';
  static const String privacySettings = '/soul/settings/privacy';
  static const String parentDashboard = '/soul/parent-dashboard';
  static const String parentActivityReport = '/soul/parent-dashboard/report';
  static const String about = '/soul/about';
  static const String signOutConfirm = '/soul/sign-out';

  // ── Legacy sub-routes (kept so existing code compiles) ────────────────────

  static const String kingdomLeaderboard = '/kingdom/leaderboard';
  static const String kingdomInventory = '/kingdom/inventory';
  static const String questDetail = '/quests/:questId';
  static const String questActive = '/quests/active';
  static const String questComplete = '/quests/:questId/complete';
  static const String questHistory = '/quests/history';
  static const String prayerDetail = '/prayer/:prayerId';
  static const String rosary = '/prayer/rosary';
  static const String divineOffice = '/prayer/divine-office';
  static const String examen = '/prayer/examen';
  static const String stationsOfCross = '/prayer/stations';
  static const String prayerJournal = '/prayer/journal';
  static const String saintsList = '/learn/saints';
  static const String saintDetail = '/learn/saints/:saintId';
  static const String saintStory = '/learn/saints/:saintId/story';
  static const String saintArt = '/learn/saints/:saintId/art';
  static const String catechismList = '/learn/catechism';
  static const String catechismTopic = '/learn/catechism/:topicId';
  static const String bibleExplorer = '/learn/bible';
  static const String bibleBook = '/learn/bible/:bookId';
  static const String aiChat = '/soul/prayer-chat';
  static const String liturgicalCalendar = '/learn/calendar';
  static const String worldAnvilWiki = '/learn/wiki';
  static const String worldAnvilArticle = '/learn/wiki/:articleId';
  static const String craftCanvas = '/workshop/manuscript';
  static const String craftGallery = '/workshop/gallery';
  static const String profileEdit = '/soul/profile-edit';
  static const String saintPatrons = '/soul/patrons';
  static const String saintPatronSelect = '/soul/patrons/select';
  static const String achievements = '/soul/achievements';
  static const String achievementDetail = '/soul/achievements/:achievementId';

  // ── Error / misc ──────────────────────────────────────────────────────────

  static const String notFound = '/404';
  static const String error = '/error';

  // ── Helper: param extraction ──────────────────────────────────────────────

  static String arkNodeDetailPath(String nodeId) => '/ark/node/$nodeId';
  static String arkStoryViewerPath(String nodeId) => '/ark/story/$nodeId';
  static String interactiveReadingPath(String nodeId) =>
      '/ark/reading/$nodeId';

  static String buildingDetailPath(String buildingId) =>
      '/kingdom/building/$buildingId';
  static String buildingUpgradePath(String buildingId) =>
      '/kingdom/building/$buildingId/upgrade';
  static String saintChatKingdomPath(String saintId) =>
      '/kingdom/saint/$saintId/chat';
  static String academyGameDetailPath(String gameId) =>
      '/academy/game/$gameId';

  static String questDetailPath(String questId) => '/quests/$questId';
  static String questCompletePath(String questId) =>
      '/quests/$questId/complete';
  static String prayerDetailPath(String prayerId) => '/prayer/$prayerId';
  static String saintDetailPath(String saintId) => '/learn/saints/$saintId';
  static String saintStoryPath(String saintId) =>
      '/learn/saints/$saintId/story';
  static String saintArtPath(String saintId) => '/learn/saints/$saintId/art';
  static String catechismTopicPath(String topicId) =>
      '/learn/catechism/$topicId';
  static String bibleBookPath(String bookId) => '/learn/bible/$bookId';
  static String worldAnvilArticlePath(String articleId) =>
      '/learn/wiki/$articleId';
  static String achievementDetailPath(String achievementId) =>
      '/soul/achievements/$achievementId';
  static String parentalConsentVerifyPath(String token) =>
      '/parental-consent/verify/$token';
}
