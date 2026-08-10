import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/onboarding/presentation/providers/swipe_controller.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/onboarding_widgets.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/revenuecat_products_section.dart';
import 'package:look_atlas/features/subscription/di/subscription_providers.dart';
import 'package:look_atlas/features/subscription/presentation/subscription_action.dart';
import 'package:look_atlas/features/subscription/presentation/subscription_controller.dart';
import 'package:look_atlas/shared/widgets/app_snack_bar.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

part '../widgets/activate_paywall_loader_widgets.dart';
part '../widgets/activate_paywall_content_widgets.dart';

/// The dark activate / paywall screen (mockup 11): a short "analyzing your
/// liked looks" loader, then the black paywall with RevenueCat monthly and
/// one-time products.
class ActivatePaywallScreen extends ConsumerStatefulWidget {
  const ActivatePaywallScreen({super.key});

  @override
  ConsumerState<ActivatePaywallScreen> createState() =>
      _ActivatePaywallScreenState();
}

class _ActivatePaywallScreenState extends ConsumerState<ActivatePaywallScreen> {
  bool _analyzing = true;
  Timer? _loader;

  @override
  void initState() {
    super.initState();
    unawaited(_verifySession());
    _loader = Timer(const Duration(milliseconds: 4500), () {
      if (mounted) setState(() => _analyzing = false);
    });
  }

  Future<void> _verifySession() async {
    try {
      await ref.read(authRepositoryProvider).verifySession();
    } on Object {
      // Pricing remains available if local session storage cannot be read.
    }
  }

  @override
  void dispose() {
    _loader?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(subscriptionActionProvider, (_, next) {
      if (next case SubscriptionIdle(:final failure?)) {
        AppSnackBar.showError(context, failure.message);
      }
    });
    final savedCount = ref.watch(swipeControllerProvider).savedCount;
    final savedUrls = [
      for (final image in ref.watch(savedImagesProvider)) image.url,
    ];
    final revenueCatProducts = ref.watch(revenueCatProductsProvider);
    final purchaseAction = ref.watch(subscriptionActionProvider);
    final purchasingProductId = switch (purchaseAction) {
      SubscriptionPurchasing(:final productId) => productId,
      _ => null,
    };
    return Scaffold(
      backgroundColor: AppColors.black,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _analyzing
            ? _AnalyzingLoader(savedCount: savedCount, urls: savedUrls)
            : _Paywall(
                urls: savedUrls,
                revenueCatSection: revenueCatProducts.when(
                  loading: () => RevenueCatProductsSection(
                    isLoading: true,
                    purchasingProductId: purchasingProductId,
                    onPurchase: _purchaseRevenueCatProduct,
                  ),
                  error: (error, _) => RevenueCatProductsSection(
                    errorMessage: error is Failure
                        ? error.message
                        : 'Plans are unavailable right now.',
                    purchasingProductId: purchasingProductId,
                    onPurchase: _purchaseRevenueCatProduct,
                    onRetry: () => ref.invalidate(revenueCatProductsProvider),
                  ),
                  data: (products) => RevenueCatProductsSection(
                    products: products,
                    purchasingProductId: purchasingProductId,
                    onPurchase: _purchaseRevenueCatProduct,
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _purchaseRevenueCatProduct(StoreProduct product) async {
    final purchased = await ref
        .read(subscriptionActionProvider.notifier)
        .purchase(product);
    if (!purchased || !mounted) return;
    AppSnackBar.showSuccess(context, 'Purchase successful.');
    context.go(AppRoutes.billingSuccess);
  }
}

// --- State A: analyzing loader ------------------------------------------------
