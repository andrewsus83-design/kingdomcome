import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failure.dart';
import '../models/user/user_model.dart';

// ---------------------------------------------------------------------------
// Abstract interface
// ---------------------------------------------------------------------------

abstract class AuthRepository {
  /// Signs in with [email] and [password].
  Future<Either<Failure, UserModel>> signIn(String email, String password);

  /// Creates a new account and returns the created [UserModel].
  Future<Either<Failure, UserModel>> signUp(
    String email,
    String password,
    String username,
    int ageGroup,
  );

  /// Signs the current user out.
  Future<Either<Failure, void>> signOut();

  /// Sends a parental-consent email to [parentEmail] linking to [userId].
  Future<Either<Failure, void>> sendParentalConsent(
    String parentEmail,
    String userId,
  );

  /// Stream that emits the current [UserModel] on auth state changes,
  /// or null when signed out.
  Stream<UserModel?> get authStateChanges;

  /// The currently authenticated user, or null if not signed in.
  UserModel? get currentUser;
}

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required SupabaseClient supabaseClient})
      : _client = supabaseClient;

  final SupabaseClient _client;

  @override
  UserModel? get currentUser {
    final session = _client.auth.currentSession;
    if (session == null) return null;
    // Profile data is loaded separately; return minimal model from session.
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final meta = user.userMetadata ?? {};
    return _userFromAuthUser(user, meta);
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _client.auth.onAuthStateChange.asyncMap((event) async {
      final user = event.session?.user;
      if (user == null) return null;
      try {
        final profile = await _client
            .from('user_profiles')
            .select()
            .eq('id', user.id)
            .single();
        return UserModel.fromJson(profile);
      } catch (_) {
        return _userFromAuthUser(user, user.userMetadata ?? {});
      }
    });
  }

  @override
  Future<Either<Failure, UserModel>> signIn(
    String email,
    String password,
  ) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        return const Left(AuthFailure(message: 'Sign in failed: no user returned.'));
      }
      final profile = await _client
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .single();
      return Right(UserModel.fromJson(profile));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.statusCode));
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserModel>> signUp(
    String email,
    String password,
    String username,
    int ageGroup,
  ) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'age_group': ageGroup,
        },
      );
      final user = response.user;
      if (user == null) {
        return const Left(
          AuthFailure(message: 'Sign up failed: no user returned.'),
        );
      }

      // The Supabase `handle_new_user` database trigger creates the profile
      // row automatically. Wait briefly and then fetch it.
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final profile = await _client
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .single();
      return Right(UserModel.fromJson(profile));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.statusCode));
    } on PostgrestException catch (e) {
      return Left(GameFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _client.auth.signOut();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.statusCode));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendParentalConsent(
    String parentEmail,
    String userId,
  ) async {
    try {
      await _client.functions.invoke(
        'send-parental-consent',
        body: {
          'parent_email': parentEmail,
          'user_id': userId,
        },
      );
      return const Right(null);
    } on FunctionException catch (e) {
      return Left(
        GameFailure(message: e.details?.toString() ?? 'Edge function error'),
      );
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  UserModel _userFromAuthUser(User user, Map<String, dynamic> meta) {
    final now = DateTime.now();
    return UserModel(
      id: user.id,
      username: meta['username'] as String? ?? user.email ?? user.id,
      displayName: meta['display_name'] as String? ??
          meta['username'] as String? ??
          user.email ??
          user.id,
      avatarUrl: meta['avatar_url'] as String?,
      ageGroup: meta['age_group'] as int? ?? 2,
      parentalConsentGiven: meta['parental_consent_given'] as bool? ?? false,
      parentEmail: meta['parent_email'] as String?,
      parishId: meta['parish_id'] as String?,
      createdAt: user.createdAt.isNotEmpty
          ? DateTime.parse(user.createdAt)
          : now,
      lastActiveAt: now,
    );
  }
}
