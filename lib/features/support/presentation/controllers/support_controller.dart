part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _SupportController extends Notifier<_SupportScreenState> {
  @override
  _SupportScreenState build() => _supportMockState;
}

final _supportControllerProvider =
    NotifierProvider<_SupportController, _SupportScreenState>(
      _SupportController.new,
    );
