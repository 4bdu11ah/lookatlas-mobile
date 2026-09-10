enum AccountSettingsStatus { loading, loaded, error }

class AccountSettingsState {
  const AccountSettingsState({
    required this.status,
    required this.companyName,
    required this.email,
    required this.plan,
    required this.planPrice,
    required this.memberSince,
    this.errorMessage,
  });

  final AccountSettingsStatus status;
  final String? companyName;
  final String? email;
  final String plan;
  final String planPrice;
  final String memberSince;
  final String? errorMessage;
}

const accountSettingsLoadingState = AccountSettingsState(
  status: AccountSettingsStatus.loading,
  companyName: null,
  email: null,
  plan: 'Pro',
  planPrice: r'$99/usd',
  memberSince: 'January 10, 2026',
);

AccountSettingsState accountSettingsLoadedState({
  required String? companyName,
  required String? email,
}) {
  return AccountSettingsState(
    status: AccountSettingsStatus.loaded,
    companyName: companyName,
    email: email,
    plan: 'Pro',
    planPrice: r'$99/usd',
    memberSince: 'January 10, 2026',
  );
}

const accountSettingsErrorState = AccountSettingsState(
  status: AccountSettingsStatus.error,
  companyName: null,
  email: null,
  plan: 'Pro',
  planPrice: r'$99/usd',
  memberSince: 'January 10, 2026',
  errorMessage: 'Failed to load settings',
);
