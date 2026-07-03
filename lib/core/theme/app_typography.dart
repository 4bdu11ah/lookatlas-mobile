import 'package:flutter/material.dart';

/// Centralized typography. All font families, weights and text styles live here
/// so the whole app draws from one type scale and rebranding the font is a
/// one-line change.
///
/// ## Wiring up custom fonts
/// The families below default to `null`, which means the platform system font
/// (San Francisco on iOS, Roboto on Android). To ship bundled fonts, drop the
/// `.ttf`/`.otf` files under `assets/fonts/` and declare them in `pubspec.yaml`:
///
/// ```yaml
/// flutter:
///   fonts:
///     - family: Inter
///       fonts:
///         - asset: assets/fonts/Inter-Regular.ttf
///         - asset: assets/fonts/Inter-Medium.ttf
///           weight: 500
///         - asset: assets/fonts/Inter-SemiBold.ttf
///           weight: 600
///         - asset: assets/fonts/Inter-Bold.ttf
///           weight: 700
///     - family: Sora
///       fonts:
///         - asset: assets/fonts/Sora-SemiBold.ttf
///           weight: 600
///         - asset: assets/fonts/Sora-Bold.ttf
///           weight: 700
/// ```
///
/// Then set [bodyFontFamily] to `'Inter'` and [displayFontFamily] to `'Sora'`.
/// Nothing else in the app needs to change.
abstract final class AppTypography {
  // --- Font families -------------------------------------------------------
  // Multiple fonts are supported: [displayFontFamily] is used for large,
  // expressive text (display/headline/title) while [bodyFontFamily] is used for
  // reading text (body/label). Point both at the same family for a single-font
  // design. `null` == system default.

  /// Font for headings and large, expressive text.
  static const String displayFontFamily = 'Satoshi';

  /// Font for body copy, labels and UI chrome.
  static const String bodyFontFamily = 'Satoshi';

  /// Optional monospace family for code, numbers or tabular data.
  static const String? monospaceFontFamily = null;

  // --- Weights -------------------------------------------------------------
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  // Satoshi is bundled at 400/500/700/900 only, so "semi-bold" maps to the
  // real w700 face instead of a per-platform synthesized w600.
  static const FontWeight semiBold = FontWeight.w700;
  static const FontWeight bold = FontWeight.w700;

  /// Builds the Material 3 [TextTheme] for the given [brightness].
  ///
  /// Colors are applied by [ThemeData] from the active `ColorScheme`, so styles
  /// here only define size, weight, spacing and family.
  static TextTheme textTheme(Brightness brightness) {
    return TextTheme(
      // Display — hero text, splash/marketing screens.
      displayLarge: _display(57, height: 1.12, spacing: -0.25),
      displayMedium: _display(45, height: 1.16),
      displaySmall: _display(36, height: 1.22),

      // Headline — section headers.
      headlineLarge: _display(32, height: 1.25),
      headlineMedium: _display(28, height: 1.29),
      headlineSmall: _display(24, height: 1.33),

      // Title — app bars, dialogs, card titles.
      titleLarge: _display(22, height: 1.27, weight: semiBold),
      titleMedium: _body(16, height: 1.5, weight: semiBold, spacing: 0.15),
      titleSmall: _body(14, height: 1.43, weight: medium, spacing: 0.1),

      // Body — the bulk of on-screen reading text.
      bodyLarge: _body(16, height: 1.5, spacing: 0.5),
      bodyMedium: _body(14, height: 1.43, spacing: 0.25),
      bodySmall: _body(12, height: 1.33, spacing: 0.4),

      // Label — buttons, chips, captions.
      labelLarge: _body(14, height: 1.43, weight: medium, spacing: 0.1),
      labelMedium: _body(12, height: 1.33, weight: medium, spacing: 0.5),
      labelSmall: _body(11, height: 1.45, weight: medium, spacing: 0.5),
    );
  }

  /// A monospace style, handy for code snippets or tabular numbers.
  static TextStyle mono({
    double fontSize = 14,
    FontWeight weight = regular,
    double height = 1.5,
  }) {
    return TextStyle(
      // ignore: avoid_redundant_argument_values, family is null until a custom font is wired up
      fontFamily: monospaceFontFamily,
      fontFamilyFallback: const ['monospace'],
      fontSize: fontSize,
      fontWeight: weight,
      height: height,
    );
  }

  // --- Internal builders ---------------------------------------------------
  static TextStyle _display(
    double size, {
    double height = 1.2,
    FontWeight weight = regular,
    double spacing = 0,
  }) {
    return TextStyle(
      fontFamily: displayFontFamily,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: spacing,
    );
  }

  static TextStyle _body(
    double size, {
    double height = 1.4,
    FontWeight weight = regular,
    double spacing = 0,
  }) {
    return TextStyle(
      fontFamily: bodyFontFamily,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: spacing,
    );
  }
}
