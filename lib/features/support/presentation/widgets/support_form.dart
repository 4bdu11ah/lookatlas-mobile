part of '../screens/support_page.dart';

class _SupportForm extends ConsumerWidget {
  const _SupportForm();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(supportControllerProvider);
    final controller = ref.read(supportControllerProvider.notifier);
    final remaining =
        ref.watch(supportRetryRemainingProvider).asData?.value ?? Duration.zero;
    if (state.submissionStatus == SupportSubmissionStatus.success) {
      return _SupportSuccess(receipt: state.receipt!);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LearningKicker('Subject'),
        const SizedBox(height: 6),
        _SupportField(
          fieldKey: const ValueKey('support-subject-field'),
          value: state.subject,
          hint: 'Summary of what you need',
          onChanged: controller.setSubject,
          enabled: !state.isSubmitting,
        ),
        const SizedBox(height: 16),
        const LearningKicker('Message'),
        const SizedBox(height: 6),
        _SupportField(
          fieldKey: const ValueKey('support-message-field'),
          value: state.message,
          hint: 'Tell us what you are trying to do so we can help directly...',
          onChanged: controller.setMessage,
          lines: 4,
          enabled: !state.isSubmitting,
        ),
        const SizedBox(height: 16),
        if (state.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              state.errorMessage!,
              style: LearningCenterStyle.body(
                12,
                color: const Color(0xFFB42318),
              ),
            ),
          ),
        if (remaining > Duration.zero)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Try again in ${(remaining.inMilliseconds / 1000).ceil()} seconds.',
              style: LearningCenterStyle.body(12),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: LearningAction(
            state.isSubmitting ? 'SENDING...' : 'SEND REQUEST',
            key: const ValueKey('support-submit-button'),
            height: 46,
            icon: LucideIcons.send,
            onPressed: state.isSubmitting || remaining > Duration.zero
                ? null
                : () => unawaited(controller.submit()),
          ),
        ),
      ],
    );
  }
}

class _SupportField extends StatefulWidget {
  const _SupportField({
    required this.fieldKey,
    required this.value,
    required this.hint,
    required this.onChanged,
    required this.enabled,
    this.lines = 1,
  });
  final Key fieldKey;
  final String value;
  final String hint;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final int lines;
  @override
  State<_SupportField> createState() => _SupportFieldState();
}

class _SupportFieldState extends State<_SupportField> {
  late final _text = TextEditingController(text: widget.value);
  @override
  void didUpdateWidget(_SupportField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_text.text != widget.value) _text.text = widget.value;
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    key: widget.fieldKey,
    controller: _text,
    onChanged: widget.onChanged,
    enabled: widget.enabled,
    minLines: widget.lines,
    maxLines: widget.lines,
    style: LearningCenterStyle.body(13, color: LearningCenterStyle.ink),
    decoration: InputDecoration(
      hintText: widget.hint,
      hintStyle: LearningCenterStyle.body(13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: LearningCenterStyle.line),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: LearningCenterStyle.line),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: LearningCenterStyle.ink),
      ),
    ),
  );
}
