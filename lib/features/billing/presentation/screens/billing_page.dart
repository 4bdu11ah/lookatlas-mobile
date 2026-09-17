import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/billing/di/billing_api_providers.dart';
import 'package:look_atlas/features/billing/domain/entities/billing_checkout.dart';
import 'package:look_atlas/features/billing/presentation/controllers/billing_controller.dart';
import 'package:look_atlas/features/billing/presentation/models/billing_screen_state.dart';
import 'package:look_atlas/features/dashboard/di/dashboard_providers.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:look_atlas/features/subscription/di/subscription_providers.dart';
import 'package:look_atlas/features/subscription/domain/entities/subscription_product.dart';
import 'package:look_atlas/features/subscription/domain/entities/subscription_status.dart';
import 'package:look_atlas/features/subscription/presentation/controllers/subscription_action.dart';
import 'package:look_atlas/features/subscription/presentation/controllers/subscription_controller.dart';
import 'package:look_atlas/shared/widgets/app_card.dart';
import 'package:look_atlas/shared/widgets/app_dialog.dart';
import 'package:look_atlas/shared/widgets/app_feature_scaffold.dart';
import 'package:look_atlas/shared/widgets/app_feedback.dart';
import 'package:look_atlas/shared/widgets/app_hairline.dart';
import 'package:look_atlas/shared/widgets/app_outlined_button.dart';
import 'package:look_atlas/shared/widgets/app_snack_bar.dart';
import 'package:look_atlas/shared/widgets/app_square_icon.dart';
import 'package:look_atlas/shared/widgets/bar_spinner.dart';
import 'package:look_atlas/shared/widgets/primary_button.dart';

part '../dialogs/billing_purchase_dialog.dart';
part '../dialogs/billing_subscription_dialog.dart';
part '../widgets/billing_history_card.dart';
part '../widgets/billing_widgets.dart';

class BillingScreen extends StatelessWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppFeatureScaffold(
      backgroundColor: AppColors.neutral50,
      title: 'Billing',
      child: _BillingPage(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Billing',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            height: 1.33,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage your subscription and view usage',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
    final stats = ref.watch(dashboardStatsProvider);
    return AppCard(
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
            child: stats.when(
              loading: () => const Center(child: BarSpinner()),
              error: (_, _) => _BillingUsageError(
                onRetry: () => ref.invalidate(dashboardStatsProvider),
              ),
              data: (value) => _BillingUsageContent(
                stats: value,
                onBuyCredits: () => _openPurchaseDialog(context, ref),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillingUsageContent extends StatelessWidget {
  const _BillingUsageContent({
    required this.stats,
    required this.onBuyCredits,
  });

  final DashboardStats stats;
  final VoidCallback onBuyCredits;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${stats.credits}',
          style: const TextStyle(
            fontSize: 30,
            height: 1.2,
            fontWeight: AppTypography.bold,
          ),
        ),
        Text(
          'Remaining of ${stats.creditsTotal} credits',
          style: const TextStyle(fontSize: 14, color: AppColors.neutral500),
        ),
        const SizedBox(height: 8),
        Text(
          'Used ${stats.creditsUsed} credits so far',
          style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
        ),
        const SizedBox(height: 20),
        _BillingActionButton(
          label: 'Buy More Credits',
          icon: Icons.shopping_cart_outlined,
          onPressed: onBuyCredits,
        ),
      ],
    );
  }
}

class _BillingUsageError extends StatelessWidget {
  const _BillingUsageError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Usage is unavailable right now.'),
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

class _BillingPlanCard extends ConsumerWidget {
  const _BillingPlanCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(subscriptionControllerProvider);
    final products = ref.watch(revenueCatProductsProvider);
    return AppCard(
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
            child: status.when(
              loading: () => const Center(child: BarSpinner()),
              error: (_, _) => _BillingCurrentPlanError(
                onRetry: () => ref.invalidate(subscriptionControllerProvider),
              ),
              data: (value) => products.when(
                loading: () => const Center(child: BarSpinner()),
                error: (_, _) => _BillingCurrentPlanError(
                  onRetry: () => ref.invalidate(revenueCatProductsProvider),
                ),
                data: (items) => _BillingCurrentPlan(
                  status: value,
                  products: items,
                  onModify: () => _openSubscriptionDialog(context, ref),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillingCurrentPlan extends StatelessWidget {
  const _BillingCurrentPlan({
    required this.status,
    required this.products,
    required this.onModify,
  });

  final SubscriptionStatus status;
  final List<SubscriptionProduct> products;
  final VoidCallback onModify;

  @override
  Widget build(BuildContext context) {
    final product = _productForId(products, status.productId);
    final title = status.isPremium
        ? product?.title ?? status.productId ?? 'Premium'
        : 'No active subscription';
    final price = product == null
        ? 'Monthly subscription'
        : '${product.priceString}/${_billingPeriod(product)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BillingCurrentPlanHeader(
          title: title,
          isPremium: status.isPremium,
        ),
        Text(
          price,
          style: const TextStyle(fontSize: 14, color: AppColors.neutral500),
        ),
        const SizedBox(height: 4),
        Text(
          _renewalText(context, status),
          style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
        ),
        const SizedBox(height: 16),
        _BillingActionButton(
          label: status.isPremium ? 'Change plan' : 'Choose plan',
          icon: Icons.settings_outlined,
          outline: true,
          onPressed: onModify,
        ),
      ],
    );
  }

  static String _renewalText(
    BuildContext context,
    SubscriptionStatus status,
  ) {
    final expiresAt = status.expiresAt;
    if (!status.isPremium) return 'Choose a monthly plan to get started.';
    if (expiresAt == null) return 'Subscription active.';
    final date = MaterialLocalizations.of(context).formatMediumDate(expiresAt);
    return status.willRenew ? 'Renews on $date' : 'Access until $date';
  }
}

class _BillingCurrentPlanHeader extends StatelessWidget {
  const _BillingCurrentPlanHeader({
    required this.title,
    required this.isPremium,
  });

  final String title;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              height: 1.4,
              fontWeight: AppTypography.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        AppBadge(
          isPremium ? 'Active' : 'Inactive',
          kind: isPremium ? AppBadgeKind.dark : AppBadgeKind.neutral,
        ),
      ],
    );
  }
}

class _BillingCurrentPlanError extends StatelessWidget {
  const _BillingCurrentPlanError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Current subscription is unavailable.'),
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

List<SubscriptionProduct> _monthlyProducts(
  List<SubscriptionProduct> products,
) => [
  for (final product in products)
    if (product.isMonthly) product,
];

SubscriptionProduct? _productForId(
  List<SubscriptionProduct> products,
  String? productId,
) {
  if (productId == null) return null;
  for (final product in products) {
    if (product.id == productId) return product;
  }
  return null;
}

String _billingPeriod(SubscriptionProduct product) =>
    switch (product.subscriptionPeriod) {
      'P1Y' => 'year',
      'P1M' => 'month',
      'P1W' => 'week',
      _ => 'billing period',
    };
