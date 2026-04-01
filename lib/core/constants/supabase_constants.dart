/// Kingdom Come — Supabase table, RPC, and realtime channel name constants.
///
/// All string literals used to address Supabase resources live here.
/// Keep this file in sync with Supabase migrations.
abstract final class SupabaseConstants {
  // ── Tables ────────────────────────────────────────────────────────────────

  /// Player profile table — one row per auth user.
  static const String tableProfiles = 'profiles';

  /// Player resources (holy points, faith coins, grace, blessings).
  static const String tableResources = 'player_resources';

  /// Player progress — XP, level, streak data.
  static const String tableProgress = 'player_progress';

  /// Kingdom buildings per player.
  static const String tableBuildings = 'kingdom_buildings';

  /// Quests master list (seeded by admin).
  static const String tableQuests = 'quests';

  /// Player quest progress — junction table.
  static const String tablePlayerQuests = 'player_quests';

  /// Saints reference data (seeded).
  static const String tableSaints = 'saints';

  /// Player-saint patron relationships.
  static const String tablePatronSaints = 'player_patron_saints';

  /// Patron saint ability slots per player.
  static const String tableSaintAbilities = 'saint_abilities';

  /// Prayers catalogue (seeded).
  static const String tablePrayers = 'prayers';

  /// Prayer completion log.
  static const String tablePrayerLog = 'prayer_log';

  /// AI chat message history.
  static const String tableChatMessages = 'chat_messages';

  /// AI chat daily usage counters.
  static const String tableChatUsage = 'chat_daily_usage';

  /// Parental consent records.
  static const String tableParentalConsent = 'parental_consent';

  /// Parent-child linkage.
  static const String tableParentChild = 'parent_child_links';

  /// Parental activity reports (generated weekly).
  static const String tableActivityReports = 'parent_activity_reports';

  /// Liturgical calendar events (seeded).
  static const String tableLiturgicalEvents = 'liturgical_events';

  /// Scripture verse of the day (seeded daily by edge function).
  static const String tableScriptureOfDay = 'scripture_of_day';

  /// Player notifications queue.
  static const String tableNotifications = 'player_notifications';

  /// Generated saint character art (OpenArt).
  static const String tableSaintArt = 'saint_generated_art';

  /// Generated story videos (Runway / HeyGen).
  static const String tableStoryVideos = 'story_videos';

  /// World Anvil article cache.
  static const String tableWorldAnvilCache = 'world_anvil_cache';

  /// Leaderboard snapshots (updated hourly by edge function).
  static const String tableLeaderboard = 'leaderboard_snapshots';

  /// In-app achievements / badges.
  static const String tableAchievements = 'achievements';

  /// Player unlocked achievements.
  static const String tablePlayerAchievements = 'player_achievements';

  // ── Views ────────────────────────────────────────────────────────────────

  /// Denormalised player summary for dashboard.
  static const String viewPlayerSummary = 'v_player_summary';

  /// Leaderboard with rank, name, level, XP.
  static const String viewLeaderboard = 'v_leaderboard';

  // ── Remote Procedure Calls (RPCs) ─────────────────────────────────────────

  /// Award XP and possibly level the player up.
  static const String rpcAwardXp = 'award_xp';

  /// Grant resources to a player (atomic increment).
  static const String rpcGrantResources = 'grant_resources';

  /// Deduct resources for a building purchase (atomic).
  static const String rpcDeductResources = 'deduct_resources';

  /// Start building construction or upgrade.
  static const String rpcStartConstruction = 'start_construction';

  /// Complete a building (called when timer expires).
  static const String rpcCompleteConstruction = 'complete_construction';

  /// Accept a quest.
  static const String rpcAcceptQuest = 'accept_quest';

  /// Submit quest completion evidence and award rewards.
  static const String rpcCompleteQuest = 'complete_quest';

  /// Record a prayer session.
  static const String rpcLogPrayer = 'log_prayer';

  /// Increment daily streak (idempotent per calendar day).
  static const String rpcIncrementStreak = 'increment_streak';

  /// Assign a patron saint to a player slot.
  static const String rpcAssignPatron = 'assign_patron_saint';

  /// Get the current liturgical season as a string.
  static const String rpcGetLiturgicalSeason = 'get_liturgical_season';

  /// Submit a chat message and receive AI reply reference.
  static const String rpcSubmitChatMessage = 'submit_chat_message';

  /// Get the player's current AI chat usage count for today.
  static const String rpcGetChatUsage = 'get_chat_usage';

  /// Request parental consent link via email.
  static const String rpcRequestParentalConsent = 'request_parental_consent';

  /// Verify parental consent token.
  static const String rpcVerifyParentalConsent = 'verify_parental_consent';

  /// Generate the weekly parent activity report.
  static const String rpcGenerateActivityReport = 'generate_activity_report';

  // ── Realtime channels ─────────────────────────────────────────────────────

  /// Channel for live kingdom building updates.
  static const String channelKingdom = 'kingdom';

  /// Channel for quest state changes.
  static const String channelQuests = 'quests';

  /// Channel for player resource changes.
  static const String channelResources = 'resources';

  /// Channel for AI chat message streaming.
  static const String channelChat = 'chat';

  /// Channel for leaderboard changes.
  static const String channelLeaderboard = 'leaderboard';

  /// Channel for player notifications.
  static const String channelNotifications = 'notifications';

  // ── Storage buckets ───────────────────────────────────────────────────────

  /// Player-uploaded quest evidence images.
  static const String bucketQuestEvidence = 'quest-evidence';

  /// Generated saint artwork.
  static const String bucketSaintArt = 'saint-art';

  /// Generated story videos.
  static const String bucketStoryVideos = 'story-videos';

  /// Player avatar images.
  static const String bucketAvatars = 'avatars';
}
