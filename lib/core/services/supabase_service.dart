import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kingdomcome/core/constants/supabase_constants.dart';
import 'package:kingdomcome/core/errors/app_exception.dart' as app;

/// Singleton wrapper around the [SupabaseClient].
///
/// Provides:
/// — Typed accessor for the underlying client.
/// — Auth helpers (sign in, sign out, current user).
/// — Convenience typed table queries.
/// — Consistent error translation from Supabase exceptions → [app.AppException].
class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  // ── Client accessor ───────────────────────────────────────────────────────

  /// The raw Supabase client. Use specific methods on this service where
  /// possible to benefit from error handling.
  SupabaseClient get client => Supabase.instance.client;

  // ── Auth ──────────────────────────────────────────────────────────────────

  /// Returns the currently authenticated [User], or null if signed out.
  User? get currentUser => client.auth.currentUser;

  /// Returns the current [Session], or null if not signed in.
  Session? get currentSession => client.auth.currentSession;

  /// Returns true when there is an active authenticated session.
  bool get isSignedIn => currentUser != null;

  /// Returns the authenticated user's ID, throwing [app.AuthException] if
  /// the user is not signed in.
  String get requiredUserId {
    final uid = currentUser?.id;
    if (uid == null) {
      throw const app.AuthException(
        message: 'User is not authenticated.',
        code: 'NOT_AUTHENTICATED',
      );
    }
    return uid;
  }

  /// Stream of auth state changes — use to react to sign-in / sign-out.
  Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;

  /// Sign in with email and password.
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e, st) {
      throw app.AuthException(
        message: e.message,
        code: e.statusCode,
        originalError: e,
        stackTrace: st,
      );
    }
  }

  /// Sign up with email and password.
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    try {
      return await client.auth.signUp(
        email: email,
        password: password,
        data: data,
      );
    } on AuthException catch (e, st) {
      throw app.AuthException(
        message: e.message,
        code: e.statusCode,
        originalError: e,
        stackTrace: st,
      );
    }
  }

  /// Sign in with a magic link (passwordless).
  Future<void> signInWithMagicLink(String email) async {
    try {
      await client.auth.signInWithOtp(email: email);
    } on AuthException catch (e, st) {
      throw app.AuthException(
        message: e.message,
        code: e.statusCode,
        originalError: e,
        stackTrace: st,
      );
    }
  }

  /// Sign out and clear the local session.
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } on AuthException catch (e, st) {
      throw app.AuthException(
        message: e.message,
        code: e.statusCode,
        originalError: e,
        stackTrace: st,
      );
    }
  }

  /// Refreshes the current session. Returns the new [Session] or null.
  Future<Session?> refreshSession() async {
    try {
      final response = await client.auth.refreshSession();
      return response.session;
    } on AuthException catch (e, st) {
      throw app.AuthException(
        message: e.message,
        code: e.statusCode,
        originalError: e,
        stackTrace: st,
      );
    }
  }

  // ── Typed table accessors ─────────────────────────────────────────────────

  SupabaseQueryBuilder get profiles =>
      client.from(SupabaseConstants.tableProfiles);

  SupabaseQueryBuilder get resources =>
      client.from(SupabaseConstants.tableResources);

  SupabaseQueryBuilder get progress =>
      client.from(SupabaseConstants.tableProgress);

  SupabaseQueryBuilder get buildings =>
      client.from(SupabaseConstants.tableBuildings);

  SupabaseQueryBuilder get quests =>
      client.from(SupabaseConstants.tableQuests);

  SupabaseQueryBuilder get playerQuests =>
      client.from(SupabaseConstants.tablePlayerQuests);

  SupabaseQueryBuilder get saints =>
      client.from(SupabaseConstants.tableSaints);

  SupabaseQueryBuilder get patronSaints =>
      client.from(SupabaseConstants.tablePatronSaints);

  SupabaseQueryBuilder get prayers =>
      client.from(SupabaseConstants.tablePrayers);

  SupabaseQueryBuilder get prayerLog =>
      client.from(SupabaseConstants.tablePrayerLog);

  SupabaseQueryBuilder get chatMessages =>
      client.from(SupabaseConstants.tableChatMessages);

  SupabaseQueryBuilder get chatUsage =>
      client.from(SupabaseConstants.tableChatUsage);

  SupabaseQueryBuilder get parentalConsent =>
      client.from(SupabaseConstants.tableParentalConsent);

  SupabaseQueryBuilder get liturgicalEvents =>
      client.from(SupabaseConstants.tableLiturgicalEvents);

  SupabaseQueryBuilder get scriptureOfDay =>
      client.from(SupabaseConstants.tableScriptureOfDay);

  SupabaseQueryBuilder get notifications =>
      client.from(SupabaseConstants.tableNotifications);

  SupabaseQueryBuilder get achievements =>
      client.from(SupabaseConstants.tableAchievements);

  SupabaseQueryBuilder get playerAchievements =>
      client.from(SupabaseConstants.tablePlayerAchievements);

  SupabaseQueryBuilder get leaderboard =>
      client.from(SupabaseConstants.tableLeaderboard);

  SupabaseQueryBuilder get worldAnvilCache =>
      client.from(SupabaseConstants.tableWorldAnvilCache);

  // ── RPC helpers ───────────────────────────────────────────────────────────

  /// Calls a Supabase RPC function with named parameters.
  Future<dynamic> rpc(
    String functionName, {
    Map<String, dynamic>? params,
  }) async {
    try {
      return await client.rpc(functionName, params: params);
    } on PostgrestException catch (e, st) {
      throw _mapPostgrestError(e, st);
    }
  }

  // ── Realtime ──────────────────────────────────────────────────────────────

  /// Opens a realtime channel by [channelName].
  RealtimeChannel channel(String channelName) =>
      client.channel(channelName);

  // ── Storage ───────────────────────────────────────────────────────────────

  SupabaseStorageClient get storage => client.storage;

  StorageFileApi questEvidenceBucket() =>
      storage.from(SupabaseConstants.bucketQuestEvidence);

  StorageFileApi saintArtBucket() =>
      storage.from(SupabaseConstants.bucketSaintArt);

  StorageFileApi storyVideosBucket() =>
      storage.from(SupabaseConstants.bucketStoryVideos);

  StorageFileApi avatarsBucket() =>
      storage.from(SupabaseConstants.bucketAvatars);

  // ── Error mapping ─────────────────────────────────────────────────────────

  app.AppException _mapPostgrestError(
    PostgrestException e,
    StackTrace st,
  ) {
    final code = e.code;
    if (code == '23505') {
      return app.ConflictException(
        message: 'A record already exists: ${e.message}',
        code: code,
        originalError: e,
        stackTrace: st,
      );
    }
    if (code == 'PGRST116') {
      return app.NotFoundException(
        message: 'Resource not found.',
        code: code,
        originalError: e,
        stackTrace: st,
      );
    }
    return app.NetworkException(
      message: e.message,
      code: code,
      originalError: e,
      stackTrace: st,
    );
  }
}
