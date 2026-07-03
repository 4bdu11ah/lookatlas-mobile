import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/subscription/domain/subscription_status.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Subscription contract. The default implementation wraps RevenueCat; the
/// presentation layer depends only on this interface.
///
/// [Package] is RevenueCat's unit of purchase and is surfaced to the paywall
/// so it can render localized prices. This is the one intentional SDK leak.
abstract interface class SubscriptionRepository {
  /// Whether a RevenueCat API key was provided for this platform.
  bool get isConfigured;

  Future<void> configure({String? appUserId});

  Stream<SubscriptionStatus> statusChanges();

  Future<SubscriptionStatus> currentStatus();

  /// Purchasable packages from the current offering.
  Future<Result<List<Package>>> fetchPackages();

  Future<Result<SubscriptionStatus>> purchase(Package package);

  Future<Result<SubscriptionStatus>> restore();

  Future<void> logIn(String userId);

  Future<void> logOut();
}
