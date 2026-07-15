part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _BillingScreenState {
  const _BillingScreenState({
    required this.creditsRemaining,
    required this.monthlyPlan,
    required this.usageLabel,
  });

  final int creditsRemaining;
  final String monthlyPlan;
  final String usageLabel;
}
