part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _BillingFeatureScaffold extends StatelessWidget {
  const _BillingFeatureScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: const CustomAppBar(
        title: 'Billing',
        showBackButton: true,
      ),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: const _BillingPage(),
          ),
        ),
      ),
    );
  }
}

class _BillingPage extends StatelessWidget {
  const _BillingPage();

  static const _items = <Widget>[
    _BillingPageHeader(),
    _BillingUsageCard(),
    _BillingPlanCard(),
    _BillingHistoryCard(),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: _items.length,
      itemBuilder: (_, index) => Padding(
        padding: EdgeInsets.only(bottom: index == _items.length - 1 ? 0 : 20),
        child: _items[index],
      ),
    );
  }
}

class _BillingPageHeader extends StatelessWidget {
  const _BillingPageHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Billing',
          style: TextStyle(
            fontSize: 24,
            height: 1.33,
            fontWeight: AppTypography.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Manage your subscription and view usage',
          style: TextStyle(
            fontSize: 14,
            height: 1.43,
            color: AppColors.neutral500,
          ),
        ),
      ],
    );
  }
}

class _BillingUsageCard extends ConsumerWidget {
  const _BillingUsageCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usage = ref.watch(
      _billingControllerProvider.select(
        (state) => (
          state.creditsRemaining,
          state.monthlyCredits,
          state.creditsUsed,
        ),
      ),
    );
    return _Card(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BillingCardHeader(
            icon: Icons.trending_up,
            title: 'Usage This Month',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${usage.$1}',
                  style: const TextStyle(
                    fontSize: 30,
                    height: 1.2,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                Text(
                  'Remaining of ${usage.$2} credits',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.neutral500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Used ${usage.$3} credits so far',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral500,
                  ),
                ),
                const SizedBox(height: 20),
                _BillingActionButton(
                  label: 'Buy More Credits',
                  icon: Icons.shopping_cart_outlined,
                  onPressed: () => _openPurchaseDialog(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BillingPlanCard extends ConsumerWidget {
  const _BillingPlanCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_billingControllerProvider);
    final price = state.plan.priceFor(state.currentCycle);
    return _Card(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BillingCardHeader(
            icon: Icons.credit_card_outlined,
            title: 'Current Plan',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      state.plan.name,
                      style: const TextStyle(
                        fontSize: 20,
                        height: 1.4,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _BillingStatusBadge(
                      label: state.cancellationScheduled
                          ? 'Cancelling'
                          : 'Active',
                      warning: state.cancellationScheduled,
                    ),
                  ],
                ),
                Text(
                  '${_billingMoney(price)}/month',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.neutral500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.cancellationScheduled
                      ? 'Access until Aug 1, 2026'
                      : 'Renews on Aug 1, 2026',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral500,
                  ),
                ),
                const SizedBox(height: 16),
                _BillingActionButton(
                  label: 'Modify',
                  icon: Icons.settings_outlined,
                  outline: true,
                  onPressed: () => _openSubscriptionDialog(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BillingStatusBadge extends StatelessWidget {
  const _BillingStatusBadge({required this.label, required this.warning});

  final String label;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: warning ? AppColors.blackAlpha10 : AppColors.black,
        border: warning ? Border.all(color: AppColors.blackAlpha20) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: warning ? AppColors.black : AppColors.white,
          fontSize: 12,
          fontWeight: AppTypography.bold,
        ),
      ),
    );
  }
}

class _BillingHistoryCard extends ConsumerWidget {
  const _BillingHistoryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refreshing = ref.watch(
      _billingControllerProvider.select((state) => state.historyRefreshing),
    );
    return _Card(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Billing History',
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.55,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _BillingActionButton(
                  label: refreshing ? 'Refreshing' : 'Refresh',
                  outline: true,
                  isLoading: refreshing,
                  onPressed: refreshing
                      ? null
                      : ref
                            .read(_billingControllerProvider.notifier)
                            .refreshHistory,
                ),
              ],
            ),
          ),
          const _Hairline(),
          const Padding(
            padding: EdgeInsets.all(20),
            child: _BillingHistoryTable(),
          ),
        ],
      ),
    );
  }
}

class _BillingHistoryTable extends StatelessWidget {
  const _BillingHistoryTable();

  static const _widths = [158.0, 172.0, 92.0, 92.0, 92.0];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 650,
        child: Column(
          children: [
            const _BillingHistoryRow(
              values: ['DATE', 'DESCRIPTION', 'AMOUNT', 'CREDITS', 'BALANCE'],
              header: true,
            ),
            for (final entry in _billingHistory)
              _BillingHistoryRow(
                values: [
                  entry.date,
                  entry.description,
                  entry.amount,
                  entry.credits,
                  entry.balance,
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _BillingHistoryRow extends StatelessWidget {
  const _BillingHistoryRow({required this.values, this.header = false});

  final List<String> values;
  final bool header;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.neutral200)),
      ),
      child: Row(
        children: [
          for (var index = 0; index < values.length; index++)
            SizedBox(
              width: _BillingHistoryTable._widths[index],
              child: Text(
                values[index],
                textAlign: index < 2 ? TextAlign.start : TextAlign.end,
                style: TextStyle(
                  fontSize: header ? 12 : 14,
                  color: header || index == 4
                      ? AppColors.neutral500
                      : AppColors.black,
                  fontWeight: header || index == 2
                      ? AppTypography.bold
                      : AppTypography.regular,
                ),
              ),
            ),
        ],
      ),
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
