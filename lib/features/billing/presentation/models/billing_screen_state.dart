const creditPackSize = 80;
const creditPackPrice = 20.0;

enum BillingAction {
  idle,
  purchasing,
  purchaseSuccess,
}

class BillingScreenState {
  const BillingScreenState({
    required this.quantity,
    required this.action,
  });

  final int quantity;
  final BillingAction action;

  int get purchaseCredits => quantity * creditPackSize;
  double get purchaseTotal => quantity * creditPackPrice;

  BillingScreenState copyWith({
    int? quantity,
    BillingAction? action,
  }) {
    return BillingScreenState(
      quantity: quantity ?? this.quantity,
      action: action ?? this.action,
    );
  }
}

const billingInitialState = BillingScreenState(
  quantity: 1,
  action: BillingAction.idle,
);
