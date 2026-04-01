import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kingdomcome/routing/route_guards.dart';
import 'package:kingdomcome/routing/route_names.dart';
import 'package:kingdomcome/presentation/screens/shell/main_shell.dart';
import 'package:kingdomcome/presentation/screens/ark/ark_screen.dart';
import 'package:kingdomcome/presentation/screens/ark/ark_node_detail_screen.dart';
import 'package:kingdomcome/presentation/screens/ark/interactive_reading_screen.dart';
import 'package:kingdomcome/presentation/screens/ark/daily_bread_screen.dart';
import 'package:kingdomcome/presentation/screens/kingdom/kingdom_screen.dart';
import 'package:kingdomcome/presentation/screens/kingdom/blueprint_mode_screen.dart';
import 'package:kingdomcome/presentation/screens/kingdom/saint_chat_sheet.dart';
import 'package:kingdomcome/presentation/screens/auth/login_screen.dart';
import 'package:kingdomcome/presentation/screens/auth/register_screen.dart';
import 'package:kingdomcome/presentation/screens/splash/splash_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Placeholder screen (used for not-yet-built sections)
// ─────────────────────────────────────────────────────────────────────────────

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title, this.params});

  final String title;
  final Map<String, String>? params;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF2D0F42),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2D0F42),
          title: Text(title,
              style: const TextStyle(
                  fontFamily: 'Cinzel', color: Color(0xFFD4A017))),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 18,
                      color: Color(0xFFD4A017))),
              if (params != null) ...[
                const SizedBox(height: 8),
                Text(
                  params!.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF9E9590)),
                ),
              ],
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Auth screen adapters
// ─────────────────────────────────────────────────────────────────────────────

// Auth screen aliases for clarity in route builder closures

// ─────────────────────────────────────────────────────────────────────────────
// Error / Not-found screens
// ─────────────────────────────────────────────────────────────────────────────

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF2D0F42),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2D0F42),
          title: const Text('Not Found',
              style: TextStyle(fontFamily: 'Cinzel', color: Color(0xFFD4A017))),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('404',
                  style: TextStyle(
                      fontSize: 72,
                      fontFamily: 'Cinzel',
                      color: Color(0xFFD4A017))),
              const SizedBox(height: 16),
              const Text('Page not found',
                  style: TextStyle(color: Color(0xFF9E9590))),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(RouteNames.kingdom),
                child: const Text('Go to Kingdom'),
              ),
            ],
          ),
        ),
      );
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.error});
  final Exception error;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF2D0F42),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2D0F42),
          title: const Text('Error',
              style: TextStyle(fontFamily: 'Cinzel', color: Color(0xFFD4A017))),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'Cinzel',
                      color: Color(0xFFFDF6E3)),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF9E9590)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go(RouteNames.kingdom),
                  child: const Text('Go to Kingdom'),
                ),
              ],
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Router provider
// ─────────────────────────────────────────────────────────────────────────────

