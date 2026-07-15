part of '../../screens/dashboard_screen.dart';

class _DashboardOverviewState {
  const _DashboardOverviewState({required this.shoots});

  final List<_Shoot> shoots;
}

class _DashboardOverviewController extends Notifier<_DashboardOverviewState> {
  @override
  _DashboardOverviewState build() => const _DashboardOverviewState(
    shoots: _shoots,
  );
}

final _dashboardOverviewControllerProvider =
    NotifierProvider<_DashboardOverviewController, _DashboardOverviewState>(
      _DashboardOverviewController.new,
    );
