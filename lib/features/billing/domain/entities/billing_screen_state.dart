part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

enum _BillingAction {
  idle,
  purchasing,
  purchaseSuccess,
}

class _BillingScreenState {
  const _BillingScreenState({
    required this.quantity,
    required this.action,
  });

  final int quantity;
  final _BillingAction action;

  int get purchaseCredits => quantity * _creditPackSize;
  double get purchaseTotal => quantity * _creditPackPrice;

  _BillingScreenState copyWith({
    int? quantity,
    _BillingAction? action,
  }) {
    return _BillingScreenState(
      quantity: quantity ?? this.quantity,
      action: action ?? this.action,
    );
  }
}
