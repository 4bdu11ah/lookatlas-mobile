import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_spacing.dart';
import 'package:look_atlas/core/theme/app_typography.dart';

/// Semantic tone of an [AppSnackBar]. Picks the leading icon and its accent
/// color; the bar itself stays monochrome (inverse surface) in every tone.
enum AppSnackBarVariant { info, success, error }

/// The app-wide snackbar: an inverse-surface floating bar with square corners
/// and a semantic leading icon, matching the monochrome design system.
///
/// Always use this instead of constructing a raw [SnackBar]:
///
/// ```dart
/// AppSnackBar.show(context, 'Profile updated.');
/// AppSnackBar.showSuccess(context, 'Purchases restored.');
/// AppSnackBar.showError(context, failure.message);
/// ```
///
/// Showing a new bar replaces any bar currently on screen, so stale messages
/// never queue up behind fresh ones.
abstract final class AppSnackBar {
  static void show(
    BuildContext context,
    String message, {
    AppSnackBarVariant variant = AppSnackBarVariant.info,
    SnackBarAction? action,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, iconColor) = switch (variant) {
      AppSnackBarVariant.info => (
        Icons.info_outline_rounded,
        scheme.onInverseSurface,
      ),
      AppSnackBarVariant.success => (
        Icons.check_circle_rounded,
        AppColors.success,
      ),
      AppSnackBarVariant.error => (Icons.error_rounded, AppColors.danger),
    };

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: scheme.inverseSurface,
          margin: const EdgeInsets.all(AppSpacing.md),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + AppSpacing.xs,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radius),
          ),
          action: action,
          content: Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: scheme.onInverseSurface,
                    fontSize: 14,
                    fontWeight: AppTypography.medium,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) => show(
    context,
    message,
    variant: AppSnackBarVariant.success,
    action: action,
  );

  static void showError(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) =>
      show(context, message, variant: AppSnackBarVariant.error, action: action);
}
