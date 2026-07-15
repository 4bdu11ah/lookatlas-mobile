part of '../screens/dashboard_screen.dart';

class _DashboardShellState {
  const _DashboardShellState({
    this.userMenuOpen = false,
  });

  final bool userMenuOpen;

  _DashboardShellState copyWith({
    bool? userMenuOpen,
  }) {
    return _DashboardShellState(
      userMenuOpen: userMenuOpen ?? this.userMenuOpen,
    );
  }
}

class _DashboardShellController extends Notifier<_DashboardShellState> {
  @override
  _DashboardShellState build() => const _DashboardShellState();

  void toggleUserMenu() {
    state = state.copyWith(userMenuOpen: !state.userMenuOpen);
  }

  void closeUserMenu() {
    if (state.userMenuOpen) {
      state = state.copyWith(userMenuOpen: false);
    }
  }
}

final _dashboardShellControllerProvider =
    NotifierProvider<_DashboardShellController, _DashboardShellState>(
      _DashboardShellController.new,
    );
