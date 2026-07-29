import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/shared/widgets/bar_spinner.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatProductsSection extends StatelessWidget {
  const RevenueCatProductsSection({
    required this.purchasingProductId,
    required this.onPurchase,
    this.products = const [],
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    super.key,
  });

  final List<StoreProduct> products;
  final String? purchasingProductId;
  final ValueChanged<StoreProduct> onPurchase;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _ProductsStatus(
        message: 'Loading plans...',
        child: BarSpinner(size: 28, color: AppColors.white),
      );
    }
    if (errorMessage case final message?) {
      return _ProductsStatus(
        message: message,
        child: OutlinedButton(
          onPressed: onRetry,
          child: const Text('Retry'),
        ),
      );
    }

    final monthlyProducts = products.where(_isMonthly).toList();
    final oneTimeProducts = products.where(_isOneTime).toList();
    if (monthlyProducts.isEmpty && oneTimeProducts.isEmpty) {
      return const _ProductsStatus(
        message:
            'No monthly plans or one-time product are configured in '
            'RevenueCat.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Choose your plan',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: AppTypography.bold,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Monthly subscriptions and a one-time option, billed by your app '
          'store.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.whiteAlpha65),
        ),
        const SizedBox(height: 16),
        _ProductList(
          products: monthlyProducts,
          purchasingProductId: purchasingProductId,
          onPurchase: onPurchase,
        ),
        if (monthlyProducts.isNotEmpty && oneTimeProducts.isNotEmpty)
          const SizedBox(height: 24),
        if (oneTimeProducts.isNotEmpty) ...[
          const Text(
            'One-time purchase',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: AppTypography.semiBold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 12),
          _ProductList(
            products: oneTimeProducts,
            purchasingProductId: purchasingProductId,
            onPurchase: onPurchase,
          ),
        ],
      ],
    );
  }

  static bool _isOneTime(StoreProduct product) =>
      product.productCategory == ProductCategory.nonSubscription;

  static bool _isMonthly(StoreProduct product) =>
      !_isOneTime(product) && product.subscriptionPeriod == 'P1M';
}

class _ProductsStatus extends StatelessWidget {
  const _ProductsStatus({required this.message, this.child});

  final String message;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (child case final childWidget?) ...[
            childWidget,
            const SizedBox(height: 12),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.whiteAlpha65),
          ),
        ],
      ),
    );
  }
}

class _ProductList extends StatelessWidget {
  const _ProductList({
    required this.products,
    required this.purchasingProductId,
    required this.onPurchase,
  });

  final List<StoreProduct> products;
  final String? purchasingProductId;
  final ValueChanged<StoreProduct> onPurchase;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == products.length - 1 ? 0 : 12,
          ),
          child: _RevenueCatProductCard(
            product: product,
            isBusy: purchasingProductId != null,
            isPurchasing: purchasingProductId == product.identifier,
            onTap: () => onPurchase(product),
          ),
        );
      },
    );
  }
}

class _RevenueCatProductCard extends StatelessWidget {
  const _RevenueCatProductCard({
    required this.product,
    required this.isBusy,
    required this.isPurchasing,
    required this.onTap,
  });

  final StoreProduct product;
  final bool isBusy;
  final bool isPurchasing;
  final VoidCallback onTap;

  bool get _isOneTime =>
      product.productCategory == ProductCategory.nonSubscription;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.whiteAlpha13,
        border: Border.all(color: AppColors.whiteAlpha20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  product.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: AppTypography.bold,
                    color: AppColors.white,
                  ),
                ),
              ),
              Text(
                _isOneTime
                    ? product.priceString
                    : '${product.priceString}/month',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: AppTypography.bold,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          if (product.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              product.description,
              style: const TextStyle(color: AppColors.whiteAlpha65),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              key: ValueKey('revenuecat-purchase-${product.identifier}'),
              onPressed: isBusy ? null : onTap,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.black,
              ),
              child: isPurchasing
                  ? const BarSpinner(size: 20, color: AppColors.black)
                  : Text(_isOneTime ? 'Unlock photos' : 'Subscribe'),
            ),
          ),
        ],
      ),
    );
  }
}
