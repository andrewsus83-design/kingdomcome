import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kingdomcome/routing/route_guards.dart';
import 'package:kingdomcome/routing/route_names.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Placeholder screen widgets
// ─────────────────────────────────────────────────────────────────────────────
// These will be replaced with real screen implementations as features are built.
// They live here temporarily so the router compiles as a complete unit.

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title, this.params});

  final String title;
  final Map<String, String>? params;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              if (params != null) ...[
                const SizedBox(height: 8),
                Text(
                  params!.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
}

// ── Auth screens ──────────────────────────────────────────────────────────────
class _SplashScreen extends _PlaceholderScreen {
  const _SplashScreen() : super(title: 'Splash');
}

class _OnboardingScreen extends _PlaceholderScreen {
  const _OnboardingScreen() : super(title: 'Onboarding');
}

class _SignInScreen extends _PlaceholderScreen {
  const _SignInScreen() : super(title: 'Sign In');
}

class _SignUpScreen extends _PlaceholderScreen {
  const _SignUpScreen() : super(title: 'Sign Up');
}

class _ForgotPasswordScreen extends _PlaceholderScreen {
  const _ForgotPasswordScreen() : super(title: 'Forgot Password');
}

class _VerifyEmailScreen extends _PlaceholderScreen {
  const _VerifyEmailScreen() : super(title: 'Verify Email');
}

class _AgeSetupScreen extends _PlaceholderScreen {
  const _AgeSetupScreen() : super(title: 'Age Setup');
}

class _ParentalConsentScreen extends _PlaceholderScreen {
  const _ParentalConsentScreen() : super(title: 'Parental Consent');
}

// ── Shell screens (tabs) ──────────────────────────────────────────────────────
class _KingdomScreen extends _PlaceholderScreen {
  const _KingdomScreen() : super(title: 'Kingdom Map');
}

class _QuestsScreen extends _PlaceholderScreen {
  const _QuestsScreen() : super(title: 'Quests');
}

class _PrayerScreen extends _PlaceholderScreen {
  const _PrayerScreen() : super(title: 'Prayer');
}

class _LearnScreen extends _PlaceholderScreen {
  const _LearnScreen() : super(title: 'Learn');
}

class _ProfileScreen extends _PlaceholderScreen {
  const _ProfileScreen() : super(title: 'Profile');
}

// ── Error / Not Found ─────────────────────────────────────────────────────────
class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Not Found')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('404', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 16),
              const Text('Page not found'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(RouteNames.kingdom),
                child: const Text('Go Home'),
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
        appBar: AppBar(title: const Text('Error')),
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
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go(RouteNames.kingdom),
                  child: const Text('Go Home'),
                ),
              ],
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Shell scaffold with bottom navigation
// ─────────────────────────────────────────────────────────────────────────────

