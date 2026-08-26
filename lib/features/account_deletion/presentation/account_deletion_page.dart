import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/features/account_deletion/presentation/account_deletion_controller.dart';
import 'package:look_atlas/features/auth/presentation/auth_controller.dart';
import 'package:look_atlas/shared/widgets/app_snack_bar.dart';
import 'package:look_atlas/shared/widgets/app_text_field.dart';
import 'package:look_atlas/shared/widgets/custom_app_bar.dart';
import 'package:look_atlas/shared/widgets/primary_button.dart';

class AccountDeletionPage extends ConsumerStatefulWidget {
  const AccountDeletionPage({super.key});

  @override
  ConsumerState<AccountDeletionPage> createState() =>
      _AccountDeletionPageState();
}

class _AccountDeletionPageState extends ConsumerState<AccountDeletionPage> {
  final _password = TextEditingController();
  final _reason = TextEditingController();
  final _confirmation = TextEditingController();
  String _provider = 'password';

  @override
  void dispose() {
    _password.dispose();
    _reason.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountDeletionControllerProvider);
    final user = ref.watch(authStateProvider).value;
    final email = user?.email ?? '';
    final controller = ref.read(accountDeletionControllerProvider.notifier);
    final locked = state.step == AccountDeletionStep.submitting;
    return PopScope(
      canPop: !locked,
      child: Scaffold(
        backgroundColor: AppColors.neutral50,
        appBar: CustomAppBar(
          title: 'Delete account',
          showBackButton: !locked,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: switch (state.step) {
              AccountDeletionStep.explain => _ExplainStep(
                onContinue: controller.continueToReauthentication,
                onKeepAccount: () => Navigator.of(context).pop(),
              ),
              AccountDeletionStep.reauthenticate => _ReauthenticateStep(
                password: _password,
                provider: _provider,
                onProviderChanged: (value) =>
                    setState(() => _provider = value!),
                onContinue: () async {
                  if (await controller.reauthenticate(
                        provider: _provider,
                        material: _password.text,
                      ) &&
                      mounted) {
                    setState(() {});
                  }
                },
                onBack: controller.backToExplain,
              ),
              AccountDeletionStep.confirm ||
              AccountDeletionStep.failed => _ConfirmStep(
                email: email,
                reason: _reason,
                confirmation: _confirmation,
                state: state,
                onReasonChanged: controller.setReason,
                onConfirmationChanged: controller.setConfirmation,
                onSubmit: () => _showFinalAlert(
                  email: email,
                  controller: controller,
                ),
              ),
              AccountDeletionStep.submitting => const _ProgressStep(),
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showFinalAlert({
    required String email,
    required AccountDeletionController controller,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Delete account permanently?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete account'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final deleted = await controller.delete(
      email: email,
    );
    _password.clear();
    if (!mounted) return;
    if (deleted) {
      AppSnackBar.showSuccess(context, 'Your account has been deleted.');
      Navigator.of(context).pop();
    }
  }
}

class _ExplainStep extends StatelessWidget {
  const _ExplainStep({required this.onContinue, required this.onKeepAccount});
  final VoidCallback onContinue;
  final VoidCallback onKeepAccount;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Delete your account?',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 12),
      const Text(
        'This permanently removes your Look Atlas account, including your workspace, uploads, generated images, and unused credits.',
      ),
      const SizedBox(height: 24),
      const _DeletionDetail(
        'Your workspace, account settings, and sign-in access',
      ),
      const _DeletionDetail(
        'Product and model uploads, generated images, and saved work',
      ),
      const _DeletionDetail('Unused credits and active jobs'),
      const SizedBox(height: 24),
      PrimaryButton(
        onPressed: onContinue,
        label: 'Continue',
        backgroundColor: AppColors.danger,
      ),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: onKeepAccount,
        child: const Text('Keep my account'),
      ),
    ],
  );
}

class _DeletionDetail extends StatelessWidget {
  const _DeletionDetail(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        const Icon(Icons.close, color: AppColors.danger),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class _ReauthenticateStep extends StatelessWidget {
  const _ReauthenticateStep({
    required this.password,
    required this.provider,
    required this.onProviderChanged,
    required this.onContinue,
    required this.onBack,
  });
  final TextEditingController password;
  final String provider;
  final ValueChanged<String?> onProviderChanged;
  final VoidCallback onContinue;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Verify it’s you',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 12),
      const Text(
        'Verify your identity immediately before deleting your account.',
      ),
      RadioGroup<String>(
        groupValue: provider,
        onChanged: onProviderChanged,
        child: const Column(
          children: [
            RadioListTile(value: 'password', title: Text('Use password')),
            RadioListTile(value: 'google', title: Text('Use Google')),
          ],
        ),
      ),
      if (provider == 'password')
        AppTextField(
          controller: password,
          labelText: 'Password',
          obscureText: true,
        )
      else
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text('Continue to verify with your Google account.'),
        ),
      const SizedBox(height: 24),
      PrimaryButton(onPressed: onContinue, label: 'Continue'),
      TextButton(onPressed: onBack, child: const Text('Back')),
    ],
  );
}

class _ConfirmStep extends StatelessWidget {
  const _ConfirmStep({
    required this.email,
    required this.reason,
    required this.confirmation,
    required this.state,
    required this.onReasonChanged,
    required this.onConfirmationChanged,
    required this.onSubmit,
  });
  final String email;
  final TextEditingController reason;
  final TextEditingController confirmation;
  final AccountDeletionState state;
  final ValueChanged<String> onReasonChanged;
  final ValueChanged<String> onConfirmationChanged;
  final VoidCallback onSubmit;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('One final step', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 12),
      Text('To permanently delete $email, type DELETE below.'),
      const SizedBox(height: 20),
      AppTextField(
        controller: reason,
        labelText: 'Why are you deleting your account?',
        maxLines: 3,
        maxLength: 500,
        onChanged: onReasonChanged,
      ),
      const SizedBox(height: 16),
      AppTextField(
        controller: confirmation,
        labelText: 'Type DELETE to confirm',
        helperText: 'This action cannot be undone.',
        onChanged: onConfirmationChanged,
      ),
      if (state.failure != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            state.failure!.message,
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
      const SizedBox(height: 24),
      PrimaryButton(
        onPressed: state.canSubmit ? onSubmit : null,
        icon: Icons.delete_outline,
        label: 'Permanently delete account',
        backgroundColor: AppColors.danger,
      ),
    ],
  );
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.only(top: 100),
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('Deleting your account…'),
        ],
      ),
    ),
  );
}
