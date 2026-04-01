import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service for scheduling and displaying local notifications.
///
/// Notification categories:
/// — Prayer reminders (daily scheduled)
/// — Streak alerts (when a streak is at risk)
/// — Construction complete
/// — Quest expiry warnings
/// — Achievement unlocked
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialised = false;

  // ── Notification IDs ──────────────────────────────────────────────────────

  static const int _prayerReminderId = 1000;
  static const int _streakAlertId = 2000;
  static const int _constructionBaseId = 3000;
  static const int _questExpiryBaseId = 4000;
  static const int _achievementBaseId = 5000;

  // ── Channel IDs (Android) ─────────────────────────────────────────────────

  static const String _prayerChannelId = 'prayer_reminders';
  static const String _gameChannelId = 'game_events';
  static const String _achievementChannelId = 'achievements';

  // ── Init ──────────────────────────────────────────────────────────────────

  /// Initialise the plugin and request permissions.
  ///
  /// Must be called from [main] before [runApp].
  Future<void> init() async {
    if (_initialised) return;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [
        DarwinNotificationCategory(
          'prayer',
          options: {
            DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
          },
        ),
      ],
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationTapped,
    );

    // Request Android 13+ permission
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    _initialised = true;
  }

  // ── Permission helpers ────────────────────────────────────────────────────

  /// Returns true if local notifications are permitted on this device.
  Future<bool> hasPermission() async {
    if (Platform.isIOS || Platform.isMacOS) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.checkPermissions();
      return result?.isEnabled ?? false;
    }
    if (Platform.isAndroid) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();
      return result ?? false;
    }
    return false;
  }

  // ── Prayer reminders ──────────────────────────────────────────────────────

  /// Schedules a daily prayer reminder at [hour]:[minute] local time.
  Future<void> scheduleDailyPrayerReminder({
    required int hour,
    required int minute,
    String title = 'Time to Pray! 🙏',
    String body = 'Take a moment to speak with God today.',
  }) async {
    await _plugin.zonedSchedule(
      _prayerReminderId,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _prayerChannelId,
          'Prayer Reminders',
          channelDescription: 'Daily reminders to pray',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_cross',
          color: const Color(0xFF4A1A6B),
        ),
        iOS: const DarwinNotificationDetails(
          categoryIdentifier: 'prayer',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Cancels the daily prayer reminder.
  Future<void> cancelPrayerReminder() async {
    await _plugin.cancel(_prayerReminderId);
  }

  // ── Streak alerts ─────────────────────────────────────────────────────────

  /// Shows an immediate notification warning that the streak is at risk.
  Future<void> showStreakAtRiskNotification({
    required int currentStreak,
  }) async {
    await _plugin.show(
      _streakAlertId,
      'Don\'t Break Your Streak! 🔥',
      'You\'ve prayed for $currentStreak days in a row. '
          'Pray today to keep it going!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _gameChannelId,
          'Game Events',
          channelDescription: 'Kingdom Come game notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_flame',
          color: const Color(0xFFD4A017),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // ── Construction complete ─────────────────────────────────────────────────

  /// Schedules a notification for when a building finishes construction.
  ///
  /// [buildingId] uniquely identifies the building (used for the notif ID).
  /// [buildingName] is displayed in the notification.
  /// [completesAt] is the UTC time the construction will finish.
  Future<void> scheduleConstructionComplete({
    required String buildingId,
    required String buildingName,
    required DateTime completesAt,
  }) async {
    final notifId =
        _constructionBaseId + buildingId.hashCode.abs() % 1000;

    await _plugin.zonedSchedule(
      notifId,
      '🏰 $buildingName is complete!',
      'Your $buildingName has finished construction. '
          'Tap to collect your rewards!',
      tz.TZDateTime.from(completesAt, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _gameChannelId,
          'Game Events',
          channelDescription: 'Kingdom Come game notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@drawable/ic_castle',
          color: const Color(0xFFD4A017),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Cancels a scheduled construction notification for [buildingId].
  Future<void> cancelConstructionNotification(String buildingId) async {
    final notifId =
        _constructionBaseId + buildingId.hashCode.abs() % 1000;
    await _plugin.cancel(notifId);
  }

  // ── Quest expiry ──────────────────────────────────────────────────────────

  /// Schedules a warning notification before a quest expires.
  Future<void> scheduleQuestExpiry({
    required String questId,
    required String questTitle,
    required DateTime expiresAt,
    int hoursBeforeExpiry = 24,
  }) async {
    final notifId =
        _questExpiryBaseId + questId.hashCode.abs() % 1000;

    final notifyAt = expiresAt
        .subtract(Duration(hours: hoursBeforeExpiry))
        .toUtc();

    if (notifyAt.isBefore(DateTime.now().toUtc())) return;

    await _plugin.zonedSchedule(
      notifId,
      '⚔️ Quest expiring soon!',
      '"$questTitle" expires in $hoursBeforeExpiry hours. '
          'Complete it before it\'s gone!',
      tz.TZDateTime.from(notifyAt, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _gameChannelId,
          'Game Events',
          channelDescription: 'Kingdom Come game notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_scroll',
          color: const Color(0xFF4A1A6B),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // ── Achievements ──────────────────────────────────────────────────────────

  /// Shows an immediate notification when the player unlocks an achievement.
  Future<void> showAchievementUnlocked({
    required String achievementTitle,
    required String achievementDescription,
    required int achievementIndex,
  }) async {
    final notifId =
        _achievementBaseId + achievementIndex.abs() % 1000;

    await _plugin.show(
      notifId,
      '🏆 Achievement Unlocked!',
      '$achievementTitle — $achievementDescription',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _achievementChannelId,
          'Achievements',
          channelDescription: 'Achievement notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@drawable/ic_trophy',
          color: const Color(0xFFD4A017),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
        ),
      ),
    );
  }

  // ── Cancel all ────────────────────────────────────────────────────────────

  /// Cancels all pending notifications.
  Future<void> cancelAll() => _plugin.cancelAll();

  // ── Helpers ───────────────────────────────────────────────────────────────

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  // ── Callbacks ─────────────────────────────────────────────────────────────

  static void _onNotificationTapped(NotificationResponse response) {
    // Deep-link handling is done via app_links. The payload can be used to
    // navigate when the notification is tapped while the app is running.
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(
      NotificationResponse response) {
    // Handle tap when app is terminated — typically a no-op; OS relaunches app.
  }
}