class _AppShell extends StatelessWidget {
  const _AppShell({
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    _TabItem(
      icon: Icons.castle_outlined,
      activeIcon: Icons.castle,
      label: 'Kingdom',
    ),
    _TabItem(
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment,
      label: 'Quests',
    ),
    _TabItem(
      icon: Icons.church_outlined,
      activeIcon: Icons.church,
      label: 'Prayer',
    ),
    _TabItem(
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book,
      label: 'Learn',
    ),
    _TabItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        destinations: _tabs
            .map(
              (tab) => NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.activeIcon),
                label: tab.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

// ─────────────────────────────────────────────────────────────────────────────
// Router provider
// ─────────────────────────────────────────────────────────────────────────────

/// Riverpod provider for the app's [GoRouter] instance.
///
/// The router listens to [authUserProvider] so it re-evaluates guards whenever
/// authentication state changes.
final appRouterProvider = Provider<GoRouter>((ref) {
  // Trigger router refresh when auth state changes
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
        builder: (context, state) => const _SplashScreen(),
      ),

      // ── Onboarding ─────────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.onboarding,
        name: 'onboarding',
        builder: (context, state) => const _OnboardingScreen(),
      ),

      // ── Auth ───────────────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.signIn,
        name: 'sign-in',
        builder: (context, state) => const _SignInScreen(),
      ),
      GoRoute(
        path: RouteNames.signUp,
        name: 'sign-up',
        builder: (context, state) => const _SignUpScreen(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        name: 'forgot-password',
        builder: (context, state) => const _ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RouteNames.verifyEmail,
        name: 'verify-email',
        builder: (context, state) => const _VerifyEmailScreen(),
      ),
      GoRoute(
        path: RouteNames.ageSetup,
        name: 'age-setup',
        builder: (context, state) => const _AgeSetupScreen(),
      ),
      GoRoute(
        path: RouteNames.parentalConsent,
        name: 'parental-consent',
        builder: (context, state) => const _ParentalConsentScreen(),
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

      // ── Main shell with 5-tab bottom nav ───────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            _AppShell(navigationShell: shell),
        branches: [
          // ── Tab 1: Kingdom Map ────────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.kingdom,
                name: 'kingdom',
                builder: (context, state) => const _KingdomScreen(),
                routes: [
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

          // ── Tab 2: Quests ─────────────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.quests,
                name: 'quests',
                builder: (context, state) => const _QuestsScreen(),
                routes: [
                  GoRoute(
                    path: 'active',
                    name: 'quest-active',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Active Quests'),
                  ),
                  GoRoute(
                    path: 'history',
                    name: 'quest-history',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Quest History'),
                  ),
                  GoRoute(
                    path: ':questId',
                    name: 'quest-detail',
                    builder: (context, state) => _PlaceholderScreen(
                      title: 'Quest Detail',
                      params: {
                        'questId': state.pathParameters['questId'] ?? '',
                      },
                    ),
                    routes: [
                      GoRoute(
                        path: 'complete',
                        name: 'quest-complete',
                        builder: (context, state) => _PlaceholderScreen(
                          title: 'Quest Complete',
                          params: {
                            'questId':
                                state.pathParameters['questId'] ?? '',
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // ── Tab 3: Prayer ─────────────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.prayer,
                name: 'prayer',
                builder: (context, state) => const _PrayerScreen(),
                routes: [
                  GoRoute(
                    path: 'rosary',
                    name: 'rosary',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Rosary'),
                  ),
                  GoRoute(
                    path: 'divine-office',
                    name: 'divine-office',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Divine Office'),
                  ),
                  GoRoute(
                    path: 'examen',
                    name: 'examen',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Daily Examen'),
                  ),
                  GoRoute(
                    path: 'stations',
                    name: 'stations-of-cross',
                    builder: (context, state) => const _PlaceholderScreen(
                        title: 'Stations of the Cross'),
                  ),
                  GoRoute(
                    path: 'journal',
                    name: 'prayer-journal',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Prayer Journal'),
                  ),
                  GoRoute(
                    path: ':prayerId',
                    name: 'prayer-detail',
                    builder: (context, state) => _PlaceholderScreen(
                      title: 'Prayer',
                      params: {
                        'prayerId':
                            state.pathParameters['prayerId'] ?? '',
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Tab 4: Learn ──────────────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.learn,
                name: 'learn',
                builder: (context, state) => const _LearnScreen(),
                routes: [
                  // Saints
                  GoRoute(
                    path: 'saints',
                    name: 'saints-list',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Saints'),
                    routes: [
                      GoRoute(
                        path: ':saintId',
                        name: 'saint-detail',
                        builder: (context, state) => _PlaceholderScreen(
                          title: 'Saint Detail',
                          params: {
                            'saintId':
                                state.pathParameters['saintId'] ?? '',
                          },
                        ),
                        routes: [
                          GoRoute(
                            path: 'story',
                            name: 'saint-story',
                            builder: (context, state) =>
                                _PlaceholderScreen(
                              title: 'Saint Story',
                              params: {
                                'saintId':
                                    state.pathParameters['saintId'] ??
                                        '',
                              },
                            ),
                          ),
                          GoRoute(
                            path: 'art',
                            name: 'saint-art',
                            builder: (context, state) =>
                                _PlaceholderScreen(
                              title: 'Saint Art',
                              params: {
                                'saintId':
                                    state.pathParameters['saintId'] ??
                                        '',
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Catechism
                  GoRoute(
                    path: 'catechism',
                    name: 'catechism-list',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Catechism'),
                    routes: [
                      GoRoute(
                        path: ':topicId',
                        name: 'catechism-topic',
                        builder: (context, state) => _PlaceholderScreen(
                          title: 'Catechism Topic',
                          params: {
                            'topicId':
                                state.pathParameters['topicId'] ?? '',
                          },
                        ),
                      ),
                    ],
                  ),

                  // Bible
                  GoRoute(
                    path: 'bible',
                    name: 'bible-explorer',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Bible Explorer'),
                    routes: [
                      GoRoute(
                        path: ':bookId',
                        name: 'bible-book',
                        builder: (context, state) => _PlaceholderScreen(
                          title: 'Bible Book',
                          params: {
                            'bookId':
                                state.pathParameters['bookId'] ?? '',
                          },
                        ),
                      ),
                    ],
                  ),

                  // AI Chat
                  GoRoute(
                    path: 'chat',
                    name: 'ai-chat',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'AI Chat'),
                  ),

                  // Liturgical Calendar
                  GoRoute(
                    path: 'calendar',
                    name: 'liturgical-calendar',
                    builder: (context, state) => const _PlaceholderScreen(
                        title: 'Liturgical Calendar'),
                  ),

                  // World Anvil Wiki
                  GoRoute(
                    path: 'wiki',
                    name: 'world-anvil-wiki',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Kingdom Wiki'),
                    routes: [
                      GoRoute(
                        path: ':articleId',
                        name: 'world-anvil-article',
                        builder: (context, state) => _PlaceholderScreen(
                          title: 'Wiki Article',
                          params: {
                            'articleId':
                                state.pathParameters['articleId'] ?? '',
                          },
                        ),
                      ),
                    ],
                  ),

                  // Craft Canvas
                  GoRoute(
                    path: 'craft',
                    name: 'craft-canvas',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Craft Canvas'),
                    routes: [
                      GoRoute(
                        path: 'gallery',
                        name: 'craft-gallery',
                        builder: (context, state) => const _PlaceholderScreen(
                            title: 'Craft Gallery'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // ── Tab 5: Profile ────────────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.profile,
                name: 'profile',
                builder: (context, state) => const _ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'profile-edit',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Edit Profile'),
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
                        builder: (context, state) =>
                            const _PlaceholderScreen(
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
                                state.pathParameters['achievementId'] ??
                                    '',
                          },
                        ),
                      ),
                    ],
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
                        builder: (context, state) => const _PlaceholderScreen(
                            title: 'Theme Settings'),
                      ),
                      GoRoute(
                        path: 'privacy',
                        name: 'privacy-settings',
                        builder: (context, state) => const _PlaceholderScreen(
                            title: 'Privacy Settings'),
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
                        builder: (context, state) => const _PlaceholderScreen(
                            title: 'Activity Report'),
                      ),
                    ],
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

      // ── 404 ────────────────────────────────────────────────────────────────
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
