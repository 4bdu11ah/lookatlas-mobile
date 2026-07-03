import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/features/subscription/data/models/subscription_status_model.dart';
import 'package:look_atlas/features/subscription/domain/subscription_status.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

void main() {
  group('SubscriptionStatusModel JSON', () {
    final premium = SubscriptionStatus(
      isPremium: true,
      activeEntitlements: const ['premium'],
      entitlementId: 'premium',
      productId: 'product_monthly',
      expiresAt: DateTime.utc(2026, 8, 1, 12),
      willRenew: true,
      managementUrl: 'https://apps.apple.com/account/subscriptions',
      isSandbox: true,
    );

    test('toJson/fromJson round-trips every field', () {
      final decoded = SubscriptionStatusModel.fromJson(
        SubscriptionStatusModel.fromEntity(premium).toJson(),
      );

      expect(decoded, premium);
    });

    test('decodes the legacy cached shape with defaults for new fields', () {
      // The pre-upgrade cache only stored these two keys.
      final decoded = SubscriptionStatusModel.fromJson(const {
        'is_premium': true,
        'active_entitlements': ['premium'],
      });

      expect(decoded.isPremium, isTrue);
      expect(decoded.activeEntitlements, ['premium']);
      expect(decoded.entitlementId, isNull);
      expect(decoded.productId, isNull);
      expect(decoded.expiresAt, isNull);
      expect(decoded.willRenew, isFalse);
      expect(decoded.managementUrl, isNull);
      expect(decoded.isSandbox, isFalse);
    });

    test('decodes an empty map to the free tier', () {
      expect(
        SubscriptionStatusModel.fromJson(const {}),
        SubscriptionStatus.free,
      );
    });

    test('decodes a malformed expires_at to null instead of throwing', () {
      final decoded = SubscriptionStatusModel.fromJson(const {
        'is_premium': true,
        'expires_at': 'not-a-date',
      });

      expect(decoded.expiresAt, isNull);
    });
  });

  group('SubscriptionStatusModel.fromCustomerInfo', () {
    CustomerInfo customerInfo(
      EntitlementInfos entitlements, {
      String? managementUrl,
    }) => CustomerInfo(
      entitlements,
      const {},
      const [],
      const [],
      const [],
      '2026-01-01',
      'anonymous-1',
      const {},
      '2026-07-01',
      managementURL: managementUrl,
    );

    test('maps an active premium entitlement', () {
      const entitlement = EntitlementInfo(
        'premium',
        true,
        true,
        '2026-06-01T00:00:00Z',
        '2026-06-01T00:00:00Z',
        'product_monthly',
        true,
        expirationDate: '2026-08-01T00:00:00Z',
      );
      final status = SubscriptionStatusModel.fromCustomerInfo(
        customerInfo(
          const EntitlementInfos(
            {'premium': entitlement},
            {'premium': entitlement},
          ),
          managementUrl: 'https://play.google.com/store/account/subscriptions',
        ),
        premiumEntitlementId: 'premium',
      );

      expect(status.isPremium, isTrue);
      expect(status.activeEntitlements, ['premium']);
      expect(status.entitlementId, 'premium');
      expect(status.productId, 'product_monthly');
      expect(status.expiresAt, DateTime.utc(2026, 8));
      expect(status.willRenew, isTrue);
      expect(
        status.managementUrl,
        'https://play.google.com/store/account/subscriptions',
      );
      expect(status.isSandbox, isTrue);
    });

    test('maps a customer without the premium entitlement to free', () {
      final status = SubscriptionStatusModel.fromCustomerInfo(
        customerInfo(const EntitlementInfos({}, {})),
        premiumEntitlementId: 'premium',
      );

      expect(status.isPremium, isFalse);
      expect(status.activeEntitlements, isEmpty);
      expect(status.entitlementId, isNull);
      expect(status.expiresAt, isNull);
      expect(status.willRenew, isFalse);
    });
  });
}
