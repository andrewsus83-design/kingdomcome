/// Kingdom Come — Centralised asset path constants.
///
/// Every asset reference in the app must go through this class.
/// This prevents typo-induced runtime crashes and makes refactoring easy.
abstract final class AssetPaths {
  // ── Base paths ────────────────────────────────────────────────────────────

  static const String _images = 'assets/images';
  static const String _animations = 'assets/animations';
  static const String _audio = 'assets/audio';
  static const String _data = 'assets/data';

  // ── UI / Brand ────────────────────────────────────────────────────────────

  static const String appLogo = '$_images/ui/app_logo.png';
  static const String appLogoWhite = '$_images/ui/app_logo_white.png';
  static const String splashBackground = '$_images/ui/splash_background.png';
  static const String onboardingBg1 = '$_images/ui/onboarding_bg_1.png';
  static const String onboardingBg2 = '$_images/ui/onboarding_bg_2.png';
  static const String onboardingBg3 = '$_images/ui/onboarding_bg_3.png';
  static const String medievalBorder = '$_images/ui/medieval_border.png';
  static const String parchmentTexture = '$_images/ui/parchment_texture.png';
  static const String stoneBrickTexture = '$_images/ui/stone_brick_texture.png';
  static const String woodPanelTexture = '$_images/ui/wood_panel_texture.png';
  static const String scrollDecoration = '$_images/ui/scroll_decoration.png';
  static const String goldDivider = '$_images/ui/gold_divider.png';
  static const String crownIcon = '$_images/ui/crown_icon.png';
  static const String shieldIcon = '$_images/ui/shield_icon.png';
  static const String crossIcon = '$_images/ui/cross_icon.png';

  // ── Kingdom map / Buildings ───────────────────────────────────────────────

  static const String mapBackground = '$_images/map/kingdom_map_bg.png';
  static const String mapFog = '$_images/map/map_fog.png';

  /// Returns the asset path for a building sprite at a given level (1-5).
  static String buildingSprite(String buildingId, int level) =>
      '$_images/buildings/${buildingId}_level$level.png';

  static const String cathedralL1 = '$_images/buildings/cathedral_level1.png';
  static const String cathedralL2 = '$_images/buildings/cathedral_level2.png';
  static const String cathedralL3 = '$_images/buildings/cathedral_level3.png';
  static const String cathedralL4 = '$_images/buildings/cathedral_level4.png';
  static const String cathedralL5 = '$_images/buildings/cathedral_level5.png';

  static const String monasteryL1 = '$_images/buildings/monastery_level1.png';
  static const String monasteryL2 = '$_images/buildings/monastery_level2.png';
  static const String monasteryL3 = '$_images/buildings/monastery_level3.png';
  static const String monasteryL4 = '$_images/buildings/monastery_level4.png';
  static const String monasteryL5 = '$_images/buildings/monastery_level5.png';

  static const String libraryL1 = '$_images/buildings/library_level1.png';
  static const String libraryL2 = '$_images/buildings/library_level2.png';
  static const String libraryL3 = '$_images/buildings/library_level3.png';
  static const String libraryL4 = '$_images/buildings/library_level4.png';
  static const String libraryL5 = '$_images/buildings/library_level5.png';

  static const String chapelL1 = '$_images/buildings/chapel_level1.png';
  static const String chapelL2 = '$_images/buildings/chapel_level2.png';
  static const String chapelL3 = '$_images/buildings/chapel_level3.png';
  static const String chapelL4 = '$_images/buildings/chapel_level4.png';
  static const String chapelL5 = '$_images/buildings/chapel_level5.png';

  static const String gardenL1 = '$_images/buildings/garden_level1.png';
  static const String gardenL2 = '$_images/buildings/garden_level2.png';
  static const String gardenL3 = '$_images/buildings/garden_level3.png';
  static const String gardenL4 = '$_images/buildings/garden_level4.png';
  static const String gardenL5 = '$_images/buildings/garden_level5.png';

  static const String scriptoriumL1 =
      '$_images/buildings/scriptorium_level1.png';
  static const String scriptoriumL2 =
      '$_images/buildings/scriptorium_level2.png';
  static const String scriptoriumL3 =
      '$_images/buildings/scriptorium_level3.png';
  static const String scriptoriumL4 =
      '$_images/buildings/scriptorium_level4.png';
  static const String scriptoriumL5 =
      '$_images/buildings/scriptorium_level5.png';

  static const String almsHouseL1 = '$_images/buildings/alms_house_level1.png';
  static const String almsHouseL2 = '$_images/buildings/alms_house_level2.png';
  static const String almsHouseL3 = '$_images/buildings/alms_house_level3.png';
  static const String almsHouseL4 = '$_images/buildings/alms_house_level4.png';
  static const String almsHouseL5 = '$_images/buildings/alms_house_level5.png';

