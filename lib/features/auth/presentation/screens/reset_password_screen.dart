import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/features/auth/domain/validators/auth_validators.dart';
import 'package:look_atlas/features/auth/presentation/auth_controller.dart';
import 'package:look_atlas/features/auth/presentation/widgets/auth_layout.dart';
import 'package:look_atlas/features/auth/presentation/widgets/labeled_text_field.dart';
import 'package:look_atlas/shared/widgets/app_snack_bar.dart';

/// Forgot-password screen: collects the account email and submits a reset
/// request through [AuthController.resetPassword], with the same loading and
/// typed-failure handling as the other auth screens.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final succeeded = await ref
        .read(authControllerProvider.notifier)
        .resetPassword(_emailController.text.trim());
    if (!mounted || !succeeded) return;

    AppSnackBar.showSuccess(
      context,
      'Check your email for a link to reset your password.',
    );
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.signIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (_, next) {
      // The controller is shared with the other auth screens; only the
      // visible screen shows the error snackbar.
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
      title: 'Reset your password',
      subtitle: "Enter your email and we'll send you a reset link",
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
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: AuthValidators.validateEmail,
            ),
            const SizedBox(height: 20),
            AuthSubmitButton(
              label: 'Send reset link',
              isLoading: isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 20),
            AuthFooterLink(
              prompt: 'Remember your password?',
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
