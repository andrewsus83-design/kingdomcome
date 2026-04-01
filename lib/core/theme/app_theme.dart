import 'package:flutter/material.dart';

import 'package:kingdomcome/core/constants/app_colors.dart';
import 'package:kingdomcome/core/constants/app_text_styles.dart';
import 'package:kingdomcome/core/constants/app_spacing.dart';

/// Kingdom Come — Full [ThemeData] for light and dark modes.
///
/// The medieval aesthetic uses:
///  - Deep purple / gold as primary brand colours
///  - Ivory / parchment surfaces in light mode
///  - Dark stone / indigo surfaces in dark mode
///  - Cinzel font for all headline slots
abstract final class AppTheme {
  // ── Shared colour scheme seeds ────────────────────────────────────────────

  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.deepPurple,
    onPrimary: AppColors.white,
    primaryContainer: AppColors.purpleLight,
    onPrimaryContainer: AppColors.white,
    secondary: AppColors.gold,
    onSecondary: AppColors.inkBlack,
    secondaryContainer: AppColors.goldLight,
    onSecondaryContainer: AppColors.inkBlack,
    tertiary: AppColors.forestGreen,
    onTertiary: AppColors.white,
    tertiaryContainer: AppColors.sage,
    onTertiaryContainer: AppColors.inkBlack,
    error: AppColors.red,
    onError: AppColors.white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: AppColors.ivory,
    onSurface: AppColors.inkBlack,
    surfaceContainerHighest: AppColors.parchment,
    onSurfaceVariant: AppColors.warmGrey,
    outline: AppColors.parchmentDark,
    outlineVariant: AppColors.lightGrey,
    shadow: Color(0x33000000),
    scrim: Color(0x80000000),
    inverseSurface: AppColors.purpleDark,
    onInverseSurface: AppColors.ivory,
    inversePrimary: AppColors.goldLight,
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.purpleLight,
    onPrimary: AppColors.white,
    primaryContainer: AppColors.deepPurple,
    onPrimaryContainer: AppColors.goldLight,
    secondary: AppColors.gold,
    onSecondary: AppColors.inkBlack,
    secondaryContainer: AppColors.goldDark,
    onSecondaryContainer: AppColors.goldLight,
    tertiary: AppColors.sage,
    onTertiary: AppColors.inkBlack,
    tertiaryContainer: AppColors.deepGreen,
    onTertiaryContainer: AppColors.sage,
    error: AppColors.red,
    onError: AppColors.inkBlack,
    errorContainer: AppColors.burgundy,
    onErrorContainer: Color(0xFFFFDAD6),
    surface: AppColors.darkSurface,
    onSurface: AppColors.ivory,
    surfaceContainerHighest: AppColors.darkCard,
    onSurfaceVariant: AppColors.parchmentDark,
    outline: AppColors.darkElevated,
    outlineVariant: AppColors.warmGrey,
    shadow: Color(0x66000000),
    scrim: Color(0xAA000000),
    inverseSurface: AppColors.ivory,
    onInverseSurface: AppColors.inkBlack,
    inversePrimary: AppColors.deepPurple,
  );

  // ── Light theme ───────────────────────────────────────────────────────────

  static ThemeData get lightTheme => _build(_lightColorScheme);

  // ── Dark theme ────────────────────────────────────────────────────────────

  static ThemeData get darkTheme => _build(_darkColorScheme);

  // ── Builder ───────────────────────────────────────────────────────────────

  static ThemeData _build(ColorScheme scheme) {
    final isLight = scheme.brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: 'Cinzel', // Overridden per-widget via TextTheme

      // ── Text theme ────────────────────────────────────────────────────────
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(
          color: scheme.onSurface,
        ),
        displayMedium: AppTextStyles.displayMedium.copyWith(
          color: scheme.onSurface,
        ),
        displaySmall: AppTextStyles.displaySmall.copyWith(
          color: scheme.onSurface,
        ),
        headlineLarge: AppTextStyles.headlineLarge.copyWith(
          color: scheme.onSurface,
        ),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(
          color: scheme.onSurface,
        ),
        headlineSmall: AppTextStyles.headlineSmall.copyWith(
          color: scheme.onSurface,
        ),
        titleLarge: AppTextStyles.titleLarge.copyWith(
          color: scheme.onSurface,
        ),
        titleMedium: AppTextStyles.titleMedium.copyWith(
          color: scheme.onSurface,
        ),
        titleSmall: AppTextStyles.titleSmall.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(
          color: scheme.onSurface,
        ),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(
          color: scheme.onSurface,
        ),
        bodySmall: AppTextStyles.bodySmall.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        labelLarge: AppTextStyles.labelLarge.copyWith(
          color: scheme.onSurface,
        ),
        labelMedium: AppTextStyles.labelMedium.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        labelSmall: AppTextStyles.labelSmall.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),

      // ── App bar ───────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 4,
        shadowColor: scheme.shadow,
        centerTitle: true,
        titleTextStyle: AppTextStyles.headlineMedium.copyWith(
          color: scheme.onPrimary,
          letterSpacing: 1.2,
        ),
        iconTheme: IconThemeData(color: scheme.onPrimary, size: AppSpacing.iconMd),
        actionsIconTheme:
            IconThemeData(color: scheme.onPrimary, size: AppSpacing.iconMd),
        surfaceTintColor: Colors.transparent,
      ),

      // ── Card ──────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: isLight ? AppColors.parchment : AppColors.darkCard,
        shadowColor: scheme.shadow,
        elevation: 3,
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          side: BorderSide(
            color: isLight ? AppColors.parchmentDark : AppColors.darkElevated,
          ),
        ),
      ),

      // ── Elevated button ───────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 4,
          shadowColor: scheme.shadow,
          padding: AppSpacing.buttonPaddingH,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          textStyle: AppTextStyles.buttonPrimary,
        ),
      ),

      // ── Outlined button ───────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary, width: 1.5),
          padding: AppSpacing.buttonPaddingH,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          textStyle: AppTextStyles.buttonSecondary,
        ),
      ),

      // ── Text button ───────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          textStyle: AppTextStyles.buttonSecondary,
        ),
      ),

      // ── Filled button ─────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.secondary,
          foregroundColor: scheme.onSecondary,
          padding: AppSpacing.buttonPaddingH,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          textStyle: AppTextStyles.buttonPrimary.copyWith(
            color: scheme.onSecondary,
          ),
        ),
      ),

      // ── Input decoration ──────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? AppColors.white : AppColors.darkElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 4,
        ),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        labelStyle: AppTextStyles.labelMedium.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        floatingLabelStyle: AppTextStyles.labelMedium.copyWith(
          color: scheme.primary,
        ),
      ),

      // ── Chip ─────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor:
            isLight ? AppColors.parchment : AppColors.darkElevated,
        selectedColor: scheme.primaryContainer,
        labelStyle: AppTextStyles.labelMedium.copyWith(
          color: scheme.onSurface,
        ),
        padding: AppSpacing.chipPadding,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          side: BorderSide(color: scheme.outline),
        ),
        side: BorderSide(color: scheme.outline),
      ),

      // ── Bottom navigation bar ─────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isLight ? AppColors.ivory : AppColors.darkCard,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTextStyles.labelSmall,
        unselectedLabelStyle: AppTextStyles.labelSmall,
      ),

      // ── Navigation bar (Material 3) ────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isLight ? AppColors.ivory : AppColors.darkCard,
        indicatorColor: scheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: scheme.onPrimaryContainer);
          }
          return IconThemeData(color: scheme.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.labelSmall.copyWith(color: scheme.primary);
          }
          return AppTextStyles.labelSmall
              .copyWith(color: scheme.onSurfaceVariant);
        }),
        elevation: 8,
        shadowColor: scheme.shadow,
      ),

      // ── Dialog ────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor:
            isLight ? AppColors.ivory : AppColors.darkElevated,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
        ),
        elevation: 8,
        shadowColor: scheme.shadow,
        titleTextStyle: AppTextStyles.headlineMedium.copyWith(
          color: scheme.onSurface,
        ),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: scheme.onSurface,
        ),
      ),

      // ── Bottom sheet ──────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor:
            isLight ? AppColors.ivory : AppColors.darkElevated,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        elevation: 8,
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
      ),

      // ── Snack bar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            isLight ? AppColors.inkBlack : AppColors.darkElevated,
        contentTextStyle:
            AppTextStyles.bodyMedium.copyWith(color: AppColors.ivory),
        actionTextColor: AppColors.gold,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // ── List tile ─────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: scheme.primaryContainer.withAlpha(77),
        contentPadding: AppSpacing.listItemPadding,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        titleTextStyle: AppTextStyles.titleMedium.copyWith(
          color: scheme.onSurface,
        ),
        subtitleTextStyle: AppTextStyles.bodySmall.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),

      // ── Progress indicator ────────────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.outlineVariant,
        circularTrackColor: scheme.outlineVariant,
      ),

      // ── Switch ────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primaryContainer;
          }
          return scheme.outlineVariant;
        }),
      ),

      // ── Tab bar ───────────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: AppTextStyles.labelLarge,
        unselectedLabelStyle: AppTextStyles.labelMedium,
      ),
    );
  }
}
