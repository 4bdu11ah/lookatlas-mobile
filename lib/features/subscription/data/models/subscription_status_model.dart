import 'package:look_atlas/features/subscription/domain/subscription_status.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Data-layer representation of [SubscriptionStatus]. Extends the domain
/// entity and adds JSON (de)serialization plus the RevenueCat mapping, keeping
/// the entity free of transport concerns.
class SubscriptionStatusModel extends SubscriptionStatus {
  const SubscriptionStatusModel({
    required super.isPremium,
    super.activeEntitlements,
    super.entitlementId,
    super.productId,
    super.expiresAt,
    super.willRenew,
    super.managementUrl,
    super.isSandbox,
  });

  /// Decodes a persisted status. Backward compatible: every field falls back
  /// to a sensible default so an old cached shape (which only stored
  /// `is_premium` and `active_entitlements`) never throws.
  factory SubscriptionStatusModel.fromJson(Map<String, dynamic> json) =>
      SubscriptionStatusModel(
        isPremium: json['is_premium'] as bool? ?? false,
        activeEntitlements:
            (json['active_entitlements'] as List<dynamic>? ?? const [])
                .cast<String>(),
        entitlementId: json['entitlement_id'] as String?,
        productId: json['product_id'] as String?,
        expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? ''),
        willRenew: json['will_renew'] as bool? ?? false,
        managementUrl: json['management_url'] as String?,
        isSandbox: json['is_sandbox'] as bool? ?? false,
      );

  /// Maps RevenueCat's [CustomerInfo] to the domain status, reading the
  /// entitlement identified by [premiumEntitlementId].
  factory SubscriptionStatusModel.fromCustomerInfo(
    CustomerInfo info, {
    required String premiumEntitlementId,
  }) {
    final entitlement = info.entitlements.active[premiumEntitlementId];
    return SubscriptionStatusModel(
      isPremium: entitlement != null,
      activeEntitlements: info.entitlements.active.keys.toList(),
      entitlementId: entitlement?.identifier,
      productId: entitlement?.productIdentifier,
      expiresAt: DateTime.tryParse(entitlement?.expirationDate ?? ''),
      willRenew: entitlement?.willRenew ?? false,
      managementUrl: info.managementURL,
      isSandbox: entitlement?.isSandbox ?? false,
    );
  }

  /// Wraps a domain [SubscriptionStatus] so it can be persisted.
  factory SubscriptionStatusModel.fromEntity(SubscriptionStatus status) =>
      SubscriptionStatusModel(
        isPremium: status.isPremium,
        activeEntitlements: status.activeEntitlements,
        entitlementId: status.entitlementId,
        productId: status.productId,
        expiresAt: status.expiresAt,
        willRenew: status.willRenew,
        managementUrl: status.managementUrl,
        isSandbox: status.isSandbox,
      );

  Map<String, dynamic> toJson() => {
    'is_premium': isPremium,
    'active_entitlements': activeEntitlements,
    'entitlement_id': entitlementId,
    'product_id': productId,
    'expires_at': expiresAt?.toIso8601String(),
    'will_renew': willRenew,
    'management_url': managementUrl,
    'is_sandbox': isSandbox,
  };
}
