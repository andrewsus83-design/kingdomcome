import 'package:hive_flutter/hive_flutter.dart';

import 'package:kingdomcome/core/errors/app_exception.dart';

/// Hive-based local storage service for offline caching and user preferences.
///
/// All Hive box names are defined as constants at the bottom of this file.
/// Typed read/write helpers ensure type safety at the call site.
class LocalStorageService {
  LocalStorageService._();

  static final LocalStorageService instance = LocalStorageService._();

  // ── Box references ────────────────────────────────────────────────────────

  late Box<dynamic> _prefs;
  late Box<Map<dynamic, dynamic>> _playerCache;
  late Box<Map<dynamic, dynamic>> _questCache;
  late Box<Map<dynamic, dynamic>> _saintCache;
  late Box<Map<dynamic, dynamic>> _prayerCache;

  bool _initialised = false;

  // ── Initialisation ────────────────────────────────────────────────────────

  /// Opens all Hive boxes. Must be called before [runApp].
  Future<void> init() async {
    if (_initialised) return;

    _prefs = await Hive.openBox<dynamic>(HiveBoxes.prefs);
    _playerCache =
        await Hive.openBox<Map<dynamic, dynamic>>(HiveBoxes.playerCache);
    _questCache =
        await Hive.openBox<Map<dynamic, dynamic>>(HiveBoxes.questCache);
    _saintCache =
        await Hive.openBox<Map<dynamic, dynamic>>(HiveBoxes.saintCache);
    _prayerCache =
        await Hive.openBox<Map<dynamic, dynamic>>(HiveBoxes.prayerCache);

    _initialised = true;
  }

  // ── Generic preferences ───────────────────────────────────────────────────

  /// Reads a value from the prefs box.
  ///
  /// Returns [defaultValue] if the key does not exist.
  T read<T>(String key, {required T defaultValue}) {
    _assertInitialised();
    final value = _prefs.get(key);
    if (value is T) return value;
    return defaultValue;
  }

  /// Writes a value to the prefs box.
  Future<void> write<T>(String key, T value) async {
    _assertInitialised();
    await _prefs.put(key, value);
  }

  /// Deletes a key from the prefs box.
  Future<void> delete(String key) async {
    _assertInitialised();
    await _prefs.delete(key);
  }

  /// Returns true if [key] exists in the prefs box.
  bool has(String key) {
    _assertInitialised();
    return _prefs.containsKey(key);
  }

  // ── Theme preference ──────────────────────────────────────────────────────

  String get themeMode =>
      read<String>(HiveKeys.themeMode, defaultValue: 'system');

  Future<void> setThemeMode(String mode) =>
      write<String>(HiveKeys.themeMode, mode);

  // ── Onboarding ────────────────────────────────────────────────────────────

  bool get hasCompletedOnboarding =>
      read<bool>(HiveKeys.onboardingComplete, defaultValue: false);

  Future<void> setOnboardingComplete() =>
      write<bool>(HiveKeys.onboardingComplete, true);

  // ── Notifications ─────────────────────────────────────────────────────────

  int get prayerReminderHour =>
      read<int>(HiveKeys.prayerHour, defaultValue: 7);

  int get prayerReminderMinute =>
      read<int>(HiveKeys.prayerMinute, defaultValue: 0);

  Future<void> setPrayerReminderTime(int hour, int minute) async {
    await write<int>(HiveKeys.prayerHour, hour);
    await write<int>(HiveKeys.prayerMinute, minute);
  }

  bool get notificationsEnabled =>
      read<bool>(HiveKeys.notificationsEnabled, defaultValue: true);

  Future<void> setNotificationsEnabled({required bool enabled}) =>
      write<bool>(HiveKeys.notificationsEnabled, enabled);

  // ── Auth cache ────────────────────────────────────────────────────────────

  String? get cachedUserId =>
      _prefs.get(HiveKeys.cachedUserId) as String?;

