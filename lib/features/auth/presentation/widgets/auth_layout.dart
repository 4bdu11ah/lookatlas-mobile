import 'package:flutter/material.dart';
import 'package:look_atlas/core/constants/app_assets.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/shared/widgets/bar_spinner.dart';

/// Shared building blocks for the auth screens (sign in, sign up, reset
/// password). They mirror the mockup design system exactly: centered brand
/// lockup, a monochrome heading block, square-cornered CTA and inline footer
/// links.

/// The logo mark + "Look Atlas" wordmark, matching the mockup header.
class AuthBrand extends StatelessWidget {
  const AuthBrand({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.logo,
      height: 60,
      width: 60,
      fit: BoxFit.cover,
    );
  }
}

/// Full-screen centered auth layout: brand, title, subtitle then [child] form.
/// Scrolls when the keyboard opens and caps content width like the mockup's
/// `max-w-md` column.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header block (mockup: text-center mb-10)
                  const Center(child: AuthBrand()),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 30,
                      fontWeight: AppTypography.bold,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 40),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width, 48px-tall primary CTA with a built-in loading spinner.
class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      onPressed: isLoading ? null : onPressed,
      child: isLoading ? const ButtonLoader() : Text(label),
    );
  }
}

/// Underlined inline text link rendered as a real [TextButton], so it gets a
/// 48px tap target, ink feedback and button semantics — unlike a bare
/// `GestureDetector` over a `Text`.
class AuthTextLink extends StatelessWidget {
  const AuthTextLink({
    required this.label,
    required this.onPressed,
    this.fontSize = 14,
    this.fontWeight = AppTypography.semiBold,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final double fontSize;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        foregroundColor: scheme.onSurface,
        textStyle: TextStyle(fontSize: fontSize, fontWeight: fontWeight),
      ),
      child: Text(
        label,
        style: TextStyle(
          decoration: TextDecoration.underline,
          decorationColor: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Centered "prompt + tappable action" line used at the foot of each form,
/// e.g. "Don't have an account? Create account".
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    required this.prompt,
    required this.action,
    required this.onTap,
    super.key,
  });

  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '$prompt ',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
        ),
        AuthTextLink(label: action, onPressed: onTap),
      ],
    );
  }
}
