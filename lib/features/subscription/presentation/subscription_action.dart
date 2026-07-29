import 'package:look_atlas/core/error/failure.dart';

/// State of the paywall's purchase/restore action. Purchase and restore are
/// mutually exclusive: at most one variant other than [SubscriptionIdle] is
/// ever active, and new actions are ignored while one is in flight.
sealed class SubscriptionAction {
  const SubscriptionAction();

  /// Whether an action is currently in flight.
  bool get isBusy => this is! SubscriptionIdle;
}

/// No action in flight. Carries the failure of the last completed action so
/// the paywall can surface it; null after success or user cancellation.
final class SubscriptionIdle extends SubscriptionAction {
  const SubscriptionIdle({this.failure});

  final SubscriptionFailure? failure;
}

/// A purchase is in flight.
final class SubscriptionPurchasing extends SubscriptionAction {
  const SubscriptionPurchasing(this.productId);

  /// Store identifier of the product being bought, so the paywall can
  /// show the spinner on the tapped plan only.
  final String productId;
}

/// A restore is in flight.
final class SubscriptionRestoring extends SubscriptionAction {
  const SubscriptionRestoring();
}
