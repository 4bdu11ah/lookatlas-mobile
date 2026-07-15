part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _BillingPage extends ConsumerWidget {
  const _BillingPage({required this.onOpenModal});

  final ValueChanged<_ModalKind> onOpenModal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_billingControllerProvider);
    return _Stack(
      children: [
        const _PageHeader(
          title: 'Billing',
          body: 'Manage credits, subscription, invoices, and cancellation.',
        ),
        const _Alert(
          kind: _AlertKind.warn,
          text:
              'Payment failed banner condition: update your payment method to keep access active.',
        ),
        _Card(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _ProgressHead(
                label: 'Usage This Month',
                value: '${state.creditsRemaining} left',
              ),
              const SizedBox(height: 12),
              const _ProgressBar(value: 0.58),
              const SizedBox(height: 8),
              _Caption(state.usageLabel),
              const SizedBox(height: 12),
              _Button(
                label: 'Buy More Credits',
                full: true,
                onTap: () => onOpenModal(_ModalKind.purchase),
              ),
            ],
          ),
        ),
        _Card(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CardTitle('Current Plan'),
                  _Badge('Active', kind: _BadgeKind.success),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                state.monthlyPlan,
                style: const TextStyle(
                  fontSize: 24,
                  height: 1.1,
                  fontWeight: AppTypography.bold,
                ),
              ),
              const SizedBox(height: 8),
              const _BodyText(
                'Renews Aug 9, 2026. Pro includes 200 photos/mo plus AI video.',
              ),
              const SizedBox(height: 12),
              _Button.secondary(
                label: 'Modify Subscription',
                full: true,
                onTap: () => onOpenModal(_ModalKind.subscription),
              ),
            ],
          ),
        ),
        _Card(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(child: _SectionTitle('Billing History')),
                  const SizedBox(width: 12),
                  _Button.secondary(
                    label: 'Refresh',
                    compact: true,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const _InvoiceRow(
                'Pro subscription',
                r'$99.00',
                'Jul 9, 2026, Balance 142',
              ),
              const _InvoiceRow(
                'Credit pack',
                r'$19.00',
                'Jun 28, 2026, +100 credits',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow(this.title, this.body);

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_CardTitle(title), _Caption(body)],
            ),
          ),
          const _Badge('Selected', kind: _BadgeKind.dark),
        ],
      ),
    );
  }
}

class _PlanOption extends StatelessWidget {
  const _PlanOption({
    required this.title,
    required this.price,
    this.body,
    this.active = false,
  });

  final String title;
  final String price;
  final String? body;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: active ? AppColors.neutral100 : AppColors.white,
        border: Border.all(
          color: active ? AppColors.black : AppColors.neutral200,
          width: active ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Eyebrow(title),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 24,
                    height: 1.15,
                    fontWeight: AppTypography.bold,
                    color: AppColors.black,
                  ),
                ),
                if (body != null) _Caption(body!),
              ],
            ),
          ),
          if (active) const Icon(Icons.check, size: 18, color: AppColors.black),
        ],
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow(this.title, this.price, this.caption);

  final String title;
  final String price;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.neutral200)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: AppTypography.bold),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  price,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(alignment: Alignment.centerLeft, child: _Caption(caption)),
        ],
      ),
    );
  }
}

class _ProgressHead extends StatelessWidget {
  const _ProgressHead({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: _CardTitle(label)),
        const SizedBox(width: 12),
        _Badge(value, kind: _BadgeKind.dark),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Container(
        height: 10,
        color: AppColors.neutral200,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value,
          child: const ColoredBox(color: AppColors.black),
        ),
      ),
    );
  }
}
