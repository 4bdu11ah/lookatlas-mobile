part of '../screens/support_page.dart';

class _SupportSuccess extends StatelessWidget {
  const _SupportSuccess({required this.receipt});
  final SupportTicketReceipt receipt;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF9E9),
      border: Border.all(color: LearningCenterStyle.line),
    ),
    child: Column(
      children: [
        Text('Request sent.', style: LearningCenterStyle.serif(26)),
        const SizedBox(height: 6),
        Text(
          receipt.id == null
              ? 'Your request was sent. Our support team will follow up by email.'
              : 'Ticket #${receipt.id} created. Our support team will follow up by email.',
          textAlign: TextAlign.center,
          style: LearningCenterStyle.body(
            12.5,
            height: 1.5,
            color: const Color(0xFF655631),
          ),
        ),
        const SizedBox(height: 14),
        LearningAction(
          'Back to Learning Center',
          outlined: true,
          icon: null,
          onPressed: () => _backToSchool(context),
        ),
      ],
    ),
  );
}
