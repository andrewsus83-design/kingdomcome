import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kingdomcome/core/constants/game_constants.dart';
import 'package:kingdomcome/core/services/local_storage_service.dart';
import 'package:kingdomcome/core/services/supabase_service.dart';
import 'package:kingdomcome/routing/route_names.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Riverpod providers used by guards
// ─────────────────────────────────────────────────────────────────────────────

/// Exposes the current Supabase [User] (null when signed out).
final authUserProvider = StreamProvider<User?>((ref) {
  return SupabaseService.instance.authStateChanges.map((e) => e.session?.user);
});

/// Exposes the current player's age group (1, 2, or 3). -1 = unknown.
///
/// In a full implementation this would be fetched from the profiles table.
/// Here it reads from local storage as a fast synchronous check.
final playerAgeGroupProvider = Provider<int>((ref) {
  return LocalStorageService.instance.read<int>(
    'player_age_group',
    defaultValue: -1,
  );
});

/// Exposes whether parental consent has been granted for AI features.
final parentalConsentProvider = Provider<bool>((ref) {
  return LocalStorageService.instance.read<bool>(
    'parental_consent_granted',
    defaultValue: false,
  );
});

/// Exposes the player's current level (defaults to 1).
final playerLevelProvider = Provider<int>((ref) {
  return LocalStorageService.instance.read<int>(
    'player_level',
    defaultValue: 1,
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// Guard functions
// ─────────────────────────────────────────────────────────────────────────────

/// GoRouter redirect callback that enforces all app-wide guards.
///
/// Evaluated on every navigation event. Returns null to allow the navigation,
/// or a redirect path string to override it.
String? appRedirect(BuildContext context, GoRouterState state, WidgetRef ref) {
  final location = state.uri.toString();

  // ── Auth guard ──────────────────────────────────────────────────────────
  final authValue = ref.read(authUserProvider);
  final isSignedIn = authValue.valueOrNull != null;

  // Public routes that don't require authentication
  const publicRoutes = [
    RouteNames.splash,
    RouteNames.onboarding,
    RouteNames.signIn,
    RouteNames.signUp,
    RouteNames.forgotPassword,
    RouteNames.verifyEmail,
    RouteNames.ageSetup,
    RouteNames.parentalConsent,
    RouteNames.notFound,
    RouteNames.error,
  ];

  final isPublic = publicRoutes.any(location.startsWith);
  final isParentalConsentVerify =
      location.startsWith('/parental-consent/verify/');

  if (!isSignedIn && !isPublic && !isParentalConsentVerify) {
    return RouteNames.signIn;
  }

  // Redirect signed-in users away from auth screens
  if (isSignedIn &&
      (location == RouteNames.signIn || location == RouteNames.signUp)) {
    return RouteNames.kingdom;
  }

  // ── Onboarding guard ─────────────────────────────────────────────────────
  if (isSignedIn) {
    final hasCompletedOnboarding =
        LocalStorageService.instance.hasCompletedOnboarding;
    if (!hasCompletedOnboarding &&
        !isPublic &&
        location != RouteNames.ageSetup) {
      return RouteNames.ageSetup;
    }
  }

  // ── Age guard ────────────────────────────────────────────────────────────
  // Routes that require age group 2+ (12+)
  const group2Routes = [
    RouteNames.craftCanvas,
    RouteNames.craftGallery,
  ];

  if (group2Routes.any(location.startsWith)) {
    final ageGroup = ref.read(playerAgeGroupProvider);
    if (ageGroup < 2) {
      return RouteNames.learn;
    }
  }

  // Routes that require age group 3 (16+)
  const group3Routes = [
    '/learn/catechism/advanced',
    '/learn/bible/commentary',
  ];

  if (group3Routes.any(location.startsWith)) {
    final ageGroup = ref.read(playerAgeGroupProvider);
    if (ageGroup < 3) {
      return RouteNames.learn;
    }
  }

  // ── Parental consent guard ────────────────────────────────────────────────
  // AI chat requires parental consent for all age groups.
  if (location.startsWith(RouteNames.aiChat)) {
    final hasConsent = ref.read(parentalConsentProvider);
    if (!hasConsent) {
      return RouteNames.parentalConsent;
    }
  }

  // ── Building unlock guard ─────────────────────────────────────────────────
  // Building upgrade screen: check player level against unlock level.
  if (location.startsWith('/kingdom/building/')) {
    final segments = location.split('/');
    // Path: /kingdom/building/:buildingId/upgrade
    if (segments.length >= 5 && segments[4] == 'upgrade') {
      final buildingId = segments[3];
      final requiredLevel = kBuildingUnlockLevels[buildingId] ?? 1;
      final playerLevel = ref.read(playerLevelProvider);
      if (playerLevel < requiredLevel) {
        // Redirect back to kingdom map
        return RouteNames.kingdom;
      }
    }
  }

  return null; // Allow navigation
}

// ─────────────────────────────────────────────────────────────────────────────
// Guard helper class (for use in individual route `redirect` callbacks)
// ─────────────────────────────────────────────────────────────────────────────

/// Utility class providing individual guard checks for use in route-level
/// redirect callbacks.
abstract final class RouteGuards {
  /// Returns the redirect path if the user is not signed in, else null.
  static String? authGuard(WidgetRef ref) {
    final authValue = ref.read(authUserProvider);
    final isSignedIn = authValue.valueOrNull != null;
    return isSignedIn ? null : RouteNames.signIn;
  }

  /// Returns the redirect path if parental consent is not granted, else null.
  static String? parentalConsentGuard(WidgetRef ref) {
    final hasConsent = ref.read(parentalConsentProvider);
    return hasConsent ? null : RouteNames.parentalConsent;
  }

  /// Returns the redirect path if the player's age group is below [minGroup].
  static String? ageGuard(WidgetRef ref, {required int minGroup}) {
    final ageGroup = ref.read(playerAgeGroupProvider);
    return ageGroup >= minGroup ? null : RouteNames.learn;
  }

  /// Returns the redirect path if the player's level is below [requiredLevel].
  static String? levelGuard(
    WidgetRef ref, {
    required int requiredLevel,
    String redirectTo = RouteNames.kingdom,
  }) {
    final playerLevel = ref.read(playerLevelProvider);
    if (playerLevel >= requiredLevel) return null;
    if (kDebugMode) {
      debugPrint(
        'RouteGuards.levelGuard: player level $playerLevel < '
        'required $requiredLevel — redirecting to $redirectTo',
      );
    }
    return redirectTo;
  }
}
