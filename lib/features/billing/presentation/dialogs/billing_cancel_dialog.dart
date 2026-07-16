part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

Future<bool> _openCancellationDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  ref.read(_billingControllerProvider.notifier).prepareCancellation();
  return await _showBillingDialog<bool>(
        context: context,
        maxWidth: 430,
        builder: (_) => const _BillingCancelDialog(),
      ) ??
      false;
}

class _BillingCancelDialog extends ConsumerWidget {
  const _BillingCancelDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_billingControllerProvider);
    final controller = ref.read(_billingControllerProvider.notifier);
    if (state.action == _BillingAction.cancellationSuccess) {
      return _BillingCancellationSuccess(
        onClose: () => Navigator.pop(context, true),
      );
    }
    return _BillingModal(
      title: 'Cancel Subscription',
      onClose: () => Navigator.pop(context, false),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "We're sorry to see you go",
            style: TextStyle(
              fontSize: 18,
              fontWeight: AppTypography.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Cancelling stops future renewals. You'll retain access until Aug 1, 2026.",
            style: TextStyle(
              color: AppColors.neutral500,
              fontSize: 14,
              height: 1.43,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'WHY ARE YOU CANCELLING? (optional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: AppTypography.bold,
            ),
          ),
          const SizedBox(height: 12),
          for (
            var index = 0;
            index < _CancellationReason.values.length;
            index++
          ) ...[
            _BillingReasonOption(
              reason: _CancellationReason.values[index],
              selected:
                  state.cancellationReason == _CancellationReason.values[index],
              onTap: () => controller.selectCancellationReason(
                _CancellationReason.values[index],
              ),
            ),
            if (index != _CancellationReason.values.length - 1)
              const SizedBox(height: 12),
          ],
          const SizedBox(height: 24),
          const Text(
            'ADDITIONAL FEEDBACK (optional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: AppTypography.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            minLines: 4,
            maxLines: 6,
            onChanged: controller.setCancellationFeedback,
            decoration: const InputDecoration(
              hintText:
                  "Let us know if there's anything we could have done better.",
              filled: true,
              fillColor: AppColors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: AppColors.neutral200, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: AppColors.black, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _BillingActionButton(
            label: 'Confirm Cancellation',
            danger: true,
            isLoading: state.action == _BillingAction.cancelling,
            onPressed: controller.cancelSubscription,
          ),
          const SizedBox(height: 12),
          _BillingActionButton(
            label: 'Keep Subscription',
            outline: true,
            onPressed: () => Navigator.pop(context, false),
          ),
        ],
      ),
    );
  }
}

class _BillingReasonOption extends StatelessWidget {
  const _BillingReasonOption({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  final _CancellationReason reason;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? AppColors.black : AppColors.neutral200,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.black, width: 2),
                ),
                child: selected
                    ? const DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.black,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  reason.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: AppTypography.medium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BillingCancellationSuccess extends StatelessWidget {
  const _BillingCancellationSuccess({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.dangerLight,
              border: Border.all(color: AppColors.danger, width: 2),
            ),
            child: const Icon(
              Icons.check,
              size: 40,
              color: AppColors.dangerDark,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Cancellation Scheduled',
            style: TextStyle(
              fontSize: 20,
              fontWeight: AppTypography.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "You'll keep access until Aug 1, 2026. After that you'll need to subscribe again to continue using Look Atlas.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.neutral500,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          _BillingActionButton(
            key: const ValueKey('billing-cancel-success-close'),
            label: 'Close',
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
