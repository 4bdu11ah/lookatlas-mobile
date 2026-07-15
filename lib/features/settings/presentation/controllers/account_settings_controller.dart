part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _AccountSettingsController extends Notifier<_AccountSettingsState> {
  @override
  _AccountSettingsState build() => _accountSettingsMockState;
}

final _accountSettingsControllerProvider =
    NotifierProvider<_AccountSettingsController, _AccountSettingsState>(
      _AccountSettingsController.new,
    );
