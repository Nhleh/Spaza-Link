import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// SpazaLink Material 3 theme factory.
///
/// Two themes are produced — light (customer app, driver app) and dark (admin
/// dashboard). Both are constructed from the same brand tokens in [AppColors].
abstract final class AppTheme {
  // ── Light Theme (Customer + Driver apps) ───────────────────────────────────

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: _lightColorScheme,
        textTheme: AppTypography.textTheme,
        scaffoldBackgroundColor: AppColors.lightBackground,
        appBarTheme: _lightAppBarTheme,
        elevatedButtonTheme: _elevatedButtonTheme(_lightColorScheme),
        outlinedButtonTheme: _outlinedButtonTheme(_lightColorScheme),
        textButtonTheme: _textButtonTheme(_lightColorScheme),
        inputDecorationTheme: _inputDecorationTheme(_lightColorScheme),
        cardTheme: _cardTheme(_lightColorScheme),
        chipTheme: _chipTheme(_lightColorScheme),
        bottomNavigationBarTheme: _bottomNavTheme(_lightColorScheme),
        floatingActionButtonTheme: _fabTheme(_lightColorScheme),
        dividerTheme: const DividerThemeData(
          color: AppColors.lightOutline,
          thickness: 1,
          space: 1,
        ),
        snackBarTheme: _snackBarTheme,
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: AppColors.brandGreenPrimary,
        ),
        switchTheme: _switchTheme(_lightColorScheme),
        checkboxTheme: _checkboxTheme(_lightColorScheme),
        radioTheme: _radioTheme(_lightColorScheme),
      );

  // ── Dark Theme (Admin Dashboard) ───────────────────────────────────────────

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: _darkColorScheme,
        textTheme: AppTypography.textTheme,
        scaffoldBackgroundColor: AppColors.adminDarkBackground,
        appBarTheme: _darkAppBarTheme,
        elevatedButtonTheme: _elevatedButtonTheme(_darkColorScheme),
        outlinedButtonTheme: _outlinedButtonTheme(_darkColorScheme),
        textButtonTheme: _textButtonTheme(_darkColorScheme),
        inputDecorationTheme: _inputDecorationTheme(_darkColorScheme),
        cardTheme: _cardTheme(_darkColorScheme),
        chipTheme: _chipTheme(_darkColorScheme),
        bottomNavigationBarTheme: _bottomNavTheme(_darkColorScheme),
        floatingActionButtonTheme: _fabTheme(_darkColorScheme),
        dividerTheme: const DividerThemeData(
          color: AppColors.adminDarkOutline,
          thickness: 1,
          space: 1,
        ),
        snackBarTheme: _snackBarTheme,
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: AppColors.brandGreenLight,
        ),
        switchTheme: _switchTheme(_darkColorScheme),
        checkboxTheme: _checkboxTheme(_darkColorScheme),
        radioTheme: _radioTheme(_darkColorScheme),
      );

  // ── Color Schemes ──────────────────────────────────────────────────────────

  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.brandGreenPrimary,
    onPrimary: AppColors.white,
    primaryContainer: AppColors.brandGreenSurface,
    onPrimaryContainer: AppColors.brandGreenDark,
    secondary: AppColors.brandGold,
    onSecondary: AppColors.brandGreenDark,
    secondaryContainer: AppColors.brandGoldSurface,
    onSecondaryContainer: AppColors.brandGreenDark,
    tertiary: AppColors.brandGreenMedium,
    onTertiary: AppColors.white,
    tertiaryContainer: AppColors.brandGreenSurfaceLight,
    onTertiaryContainer: AppColors.brandGreenDark,
    error: AppColors.error,
    onError: AppColors.white,
    errorContainer: AppColors.errorLight,
    onErrorContainer: AppColors.error,
    surface: AppColors.lightSurface,
    onSurface: AppColors.lightOnSurface,
    surfaceContainerHighest: AppColors.lightSurfaceVariant,
    onSurfaceVariant: AppColors.lightOnSurfaceVariant,
    outline: AppColors.lightOutline,
    outlineVariant: AppColors.lightOutlineVariant,
    shadow: Color(0x1A000000),
    scrim: AppColors.lightScrim,
    inverseSurface: AppColors.lightOnSurface,
    onInverseSurface: AppColors.lightSurface,
    inversePrimary: AppColors.brandGreenLight,
    surfaceTint: AppColors.brandGreenPrimary,
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.brandGreenLight,
    onPrimary: Color(0xFF003300),
    primaryContainer: AppColors.brandGreenDark,
    onPrimaryContainer: AppColors.brandGreenSurface,
    secondary: AppColors.brandGold,
    onSecondary: Color(0xFF2A1A00),
    secondaryContainer: Color(0xFF3D2800),
    onSecondaryContainer: AppColors.brandGoldLight,
    tertiary: AppColors.brandGreenLight,
    onTertiary: Color(0xFF003300),
    tertiaryContainer: AppColors.brandGreenDark,
    onTertiaryContainer: AppColors.brandGreenSurface,
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: AppColors.adminDarkSurface,
    onSurface: AppColors.darkOnSurface,
    surfaceContainerHighest: AppColors.adminDarkSurfaceVariant,
    onSurfaceVariant: AppColors.darkOnSurfaceVariant,
    outline: AppColors.adminDarkOutline,
    outlineVariant: AppColors.darkOutline,
    shadow: Color(0x40000000),
    scrim: Color(0x800B1120),
    inverseSurface: AppColors.darkOnSurface,
    onInverseSurface: AppColors.adminDarkBackground,
    inversePrimary: AppColors.brandGreenPrimary,
    surfaceTint: AppColors.brandGreenLight,
  );

  // ── App Bars ───────────────────────────────────────────────────────────────

  static const AppBarTheme _lightAppBarTheme = AppBarTheme(
    backgroundColor: AppColors.brandGreenPrimary,
    foregroundColor: AppColors.white,
    elevation: 0,
    scrolledUnderElevation: 2,
    centerTitle: false,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
    iconTheme: IconThemeData(color: AppColors.white, size: 24),
    actionsIconTheme: IconThemeData(color: AppColors.white, size: 24),
    titleTextStyle: TextStyle(
      color: AppColors.white,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    ),
  );

  static const AppBarTheme _darkAppBarTheme = AppBarTheme(
    backgroundColor: AppColors.adminDarkSurface,
    foregroundColor: AppColors.darkOnSurface,
    elevation: 0,
    scrolledUnderElevation: 2,
    centerTitle: false,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
    iconTheme: IconThemeData(color: AppColors.darkOnSurface, size: 24),
    actionsIconTheme: IconThemeData(color: AppColors.darkOnSurface, size: 24),
    titleTextStyle: TextStyle(
      color: AppColors.darkOnSurface,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    ),
  );

  // ── Buttons ────────────────────────────────────────────────────────────────

  static ElevatedButtonThemeData _elevatedButtonTheme(ColorScheme cs) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.buttonPaddingH,
          ),
          textStyle: AppTypography.labelLarge.copyWith(fontSize: 15),
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonTheme(ColorScheme cs) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          side: BorderSide(color: cs.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.buttonPaddingH,
          ),
          textStyle: AppTypography.labelLarge.copyWith(fontSize: 15),
        ),
      );

  static TextButtonThemeData _textButtonTheme(ColorScheme cs) =>
      TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          textStyle: AppTypography.labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
      );

  // ── Input ──────────────────────────────────────────────────────────────────

  static InputDecorationTheme _inputDecorationTheme(ColorScheme cs) =>
      InputDecorationTheme(
        filled: true,
        fillColor: cs.brightness == Brightness.light
            ? AppColors.lightSurfaceVariant
            : AppColors.adminDarkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: BorderSide(
            color: cs.brightness == Brightness.light
                ? AppColors.lightOutline
                : AppColors.adminDarkOutline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: BorderSide(color: cs.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: BorderSide(color: cs.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.inputPaddingH,
          vertical: AppSpacing.inputPaddingV,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: cs.onSurfaceVariant,
        ),
        labelStyle: AppTypography.bodyMedium,
        floatingLabelStyle: TextStyle(
          color: cs.primary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        errorStyle: AppTypography.bodySmall.copyWith(color: cs.error),
      );

  // ── Cards ──────────────────────────────────────────────────────────────────

  static CardThemeData _cardTheme(ColorScheme cs) => CardThemeData(
        color: cs.brightness == Brightness.light
            ? AppColors.lightSurface
            : AppColors.adminDarkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          side: BorderSide(
            color: cs.brightness == Brightness.light
                ? AppColors.lightOutline
                : AppColors.adminDarkOutline,
          ),
        ),
        margin: EdgeInsets.zero,
      );

  // ── Chips ──────────────────────────────────────────────────────────────────

  static ChipThemeData _chipTheme(ColorScheme cs) => ChipThemeData(
        backgroundColor: cs.brightness == Brightness.light
            ? AppColors.lightSurfaceVariant
            : AppColors.adminDarkSurfaceVariant,
        selectedColor: cs.primaryContainer,
        labelStyle: AppTypography.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        side: BorderSide.none,
      );

  // ── Bottom Navigation ──────────────────────────────────────────────────────

  static BottomNavigationBarThemeData _bottomNavTheme(ColorScheme cs) =>
      BottomNavigationBarThemeData(
        backgroundColor: cs.brightness == Brightness.light
            ? AppColors.lightSurface
            : AppColors.adminDarkSurface,
        selectedItemColor: cs.primary,
        unselectedItemColor: cs.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTypography.labelSmall,
        unselectedLabelStyle: AppTypography.labelSmall,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      );

  // ── FAB ────────────────────────────────────────────────────────────────────

  static FloatingActionButtonThemeData _fabTheme(ColorScheme cs) =>
      FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        elevation: 2,
      );

  // ── Snack Bar ──────────────────────────────────────────────────────────────

  static const SnackBarThemeData _snackBarTheme = SnackBarThemeData(
    backgroundColor: AppColors.lightOnSurface,
    contentTextStyle: TextStyle(color: AppColors.white),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusMd)),
    ),
  );

  // ── Switch / Checkbox / Radio ──────────────────────────────────────────────

  static SwitchThemeData _switchTheme(ColorScheme cs) => SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cs.onPrimary;
          return cs.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cs.primary;
          return cs.surfaceContainerHighest;
        }),
      );

  static CheckboxThemeData _checkboxTheme(ColorScheme cs) => CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cs.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(cs.onPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        ),
      );

  static RadioThemeData _radioTheme(ColorScheme cs) => RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cs.primary;
          return cs.onSurfaceVariant;
        }),
      );
}
