part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _SupportPage extends ConsumerWidget {
  const _SupportPage({required this.onOpenModal});

  final ValueChanged<_ModalKind> onOpenModal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_supportControllerProvider);
    return _Stack(
      children: [
        const _PageHeader(
          title: 'Support',
          body: 'Get help with Look Atlas.',
        ),
        _Card(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: _SectionTitle('Contact support'),
              ),
              const SizedBox(height: 12),
              const _InputLike('What do you need help with?', label: 'Subject'),
              const SizedBox(height: 12),
              const _SelectLike('Normal', label: 'Priority'),
              const SizedBox(height: 12),
              const _TextAreaLike('Describe the issue...', label: 'Message'),
              const SizedBox(height: 12),
              _Button(
                label: 'Send Message',
                full: true,
                onTap: () => onOpenModal(_ModalKind.supportSuccess),
              ),
            ],
          ),
        ),
        _Grid2(
          children: [
            for (final topic in state.topics)
              _MetricCard(topic, _supportTopicBody(topic)),
          ],
        ),
      ],
    );
  }

  String _supportTopicBody(String topic) {
    return switch (topic) {
      'Billing questions' => 'Refunds, invoices, payment failures.',
      'Shoot quality' => 'Generation failures, edits, reruns.',
      _ => 'Support requests and account help.',
    };
  }
}
