import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/settings/presentation/models/account_settings_state.dart';

class AccountSettingsController extends Notifier<AccountSettingsState> {
  @override
  AccountSettingsState build() {
    final authState = ref.watch(authStateProvider);
    return authState.when(
      data: (user) => accountSettingsLoadedState(
        companyName: user?.companyName?.trim(),
        email: user?.email.trim(),
      ),
      error: (_, _) => accountSettingsErrorState,
      loading: () => accountSettingsLoadingState,
    );
  }
}

final NotifierProvider<AccountSettingsController, AccountSettingsState>
accountSettingsControllerProvider =
    NotifierProvider.autoDispose<
      AccountSettingsController,
      AccountSettingsState
    >(AccountSettingsController.new);
