import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:look_atlas/core/config/app_config.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/logging/app_logger.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/core/storage/key_value_store.dart';
import 'package:look_atlas/features/subscription/data/models/subscription_product_model.dart';
import 'package:look_atlas/features/subscription/data/models/subscription_status_model.dart';
import 'package:look_atlas/features/subscription/domain/entities/subscription_product.dart';
import 'package:look_atlas/features/subscription/domain/entities/subscription_status.dart';
import 'package:look_atlas/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat-backed subscription repository.
///
/// If no platform API key is configured the repository becomes a no-op that
/// reports the free tier, so the look_atlas runs without a RevenueCat account.
class RevenueCatSubscriptionRepository implements SubscriptionRepository {
  RevenueCatSubscriptionRepository(this._store);

  /// Persists the last-known status so a premium user who launches offline
  /// is not downgraded to free while RevenueCat is unreachable.
  final KeyValueStore _store;

  static const _statusKey = 'subscription_last_status';

  final _controller = StreamController<SubscriptionStatus>.broadcast();

  /// Whether [_onCustomerInfo] was registered with the SDK (so [dispose] only
  /// removes what was added).
  bool _listenerAdded = false;
  final Map<String, StoreProduct> _productsById = {};

  String get _apiKey => Platform.isIOS
      ? AppConfig.revenueCatIosKey
      : AppConfig.revenueCatAndroidKey;

  @override
  bool get isConfigured => _apiKey.isNotEmpty;

  @override
  Future<void> configure({String? appUserId}) async {
    if (!isConfigured) {
      AppLogger.warning('RevenueCat not configured; running on free tier.');
      _controller.add(SubscriptionStatus.free);
      return;
    }

    await Purchases.setLogLevel(
      AppConfig.isDev ? LogLevel.debug : LogLevel.warn,
    );
    final config = PurchasesConfiguration(_apiKey)..appUserID = appUserId;
    await Purchases.configure(config);

    Purchases.addCustomerInfoUpdateListener(_onCustomerInfo);
    _listenerAdded = true;
    _controller.add(await currentStatus());
  }

  void _onCustomerInfo(CustomerInfo info) => _controller.add(_mapStatus(info));

  @override
  Stream<SubscriptionStatus> statusChanges() => _controller.stream;

  @override
  Future<SubscriptionStatus> currentStatus() async {
    if (!isConfigured) return SubscriptionStatus.free;
    try {
      return _mapStatus(await Purchases.getCustomerInfo());
    } on PlatformException catch (error, stack) {
      AppLogger.warning('currentStatus failed: $error\n$stack');
      // Offline fresh start: fall back to the last persisted status so a
      // premium user is not shown the free tier, defaulting to free when
      // nothing was ever persisted.
      return _readPersistedStatus() ?? SubscriptionStatus.free;
    }
  }

  @override
  Future<Result<List<SubscriptionProduct>>> fetchProducts() async {
    if (!isConfigured) return const Ok([]);
    try {
      final subscriptions = AppConfig.revenueCatSubscriptionProductIds;
      final oneTime = AppConfig.revenueCatOneTimeProductIds;
      final products = await Future.wait([
        if (subscriptions.isNotEmpty) Purchases.getProducts(subscriptions),
        if (oneTime.isNotEmpty)
          Purchases.getProducts(
            oneTime,
            productCategory: ProductCategory.nonSubscription,
          ),
      ]);
      final storeProducts = [for (final group in products) ...group];
      _productsById
        ..clear()
        ..addEntries(
          storeProducts.map((product) => MapEntry(product.identifier, product)),
        );
      return Ok(
        storeProducts.map(SubscriptionProductModel.fromStoreProduct).toList(),
      );
    } on PlatformException catch (error, stack) {
      return Err(
        SubscriptionFailure(
          'Products are unavailable right now. Please try again.',
          cause: error,
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<SubscriptionStatus>> purchase(String productId) async {
    if (!isConfigured) {
      return const Err(SubscriptionFailure('Purchases are not available.'));
    }
    final product = _productsById[productId];
    if (product == null) {
      return const Err(
        SubscriptionFailure(
          'We could not complete the purchase. Please try again.',
        ),
      );
    }
    try {
      final result = await Purchases.purchase(
        PurchaseParams.storeProduct(product),
      );
      return Ok(_emit(_mapStatus(result.customerInfo)));
    } on PlatformException catch (error, stack) {
      return Err(_mapError(error, stack));
    }
  }

  @override
  Future<Result<SubscriptionStatus>> restore() async {
    if (!isConfigured) {
      return const Err(SubscriptionFailure('Purchases are not available.'));
    }
    try {
      return Ok(_emit(_mapStatus(await Purchases.restorePurchases())));
    } on PlatformException catch (error, stack) {
      return Err(_mapError(error, stack));
    }
  }

  @override
  Future<void> logIn(String userId) async {
    if (!isConfigured) return;
    final result = await Purchases.logIn(userId);
    _controller.add(_mapStatus(result.customerInfo));
  }

  @override
  Future<void> logOut() async {
    if (!isConfigured) return;
    _controller.add(_mapStatus(await Purchases.logOut()));
  }

  /// Pushes [status] through [statusChanges] so listeners (the subscription
  /// controller) see every transition the repo learns about, even when the
  /// SDK's own customer-info callback lags behind.
  SubscriptionStatus _emit(SubscriptionStatus status) {
    _controller.add(status);
    return status;
  }

  SubscriptionStatus _mapStatus(CustomerInfo info) {
    final status = SubscriptionStatusModel.fromCustomerInfo(
      info,
      premiumEntitlementId: AppConfig.premiumEntitlementId,
    );
    _persistStatus(status);
    return status;
  }

  /// Fire-and-forget write of the last-known status for offline fallback.
  void _persistStatus(SubscriptionStatus status) {
    unawaited(
      _store.setString(
        _statusKey,
        jsonEncode(SubscriptionStatusModel.fromEntity(status).toJson()),
      ),
    );
  }

  SubscriptionStatus? _readPersistedStatus() {
    final raw = _store.getString(_statusKey);
    if (raw == null) return null;
    try {
      return SubscriptionStatusModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } on Object catch (error) {
      // A corrupt or unexpectedly-shaped cache must never crash startup.
      AppLogger.warning('Discarding unreadable cached status: $error');
      return null;
    }
  }

  SubscriptionFailure _mapError(PlatformException error, StackTrace stack) {
    final code = PurchasesErrorHelper.getErrorCode(error);
    if (code == PurchasesErrorCode.purchaseCancelledError) {
      return SubscriptionFailure(
        'Purchase cancelled.',
        userCancelled: true,
        cause: error,
        stackTrace: stack,
      );
    }
    return SubscriptionFailure(
      'We could not complete the purchase. Please try again.',
      cause: error,
      stackTrace: stack,
    );
  }

  void dispose() {
    // Pair with the add in [configure]; the SDK holds listeners globally.
    if (_listenerAdded) {
      Purchases.removeCustomerInfoUpdateListener(_onCustomerInfo);
      _listenerAdded = false;
    }
    unawaited(_controller.close());
  }
}
