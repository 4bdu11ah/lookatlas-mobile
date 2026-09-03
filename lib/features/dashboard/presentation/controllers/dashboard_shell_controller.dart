part of '../screens/dashboard_screen.dart';

class _DashboardShellState {
  const _DashboardShellState({
    this.userMenuOpen = false,
    this.navigationOpen = false,
    this.accountLinksOpen = false,
  });

  final bool userMenuOpen;
  final bool navigationOpen;
  final bool accountLinksOpen;

  _DashboardShellState copyWith({
    bool? userMenuOpen,
    bool? navigationOpen,
    bool? accountLinksOpen,
  }) {
    return _DashboardShellState(
      userMenuOpen: userMenuOpen ?? this.userMenuOpen,
      navigationOpen: navigationOpen ?? this.navigationOpen,
      accountLinksOpen: accountLinksOpen ?? this.accountLinksOpen,
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

  void openNavigation() {
    state = state.copyWith(userMenuOpen: false, navigationOpen: true);
  }

  void closeNavigation() {
    if (state.navigationOpen) {
      state = state.copyWith(navigationOpen: false);
    }
  }

  void toggleAccountLinks() {
    state = state.copyWith(accountLinksOpen: !state.accountLinksOpen);
  }
}

final _dashboardShellControllerProvider =
    NotifierProvider<_DashboardShellController, _DashboardShellState>(
      _DashboardShellController.new,
    );
