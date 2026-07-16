part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

Future<void> _showSupportSuccessDialog(BuildContext context) {
  return showAppDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => const _SupportSuccessDialog(),
  );
}

class _SupportSuccessDialog extends StatelessWidget {
  const _SupportSuccessDialog();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ColoredBox(
            color: Color(0xFF16A34A),
            child: SizedBox.square(
              dimension: 64,
              child: Icon(Icons.check, size: 32, color: AppColors.white),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Message Received!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: AppTypography.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Thank you for contacting us. We'll get back to you within 24 hours.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.43,
              color: AppColors.neutral500,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 40,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                backgroundColor: AppColors.black,
                foregroundColor: AppColors.white,
                shape: const RoundedRectangleBorder(),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: AppTypography.medium,
                ),
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}
