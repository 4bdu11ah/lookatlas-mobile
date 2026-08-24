import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/auth/domain/validators/auth_validators.dart';
import 'package:look_atlas/features/auth/presentation/auth_controller.dart';
import 'package:look_atlas/features/auth/presentation/password_visibility_controller.dart';
import 'package:look_atlas/features/auth/presentation/widgets/auth_layout.dart';
import 'package:look_atlas/features/auth/presentation/widgets/auth_turnstile.dart';
import 'package:look_atlas/features/auth/presentation/widgets/social_sign_in_buttons.dart';
import 'package:look_atlas/shared/widgets/app_snack_bar.dart';
import 'package:look_atlas/shared/widgets/app_text_field.dart';

/// Login screen — mirrors `login.html` (brand, email + password, forgot
/// password link, sign in CTA, create-account footer).
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _captchaToken;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final captchaToken = _captchaToken;
    if (captchaToken == null || captchaToken.isEmpty) {
      AppSnackBar.showError(
        context,
        'Complete the security check before continuing.',
      );
      return;
    }
    await ref
        .read(authControllerProvider.notifier)
        .signIn(
          _emailController.text.trim(),
          _passwordController.text,
          captchaToken: captchaToken,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (_, next) {
      // Other auth screens can be stacked on top of this one and share the
      // controller; only the visible screen shows the error snackbar.
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
      if (next case AsyncError(:final error)) {
        final message = error is Failure
            ? error.message
            : 'Something went wrong.';
        AppSnackBar.showError(context, message);
      }
    });

    final isLoading = ref.watch(
      authControllerProvider.select((s) => s.isLoading),
    );
    final isPasswordVisible = ref.watch(signInPasswordVisibilityProvider);

    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to your account to continue',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              labelText: 'Email address',
              controller: _emailController,
              hintText: 'you@company.com',
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              validator: AuthValidators.validateEmail,
            ),
            const SizedBox(height: 20),
            AppTextField(
              labelText: 'Password',
              controller: _passwordController,
              hintText: 'Enter your password',
              autofillHints: const [AutofillHints.password],
              obscureText: !isPasswordVisible,
              trailing: IconButton(
                tooltip: isPasswordVisible ? 'Hide password' : 'Show password',
                onPressed: ref
                    .read(signInPasswordVisibilityProvider.notifier)
                    .toggle,
                icon: Icon(
                  isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: AuthValidators.validatePassword,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: AuthTextLink(
                label: 'Forgot password?',
                fontWeight: AppTypography.medium,
                onPressed: () => context.push(AppRoutes.resetPassword),
              ),
            ),
            const SizedBox(height: 20),
            AuthTurnstile(onTokenChanged: (token) => _captchaToken = token),
            const SizedBox(height: 20),
            AuthSubmitButton(
              label: 'Sign in',
              isLoading: isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 20),
            const SocialSignInButtons(),
            const SizedBox(height: 20),
            AuthFooterLink(
              prompt: "Don't have an account?",
              action: 'Create account',
              onTap: () => context.push(AppRoutes.signUp),
            ),
          ],
        ),
      ),
    );
  }
}
