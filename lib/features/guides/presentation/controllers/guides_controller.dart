part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _GuidesController extends Notifier<_GuidesScreenState> {
  @override
  _GuidesScreenState build() => _guidesInitialState;

  void selectTab(_GuideTab tab) {
    if (tab == state.selectedTab) return;
    state = _GuidesScreenState(selectedTab: tab);
  }
}

final NotifierProvider<_GuidesController, _GuidesScreenState>
_guidesControllerProvider =
    NotifierProvider.autoDispose<_GuidesController, _GuidesScreenState>(
      _GuidesController.new,
    );
