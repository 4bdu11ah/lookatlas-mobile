import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_spacing.dart';
import 'package:look_atlas/core/theme/app_typography.dart';

/// Centralized Material 3 theming for the Look Atlas monochrome design system.
///
/// The palette is defined explicitly (not seed-derived) so the app matches the
/// mockups exactly: near-black on white, `#F5F5F5` fills, `#E5E5E5` borders and
/// sharp, square corners throughout.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  /// Light: near-black foreground on white. This is the primary look shown in
  /// the mockups.
  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.black,
    onPrimary: AppColors.white,
    secondary: AppColors.neutral100,
    onSecondary: AppColors.black,
    surface: AppColors.white,
    onSurface: AppColors.black,
    // Card / input fills map to the muted `#F5F5F5` token.
    surfaceContainerHighest: AppColors.neutral100,
    surfaceContainerHigh: AppColors.neutral100,
    surfaceContainer: AppColors.neutral50,
    onSurfaceVariant: AppColors.neutral500, // muted-foreground
    outline: AppColors.neutral200, // border / input
    outlineVariant: AppColors.neutral200,
    error: AppColors.danger,
    onError: AppColors.white,
  );

  /// Dark: inverted monochrome, matching the mockup gallery chrome.
  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.neutral50,
    onPrimary: AppColors.black,
    secondary: AppColors.neutral900,
    onSecondary: AppColors.neutral50,
    surface: AppColors.black,
    onSurface: AppColors.neutral50,
    surfaceContainerHighest: AppColors.neutral900,
    surfaceContainerHigh: AppColors.neutral900,
    surfaceContainer: AppColors.neutral900,
    onSurfaceVariant: AppColors.neutral400,
    outline: AppColors.neutral800,
    outlineVariant: AppColors.neutral800,
    error: AppColors.danger,
    onError: AppColors.white,
  );

  static ThemeData _build(Brightness brightness) {
    final scheme = brightness == Brightness.dark ? _darkScheme : _lightScheme;

    // Sharp, square corners everywhere.
    final squareShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radius),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      textTheme: AppTypography.textTheme(brightness),
    );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: squareShape,
          textStyle: const TextStyle(
            fontFamily: AppTypography.bodyFontFamily,
            fontWeight: AppTypography.semiBold,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: squareShape,
          side: BorderSide(color: scheme.outline),
          foregroundColor: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      // Defaults for the app-wide AppSnackBar (shared/widgets/app_snack_bar.dart)
      // and any raw SnackBar: inverse-surface floating bar, square corners.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(
          fontFamily: AppTypography.bodyFontFamily,
          color: scheme.onInverseSurface,
          fontSize: 14,
        ),
        shape: squareShape,
        elevation: 2,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          borderSide: BorderSide(color: scheme.onSurface, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
    );
  }
}
