import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_spacing.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/subscription/di/subscription_providers.dart';
import 'package:look_atlas/features/subscription/domain/subscription_status.dart';
import 'package:look_atlas/features/subscription/presentation/subscription_action.dart';
import 'package:look_atlas/features/subscription/presentation/subscription_controller.dart';
import 'package:look_atlas/shared/widgets/app_snack_bar.dart';
import 'package:look_atlas/shared/widgets/bar_spinner.dart';
import 'package:look_atlas/shared/widgets/primary_button.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Public paywall: reachable before sign-in so an anonymous visitor can
/// purchase first and register afterwards (the entitlement transfers to the
/// new account; see the flow doc in `subscription_controller.dart`).
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  Future<void> _purchase(
    BuildContext context,
    WidgetRef ref,
    Package package,
  ) async {
    final succeeded = await ref
        .read(subscriptionActionProvider.notifier)
        .purchase(package);
    if (!succeeded || !context.mounted) return;
    _handleSuccess(context, ref, message: 'You are now premium.');
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final succeeded = await ref
        .read(subscriptionActionProvider.notifier)
        .restore();
    if (!succeeded || !context.mounted) return;
    _handleSuccess(context, ref, message: 'Purchases restored.');
  }

  void _handleSuccess(
    BuildContext context,
    WidgetRef ref, {
    required String message,
  }) {
    final loggedIn = ref.read(authRepositoryProvider).currentUser != null;
    if (loggedIn) {
      AppSnackBar.showSuccess(context, message);
      if (Navigator.canPop(context)) Navigator.pop(context);
      return;
    }
    // Anonymous purchase: send the visitor to sign-up so the entitlement is
    // transferred to their new account on registration. `from` lands them on
    // home afterwards.
    AppSnackBar.showSuccess(
      context,
      'Purchase successful. Create an account to secure your subscription.',
    );
    context.go(
      Uri(
        path: AppRoutes.signUp,
        queryParameters: {'from': AppRoutes.home},
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(subscriptionActionProvider, (_, next) {
      if (next case SubscriptionIdle(:final failure?)) {
        AppSnackBar.showError(context, failure.message);
      }
    });

    final status =
        ref.watch(subscriptionControllerProvider).value ??
        SubscriptionStatus.free;

    return Scaffold(
      appBar: AppBar(title: const Text('Go Premium')),
      body: SafeArea(
        child: status.isPremium
            ? _PremiumView(status: status)
            : _OfferingsView(
                onPurchase: (package) => _purchase(context, ref, package),
                onRestore: () => _restore(context, ref),
              ),
      ),
    );
  }
}

/// The plan list for non-premium users, with loading/error/retry UX around
/// the offerings fetch.
class _OfferingsView extends ConsumerWidget {
  const _OfferingsView({required this.onPurchase, required this.onRestore});

  final void Function(Package package) onPurchase;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packagesAsync = ref.watch(revenueCatPackagesProvider);
    final action = ref.watch(subscriptionActionProvider);
    final theme = Theme.of(context);

    return packagesAsync.when(
      loading: () => const Center(child: BarSpinner(size: 32)),
      error: (error, _) => _EmptyState(
        message: error is Failure
            ? error.message
            : 'Plans are unavailable right now.',
        onRetry: () => ref.invalidate(revenueCatPackagesProvider),
      ),
      data: (packages) {
        if (packages.isEmpty) {
          return const _EmptyState(
            message:
                'No plans configured. Add offerings in your RevenueCat dashboard.',
          );
        }
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('Unlock everything', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Choose a plan to access all premium features.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final package in packages) ...[
              _PlanCard(
                package: package,
                enabled: !action.isBusy,
                isPurchasing: switch (action) {
                  SubscriptionPurchasing(:final packageId) =>
                    packageId == package.identifier,
                  _ => false,
                },
                onTap: () => onPurchase(package),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            const SizedBox(height: AppSpacing.sm),
            _RestoreButton(action: action, onPressed: onRestore),
          ],
        );
      },
    );
  }
}

class _RestoreButton extends StatelessWidget {
  const _RestoreButton({required this.action, required this.onPressed});

  final SubscriptionAction action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: action.isBusy ? null : onPressed,
      child: action is SubscriptionRestoring
          ? const ButtonLoader()
          : const Text('Restore purchases'),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.package,
    required this.enabled,
    required this.isPurchasing,
    required this.onTap,
  });

  final Package package;
  final bool enabled;
  final bool isPurchasing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final product = package.storeProduct;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              product.priceString,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            if (product.description.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(product.description, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Subscribe',
              isLoading: isPurchasing,
              onPressed: enabled ? onTap : null,
              fitToContent: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown to users who already have the premium entitlement: plan, renewal or
/// expiry date, and where to manage the subscription.
class _PremiumView extends StatelessWidget {
  const _PremiumView({required this.status});

  final SubscriptionStatus status;

  String _renewalText(BuildContext context) {
    final expiresAt = status.expiresAt;
    if (expiresAt == null) return 'You have lifetime access.';
    final date = MaterialLocalizations.of(context).formatMediumDate(expiresAt);
    return status.willRenew ? 'Renews on $date.' : 'Expires on $date.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final managementUrl = status.managementUrl;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('You are premium', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(_renewalText(context), style: theme.textTheme.bodyMedium),
        if (status.productId != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Plan: ${status.productId}'
            '${status.isSandbox ? ' (sandbox)' : ''}',
            style: theme.textTheme.bodySmall,
          ),
        ],
        if (managementUrl != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Manage subscription', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),

          // dependency is added; until then it is shown as copyable text.
          SelectableText(managementUrl, style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