/// Riverpod provider for the app's [GoRouter] instance.
final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    refreshListenable: notifier,
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) => appRedirect(context, state, ref),
    errorBuilder: (context, state) =>
        _ErrorScreen(error: state.error ?? Exception('Unknown error')),
    routes: [
      // ── Splash ─────────────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Onboarding ─────────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.onboarding,
        name: 'onboarding',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Onboarding'),
      ),

      // ── Auth ───────────────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.signIn,
        name: 'sign-in',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.signUp,
        name: 'sign-up',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        name: 'forgot-password',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Forgot Password'),
      ),
      GoRoute(
        path: RouteNames.verifyEmail,
        name: 'verify-email',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Verify Email'),
      ),
      GoRoute(
        path: RouteNames.ageSetup,
        name: 'age-setup',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Age Setup'),
      ),
      GoRoute(
        path: RouteNames.parentalConsent,
        name: 'parental-consent',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Parental Consent'),
        routes: [
          GoRoute(
            path: 'verify/:token',
            name: 'parental-consent-verify',
            builder: (context, state) => _PlaceholderScreen(
              title: 'Verify Consent',
              params: {'token': state.pathParameters['token'] ?? ''},
            ),
          ),
        ],
      ),

      // ── Main shell: 5-tab StatefulShellRoute ───────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(navigationShell: shell),
        branches: [
          // ── Branch 0: The Ark (/ark) ──────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.ark,
                name: 'ark',
                builder: (context, state) => const ArkScreen(),
                routes: [
                  GoRoute(
                    path: 'node/:nodeId',
                    name: 'ark-node-detail',
                    builder: (context, state) => ArkNodeDetailScreen(
                      nodeId: state.pathParameters['nodeId'] ?? '',
                    ),
                  ),
                  GoRoute(
                    path: 'story/:nodeId',
                    name: 'ark-story-viewer',
                    builder: (context, state) => _PlaceholderScreen(
                      title: 'Story Viewer',
                      params: {
                        'nodeId': state.pathParameters['nodeId'] ?? '',
                      },
                    ),
                  ),
                  GoRoute(
                    path: 'daily-bread',
                    name: 'daily-bread',
                    builder: (context, state) => const DailyBreadScreen(),
                  ),
                  GoRoute(
                    path: 'reading/:nodeId',
                    name: 'interactive-reading',
                    builder: (context, state) => InteractiveReadingScreen(
                      nodeId: state.pathParameters['nodeId'] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Branch 1: The Kingdom (/kingdom) ──────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.kingdom,
                name: 'kingdom',
                builder: (context, state) => const KingdomScreen(),
                routes: [
                  GoRoute(
                    path: 'build',
                    name: 'kingdom-build-menu',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Build Menu'),
                  ),
                  GoRoute(
                    path: 'building/:buildingId',
                    name: 'building-detail',
                    builder: (context, state) => _PlaceholderScreen(
                      title: 'Building Detail',
                      params: {
                        'buildingId':
                            state.pathParameters['buildingId'] ?? '',
                      },
                    ),
                    routes: [
                      GoRoute(
                        path: 'upgrade',
                        name: 'building-upgrade',
                        builder: (context, state) => _PlaceholderScreen(
                          title: 'Building Upgrade',
                          params: {
                            'buildingId':
                                state.pathParameters['buildingId'] ?? '',
                          },
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'blueprints',
                    name: 'blueprint-mode',
                    builder: (context, state) =>
                        const BlueprintModeScreen(),
                  ),
                  GoRoute(
                    path: 'saint/:saintId/chat',
                    name: 'saint-chat-kingdom',
                    builder: (context, state) => SaintChatSheetPage(
                      saintId: state.pathParameters['saintId'] ?? '',
                    ),
                  ),
                  GoRoute(
                    path: 'leaderboard',
                    name: 'kingdom-leaderboard',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Leaderboard'),
                  ),
                  GoRoute(
                    path: 'inventory',
                    name: 'kingdom-inventory',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Inventory'),
                  ),
                ],
              ),
            ],
          ),

          // ── Branch 2: The Academy (/academy) ──────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.academy,
                name: 'academy',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'The Academy'),
                routes: [
                  GoRoute(
                    path: 'trivia',
                    name: 'academy-trivia',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Trivia Challenge'),
                  ),
                  GoRoute(
                    path: 'puzzles',
                    name: 'academy-puzzles',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Puzzle Rooms'),
                  ),
                  GoRoute(
                    path: 'leaderboard',
                    name: 'academy-leaderboard',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Academy Leaderboard'),
                  ),
                  GoRoute(
                    path: 'game/:gameId',
                    name: 'academy-game-detail',
                    builder: (context, state) => _PlaceholderScreen(
                      title: 'Game Detail',
                      params: {
                        'gameId': state.pathParameters['gameId'] ?? '',
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Branch 3: The Workshop (/workshop) ────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.workshop,
                name: 'workshop',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'The Workshop'),
                routes: [
                  GoRoute(
                    path: 'scanner',
                    name: 'workshop-scanner',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Art Scanner'),
                  ),
                  GoRoute(
                    path: 'stained-glass',
                    name: 'workshop-stained-glass',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Stained Glass Studio'),
                  ),
                  GoRoute(
                    path: 'manuscript',
                    name: 'workshop-manuscript',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Illuminated Manuscript'),
                  ),
                  GoRoute(
                    path: 'banner',
                    name: 'workshop-banner',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Banner Maker'),
                  ),
                  GoRoute(
                    path: 'gallery',
                    name: 'workshop-gallery',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Gallery'),
                  ),
                  GoRoute(
                    path: 'printables',
                    name: 'workshop-printables',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Printables'),
                  ),
                ],
              ),
            ],
          ),

          // ── Branch 4: My Soul (/soul) ──────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.soul,
                name: 'soul',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'My Soul'),
                routes: [
                  GoRoute(
                    path: 'prayer-chat',
                    name: 'prayer-chat',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Prayer Chat'),
                  ),
                  GoRoute(
                    path: 'grace-stats',
                    name: 'grace-stats',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Grace Statistics'),
                  ),
                  GoRoute(
                    path: 'parent-gate',
                    name: 'parent-gate',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Parent Gate'),
                  ),
                  GoRoute(
                    path: 'settings',
                    name: 'settings',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Settings'),
                    routes: [
                      GoRoute(
                        path: 'notifications',
                        name: 'notification-settings',
                        builder: (context, state) => const _PlaceholderScreen(
                            title: 'Notification Settings'),
                      ),
                      GoRoute(
                        path: 'theme',
                        name: 'theme-settings',
                        builder: (context, state) =>
                            const _PlaceholderScreen(title: 'Theme Settings'),
                      ),
                      GoRoute(
                        path: 'privacy',
                        name: 'privacy-settings',
                        builder: (context, state) =>
                            const _PlaceholderScreen(title: 'Privacy Settings'),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'parent-dashboard',
                    name: 'parent-dashboard',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Parent Dashboard'),
                    routes: [
                      GoRoute(
                        path: 'report',
                        name: 'activity-report',
                        builder: (context, state) =>
                            const _PlaceholderScreen(title: 'Activity Report'),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'patrons',
                    name: 'saint-patrons',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Patron Saints'),
                    routes: [
                      GoRoute(
                        path: 'select',
                        name: 'patron-select',
                        builder: (context, state) => const _PlaceholderScreen(
                            title: 'Select Patron Saint'),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'achievements',
                    name: 'achievements',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Achievements'),
                    routes: [
                      GoRoute(
                        path: ':achievementId',
                        name: 'achievement-detail',
                        builder: (context, state) => _PlaceholderScreen(
                          title: 'Achievement',
                          params: {
                            'achievementId':
                                state.pathParameters['achievementId'] ?? '',
                          },
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'profile-edit',
                    name: 'profile-edit',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Edit Profile'),
                  ),
                  GoRoute(
                    path: 'about',
                    name: 'about',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'About Kingdom Come'),
                  ),
                  GoRoute(
                    path: 'sign-out',
                    name: 'sign-out-confirm',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Sign Out'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // ── 404 ──────────────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.notFound,
        name: 'not-found',
        builder: (context, state) => const _NotFoundScreen(),
      ),
    ],
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// Router notifier — triggers GoRouter.refresh on auth changes
// ─────────────────────────────────────────────────────────────────────────────

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(
      authUserProvider,
      (_, __) => notifyListeners(),
    );
  }
}
