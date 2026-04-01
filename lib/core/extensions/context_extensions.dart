import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kingdomcome/core/theme/liturgical_colors.dart';
import 'package:kingdomcome/core/utils/liturgical_calendar.dart';

/// Convenience extensions on [BuildContext].
///
/// Import this file to get shorthand access to theme, media query, navigation,
/// snack bars, and the current liturgical season.
extension ContextThemeExtension on BuildContext {
  // ── Theme ─────────────────────────────────────────────────────────────────

  /// The current [ThemeData].
  ThemeData get theme => Theme.of(this);

  /// The current [ColorScheme].
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// The current [TextTheme].
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// True when the app is in dark mode.
  bool get isDark =>
      Theme.of(this).brightness == Brightness.dark;

  // ── MediaQuery ────────────────────────────────────────────────────────────

  /// The current [MediaQueryData].
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Screen width in logical pixels.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Screen height in logical pixels.
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// The system top padding (status bar height).
  double get topPadding => MediaQuery.paddingOf(this).top;

  /// The system bottom padding (home indicator / nav bar height).
  double get bottomPadding => MediaQuery.paddingOf(this).bottom;

  /// True when the device is in landscape orientation.
  bool get isLandscape =>
      MediaQuery.orientationOf(this) == Orientation.landscape;

  /// True when the device is considered a tablet (width ≥ 600 dp).
  bool get isTablet => MediaQuery.sizeOf(this).width >= 600;

  // ── Navigation ────────────────────────────────────────────────────────────

  /// Pops the current route.
  void pop<T>([T? result]) => Navigator.of(this).pop(result);

  /// Returns true if the navigator can pop.
  bool get canPop => Navigator.of(this).canPop();

  // ── SnackBar ──────────────────────────────────────────────────────────────

  /// Shows a [SnackBar] with [message].
  ///
  /// Optionally provide an [action] label and [onAction] callback.
  void showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
    bool isError = false,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(this).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
        ),
        duration: duration,
        backgroundColor: isError
            ? Theme.of(this).colorScheme.error
            : null,
        action: (actionLabel != null && onAction != null)
            ? SnackBarAction(
                label: actionLabel,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  /// Shows an error [SnackBar] with a red background.
  void showErrorSnackBar(String message) =>
      showSnackBar(message, isError: true);

  // ── Liturgical season ─────────────────────────────────────────────────────

  /// Returns the current [LiturgicalSeason] for today.
  ///
  /// Note: this computes from the calendar on every access. For reactive
  /// updates, prefer using the Riverpod liturgicalSeasonProvider.
  LiturgicalSeason get liturgicalSeason =>
      LiturgicalCalendar.currentSeason;

  /// Returns the primary colour for the current liturgical season.
  Color get liturgicalPrimaryColor =>
      LiturgicalColors.primaryFor(liturgicalSeason);

  /// Returns the accent colour for the current liturgical season.
  Color get liturgicalAccentColor =>
      LiturgicalColors.accentFor(liturgicalSeason);

  // ── GoRouter ──────────────────────────────────────────────────────────────

  /// Navigates to [location] using GoRouter.
  void go(String location, {Object? extra}) =>
      GoRouter.of(this).go(location, extra: extra);

  /// Pushes [location] onto the navigation stack.
  Future<T?> push<T>(String location, {Object? extra}) =>
      GoRouter.of(this).push<T>(location, extra: extra);

  /// Replaces the current route with [location].
  void replace(String location, {Object? extra}) =>
      GoRouter.of(this).replace(location, extra: extra);
}

/// Extension that adds a [ProviderScope] lookup helper.
///
/// Useful in widgets that need a [ProviderContainer] reference.
extension ContextRiverpodExtension on BuildContext {
  /// Returns the [ProviderContainer] scoped to this widget subtree.
  ///
  /// Prefer using [ConsumerWidget] or [Consumer] over direct container access.
  ProviderContainer get container =>
      ProviderScope.containerOf(this);
}
