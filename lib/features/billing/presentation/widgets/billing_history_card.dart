part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _BillingHistoryCard extends ConsumerWidget {
  const _BillingHistoryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(billingHistoryProvider);
    final refreshing = history.isLoading;
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
                      : () => ref.invalidate(billingHistoryProvider),
                ),
              ],
            ),
          ),
          const _Hairline(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: history.when(
              loading: () => const Center(child: BarSpinner()),
              error: (_, _) => _BillingHistoryError(
                onRetry: () => ref.invalidate(billingHistoryProvider),
              ),
              data: (entries) => entries.isEmpty
                  ? const _BillingHistoryEmpty()
                  : _BillingHistoryTable(entries: entries),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillingHistoryTable extends StatelessWidget {
  const _BillingHistoryTable({required this.entries});

  static const _widths = [158.0, 172.0, 92.0, 92.0, 92.0];

  final List<BillingHistoryEntry> entries;

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
            ListView.builder(
              itemCount: entries.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (_, index) => _BillingHistoryRow(
                values: _historyValues(context, entries[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillingHistoryEmpty extends StatelessWidget {
  const _BillingHistoryEmpty();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'No billing history yet.',
      style: TextStyle(fontSize: 14, color: AppColors.neutral500),
    );
  }
}

class _BillingHistoryError extends StatelessWidget {
  const _BillingHistoryError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Billing history is unavailable right now.'),
        const SizedBox(height: 12),
        _BillingActionButton(
          label: 'Retry',
          outline: true,
          onPressed: onRetry,
        ),
      ],
    );
  }
}

List<String> _historyValues(
  BuildContext context,
  BillingHistoryEntry entry,
) => [
  _historyDate(context, entry.occurredAt),
  entry.description,
  _historyAmount(entry),
  _historyCredits(entry.credits),
  entry.balance?.toString() ?? '-',
];

String _historyDate(BuildContext context, DateTime? occurredAt) {
  if (occurredAt == null) return 'Date unavailable';
  final local = occurredAt.toLocal();
  final localizations = MaterialLocalizations.of(context);
  final date = localizations.formatMediumDate(local);
  final time = localizations.formatTimeOfDay(TimeOfDay.fromDateTime(local));
  return '$date, $time';
}

String _historyAmount(BillingHistoryEntry entry) {
  final amount = entry.amount;
  if (amount == null) return '-';
  return NumberFormat.simpleCurrency(
    name: entry.currencyCode.toUpperCase(),
  ).format(amount);
}

String _historyCredits(int? credits) {
  if (credits == null) return '-';
  return credits > 0 ? '+$credits' : '$credits';
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
