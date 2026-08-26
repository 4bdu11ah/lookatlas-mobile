import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/features/auth/domain/validators/auth_validators.dart';
import 'package:look_atlas/features/auth/presentation/auth_controller.dart';
import 'package:look_atlas/features/auth/presentation/password_visibility_controller.dart';
import 'package:look_atlas/features/auth/presentation/widgets/auth_layout.dart';
import 'package:look_atlas/features/auth/presentation/widgets/auth_turnstile.dart';
import 'package:look_atlas/features/auth/presentation/widgets/social_sign_in_buttons.dart';
import 'package:look_atlas/shared/widgets/app_snack_bar.dart';
import 'package:look_atlas/shared/widgets/app_text_field.dart';

/// Create-account screen — mirrors `signup.html` (email, password with helper,
/// create CTA, terms line, sign-in footer).
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _captchaToken;
  int _captchaGeneration = 0;

  @override
  void dispose() {
    _companyNameController.dispose();
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
    try {
      await ref
          .read(authControllerProvider.notifier)
          .signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            companyName: _companyNameController.text.trim(),
            captchaToken: captchaToken,
          );
    } finally {
      _resetCaptcha();
    }
  }

  void _resetCaptcha() {
    if (!mounted) return;
    setState(() {
      _captchaToken = null;
      _captchaGeneration++;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (_, next) {
      // This screen is pushed over SignIn and both share the controller;
      // only the visible screen shows the error snackbar.
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
    final scheme = Theme.of(context).colorScheme;
    final isPasswordVisible = ref.watch(signUpPasswordVisibilityProvider);

    return AuthScaffold(
      title: 'Create your account',
      subtitle: 'Start creating stunning product photos with AI',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              labelText: 'Company name',
              controller: _companyNameController,
              hintText: 'Your company',
              autofillHints: const [AutofillHints.organizationName],
              textInputAction: TextInputAction.next,
              validator: AuthValidators.validateCompanyName,
            ),
            const SizedBox(height: 20),
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
              hintText: 'Create a strong password',
              helperText:
                  'Must be at least '
                  '${AuthValidators.minPasswordLength} characters long',
              autofillHints: const [AutofillHints.newPassword],
              obscureText: !isPasswordVisible,
              trailing: IconButton(
                tooltip: isPasswordVisible ? 'Hide password' : 'Show password',
                onPressed: ref
                    .read(signUpPasswordVisibilityProvider.notifier)
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
            const SizedBox(height: 20),
            AuthTurnstile(
              key: ValueKey(_captchaGeneration),
              action: AuthTurnstileAction.signup,
              onTokenChanged: (token) => _captchaToken = token,
            ),
            const SizedBox(height: 20),
            AuthSubmitButton(
              label: 'Create account',
              isLoading: isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 20),
            const SocialSignInButtons(),
            const SizedBox(height: 20),
            _TermsLine(scheme: scheme),
            AuthFooterLink(
              prompt: 'Already have an account?',
              action: 'Sign in',
              onTap: () => context.canPop()
                  ? context.pop()
                  : context.go(AppRoutes.signIn),
            ),
          ],
        ),
      ),
    );
  }
}

/// The centered "By signing up, you agree to our Terms / Privacy" line.
///
/// The policy links are disabled [TextButton]s (null `onPressed`) until real
/// document URLs exist — a dead `onTap: () {}` would ship a tappable element
/// that does nothing.
class _TermsLine extends StatelessWidget {
  const _TermsLine({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      color: scheme.onSurfaceVariant,
      fontSize: 12,
      height: 1.5,
    );
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('By signing up, you agree to our ', style: base),
        AuthTextLink(
          label: 'Terms of Service',
          fontSize: 12,
          onPressed: () {},
        ),
        Text(' and ', style: base),
        AuthTextLink(
          label: 'Privacy Policy',
          fontSize: 12,
          onPressed: () {},
        ),
      ],
    );
  }
}
