import 'package:flutter/foundation.dart';

/// Snapshot of the user's entitlement state, decoupled from the RevenueCat SDK
/// so the rest of the app never imports purchase types directly. Pure: no
/// serialization concerns (that lives in the data-layer
/// `SubscriptionStatusModel`). Hand-written `copyWith` per AGENTS.md §8
/// (no codegen).
@immutable
class SubscriptionStatus {
  const SubscriptionStatus({
    required this.isPremium,
    this.activeEntitlements = const [],
    this.entitlementId,
    this.productId,
    this.expiresAt,
    this.willRenew = false,
    this.managementUrl,
    this.isSandbox = false,
  });

  /// Whether the premium entitlement is currently active.
  final bool isPremium;

  /// Identifiers of every active entitlement.
  final List<String> activeEntitlements;

  /// The premium entitlement identifier, when active.
  final String? entitlementId;

  /// The store product that unlocked premium, when active.
  final String? productId;

  /// When the premium entitlement expires. Null for free users and for
  /// lifetime purchases.
  final DateTime? expiresAt;

  /// Whether the subscription auto-renews at [expiresAt].
  final bool willRenew;

  /// Store URL where the user can manage (cancel, upgrade) the subscription.
  final String? managementUrl;

  /// True when the entitlement was unlocked by a sandbox (test) purchase.
  final bool isSandbox;

  static const free = SubscriptionStatus(isPremium: false);

  SubscriptionStatus copyWith({
    bool? isPremium,
    List<String>? activeEntitlements,
    String? entitlementId,
    String? productId,
    DateTime? expiresAt,
    bool? willRenew,
    String? managementUrl,
    bool? isSandbox,
  }) => SubscriptionStatus(
    isPremium: isPremium ?? this.isPremium,
    activeEntitlements: activeEntitlements ?? this.activeEntitlements,
    entitlementId: entitlementId ?? this.entitlementId,
    productId: productId ?? this.productId,
    expiresAt: expiresAt ?? this.expiresAt,
    willRenew: willRenew ?? this.willRenew,
    managementUrl: managementUrl ?? this.managementUrl,
    isSandbox: isSandbox ?? this.isSandbox,
  );

  @override
  bool operator ==(Object other) =>
      other is SubscriptionStatus &&
      other.isPremium == isPremium &&
      listEquals(other.activeEntitlements, activeEntitlements) &&
      other.entitlementId == entitlementId &&
      other.productId == productId &&
      other.expiresAt == expiresAt &&
      other.willRenew == willRenew &&
      other.managementUrl == managementUrl &&
      other.isSandbox == isSandbox;

  @override
  int get hashCode => Object.hash(
    isPremium,
    Object.hashAll(activeEntitlements),
    entitlementId,
    productId,
    expiresAt,
    willRenew,
    managementUrl,
    isSandbox,
  );
}
