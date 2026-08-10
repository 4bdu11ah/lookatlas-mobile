part of '../screens/dashboard_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_dashboardShellControllerProvider);
    final controller = ref.read(_dashboardShellControllerProvider.notifier);
    final screen = _DashboardPageView(
      onNavigate: (page) => _navigateDashboard(context, ref, page),
    );
    final user = ref.watch(authStateProvider).value;
    final company = user?.companyName?.trim();
    final email = user?.email.trim();
    final initialSource = company != null && company.isNotEmpty
        ? company
        : email;
    final initial = initialSource != null && initialSource.isNotEmpty
        ? initialSource[0].toUpperCase()
        : 'A';
    return Scaffold(
      backgroundColor: AppColors.neutral100,
      drawer: _DashboardDrawer(
        selected: _DashboardPage.dashboard,
        onSelect: (_) => controller.closeUserMenu(),
      ),
      body: SafeArea(
        bottom: false,
        child: ResponsiveContent(
          child: Stack(
            children: [
              Column(
                children: [
                  _Header(
                    initial: initial,
                    userMenuOpen: state.userMenuOpen,
                    onToggleUserMenu: controller.toggleUserMenu,
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => ref
                          .read(
                            _dashboardOverviewControllerProvider.notifier,
                          )
                          .refresh(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          10,
                          20,
                          10,
                        ),
                        child: screen,
                      ),
                    ),
                  ),
                ],
              ),
              if (state.userMenuOpen)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: controller.closeUserMenu,
                  ),
                ),
              if (state.userMenuOpen)
                Positioned(
                  top: 72,
                  right: 16,
                  child: _UserMenu(
                    onSettings: () => _navigateDashboard(
                      context,
                      ref,
                      _DashboardPage.settings,
                    ),
                    onBilling: () => _navigateDashboard(
                      context,
                      ref,
                      _DashboardPage.billing,
                    ),
                    onLogOut: () => _logOut(context, ref),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

void _navigateDashboard(
  BuildContext context,
  WidgetRef ref,
  _DashboardPage page,
) {
  ref.read(_dashboardShellControllerProvider.notifier).closeUserMenu();
  if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
    Navigator.pop(context);
  }
  if (page == _DashboardPage.dashboard) {
    context.go(page.routePath);
  } else {
    unawaited(context.push<void>(page.routePath));
  }
}

Future<void> _openDashboardModal(
  BuildContext context,
  WidgetRef ref,
  _ModalKind kind,
) {
  ref.read(_dashboardShellControllerProvider.notifier).closeUserMenu();
  return showAppDialog<void>(
    context: context,
    builder: (_) => _DashboardModal(
      kind: kind,
      onNavigate: (page) => _navigateDashboard(context, ref, page),
      onOpenModal: (nextKind) => _openDashboardModal(context, ref, nextKind),
      onToast: (text) => _toastDashboard(context, text),
    ),
  );
}

void _toastDashboard(BuildContext context, String text) =>
    AppSnackBar.show(context, text);

Future<void> _logOut(BuildContext context, WidgetRef ref) async {
  final result = await ref.read(authRepositoryProvider).signOut();
  if (result.isErr && context.mounted) {
    AppSnackBar.showError(context, 'Could not log out. Please try again.');
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.initial,
    required this.userMenuOpen,
    required this.onToggleUserMenu,
  });

  final String initial;
  final bool userMenuOpen;
  final VoidCallback onToggleUserMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.neutral200)),
      ),
      child: Row(
        children: [
          _IconButton(
            icon: Icons.menu,
            label: 'Open navigation',
            dimension: 40,
            onTap: () => Scaffold.of(context).openDrawer(),
          ),
          const Spacer(),
          InkWell(
            onTap: onToggleUserMenu,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Container(
                width: 36,
                height: 36,
                color: userMenuOpen ? AppColors.neutralLight : AppColors.black,
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: AppTypography.bold,
                    color: userMenuOpen ? AppColors.black : AppColors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardDrawer extends StatelessWidget {
  const _DashboardDrawer({required this.selected, required this.onSelect});

  final _DashboardPage selected;
  final ValueChanged<_DashboardPage> onSelect;

  static const List<_DashboardPage> _items = [
    _DashboardPage.dashboard,
    _DashboardPage.workshop,
    _DashboardPage.models,
    _DashboardPage.products,
    _DashboardPage.jobs,
    _DashboardPage.billing,
    _DashboardPage.support,
    _DashboardPage.guides,
    _DashboardPage.settings,
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 256,
      shape: const RoundedRectangleBorder(),
      backgroundColor: AppColors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              height: 88,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.neutral200)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.neutral200),
                    ),
                    child: const AppImage('assets/images/logo.png'),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Look Atlas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                  ),
                  _IconButton(
                    icon: Icons.close,
                    label: 'Close navigation',
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final active = selected == item;
                  return _NavTile(
                    tileKey: ValueKey('dashboard-drawer-${item.name}'),
                    icon: item.icon,
                    label: item.label,
                    active: active,
                    onTap: () {
                      final router = GoRouter.of(context);
                      Scaffold.of(context).closeDrawer();
                      onSelect(item);
                      unawaited(router.push<void>(item.routePath));
                    },
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'V0.1.0',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.88,
                    color: AppColors.neutral500,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserMenu extends StatelessWidget {
  const _UserMenu({
    required this.onSettings,
    required this.onBilling,
    required this.onLogOut,
  });

  final VoidCallback onSettings;
  final VoidCallback onBilling;
  final Future<void> Function() onLogOut;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      elevation: 8,
      child: Container(
        width: 256,
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Eyebrow('Credits'),
                  _DashboardCredits(),
                ],
              ),
            ),
            const _Hairline(),
            _MenuRow(
              icon: Icons.account_circle_outlined,
              label: 'Account Settings',
              onTap: onSettings,
            ),
            _MenuRow(
              icon: Icons.credit_card_outlined,
              label: 'Billing & Credits',
              onTap: onBilling,
            ),
            _MenuRow(
              icon: Icons.logout,
              label: 'Log Out',
              onTap: () => unawaited(onLogOut()),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCredits extends ConsumerWidget {
  const _DashboardCredits();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_dashboardOverviewControllerProvider);
    return switch (state) {
      AsyncData(:final value) => Text(
        '${value.stats.credits}',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: AppTypography.bold,
        ),
      ),
      AsyncError() => const Text('N/A'),
      _ => const BarSpinner(size: 20),
    };
  }
}
