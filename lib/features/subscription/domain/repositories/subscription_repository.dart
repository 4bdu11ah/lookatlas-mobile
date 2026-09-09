import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/subscription/domain/entities/subscription_product.dart';
import 'package:look_atlas/features/subscription/domain/entities/subscription_status.dart';

/// Subscription contract. Default implementation wraps RevenueCat; the
/// presentation layer depends only on this interface.
///
abstract interface class SubscriptionRepository {
  /// Whether a RevenueCat API key was provided for this platform.
  bool get isConfigured;

  Future<void> configure({String? appUserId});

  Stream<SubscriptionStatus> statusChanges();

  Future<SubscriptionStatus> currentStatus();

  Future<Result<List<SubscriptionProduct>>> fetchProducts();

  Future<Result<SubscriptionStatus>> purchase(String productId);

  Future<Result<SubscriptionStatus>> restore();

  Future<void> logIn(String userId);

  Future<void> logOut();
}
