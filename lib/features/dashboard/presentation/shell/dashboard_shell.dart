part of '../screens/dashboard_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_dashboardShellControllerProvider);
    final controller = ref.read(_dashboardShellControllerProvider.notifier);
    final screen = _DashboardOverviewScreen(
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
    final welcomeState = ref.watch(studioSchoolControllerProvider);
    final showCompleteProfile = switch (welcomeState) {
      SchoolReady(:final welcome) || SchoolOfflineCached(:final welcome) =>
        welcome.eligible && (welcome.dashboard?.profileIncomplete ?? false),
      _ => false,
    };
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
                    showCompleteProfile: showCompleteProfile,
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => Future.wait([
                        ref
                            .read(
                              _dashboardOverviewControllerProvider.notifier,
                            )
                            .refresh(),
                        ref
                            .read(studioSchoolControllerProvider.notifier)
                            .refresh(),
                      ]),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                        child: screen,
                      ),
                    ),
                  ),
                ],
              ),
              const _WelcomeFocusRefresh(),
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

class _WelcomeFocusRefresh extends ConsumerStatefulWidget {
  const _WelcomeFocusRefresh();

  @override
  ConsumerState<_WelcomeFocusRefresh> createState() =>
      _WelcomeFocusRefreshState();
}

class _WelcomeFocusRefreshState extends ConsumerState<_WelcomeFocusRefresh>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(studioSchoolControllerProvider.notifier).refresh());
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
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
  if (kind == _ModalKind.editAi) {
    return _showAiEditDialog(
      context,
      onToast: (text) => _toastDashboard(context, text),
    );
  }
  if (kind == _ModalKind.directorPortfolio) {
    final createState = ref.read(_createShootControllerProvider);
    final shootDirector = _selectedShootDirector(ref);
    final director = _onboardingDirectorFor(shootDirector);
    if (director != null) {
      final selected = createState.demoMode
          ? createState.demoDirectors.any(
              (config) => config.directorId == shootDirector?.id,
            )
          : createState.selectedDirector == createState.previewDirector;
      return showDirectorPortfolio(
        context,
        director: director,
        isSelected: selected,
        onSelect: () {
          final controller = ref.read(
            _createShootControllerProvider.notifier,
          );
          if (createState.demoMode) {
            controller.toggleDemoDirector(createState.previewDirector);
          } else {
            controller.selectDirector(createState.previewDirector);
          }
        },
      );
    }
  }
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

Director? _onboardingDirectorFor(ShootLook? shootDirector) {
  if (shootDirector == null) return null;
  for (final director in directors) {
    if (director.apiId == shootDirector.id ||
        director.id == shootDirector.id ||
        director.name == shootDirector.name) {
      return director;
    }
  }
  return null;
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
    required this.showCompleteProfile,
  });

  final String initial;
  final bool userMenuOpen;
  final VoidCallback onToggleUserMenu;
  final bool showCompleteProfile;

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
          SizedBox.square(
            dimension: 40,
            child: AppIconButton(
              icon: LucideIcons.menu,
              tooltip: 'Open navigation',
              onPressed: () => Scaffold.of(context).openDrawer(),
              color: AppColors.inkAlpha68,
            ),
          ),
          const Spacer(),
          if (showCompleteProfile) ...[
            _CompactProfileButton(
              onPressed: () => unawaited(context.push<void>(AppRoutes.welcome)),
            ),
            const SizedBox(width: 4),
          ],
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

class _CompactProfileButton extends StatelessWidget {
  const _CompactProfileButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 132,
    height: 40,
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 7),
        side: const BorderSide(color: AppColors.neutral200),
      ),
      onPressed: onPressed,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.sparkles, size: 16),
          SizedBox(width: 4),
          Flexible(
            child: Text(
              'Complete profile',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: AppTypography.bold,
              ),
            ),
          ),
        ],
      ),
    ),
  );
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
    _DashboardPage.school,
    _DashboardPage.assistant,
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
                  AppIconButton(
                    icon: LucideIcons.x,
                    tooltip: 'Close navigation',
                    onPressed: () => Navigator.pop(context),
                    color: AppColors.inkAlpha68,
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
              icon: LucideIcons.userCircle,
              label: 'Account Settings',
              onTap: onSettings,
            ),
            _MenuRow(
              icon: LucideIcons.creditCard,
              label: 'Billing & Credits',
              onTap: onBilling,
            ),
            _MenuRow(
              icon: LucideIcons.logOut,
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
