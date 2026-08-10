import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/config/app_config.dart';
import 'package:look_atlas/core/constants/app_assets.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/features/auth/presentation/auth_controller.dart';
import 'package:look_atlas/shared/widgets/app_image.dart';

/// "or continue with" divider plus the Apple and Google sign-in buttons.
///
/// Shared by the sign-in AND sign-up screens (Apple review expects parity).
/// The Apple button only renders on Apple platforms, per
/// [AppConfig.isAppleSignInSupported]. Errors surface through the screens'
/// existing `ref.listen` snackbar handling; a dismissed sheet stays silent.
class SocialSignInButtons extends ConsumerWidget {
  const SocialSignInButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      authControllerProvider.select((s) => s.isLoading),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _OrDivider(),
        const SizedBox(height: 20),
        if (AppConfig.isAppleSignInSupported) ...[
          _AppleButton(
            onPressed: isLoading
                ? null
                : () => ref
                      .read(authControllerProvider.notifier)
                      .signInWithApple(),
          ),
          const SizedBox(height: 12),
        ],
        _GoogleButton(
          onPressed: isLoading
              ? null
              : () => ref
                    .read(authControllerProvider.notifier)
                    .signInWithGoogle(),
        ),
      ],
    );
  }
}

/// Horizontal rule with a centered "or continue with" label.
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(child: Divider(color: scheme.outlineVariant)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or continue with',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
        ),
        Expanded(child: Divider(color: scheme.outlineVariant)),
      ],
    );
  }
}

/// Apple HIG basics: black button with white content in light mode, inverted
/// in dark mode.
class _AppleButton extends StatelessWidget {
  const _AppleButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: isDark ? AppColors.white : AppColors.black,
        foregroundColor: isDark ? AppColors.black : AppColors.white,
      ),
      onPressed: onPressed,
      icon: const Icon(Icons.apple, size: 22),
      label: const Text(
        'Continue with Apple',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      onPressed: onPressed,
      // Official multicolor "G" per
      // https://developers.google.com/identity/branding-guidelines.
      icon: const AppImage(
        AppAssets.googleLogo,
        width: 18,
        height: 18,
      ),
      label: const Text(
        'Continue with Google',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
