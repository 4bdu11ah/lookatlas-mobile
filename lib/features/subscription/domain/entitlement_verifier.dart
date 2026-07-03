import 'package:look_atlas/features/subscription/domain/subscription_status.dart';

/// Seam for verifying that a [SubscriptionStatus] really grants access.
///
/// Client-side RevenueCat entitlements are the source of truth for in-app UI
/// today, so the default [LocalEntitlementVerifier] simply trusts the status.
/// When backend register/login APIs exist, add a `RemoteEntitlementVerifier`
/// that cross-checks the backend's webhook-fed entitlements table (RevenueCat
/// webhooks -> backend) for server-gated content, and swap it in with a single
/// override of `entitlementVerifierProvider`.
// ignore: one_member_abstracts, an interface (not a callback) so the remote implementation can grow config and be swapped via DI
abstract interface class EntitlementVerifier {
  /// Whether [status] should be treated as granting premium access.
  Future<bool> verify(SubscriptionStatus status);
}

/// Default verifier: trusts the client-side entitlement flag as-is.
class LocalEntitlementVerifier implements EntitlementVerifier {
  const LocalEntitlementVerifier();

  @override
  Future<bool> verify(SubscriptionStatus status) async => status.isPremium;
}
