import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardShellState {
  const DashboardShellState({
    this.userMenuOpen = false,
    this.navigationOpen = false,
    this.accountLinksOpen = false,
  });

  final bool userMenuOpen;
  final bool navigationOpen;
  final bool accountLinksOpen;

  DashboardShellState copyWith({
    bool? userMenuOpen,
    bool? navigationOpen,
    bool? accountLinksOpen,
  }) {
    return DashboardShellState(
      userMenuOpen: userMenuOpen ?? this.userMenuOpen,
      navigationOpen: navigationOpen ?? this.navigationOpen,
      accountLinksOpen: accountLinksOpen ?? this.accountLinksOpen,
    );
  }
}

class DashboardShellController extends Notifier<DashboardShellState> {
  @override
  DashboardShellState build() => const DashboardShellState();

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

final dashboardShellControllerProvider =
    NotifierProvider<DashboardShellController, DashboardShellState>(
      DashboardShellController.new,
    );
