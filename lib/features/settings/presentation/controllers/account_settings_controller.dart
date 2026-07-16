part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _AccountSettingsController extends Notifier<_AccountSettingsState> {
  @override
  _AccountSettingsState build() {
    final authState = ref.watch(authStateProvider);
    return authState.when(
      data: (user) => _accountSettingsLoadedState(
        companyName: user?.companyName?.trim(),
        email: user?.email.trim(),
      ),
      error: (_, _) => _accountSettingsErrorState,
      loading: () => _accountSettingsLoadingState,
    );
  }
}

final NotifierProvider<_AccountSettingsController, _AccountSettingsState>
_accountSettingsControllerProvider =
    NotifierProvider.autoDispose<
      _AccountSettingsController,
      _AccountSettingsState
    >(_AccountSettingsController.new);
