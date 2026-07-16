import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/features/auth/domain/validators/auth_validators.dart';
import 'package:look_atlas/features/auth/presentation/auth_controller.dart';
import 'package:look_atlas/features/auth/presentation/password_visibility_controller.dart';
import 'package:look_atlas/features/auth/presentation/widgets/auth_layout.dart';
import 'package:look_atlas/features/auth/presentation/widgets/auth_password_field.dart';
import 'package:look_atlas/features/auth/presentation/widgets/labeled_text_field.dart';
import 'package:look_atlas/features/auth/presentation/widgets/social_sign_in_buttons.dart';
import 'package:look_atlas/shared/widgets/app_snack_bar.dart';

/// Create-account screen — mirrors `signup.html` (email, password with helper,
/// create CTA, terms line, sign-in footer). The captcha shown in the mockup is
/// intentionally omitted.
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

  @override
  void dispose() {
    _companyNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authControllerProvider.notifier)
        .signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          companyName: _companyNameController.text.trim(),
        );
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

    return AuthScaffold(
      title: 'Create your account',
      subtitle: 'Start creating stunning product photos with AI',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LabeledTextField(
              label: 'Company name',
              controller: _companyNameController,
              hintText: 'Your company',
              autofillHints: const [AutofillHints.organizationName],
              textInputAction: TextInputAction.next,
              validator: AuthValidators.validateCompanyName,
            ),
            const SizedBox(height: 20),
            LabeledTextField(
              label: 'Email address',
              controller: _emailController,
              hintText: 'you@company.com',
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              validator: AuthValidators.validateEmail,
            ),
            const SizedBox(height: 20),
            AuthPasswordField(
              controller: _passwordController,
              hintText: 'Create a strong password',
              helperText:
                  'Must be at least '
                  '${AuthValidators.minPasswordLength} characters long',
              autofillHints: const [AutofillHints.newPassword],
              visibilityProvider: signUpPasswordVisibilityProvider,
              onFieldSubmitted: (_) => _submit(),
              validator: AuthValidators.validatePassword,
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
