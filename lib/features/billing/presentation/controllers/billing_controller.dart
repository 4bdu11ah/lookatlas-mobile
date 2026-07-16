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

  void preparePlans() {
    state = state.copyWith(
      selectedCycle: state.currentCycle,
      action: _BillingAction.idle,
    );
  }

  void selectCycle(_BillingCycle cycle) {
    state = state.copyWith(selectedCycle: cycle);
  }

  Future<void> changePlan(_BillingPlan plan) async {
    if (state.action == _BillingAction.changingPlan) return;
    state = state.copyWith(action: _BillingAction.changingPlan);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final details = _billingPlans[plan]!;
    state = state.copyWith(
      currentPlan: plan,
      currentCycle: state.selectedCycle,
      creditsRemaining: state.creditsRemaining + details.credits,
      cancellation: state.cancellation.copyWith(scheduled: false),
      action: _BillingAction.planChangeSuccess,
    );
  }

  void prepareCancellation() {
    state = state.copyWith(
      action: _BillingAction.idle,
      cancellation: state.cancellation.copyWith(
        clearReason: true,
        feedback: '',
      ),
    );
  }

  void selectCancellationReason(_CancellationReason reason) {
    state = state.copyWith(
      cancellation: state.cancellation.copyWith(reason: reason),
    );
  }

  void setCancellationFeedback(String feedback) {
    state = state.copyWith(
      cancellation: state.cancellation.copyWith(feedback: feedback),
    );
  }

  Future<void> cancelSubscription() async {
    if (state.action == _BillingAction.cancelling) return;
    state = state.copyWith(action: _BillingAction.cancelling);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    state = state.copyWith(
      cancellation: state.cancellation.copyWith(scheduled: true),
      action: _BillingAction.cancellationSuccess,
    );
  }

  Future<void> refreshHistory() async {
    if (state.historyRefreshing) return;
    state = state.copyWith(historyRefreshing: true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    state = state.copyWith(historyRefreshing: false);
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