  static const String belltowerL1 = '$_images/buildings/belltower_level1.png';
  static const String belltowerL2 = '$_images/buildings/belltower_level2.png';
  static const String belltowerL3 = '$_images/buildings/belltower_level3.png';
  static const String belltowerL4 = '$_images/buildings/belltower_level4.png';
  static const String belltowerL5 = '$_images/buildings/belltower_level5.png';

  static const String fountainL1 = '$_images/buildings/fountain_level1.png';
  static const String fountainL2 = '$_images/buildings/fountain_level2.png';
  static const String fountainL3 = '$_images/buildings/fountain_level3.png';
  static const String fountainL4 = '$_images/buildings/fountain_level4.png';
  static const String fountainL5 = '$_images/buildings/fountain_level5.png';

  static const String pilgramageRouteL1 =
      '$_images/buildings/pilgrimage_route_level1.png';
  static const String pilgramageRouteL2 =
      '$_images/buildings/pilgrimage_route_level2.png';
  static const String pilgramageRouteL3 =
      '$_images/buildings/pilgrimage_route_level3.png';
  static const String pilgramageRouteL4 =
      '$_images/buildings/pilgrimage_route_level4.png';
  static const String pilgramageRouteL5 =
      '$_images/buildings/pilgrimage_route_level5.png';

  // ── Saints ────────────────────────────────────────────────────────────────

  /// Returns the avatar path for a saint by their ID slug.
  static String saintAvatar(String saintId) =>
      '$_images/saints/${saintId}_avatar.png';

  static String saintFullArt(String saintId) =>
      '$_images/saints/${saintId}_full.png';

  static const String saintPlaceholder = '$_images/saints/placeholder.png';

  // Sample saints pre-declared for compile-time safety
  static const String saintFrancisAvatar =
      '$_images/saints/st_francis_avatar.png';
  static const String saintClareAvatar =
      '$_images/saints/st_clare_avatar.png';
  static const String saintDominicAvatar =
      '$_images/saints/st_dominic_avatar.png';
  static const String saintThomasAvatar =
      '$_images/saints/st_thomas_avatar.png';
  static const String saintJoanAvatar = '$_images/saints/st_joan_avatar.png';
  static const String saintTeresaAvatar =
      '$_images/saints/st_teresa_avatar.png';
  static const String saintIgnatiusAvatar =
      '$_images/saints/st_ignatius_avatar.png';
  static const String saintBenedictAvatar =
      '$_images/saints/st_benedict_avatar.png';
  static const String saintBrigidAvatar =
      '$_images/saints/st_brigid_avatar.png';
  static const String saintNicholasAvatar =
      '$_images/saints/st_nicholas_avatar.png';

  // ── Animations (Lottie / Rive) ────────────────────────────────────────────

  static const String celebrationAnimation =
      '$_animations/celebration.json';
  static const String levelUpAnimation = '$_animations/level_up.json';
  static const String prayerAnimation = '$_animations/prayer.json';
  static const String constructionAnimation =
      '$_animations/construction.json';
  static const String questCompleteAnimation =
      '$_animations/quest_complete.json';
  static const String streakFireAnimation = '$_animations/streak_fire.json';
  static const String holyLightAnimation = '$_animations/holy_light.json';
  static const String rosaryAnimation = '$_animations/rosary.json';
  static const String loadingCrossAnimation =
      '$_animations/loading_cross.json';

  // ── Audio ─────────────────────────────────────────────────────────────────

  static const String bgMusicKingdom = '$_audio/bg_kingdom_ambient.mp3';
  static const String bgMusicPrayer = '$_audio/bg_prayer_chant.mp3';
  static const String bgMusicBattle = '$_audio/bg_battle_hymn.mp3';
  static const String bgMusicLibrary = '$_audio/bg_library_quiet.mp3';
  static const String bgMusicMap = '$_audio/bg_map_explore.mp3';

  static const String sfxCoinCollect = '$_audio/sfx_coin_collect.mp3';
  static const String sfxLevelUp = '$_audio/sfx_level_up.mp3';
  static const String sfxBuildingComplete = '$_audio/sfx_building_complete.mp3';
  static const String sfxQuestAccept = '$_audio/sfx_quest_accept.mp3';
  static const String sfxQuestComplete = '$_audio/sfx_quest_complete.mp3';
  static const String sfxButtonTap = '$_audio/sfx_button_tap.mp3';
  static const String sfxScrollUnfurl = '$_audio/sfx_scroll_unfurl.mp3';
  static const String sfxChurchBell = '$_audio/sfx_church_bell.mp3';
  static const String sfxPrayerBead = '$_audio/sfx_prayer_bead.mp3';
  static const String sfxUnlock = '$_audio/sfx_unlock.mp3';

  // ── Data files ────────────────────────────────────────────────────────────

  static const String saintsData = '$_data/saints.json';
  static const String prayersData = '$_data/prayers.json';
  static const String liturgicalCalendarData = '$_data/liturgical_calendar.json';
  static const String buildingsData = '$_data/buildings.json';
  static const String questsData = '$_data/quests.json';
  static const String bibleVerseOfDayData = '$_data/bible_verses.json';
}
