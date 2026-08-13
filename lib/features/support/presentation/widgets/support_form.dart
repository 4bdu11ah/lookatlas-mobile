part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _SupportFormCard extends ConsumerStatefulWidget {
  const _SupportFormCard();

  @override
  ConsumerState<_SupportFormCard> createState() => _SupportFormCardState();
}

class _SupportFormCardState extends ConsumerState<_SupportFormCard> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _subjectController;
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(_supportControllerProvider);
    _fullNameController = TextEditingController(text: state.fullName);
    _emailController = TextEditingController(text: state.email);
    _subjectController = TextEditingController(text: state.subject);
    _messageController = TextEditingController(text: state.message);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final submitted = await ref
        .read(_supportControllerProvider.notifier)
        .submit();
    if (!mounted || !submitted) return;
    await _showSupportSuccessDialog(context);
    if (!mounted) return;
    _subjectController.clear();
    _messageController.clear();
    ref.read(_supportControllerProvider.notifier).acknowledgeSuccess();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      _supportControllerProvider.select(
        (state) => (state.fullName, state.email),
      ),
      (_, identity) {
        if (_fullNameController.text.isEmpty && identity.$1.isNotEmpty) {
          _fullNameController.text = identity.$1;
        }
        if (_emailController.text.isEmpty && identity.$2.isNotEmpty) {
          _emailController.text = identity.$2;
        }
      },
    );
    final controller = ref.read(_supportControllerProvider.notifier);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Send us a Message',
              style: TextStyle(
                fontSize: 20,
                height: 1.4,
                fontWeight: AppTypography.bold,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.neutral200),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SupportErrorBanner(),
                AppTextField(
                  fieldKey: const ValueKey('support-name-field'),
                  labelText: 'Full Name *',
                  controller: _fullNameController,
                  hintText: 'Enter your full name',
                  textInputAction: TextInputAction.next,
                  onChanged: controller.setFullName,
                ),
                const SizedBox(height: 24),
                AppTextField(
                  fieldKey: const ValueKey('support-email-field'),
                  labelText: 'Email Address *',
                  controller: _emailController,
                  hintText: 'you@company.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onChanged: controller.setEmail,
                ),
                const SizedBox(height: 24),
                AppTextField(
                  fieldKey: const ValueKey('support-subject-field'),
                  labelText: 'Subject *',
                  controller: _subjectController,
                  hintText: 'How can we help?',
                  textInputAction: TextInputAction.next,
                  onChanged: controller.setSubject,
                ),
                const SizedBox(height: 24),
                const _SupportPriorityField(),
                const SizedBox(height: 24),
                _SupportMessageField(controller: _messageController),
                const SizedBox(height: 24),
                _SupportSubmitFooter(onSubmit: _submit),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportErrorBanner extends ConsumerWidget {
  const _SupportErrorBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = ref.watch(
      _supportControllerProvider.select((state) => state.errorMessage),
    );
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.1),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            error,
            style: const TextStyle(
              fontSize: 14,
              height: 1.43,
              color: AppColors.danger,
            ),
          ),
        ),
      ),
    );
  }
}

class _SupportPriorityField extends ConsumerWidget {
  const _SupportPriorityField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priority = ref.watch(
      _supportControllerProvider.select((state) => state.priority),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SupportFieldLabel(label: 'Priority Level'),
        const SizedBox(height: 8),
        AppDropdown<_SupportPriority>(
          value: priority,
          values: _SupportPriority.values,
          labelFor: (value) => value.label,
          onChanged: ref.read(_supportControllerProvider.notifier).setPriority,
        ),
      ],
    );
  }
}

class _SupportMessageField extends ConsumerWidget {
  const _SupportMessageField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final characterCount = ref.watch(
      _supportControllerProvider.select((state) => state.message.length),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SupportFieldLabel(label: 'Message', required: true),
        const SizedBox(height: 8),
        SizedBox(
          height: 184,
          child: Stack(
            children: [
              Positioned.fill(
                child: AppTextField(
                  fieldKey: const ValueKey('support-message-field'),
                  controller: controller,
                  onChanged: ref
                      .read(_supportControllerProvider.notifier)
                      .setMessage,
                  expands: true,
                  minLines: null,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textStyle: const TextStyle(fontSize: 16, height: 1.5),
                  hintText:
                      'Please provide detailed information about your issue or question...',
                  hintStyle: const TextStyle(
                    fontSize: 16,
                    color: AppColors.neutral500,
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
                ),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: IgnorePointer(
                  child: Text(
                    '$characterCount characters',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SupportFieldLabel extends StatelessWidget {
  const _SupportFieldLabel({required this.label, this.required = false});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: label,
        children: required
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.danger),
                ),
              ]
            : const [],
      ),
      style: const TextStyle(
        fontSize: 14,
        fontWeight: AppTypography.medium,
      ),
    );
  }
}

class _SupportSubmitFooter extends ConsumerWidget {
  const _SupportSubmitFooter({required this.onSubmit});

  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubmitting = ref.watch(
      _supportControllerProvider.select((state) => state.isSubmitting),
    );
    const responseCopy = Text.rich(
      TextSpan(
        text: "We'll respond within ",
        children: [
          TextSpan(
            text: '24 hours',
            style: TextStyle(
              color: AppColors.black,
              fontWeight: AppTypography.bold,
            ),
          ),
        ],
      ),
      style: TextStyle(fontSize: 12, color: AppColors.neutral500),
    );
    final button = _SupportSubmitButton(
      isSubmitting: isSubmitting,
      onSubmit: onSubmit,
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.neutral200)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 280) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  responseCopy,
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerRight, child: button),
                ],
              );
            }
            return Row(
              children: [
                const Expanded(child: responseCopy),
                const SizedBox(width: 12),
                button,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SupportSubmitButton extends StatelessWidget {
  const _SupportSubmitButton({
    required this.isSubmitting,
    required this.onSubmit,
  });

  final bool isSubmitting;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !isSubmitting,
      child: Material(
        color: AppColors.black,
        child: InkWell(
          key: const ValueKey('support-submit-button'),
          onTap: isSubmitting ? null : onSubmit,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: SizedBox(
              height: 40,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSubmitting)
                    const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  else
                    const Icon(
                      Icons.send_outlined,
                      size: 16,
                      color: AppColors.white,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    isSubmitting ? 'Sending...' : 'Send Message',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: AppTypography.medium,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
