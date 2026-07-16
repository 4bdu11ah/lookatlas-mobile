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
import 'package:look_atlas/features/auth/presentation/widgets/auth_password_field.dart';
import 'package:look_atlas/features/auth/presentation/widgets/labeled_text_field.dart';
import 'package:look_atlas/features/auth/presentation/widgets/social_sign_in_buttons.dart';
import 'package:look_atlas/shared/widgets/app_snack_bar.dart';

/// Login screen — mirrors `login.html` (brand, email + password, forgot
/// password link, sign in CTA, create-account footer). The captcha shown in
/// the mockup is intentionally omitted.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authControllerProvider.notifier)
        .signIn(_emailController.text.trim(), _passwordController.text);
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

    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to your account to continue',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
              hintText: 'Enter your password',
              autofillHints: const [AutofillHints.password],
              visibilityProvider: signInPasswordVisibilityProvider,
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
