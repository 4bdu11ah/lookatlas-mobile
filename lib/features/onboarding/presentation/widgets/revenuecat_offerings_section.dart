import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/shared/widgets/bar_spinner.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatOfferingsSection extends StatelessWidget {
  const RevenueCatOfferingsSection({
    required this.packages,
    required this.purchasingPackageId,
    required this.onPurchase,
    super.key,
  });

  final List<Package> packages;
  final String? purchasingPackageId;
  final ValueChanged<Package> onPurchase;

  @override
  Widget build(BuildContext context) {
    if (packages.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Available in the app',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: AppTypography.bold,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Subscriptions and one-time downloads from your app store.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.whiteAlpha65),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: packages.length,
          itemBuilder: (context, index) {
            final package = packages[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == packages.length - 1 ? 0 : 12,
              ),
              child: _RevenueCatProductCard(
                package: package,
                isBusy: purchasingPackageId != null,
                isPurchasing: purchasingPackageId == package.identifier,
                onTap: () => onPurchase(package),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RevenueCatProductCard extends StatelessWidget {
  const _RevenueCatProductCard({
    required this.package,
    required this.isBusy,
    required this.isPurchasing,
    required this.onTap,
  });

  final Package package;
  final bool isBusy;
  final bool isPurchasing;
  final VoidCallback onTap;

  bool get _isOneTime =>
      package.packageType == PackageType.lifetime ||
      package.storeProduct.productCategory == ProductCategory.nonSubscription;

  @override
  Widget build(BuildContext context) {
    final product = package.storeProduct;
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
                product.priceString,
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
