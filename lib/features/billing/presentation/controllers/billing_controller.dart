part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _BillingController extends Notifier<_BillingScreenState> {
  @override
  _BillingScreenState build() => _billingMockState;
}

final _billingControllerProvider =
    NotifierProvider<_BillingController, _BillingScreenState>(
      _BillingController.new,
    );
