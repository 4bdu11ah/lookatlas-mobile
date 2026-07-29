/// Subscription state and actions.
///
/// How the purchase-before-login flow works end to end:
///
/// 1. Bootstrap configures RevenueCat with the restored user id, or
///    anonymously when nobody is signed in, so the paywall (a public route)
///    can sell to visitors before they register.
/// 2. An anonymous purchase succeeds under RevenueCat's anonymous app user id;
///    the paywall then sends the visitor to sign-up.
/// 3. On register/sign-in, `AuthController._syncIdentity` calls
///    `SubscriptionRepository.logIn(user.id)`, which transfers the anonymous
///    purchase to the account (RevenueCat's default transfer behavior) and
///    pushes the merged `CustomerInfo` through `statusChanges()` — so
///    [SubscriptionController] refreshes itself without a manual invalidate.
///    `logOut` on sign-out mirrors this back to a fresh anonymous user.
/// 4. Offline fallback: the repository persists the last-known status, so a
///    premium user who launches without connectivity keeps premium UI.
/// 5. Server-gated content (once a backend exists) should cross-check
///    entitlements via the `EntitlementVerifier` seam instead of trusting the
///    client flag; see `entitlement_verifier.dart`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/subscription/di/subscription_providers.dart';
import 'package:look_atlas/features/subscription/domain/subscription_repository.dart';
import 'package:look_atlas/features/subscription/domain/subscription_status.dart';
import 'package:look_atlas/features/subscription/presentation/subscription_action.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Live subscription status. Updates automatically when RevenueCat reports a
/// change (purchase, renewal, expiry, identity transfer on login).
class SubscriptionController extends AsyncNotifier<SubscriptionStatus> {
  SubscriptionRepository get _repo => ref.read(subscriptionRepositoryProvider);

  @override
  Future<SubscriptionStatus> build() async {
    // The stream is authoritative. A `statusChanges()` event can arrive while
    // `currentStatus()` is still in flight (e.g. RevenueCat pushes an update
    // right after configure); when this build future then completes it would
    // clobber the fresher event. Remember the latest stream value and prefer
    // it over the possibly-stale fetch.
    SubscriptionStatus? fromStream;
    final sub = _repo.statusChanges().listen((status) {
      fromStream = status;
      state = AsyncData(status);
    });
    ref.onDispose(sub.cancel);

    final current = await _repo.currentStatus();
    return fromStream ?? current;
  }
}

/// Runs purchase/restore for the paywall and exposes their in-flight state.
///
/// Rules: the two actions are mutually exclusive and non-reentrant (a call
/// while busy is a no-op returning false); a user-cancelled purchase returns
/// to idle silently; every other failure lands in [SubscriptionIdle.failure]
/// as a typed [SubscriptionFailure] with a user-safe message. Successful
/// results reach [SubscriptionController] through the repository's
/// `statusChanges()` stream, so no cross-notifier write is needed.
class SubscriptionActionController extends Notifier<SubscriptionAction> {
  SubscriptionRepository get _repo => ref.read(subscriptionRepositoryProvider);

  @override
  SubscriptionAction build() => const SubscriptionIdle();

  /// Purchases [product]. Returns whether the purchase succeeded.
  Future<bool> purchase(StoreProduct product) => _run(
    SubscriptionPurchasing(product.identifier),
    () => _repo.purchase(product),
  );

  /// Restores previous purchases. Returns whether the restore succeeded.
  Future<bool> restore() => _run(const SubscriptionRestoring(), _repo.restore);

  Future<bool> _run(
    SubscriptionAction busy,
    Future<Result<SubscriptionStatus>> Function() action,
  ) async {
    if (state.isBusy) return false;
    state = busy;
    final result = await action();
    state = SubscriptionIdle(failure: _failureToSurface(result));
    return result.isOk;
  }

  /// Null for success and for a user-cancelled purchase (not an error);
  /// otherwise a typed [SubscriptionFailure] safe to show verbatim.
  SubscriptionFailure? _failureToSurface(Result<SubscriptionStatus> result) =>
      switch (result.failureOrNull) {
        null => null,
        SubscriptionFailure(userCancelled: true) => null,
        final SubscriptionFailure failure => failure,
        final failure => SubscriptionFailure(
          'We could not complete the purchase. Please try again.',
          cause: failure,
        ),
      };
}

final subscriptionControllerProvider =
    AsyncNotifierProvider<SubscriptionController, SubscriptionStatus>(
      SubscriptionController.new,
    );

/// autoDispose so a stale failure from a previous attempt does not persist
/// app-wide once the paywall has stopped listening.
final NotifierProvider<SubscriptionActionController, SubscriptionAction>
subscriptionActionProvider =
    NotifierProvider.autoDispose<
      SubscriptionActionController,
      SubscriptionAction
    >(SubscriptionActionController.new);

/// Convenience flag for gating premium features in the UI.
final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionControllerProvider).value?.isPremium ?? false;
});
