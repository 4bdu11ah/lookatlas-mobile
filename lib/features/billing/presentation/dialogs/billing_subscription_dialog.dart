part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

Future<void> _openSubscriptionDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  await _showBillingDialog<void>(
    context: context,
    maxWidth: 430,
    builder: (_) => const _BillingSubscriptionDialog(),
  );
}

class _BillingSubscriptionDialog extends ConsumerWidget {
  const _BillingSubscriptionDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(subscriptionActionProvider, (_, next) {
      if (next case SubscriptionIdle(:final failure?)) {
        AppSnackBar.showError(context, failure.message);
      }
    });

    final products = ref.watch(revenueCatProductsProvider);
    final action = ref.watch(subscriptionActionProvider);
    final currentProductId = ref
        .watch(subscriptionControllerProvider)
        .value
        ?.productId;
    return _BillingModal(
      title: 'Modify Subscription',
      subtitle: 'Choose a monthly plan that fits your needs',
      onClose: () => Navigator.pop(context),
      body: products.when(
        loading: () => const _BillingPlansLoading(),
        error: (error, _) => _BillingPlansError(
          message: error is Failure
              ? error.message
              : 'Plans are unavailable right now.',
          onRetry: () => ref.invalidate(revenueCatProductsProvider),
        ),
        data: (value) => _BillingMonthlyPlans(
          products: _monthlyProducts(value),
          currentProductId: currentProductId,
          action: action,
          onPurchase: (product) =>
              _purchaseBillingProduct(context, ref, product),
        ),
      ),
      footer: _BillingActionButton(
        label: 'Close',
        outline: true,
        onPressed: action.isBusy ? null : () => Navigator.pop(context),
      ),
    );
  }
}

Future<void> _purchaseBillingProduct(
  BuildContext context,
  WidgetRef ref,
  revenuecat.StoreProduct product,
) async {
  final purchased = await ref
      .read(subscriptionActionProvider.notifier)
      .purchase(product);
  if (!purchased || !context.mounted) return;
  AppSnackBar.showSuccess(context, 'Subscription updated.');
  Navigator.pop(context);
}

class _BillingPlansLoading extends StatelessWidget {
  const _BillingPlansLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(child: BarSpinner(size: 28)),
    );
  }
}

class _BillingPlansError extends StatelessWidget {
  const _BillingPlansError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          _BillingActionButton(
            label: 'Retry',
            outline: true,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _BillingMonthlyPlans extends StatelessWidget {
  const _BillingMonthlyPlans({
    required this.products,
    required this.currentProductId,
    required this.action,
    required this.onPurchase,
  });

  final List<revenuecat.StoreProduct> products;
  final String? currentProductId;
  final SubscriptionAction action;
  final ValueChanged<revenuecat.StoreProduct> onPurchase;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const _BillingNotice(
        warning: true,
        text: 'No monthly subscription products are configured in RevenueCat.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < products.length; index++) ...[
          _BillingMonthlyPlanOption(
            product: products[index],
            currentProductId: currentProductId,
            action: action,
            onSelect: () => onPurchase(products[index]),
          ),
          if (index != products.length - 1) const SizedBox(height: 20),
        ],
        const SizedBox(height: 20),
        const _BillingNotice(
          text:
              'Manage or cancel an active subscription from your App Store '
              'or Google Play account.',
        ),
      ],
    );
  }
}

class _BillingMonthlyPlanOption extends StatelessWidget {
  const _BillingMonthlyPlanOption({
    required this.product,
    required this.currentProductId,
    required this.action,
    required this.onSelect,
  });

  final revenuecat.StoreProduct product;
  final String? currentProductId;
  final SubscriptionAction action;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final isCurrent = product.identifier == currentProductId;
    final isPurchasing = switch (action) {
      SubscriptionPurchasing(:final productId) =>
        productId == product.identifier,
      _ => false,
    };
    return Container(
      key: ValueKey('billing-plan-${product.identifier}'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(
          color: isCurrent ? AppColors.black : AppColors.neutral200,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BillingProductSummary(product: product),
          if (product.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              product.description,
              style: const TextStyle(
                color: AppColors.neutral500,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 20),
          _BillingPlanPurchaseButton(
            isCurrent: isCurrent,
            hasCurrentPlan: currentProductId != null,
            isPurchasing: isPurchasing,
            isBusy: action.isBusy,
            onSelect: onSelect,
          ),
        ],
      ),
    );
  }
}

class _BillingPlanPurchaseButton extends StatelessWidget {
  const _BillingPlanPurchaseButton({
    required this.isCurrent,
    required this.hasCurrentPlan,
    required this.isPurchasing,
    required this.isBusy,
    required this.onSelect,
  });

  final bool isCurrent;
  final bool hasCurrentPlan;
  final bool isPurchasing;
  final bool isBusy;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return _BillingActionButton(
      label: isCurrent
          ? 'Current plan'
          : hasCurrentPlan
          ? 'Switch plan'
          : 'Subscribe',
      isLoading: isPurchasing,
      outline: isCurrent,
      onPressed: isCurrent || isBusy ? null : onSelect,
    );
  }
}

class _BillingProductSummary extends StatelessWidget {
  const _BillingProductSummary({required this.product});

  final revenuecat.StoreProduct product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: AppTypography.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${product.priceString}/month',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: AppTypography.bold,
          ),
        ),
      ],
    );
  }
}
