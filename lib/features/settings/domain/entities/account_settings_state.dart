part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

enum _AccountSettingsStatus { loading, loaded, error }

class _AccountSettingsState {
  const _AccountSettingsState({
    required this.status,
    required this.companyName,
    required this.email,
    required this.plan,
    required this.planPrice,
    required this.memberSince,
    this.errorMessage,
  });

  final _AccountSettingsStatus status;
  final String? companyName;
  final String? email;
  final String plan;
  final String planPrice;
  final String memberSince;
  final String? errorMessage;
}
