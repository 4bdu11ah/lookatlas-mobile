import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/subscription/domain/subscription_status.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Subscription contract. The default implementation wraps RevenueCat; the
/// presentation layer depends only on this interface.
///
/// [StoreProduct] is surfaced so paywalls can render localized store prices
/// and purchase products directly without RevenueCat offerings.
abstract interface class SubscriptionRepository {
  /// Whether a RevenueCat API key was provided for this platform.
  bool get isConfigured;

  Future<void> configure({String? appUserId});

  Stream<SubscriptionStatus> statusChanges();

  Future<SubscriptionStatus> currentStatus();

  Future<Result<List<StoreProduct>>> fetchProducts();

  Future<Result<SubscriptionStatus>> purchase(StoreProduct product);

  Future<Result<SubscriptionStatus>> restore();

  Future<void> logIn(String userId);

  Future<void> logOut();
}
