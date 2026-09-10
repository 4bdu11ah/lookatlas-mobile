import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/billing/presentation/models/billing_screen_state.dart';

class BillingController extends Notifier<BillingScreenState> {
  @override
  BillingScreenState build() => billingInitialState;

  void preparePurchase() {
    state = state.copyWith(quantity: 1, action: BillingAction.idle);
  }

  void changeQuantity(int change) {
    final quantity = (state.quantity + change).clamp(1, 10);
    state = state.copyWith(quantity: quantity);
  }

  Future<void> completePurchase() async {
    if (state.action == BillingAction.purchasing) return;
    state = state.copyWith(action: BillingAction.purchasing);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    state = state.copyWith(action: BillingAction.purchaseSuccess);
  }

  void finishPurchase() {
    state = state.copyWith(
      action: BillingAction.idle,
      quantity: 1,
    );
  }

  void resetAction() {
    state = state.copyWith(action: BillingAction.idle);
  }
}

final NotifierProvider<BillingController, BillingScreenState>
billingControllerProvider =
    NotifierProvider.autoDispose<BillingController, BillingScreenState>(
      BillingController.new,
    );
