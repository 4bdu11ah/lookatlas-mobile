import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/config/app_config.dart';
import 'package:look_atlas/core/constants/app_assets.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/auth/domain/validators/auth_validators.dart';
import 'package:look_atlas/features/auth/presentation/controllers/auth_controller.dart';
import 'package:look_atlas/features/auth/presentation/controllers/password_visibility_controller.dart';
import 'package:look_atlas/features/auth/presentation/controllers/sign_in_ui_controller.dart';
import 'package:look_atlas/features/auth/presentation/widgets/auth_turnstile.dart';
import 'package:look_atlas/features/auth/presentation/widgets/sign_up_brand_strip.dart';
import 'package:look_atlas/shared/widgets/app_image.dart';

/// Main off-white card containing the sign-in form, social buttons, and brand strip.
class SignInFormCard extends ConsumerWidget {
  const SignInFormCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.onSubmit,
    this.margin = const EdgeInsets.symmetric(horizontal: 6),
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      authControllerProvider.select((s) => s.isLoading),
    );
    final isPasswordVisible = ref.watch(signInPasswordVisibilityProvider);
    final captchaGen = ref.watch(signInCaptchaGenerationProvider);

    return Container(
      width: double.infinity,
      color: AppColors.surfaceOffWhite,
      margin: margin,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App Logo
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: const AppImage(
                  AppAssets.logo,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Title
            Text(
              'Welcome back',
              style: AppTypography.sfPro(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                height: 1.25,
                color: AppColors.darkSurface,
              ),
            ),
            const SizedBox(height: 10),
            // Subtitle
            Text(
              'Sign in to your account to continue',
              style: AppTypography.sfPro(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            // Social Auth Buttons
            if (AppConfig.isAppleSignInSupported) ...[
              _SocialAuthButton(
                onPressed: isLoading
                    ? null
                    : () => ref
                          .read(authControllerProvider.notifier)
                          .signInWithApple(),
                icon: const Icon(
                  Icons.apple,
                  size: 22,
                  color: AppColors.darkSurface,
                ),
                label: 'Continue with Apple',
              ),
              const SizedBox(height: 12),
            ],
            _SocialAuthButton(
              onPressed: isLoading
                  ? null
                  : () => ref
                        .read(authControllerProvider.notifier)
                        .signInWithGoogle(),
              icon: const AppImage(
                AppAssets.googleLogo,
                width: 20,
                height: 20,
              ),
              label: 'Continue with Google',
            ),
            const SizedBox(height: 20),
            // Divider "or continue with"
            const _OrDivider(),
            const SizedBox(height: 20),
            // Email Field
            const _FieldLabel('Email address'),
            const SizedBox(height: 6),
            TextFormField(
              controller: emailController,
              style: AppTypography.sfPro(
                fontSize: 15,
                color: AppColors.darkSurface,
              ),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              validator: AuthValidators.validateEmail,
              decoration: _inputDecoration('you@company.com'),
            ),
            const SizedBox(height: 16),
            // Password Field
            const _FieldLabel('Password'),
            const SizedBox(height: 6),
            TextFormField(
              controller: passwordController,
              style: AppTypography.sfPro(
                fontSize: 15,
                color: AppColors.darkSurface,
              ),
              obscureText: !isPasswordVisible,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onSubmit(),
              validator: AuthValidators.validatePassword,
              decoration: _inputDecoration(
                'Enter your password',
                suffixIcon: IconButton(
                  tooltip: isPasswordVisible
                      ? 'Hide password'
                      : 'Show password',
                  onPressed: ref
                      .read(signInPasswordVisibilityProvider.notifier)
                      .toggle,
                  icon: Icon(
                    isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Forgot Password Link
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => context.push(AppRoutes.resetPassword),
                child: Text(
                  'Forgot password?',
                  style: AppTypography.sfPro(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Turnstile CAPTCHA
            AuthTurnstile(
              key: ValueKey(captchaGen),
              action: AuthTurnstileAction.login,
              onTokenChanged: (token) => ref
                  .read(signInTurnstileTokenProvider.notifier)
                  .setToken(token),
            ),
            const SizedBox(height: 20),
            // Primary CTA Button
            _PrimarySignInButton(
              isLoading: isLoading,
              onPressed: onSubmit,
            ),
            const SizedBox(height: 36),
            // Brand Proof & Footer Link
            SignUpBrandStrip(
              promptText: "Don't have an account? ",
              actionText: 'Create account',
              onActionTap: () => context.push(AppRoutes.signUp),
            ),
          ],
        ),
      ),
    );
  }

  static InputDecoration _inputDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.sfPro(
        fontSize: 15,
        color: AppColors.textPlaceholder,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.darkSurface, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.sfPro(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _SocialAuthButton extends StatelessWidget {
  const _SocialAuthButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.borderLight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.sfPro(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.darkSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: AppColors.borderLight, thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or continue with',
            style: AppTypography.sfPro(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPlaceholder,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: AppColors.borderLight, thickness: 1),
        ),
      ],
    );
  }
}

class _PrimarySignInButton extends StatelessWidget {
  const _PrimarySignInButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        elevation: 0,
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sign in',
                  style: AppTypography.sfPro(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
              ],
            ),
    );
  }
}