  Future<void> setCachedUserId(String id) =>
      write<String>(HiveKeys.cachedUserId, id);

  Future<void> clearCachedUserId() => delete(HiveKeys.cachedUserId);

  // ── Player cache ──────────────────────────────────────────────────────────

  /// Stores a player profile snapshot for offline access.
  Future<void> cachePlayerProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    _assertInitialised();
    await _playerCache.put(
      userId,
      Map<dynamic, dynamic>.from(data),
    );
  }

  /// Returns the cached player profile for [userId], or null.
  Map<String, dynamic>? getCachedPlayerProfile(String userId) {
    _assertInitialised();
    final raw = _playerCache.get(userId);
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw);
  }

  /// Clears the player profile cache.
  Future<void> clearPlayerCache() async {
    _assertInitialised();
    await _playerCache.clear();
  }

  // ── Quest cache ───────────────────────────────────────────────────────────

  Future<void> cacheQuests(List<Map<String, dynamic>> quests) async {
    _assertInitialised();
    await _questCache.clear();
    for (var i = 0; i < quests.length; i++) {
      await _questCache.put(i, Map<dynamic, dynamic>.from(quests[i]));
    }
  }

  List<Map<String, dynamic>> getCachedQuests() {
    _assertInitialised();
    return _questCache.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // ── Saint cache ───────────────────────────────────────────────────────────

  Future<void> cacheSaint(String saintId, Map<String, dynamic> data) async {
    _assertInitialised();
    await _saintCache.put(saintId, Map<dynamic, dynamic>.from(data));
  }

  Map<String, dynamic>? getCachedSaint(String saintId) {
    _assertInitialised();
    final raw = _saintCache.get(saintId);
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw);
  }

  // ── Prayer cache ──────────────────────────────────────────────────────────

  Future<void> cachePrayer(
    String prayerId,
    Map<String, dynamic> data,
  ) async {
    _assertInitialised();
    await _prayerCache.put(prayerId, Map<dynamic, dynamic>.from(data));
  }

  Map<String, dynamic>? getCachedPrayer(String prayerId) {
    _assertInitialised();
    final raw = _prayerCache.get(prayerId);
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw);
  }

  List<Map<String, dynamic>> getAllCachedPrayers() {
    _assertInitialised();
    return _prayerCache.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // ── Last sync timestamps ──────────────────────────────────────────────────

  DateTime? lastSyncedAt(String key) {
    final iso = _prefs.get('last_sync_$key') as String?;
    if (iso == null) return null;
    return DateTime.tryParse(iso);
  }

  Future<void> setLastSyncedAt(String key) async {
    await _prefs.put('last_sync_$key', DateTime.now().toIso8601String());
  }

  // ── Full clear ────────────────────────────────────────────────────────────

  /// Clears all local storage data. Call on sign-out.
  Future<void> clearAll() async {
    _assertInitialised();
    await Future.wait([
      _prefs.clear(),
      _playerCache.clear(),
      _questCache.clear(),
      _saintCache.clear(),
      _prayerCache.clear(),
    ]);
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _assertInitialised() {
    if (!_initialised) {
      throw StorageException(
        message: 'LocalStorageService has not been initialised. '
            'Call LocalStorageService.instance.init() in main().',
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

/// Hive box names.
abstract final class HiveBoxes {
  static const String prefs = 'kc_prefs';
  static const String playerCache = 'kc_player_cache';
  static const String questCache = 'kc_quest_cache';
  static const String saintCache = 'kc_saint_cache';
  static const String prayerCache = 'kc_prayer_cache';
}

/// Keys used within the prefs box.
abstract final class HiveKeys {
  static const String themeMode = 'theme_mode';
  static const String onboardingComplete = 'onboarding_complete';
  static const String prayerHour = 'prayer_hour';
  static const String prayerMinute = 'prayer_minute';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String cachedUserId = 'cached_user_id';
}
