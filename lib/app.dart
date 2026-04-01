import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kingdomcome/core/theme/app_theme.dart';
import 'package:kingdomcome/routing/app_router.dart';

/// Root application widget.
///
/// Wraps the app in [MaterialApp.router] with [GoRouter], the Kingdom Come
/// medieval theme, and Riverpod-driven theme-mode switching.
class KingdomComeApp extends ConsumerWidget {
  const KingdomComeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Kingdom Come',
      debugShowCheckedModeBanner: false,

      // Themes
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // Navigation
      routerConfig: router,

      // Localisation (English only for MVP; placeholder for i18n expansion)
      supportedLocales: const [Locale('en', 'US')],
      locale: const Locale('en', 'US'),
    );
  }
}

/// Provider for the app-wide theme mode (light / dark / system).
///
/// Persists preference via [SharedPreferences] in a real implementation;
/// defaults to system for first launch.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
