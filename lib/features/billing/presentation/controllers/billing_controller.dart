part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _BillingController extends Notifier<_BillingScreenState> {
  @override
  _BillingScreenState build() => _billingMockState;

  void preparePurchase() {
    state = state.copyWith(quantity: 1, action: _BillingAction.idle);
  }

  void changeQuantity(int change) {
    final quantity = (state.quantity + change).clamp(1, 10);
    state = state.copyWith(quantity: quantity);
  }

  Future<void> completePurchase() async {
    if (state.action == _BillingAction.purchasing) return;
    state = state.copyWith(action: _BillingAction.purchasing);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    state = state.copyWith(action: _BillingAction.purchaseSuccess);
  }

  void finishPurchase() {
    state = state.copyWith(
      action: _BillingAction.idle,
      quantity: 1,
    );
  }

  void resetAction() {
    state = state.copyWith(action: _BillingAction.idle);
  }
}

final NotifierProvider<_BillingController, _BillingScreenState>
_billingControllerProvider =
    NotifierProvider.autoDispose<_BillingController, _BillingScreenState>(
      _BillingController.new,
    );
