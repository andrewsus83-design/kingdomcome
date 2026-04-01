import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kingdomcome/data/models/user/user_model.dart';

part 'auth_provider.g.dart';

// ── Internal Supabase client provider ────────────────────────────────────────

final _supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// ── Auth notifier ─────────────────────────────────────────────────────────────

@riverpod
class AuthNotifier extends _$AuthNotifier {
  SupabaseClient get _client => ref.read(_supabaseClientProvider);

  @override
  Future<UserModel?> build() async {
    // Re-run whenever the auth state changes (login / logout / session refresh)
    final authState = await _authStateStream().first;
    if (authState.session == null) return null;
    return _fetchUserModel(authState.session!.user.id);
  }

  /// Signs the user in with email and password.
  ///
  /// Throws [AuthException] on failure.
  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) {
        throw const AuthException('Sign in failed — no user returned.');
      }
      return _fetchUserModel(response.user!.id);
    });
  }

  /// Creates a new account and user profile.
  ///
  /// If [age] < 13, the account is flagged for parental consent and a consent
  /// email will be sent to [parentEmail].
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required int age,
    String? parentEmail,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final ageGroup = _ageToGroup(age);
      final requiresConsent = age < 13;

      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'age_group': ageGroup,
          'parental_consent_given': !requiresConsent,
          if (parentEmail != null) 'parent_email': parentEmail,
        },
      );

      if (response.user == null) {
        throw const AuthException('Registration failed — no user returned.');
      }

      final userId = response.user!.id;

      // Upsert profile row (trigger may have already created it)
      await _client.from('profiles').upsert({
        'id': userId,
        'username': username,
        'display_name': username,
        'age_group': ageGroup,
        'parental_consent_given': !requiresConsent,
        if (parentEmail != null) 'parent_email': parentEmail,
        'created_at': DateTime.now().toIso8601String(),
        'last_active_at': DateTime.now().toIso8601String(),
      });

      if (requiresConsent && parentEmail != null) {
        // Trigger parental consent email via Supabase RPC
        await _client.rpc('request_parental_consent', params: {
          'p_user_id': userId,
          'p_parent_email': parentEmail,
        });
      }

      return _fetchUserModel(userId);
    });
  }

  /// Signs the current user out and clears state.
  Future<void> signOut() async {
    await _client.auth.signOut();
    state = const AsyncData(null);
  }

  /// Updates the parental consent flag for the current user.
  Future<void> updateParentalConsent({required bool given}) async {
    final current = state.valueOrNull;
    if (current == null) return;

    await _client.from('profiles').update({
      'parental_consent_given': given,
    }).eq('id', current.id);

    state = AsyncData(current.copyWith(parentalConsentGiven: given));
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Stream<AuthState> _authStateStream() {
    return _client.auth.onAuthStateChange;
  }

  Future<UserModel?> _fetchUserModel(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return UserModel.fromJson(data);
  }

  int _ageToGroup(int age) {
    if (age <= 10) return 1;
    if (age <= 14) return 2;
    return 3;
  }
}

// ── Convenience providers ─────────────────────────────────────────────────────

/// Returns the currently signed-in [UserModel], or null if not authenticated.
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authNotifierProvider).valueOrNull;
});

/// True when a user session is active.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
