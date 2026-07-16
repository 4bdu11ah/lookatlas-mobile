part of '../../dashboard/presentation/screens/dashboard_screen.dart';

const _accountSettingsLoadingState = _AccountSettingsState(
  status: _AccountSettingsStatus.loading,
  companyName: null,
  email: null,
  plan: 'Pro',
  planPrice: r'$99/usd',
  memberSince: 'January 10, 2026',
);

_AccountSettingsState _accountSettingsLoadedState({
  required String? companyName,
  required String? email,
}) {
  return _AccountSettingsState(
    status: _AccountSettingsStatus.loaded,
    companyName: companyName,
    email: email,
    plan: 'Pro',
    planPrice: r'$99/usd',
    memberSince: 'January 10, 2026',
  );
}

const _accountSettingsErrorState = _AccountSettingsState(
  status: _AccountSettingsStatus.error,
  companyName: null,
  email: null,
  plan: 'Pro',
  planPrice: r'$99/usd',
  memberSince: 'January 10, 2026',
  errorMessage: 'Failed to load settings',
);
