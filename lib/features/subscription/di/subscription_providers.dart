import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/providers/core_providers.dart';
import 'package:look_atlas/features/subscription/data/revenuecat_subscription_repository.dart';
import 'package:look_atlas/features/subscription/domain/entitlement_verifier.dart';
import 'package:look_atlas/features/subscription/domain/subscription_repository.dart';

/// Dependency injection for the subscription feature. Presentation code
/// (controllers, screens) depends on these providers, never on the concrete
/// implementations directly.

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final repo = RevenueCatSubscriptionRepository(
    ref.watch(keyValueStoreProvider),
  );
  ref.onDispose(repo.dispose);
  return repo;
});

/// Entitlement verification seam. Swap in a `RemoteEntitlementVerifier` with
/// a single override here once a backend entitlements API exists; see
/// [EntitlementVerifier] for the intended setup.
final entitlementVerifierProvider = Provider<EntitlementVerifier>(
  (ref) => const LocalEntitlementVerifier(),
);
