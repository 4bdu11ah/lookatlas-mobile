import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/billing/di/billing_api_providers.dart';
import 'package:look_atlas/features/billing/domain/entities/billing_checkout.dart';
import 'package:look_atlas/services/service_providers.dart';

@immutable
class BillingCheckoutState {
  const BillingCheckoutState({this.isBusy = false, this.failure});

  final bool isBusy;
  final Failure? failure;
}

class BillingCheckoutController extends Notifier<BillingCheckoutState> {
  @override
  BillingCheckoutState build() => const BillingCheckoutState();

  Future<bool> startSubscription({
    required String priceId,
    bool useProUpsell = false,
  }) => _start(
    () => ref.read(createBillingCheckoutUseCaseProvider)(
      priceId: priceId,
      successUrl: Uri.parse('lookatlas:/billing/success'),
      cancelUrl: Uri.parse('lookatlas:/onboarding/activate'),
      useProUpsell: useProUpsell,
    ),
  );

  Future<bool> startOnetime() => _start(
    () => ref.read(createOnetimeCheckoutUseCaseProvider)(
      successUrl: Uri.parse(
        'lookatlas:/onboarding/success?session_id={CHECKOUT_SESSION_ID}',
      ),
      cancelUrl: Uri.parse('lookatlas:/onboarding/activate'),
    ),
  );

  Future<bool> _start(
    Future<Result<CheckoutSession>> Function() create,
  ) async {
    if (state.isBusy) return false;
    state = const BillingCheckoutState(isBusy: true);
    final result = await create();
    if (result case Err(:final failure)) {
      state = BillingCheckoutState(failure: failure);
      return false;
    }
    try {
      await ref
          .read(externalUrlServiceProvider)
          .openCheckout(result.valueOrNull!.url);
      state = const BillingCheckoutState();
      return true;
    } on Object catch (error, stack) {
      state = BillingCheckoutState(
        failure: UnknownFailure(
          'Could not open secure checkout.',
          cause: error,
          stackTrace: stack,
        ),
      );
      return false;
    }
  }
}

final billingCheckoutControllerProvider =
    NotifierProvider<BillingCheckoutController, BillingCheckoutState>(
      BillingCheckoutController.new,
    );
