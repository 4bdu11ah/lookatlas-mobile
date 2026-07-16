part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

Future<void> _openPurchaseDialog(BuildContext context, WidgetRef ref) async {
  ref.read(_billingControllerProvider.notifier).preparePurchase();
  await _showBillingDialog<void>(
    context: context,
    builder: (_) => const _BillingPurchaseDialog(),
  );
}

class _BillingPurchaseDialog extends ConsumerWidget {
  const _BillingPurchaseDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_billingControllerProvider);
    final controller = ref.read(_billingControllerProvider.notifier);
    if (state.action == _BillingAction.purchaseSuccess) {
      return _BillingPurchaseSuccess(
        credits: state.purchaseCredits,
        charge: state.purchaseTotal,
        onClose: () {
          controller.finishPurchase();
          Navigator.pop(context);
        },
      );
    }

    void close() {
      controller.resetAction();
      Navigator.pop(context);
    }

    return _BillingModal(
      title: 'Buy Credits',
      subtitle: 'Top up your balance in a few clicks.',
      onClose: close,
      body: _BillingPurchaseBody(state: state),
      footer: Row(
        children: [
          Expanded(
            child: _BillingActionButton(
              label: 'Cancel',
              outline: true,
              onPressed: close,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _BillingActionButton(
              label: state.action == _BillingAction.purchasing
                  ? 'Processing...'
                  : 'Complete Purchase',
              icon: Icons.credit_card_outlined,
              isLoading: state.action == _BillingAction.purchasing,
              onPressed: controller.completePurchase,
            ),
          ),
        ],
      ),
    );
  }
}

class _BillingPurchaseBody extends ConsumerWidget {
  const _BillingPurchaseBody({required this.state});

  final _BillingScreenState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(_billingControllerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            border: Border.all(color: AppColors.neutral200),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '80 Credit Pack',
                          style: TextStyle(
                            color: AppColors.neutral500,
                            fontSize: 12,
                            fontWeight: AppTypography.medium,
                          ),
                        ),
                        Text(
                          '80 credits',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Price per pack',
                        style: TextStyle(
                          color: AppColors.neutral500,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        r'$20.00',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                r'$0.25 per credit',
                style: TextStyle(
                  color: AppColors.neutral500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'QUANTITY',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _BillingStepButton(
                    key: const ValueKey('billing-credit-minus'),
                    icon: Icons.remove,
                    enabled: state.quantity > 1,
                    onPressed: () => controller.changeQuantity(-1),
                  ),
                  SizedBox(
                    width: 80,
                    child: Column(
                      children: [
                        Text(
                          '${state.quantity}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                        const Text(
                          'packs',
                          style: TextStyle(
                            color: AppColors.neutral500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _BillingStepButton(
                    key: const ValueKey('billing-credit-plus'),
                    icon: Icons.add,
                    enabled: state.quantity < 10,
                    onPressed: () => controller.changeQuantity(1),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Column(
            children: [
              _BillingTotalRow(
                label: 'TOTAL CREDITS',
                value: '${state.purchaseCredits}',
              ),
              const SizedBox(height: 16),
              const _Hairline(),
              const SizedBox(height: 16),
              _BillingTotalRow(
                label: 'TOTAL DUE',
                value: _billingMoney(
                  state.purchaseTotal,
                  alwaysShowCents: true,
                ),
                large: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BillingStepButton extends StatelessWidget {
  const _BillingStepButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 40,
      child: IconButton.outlined(
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          shape: const RoundedRectangleBorder(),
          side: const BorderSide(color: AppColors.black, width: 2),
        ),
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 20),
      ),
    );
  }
}

class _BillingTotalRow extends StatelessWidget {
  const _BillingTotalRow({
    required this.label,
    required this.value,
    this.large = false,
  });

  final String label;
  final String value;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.neutral500,
              fontSize: 14,
              fontWeight: AppTypography.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: large ? 24 : 20,
            fontWeight: AppTypography.bold,
          ),
        ),
      ],
    );
  }
}

class _BillingPurchaseSuccess extends StatelessWidget {
  const _BillingPurchaseSuccess({
    required this.credits,
    required this.charge,
    required this.onClose,
  });

  final int credits;
  final double charge;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            color: AppColors.black,
            alignment: Alignment.center,
            child: const Icon(Icons.check, color: AppColors.white, size: 24),
          ),
          const SizedBox(height: 20),
          const Text(
            'Credits added',
            style: TextStyle(
              fontSize: 20,
              fontWeight: AppTypography.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$credits credits are now available in your account.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.neutral500,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Charged ${_billingMoney(charge, alwaysShowCents: true)}',
            style: const TextStyle(
              color: AppColors.neutral500,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 28),
          _BillingActionButton(
            key: const ValueKey('billing-purchase-success-close'),
            label: 'Close',
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
