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

  /// Kingdom Map tab (tab 1)
  static const String kingdom = '/kingdom';

  /// Quests tab (tab 2)
  static const String quests = '/quests';

  /// Prayer tab (tab 3)
  static const String prayer = '/prayer';

  /// Learn tab (tab 4)
  static const String learn = '/learn';

  /// Profile tab (tab 5)
  static const String profile = '/profile';

  // ── Kingdom Map sub-routes ────────────────────────────────────────────────

  static const String buildingDetail = '/kingdom/building/:buildingId';
  static const String buildingUpgrade =
      '/kingdom/building/:buildingId/upgrade';
  static const String kingdomLeaderboard = '/kingdom/leaderboard';
  static const String kingdomInventory = '/kingdom/inventory';

  // ── Quests sub-routes ─────────────────────────────────────────────────────

  static const String questDetail = '/quests/:questId';
  static const String questActive = '/quests/active';
  static const String questComplete = '/quests/:questId/complete';
  static const String questHistory = '/quests/history';

  // ── Prayer sub-routes ─────────────────────────────────────────────────────

  static const String prayerDetail = '/prayer/:prayerId';
  static const String rosary = '/prayer/rosary';
  static const String divineOffice = '/prayer/divine-office';
  static const String examen = '/prayer/examen';
  static const String stationsOfCross = '/prayer/stations';
  static const String prayerJournal = '/prayer/journal';

  // ── Learn sub-routes ──────────────────────────────────────────────────────

  static const String saintsList = '/learn/saints';
  static const String saintDetail = '/learn/saints/:saintId';
  static const String saintStory = '/learn/saints/:saintId/story';
  static const String saintArt = '/learn/saints/:saintId/art';
  static const String catechismList = '/learn/catechism';
  static const String catechismTopic = '/learn/catechism/:topicId';
  static const String bibleExplorer = '/learn/bible';
  static const String bibleBook = '/learn/bible/:bookId';
  static const String aiChat = '/learn/chat';
  static const String liturgicalCalendar = '/learn/calendar';
  static const String worldAnvilWiki = '/learn/wiki';
  static const String worldAnvilArticle = '/learn/wiki/:articleId';
  static const String craftCanvas = '/learn/craft';
  static const String craftGallery = '/learn/craft/gallery';

  // ── Profile sub-routes ────────────────────────────────────────────────────

  static const String profileEdit = '/profile/edit';
  static const String saintPatrons = '/profile/patrons';
  static const String saintPatronSelect = '/profile/patrons/select';
  static const String achievements = '/profile/achievements';
  static const String achievementDetail =
      '/profile/achievements/:achievementId';
  static const String settings = '/profile/settings';
  static const String notificationSettings = '/profile/settings/notifications';
  static const String themeSettings = '/profile/settings/theme';
  static const String privacySettings = '/profile/settings/privacy';
  static const String parentDashboard = '/profile/parent-dashboard';
  static const String parentActivityReport =
      '/profile/parent-dashboard/report';
  static const String about = '/profile/about';
  static const String signOutConfirm = '/profile/sign-out';

  // ── Error / misc ──────────────────────────────────────────────────────────

  static const String notFound = '/404';
  static const String error = '/error';

  // ── Helper: param extraction ──────────────────────────────────────────────

  /// Returns the full [buildingDetail] path with the [buildingId] filled in.
  static String buildingDetailPath(String buildingId) =>
      '/kingdom/building/$buildingId';

  /// Returns the full [buildingUpgrade] path with the [buildingId] filled in.
  static String buildingUpgradePath(String buildingId) =>
      '/kingdom/building/$buildingId/upgrade';

  /// Returns the full [questDetail] path with the [questId] filled in.
  static String questDetailPath(String questId) => '/quests/$questId';

  /// Returns the full [questComplete] path with the [questId] filled in.
  static String questCompletePath(String questId) =>
      '/quests/$questId/complete';

  /// Returns the full [prayerDetail] path with the [prayerId] filled in.
  static String prayerDetailPath(String prayerId) => '/prayer/$prayerId';

  /// Returns the full [saintDetail] path with the [saintId] filled in.
  static String saintDetailPath(String saintId) =>
      '/learn/saints/$saintId';

  /// Returns the full [saintStory] path with the [saintId] filled in.
  static String saintStoryPath(String saintId) =>
      '/learn/saints/$saintId/story';

  /// Returns the full [saintArt] path with the [saintId] filled in.
  static String saintArtPath(String saintId) =>
      '/learn/saints/$saintId/art';

  /// Returns the full [catechismTopic] path with the [topicId] filled in.
  static String catechismTopicPath(String topicId) =>
      '/learn/catechism/$topicId';

  /// Returns the full [bibleBook] path with the [bookId] filled in.
  static String bibleBookPath(String bookId) => '/learn/bible/$bookId';

  /// Returns the full [worldAnvilArticle] path with the [articleId] filled in.
  static String worldAnvilArticlePath(String articleId) =>
      '/learn/wiki/$articleId';

  /// Returns the full [achievementDetail] path with the [achievementId] filled.
  static String achievementDetailPath(String achievementId) =>
      '/profile/achievements/$achievementId';

  /// Returns the full [parentalConsentVerify] path with [token] filled in.
  static String parentalConsentVerifyPath(String token) =>
      '/parental-consent/verify/$token';
}
