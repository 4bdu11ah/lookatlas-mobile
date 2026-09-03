part of '../screens/dashboard_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drawerController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    reverseDuration: const Duration(milliseconds: 220),
  );
  final FocusNode _menuFocusNode = FocusNode(debugLabel: 'navigation menu');
  final FocusNode _drawerCloseFocusNode = FocusNode(
    debugLabel: 'close navigation',
  );
  final FocusScopeNode _drawerFocusScopeNode = FocusScopeNode(
    debugLabel: 'navigation drawer',
  );

  @override
  void dispose() {
    _drawerController.dispose();
    _menuFocusNode.dispose();
    _drawerCloseFocusNode.dispose();
    _drawerFocusScopeNode.dispose();
    super.dispose();
  }

  Future<void> _openDrawer() {
    ref.read(_dashboardShellControllerProvider.notifier).openNavigation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _drawerCloseFocusNode.requestFocus();
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      _drawerController.value = 1;
      return Future.value();
    }
    final mobile =
        MediaQuery.sizeOf(context).width < AppResponsive.compactBreakpoint;
    return _drawerController.animateTo(
      1,
      duration: mobile ? const Duration(milliseconds: 420) : null,
      curve: mobile ? const Cubic(0.2, 0.8, 0.2, 1) : Curves.easeOutCubic,
    );
  }

  Future<void> _closeDrawer() async {
    ref.read(_dashboardShellControllerProvider.notifier).closeNavigation();
    if (MediaQuery.disableAnimationsOf(context)) {
      _drawerController.value = 0;
    } else {
      final mobile =
          MediaQuery.sizeOf(context).width < AppResponsive.compactBreakpoint;
      await _drawerController.animateBack(
        0,
        duration: mobile ? const Duration(milliseconds: 300) : null,
        curve: mobile ? Curves.easeInCubic : Curves.easeOutCubic,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _menuFocusNode.requestFocus();
    });
  }

  void _dragDrawer(double delta, double travel) {
    _drawerController.value = (_drawerController.value + delta / travel).clamp(
      0,
      1,
    );
  }

  void _finishDrawerDrag(double velocity) {
    final shouldOpen =
        velocity > 350 || (velocity >= -350 && _drawerController.value >= 0.5);
    if (shouldOpen) {
      unawaited(_openDrawer());
    } else {
      unawaited(_closeDrawer());
    }
  }

  Future<void> _selectDrawerRoute(String route) async {
    await _closeDrawer();
    if (!mounted) return;
    if (route == AppRoutes.home) {
      GoRouter.of(context).go(route);
    } else {
      unawaited(GoRouter.of(context).push<void>(route));
    }
  }

  Future<void> _selectLegacyDrawerPage(_DashboardPage page) =>
      _selectDrawerRoute(page.routePath);

  @override
  Widget build(BuildContext context) {
    final mobile =
        MediaQuery.sizeOf(context).width < AppResponsive.compactBreakpoint;
    final state = ref.watch(_dashboardShellControllerProvider);
    final controller = ref.read(_dashboardShellControllerProvider.notifier);
    final screen = _DashboardOverviewScreen(
      onNavigate: (page) => _navigateDashboard(context, ref, page),
    );
    final user = ref.watch(authStateProvider).value;
    final company = user?.companyName?.trim();
    final displayName = user?.displayName?.trim();
    final email = user?.email.trim() ?? '';
    final accountName = company?.isNotEmpty ?? false
        ? company!
        : displayName?.isNotEmpty ?? false
        ? displayName!
        : email.isNotEmpty
        ? email.split('@').first
        : 'Your workspace';
    final initials = _accountInitials(accountName);
    final legacyInitial = initials[0];
    final welcomeState = ref.watch(studioSchoolControllerProvider);
    final showCompleteProfile = switch (welcomeState) {
      SchoolReady(:final welcome) || SchoolOfflineCached(:final welcome) =>
        welcome.eligible && (welcome.dashboard?.profileIncomplete ?? false),
      _ => false,
    };
    final content = SafeArea(
      bottom: false,
      child: ResponsiveContent(
        child: Stack(
          children: [
            Column(
              children: [
                if (mobile)
                  _Header(
                    menuFocusNode: _menuFocusNode,
                    onOpenNavigation: () => unawaited(_openDrawer()),
                    onOpenBilling: () => _navigateDashboard(
                      context,
                      ref,
                      _DashboardPage.billing,
                    ),
                  )
                else
                  _LegacyHeader(
                    initial: legacyInitial,
                    userMenuOpen: state.userMenuOpen,
                    onOpenNavigation: () => unawaited(_openDrawer()),
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
            if (!mobile && state.userMenuOpen)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: controller.closeUserMenu,
                ),
              ),
            if (!mobile && state.userMenuOpen)
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
    );
    final scaffold = Scaffold(
      backgroundColor: AppColors.neutral50,
      body: mobile
          ? _DashboardDrawerTransition(
              animation: _drawerController,
              drawer: _DashboardDrawer(
                selected: _DashboardPage.dashboard,
                focusScopeNode: _drawerFocusScopeNode,
                closeFocusNode: _drawerCloseFocusNode,
                accountName: accountName,
                accountEmail: email,
                initials: initials,
                accountLinksOpen: state.accountLinksOpen,
                onClose: () => unawaited(_closeDrawer()),
                onToggleAccount: controller.toggleAccountLinks,
                onNavigate: (route) => unawaited(_selectDrawerRoute(route)),
              ),
              onClose: () => unawaited(_closeDrawer()),
              onDragUpdate: _dragDrawer,
              onDragEnd: _finishDrawerDrag,
              child: content,
            )
          : _DashboardLegacyDrawerTransition(
              animation: _drawerController,
              drawer: _LegacyDashboardDrawer(
                selected: _DashboardPage.dashboard,
                onClose: () => unawaited(_closeDrawer()),
                onSelect: (page) => unawaited(_selectLegacyDrawerPage(page)),
              ),
              onClose: () => unawaited(_closeDrawer()),
              onDragUpdate: _dragDrawer,
              onDragEnd: _finishDrawerDrag,
              child: content,
            ),
    );
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (state.navigationOpen) unawaited(_closeDrawer());
        },
      },
      child: FocusTraversalGroup(
        child: AnimatedBuilder(
          animation: _drawerController,
          child: scaffold,
          builder: (context, child) => PopScope(
            canPop: _drawerController.isDismissed,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) unawaited(_closeDrawer());
            },
            child: child!,
          ),
        ),
      ),
    );
  }
}

String _accountInitials(String name) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .take(2)
      .toList();
  if (words.isEmpty) return 'A';
  return words.map((word) => word[0].toUpperCase()).join();
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

class _LegacyHeader extends StatelessWidget {
  const _LegacyHeader({
    required this.initial,
    required this.userMenuOpen,
    required this.onOpenNavigation,
    required this.onToggleUserMenu,
    required this.showCompleteProfile,
  });

  final String initial;
  final bool userMenuOpen;
  final VoidCallback onOpenNavigation;
  final VoidCallback onToggleUserMenu;
  final bool showCompleteProfile;

  @override
  Widget build(BuildContext context) => Container(
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
            onPressed: onOpenNavigation,
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

class _Header extends StatelessWidget {
  const _Header({
    required this.menuFocusNode,
    required this.onOpenNavigation,
    required this.onOpenBilling,
  });

  final FocusNode menuFocusNode;
  final VoidCallback onOpenNavigation;
  final VoidCallback onOpenBilling;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.neutral200)),
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Open navigation',
            child: SizedBox.square(
              dimension: 44,
              child: IconButton(
                key: const ValueKey('dashboard-open-navigation'),
                focusNode: menuFocusNode,
                tooltip: 'Open navigation',
                onPressed: onOpenNavigation,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: const Color(0xFF181816),
                  side: const BorderSide(color: Color(0xFFDCDCD5)),
                  shape: const RoundedRectangleBorder(),
                ),
                icon: const Icon(LucideIcons.menu, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WORKSPACE',
                  style: TextStyle(
                    color: Color(0xFF6F6F68),
                    fontSize: 10,
                    height: 1.2,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Overview',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF181816),
                    fontSize: 15,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ],
            ),
          ),
          Consumer(
            builder: (context, ref, _) {
              final dashboard = ref.watch(_dashboardOverviewControllerProvider);
              final label = switch (dashboard) {
                AsyncData(:final value) when value.stats != null =>
                  '${value.stats!.credits} credits',
                AsyncError() => 'Credits',
                _ => '… credits',
              };
              return Semantics(
                button: true,
                label: '$label, open billing and credits',
                child: InkWell(
                  key: const ValueKey('dashboard-header-credits'),
                  onTap: onOpenBilling,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAF8),
                      border: Border.all(color: const Color(0xFFDCDCD5)),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF181816),
                        fontSize: 11,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DashboardDrawer extends StatelessWidget {
  const _DashboardDrawer({
    required this.selected,
    required this.focusScopeNode,
    required this.closeFocusNode,
    required this.accountName,
    required this.accountEmail,
    required this.initials,
    required this.accountLinksOpen,
    required this.onClose,
    required this.onToggleAccount,
    required this.onNavigate,
  });

  final _DashboardPage selected;
  final FocusScopeNode focusScopeNode;
  final FocusNode closeFocusNode;
  final String accountName;
  final String accountEmail;
  final String initials;
  final bool accountLinksOpen;
  final VoidCallback onClose;
  final VoidCallback onToggleAccount;
  final ValueChanged<String> onNavigate;

  static const _groups = <_DrawerGroup>[
    _DrawerGroup('Workspace', [
      _DrawerDestination(
        keyName: 'dashboard',
        label: 'Overview',
        icon: LucideIcons.house,
        route: AppRoutes.home,
      ),
      _DrawerDestination(
        keyName: 'jobs',
        label: 'Shoots',
        icon: LucideIcons.circleDot,
        route: AppRoutes.dashboardShoots,
      ),
      _DrawerDestination(
        keyName: 'brand-studio',
        label: 'Brand Studio',
        icon: LucideIcons.sparkles,
        route: AppRoutes.studioSchool,
      ),
    ]),
    _DrawerGroup('Library', [
      _DrawerDestination(
        keyName: 'products',
        label: 'Products',
        icon: LucideIcons.package,
        route: AppRoutes.dashboardProducts,
      ),
      _DrawerDestination(
        keyName: 'models',
        label: 'House Models',
        icon: LucideIcons.userRound,
        route: AppRoutes.dashboardModels,
      ),
      _DrawerDestination(
        keyName: 'design-boards',
        label: 'Design Boards',
        icon: LucideIcons.diamond,
        route: AppRoutes.dashboardGuides,
      ),
    ]),
    _DrawerGroup('Tools', [
      _DrawerDestination(
        keyName: 'workshop',
        label: 'Workshop',
        icon: LucideIcons.wandSparkles,
        route: AppRoutes.workshop,
      ),
      _DrawerDestination(
        keyName: 'lookbooks',
        label: 'Lookbooks',
        icon: LucideIcons.notebookTabs,
        route: AppRoutes.dashboardGuides,
      ),
      _DrawerDestination(
        keyName: 'image-editor',
        label: 'Image Editor',
        icon: LucideIcons.image,
        route: AppRoutes.assistant,
      ),
      _DrawerDestination(
        keyName: 'video-editor',
        label: 'Video Editor',
        icon: LucideIcons.play,
        disabled: true,
        trailingLabel: 'SOON',
      ),
    ]),
    _DrawerGroup('Social Media', [
      _DrawerDestination(
        keyName: 'create-content',
        label: 'Create Content',
        icon: LucideIcons.pencil,
        route: AppRoutes.createShoot,
      ),
      _DrawerDestination(
        keyName: 'calendar',
        label: 'Calendar',
        icon: LucideIcons.calendarDays,
        route: AppRoutes.dashboardShoots,
        badge: 3,
      ),
    ]),
    _DrawerGroup('Services', [
      _DrawerDestination(
        keyName: 'touch-ups',
        label: 'Touch-ups',
        icon: LucideIcons.scanLine,
        route: AppRoutes.dashboardSupport,
      ),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: double.infinity,
      shape: const RoundedRectangleBorder(),
      elevation: 0,
      backgroundColor: const Color(0xFFF8F8F5),
      child: SafeArea(
        child: FocusScope(
          node: focusScopeNode,
          child: Semantics(
            scopesRoute: true,
            namesRoute: true,
            label: 'App navigation',
            explicitChildNodes: true,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 18, 14),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFDCDCD5)),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox.square(
                        dimension: 35,
                        child: AppImage('assets/images/logo.png'),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Look ',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: AppTypography.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              TextSpan(
                                text: 'Atlas',
                                style: TextStyle(
                                  fontFamily: 'InstrumentSerif',
                                  fontSize: 20,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                        ),
                      ),
                      SizedBox.square(
                        dimension: 40,
                        child: IconButton(
                          key: const ValueKey('dashboard-close-navigation'),
                          focusNode: closeFocusNode,
                          tooltip: 'Close navigation',
                          onPressed: onClose,
                          style: IconButton.styleFrom(
                            shape: const RoundedRectangleBorder(),
                            side: const BorderSide(color: Color(0xFFDCDCD5)),
                            foregroundColor: const Color(0xFF181816),
                          ),
                          icon: const Icon(LucideIcons.x, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: _CreateShootButton(
                    onTap: () => onNavigate(AppRoutes.createShoot),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    key: const ValueKey('dashboard-drawer-scroll'),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _groups.length,
                    itemBuilder: (context, index) => _DrawerNavGroup(
                      group: _groups[index],
                      drawTopBorder: index > 0,
                      selectedRoute: selected.routePath,
                      onNavigate: onNavigate,
                    ),
                  ),
                ),
                _DrawerAccount(
                  name: accountName,
                  email: accountEmail,
                  initials: initials,
                  expanded: accountLinksOpen,
                  onToggle: onToggleAccount,
                  onNavigate: onNavigate,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerGroup {
  const _DrawerGroup(this.label, this.destinations);

  final String label;
  final List<_DrawerDestination> destinations;
}

class _LegacyDashboardDrawer extends StatelessWidget {
  const _LegacyDashboardDrawer({
    required this.selected,
    required this.onClose,
    required this.onSelect,
  });

  final _DashboardPage selected;
  final VoidCallback onClose;
  final ValueChanged<_DashboardPage> onSelect;

  static const _items = <_DashboardPage>[
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
  Widget build(BuildContext context) => Drawer(
    width: 256,
    shape: const RoundedRectangleBorder(),
    backgroundColor: AppColors.neutral50,
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
                  onPressed: onClose,
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
                return _NavTile(
                  tileKey: ValueKey('dashboard-drawer-${item.name}'),
                  icon: item.icon,
                  label: item.label,
                  active: selected == item,
                  onTap: () => onSelect(item),
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

class _DrawerDestination {
  const _DrawerDestination({
    required this.keyName,
    required this.label,
    required this.icon,
    this.route,
    this.disabled = false,
    this.trailingLabel,
    this.badge,
  });

  final String keyName;
  final String label;
  final IconData icon;
  final String? route;
  final bool disabled;
  final String? trailingLabel;
  final int? badge;
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
  Widget build(BuildContext context) => Material(
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
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_Eyebrow('Credits'), _DashboardCredits()],
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

class _DashboardCredits extends ConsumerWidget {
  const _DashboardCredits();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_dashboardOverviewControllerProvider);
    return switch (state) {
      AsyncData(:final value) when value.stats != null => Text(
        '${value.stats!.credits}',
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

class _CreateShootButton extends StatelessWidget {
  const _CreateShootButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Create a shoot',
    child: Material(
      color: const Color(0xFF181816),
      child: InkWell(
        key: const ValueKey('dashboard-drawer-create'),
        onTap: onTap,
        child: const SizedBox(
          height: 50,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                Icon(LucideIcons.plus, size: 17, color: AppColors.white),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Create a shoot',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 13,
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                ),
                Icon(LucideIcons.arrowRight, size: 17, color: AppColors.white),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _DrawerNavGroup extends StatelessWidget {
  const _DrawerNavGroup({
    required this.group,
    required this.drawTopBorder,
    required this.selectedRoute,
    required this.onNavigate,
  });

  final _DrawerGroup group;
  final bool drawTopBorder;
  final String selectedRoute;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(0, 13, 0, 11),
    decoration: drawTopBorder
        ? const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xCCDCDCD5))),
          )
        : null,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 7),
          child: Text(
            group.label,
            style: const TextStyle(
              color: Color(0xFF181816),
              fontFamily: 'InstrumentSerif',
              fontSize: 15,
              height: 1.2,
            ),
          ),
        ),
        for (var index = 0; index < group.destinations.length; index++) ...[
          if (index > 0) const SizedBox(height: 2),
          _DrawerNavTile(
            destination: group.destinations[index],
            active:
                group.destinations[index].route == selectedRoute &&
                group.destinations[index].keyName == 'dashboard',
            onTap: group.destinations[index].route == null
                ? null
                : () => onNavigate(group.destinations[index].route!),
          ),
        ],
      ],
    ),
  );
}

class _DrawerNavTile extends StatelessWidget {
  const _DrawerNavTile({
    required this.destination,
    required this.active,
    required this.onTap,
  });

  final _DrawerDestination destination;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = active
        ? AppColors.white
        : destination.disabled
        ? const Color(0xFF9A9A94)
        : const Color(0xFF5F5F59);
    return Semantics(
      button: true,
      enabled: !destination.disabled,
      selected: active,
      label: destination.badge == null
          ? destination.label
          : '${destination.label}, ${destination.badge} posts need attention',
      child: Material(
        color: active ? const Color(0xFF181816) : AppColors.transparent,
        child: InkWell(
          key: ValueKey('dashboard-drawer-${destination.keyName}'),
          onTap: destination.disabled ? null : onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 46),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  width: 2,
                  color: active
                      ? const Color(0xFF181816)
                      : AppColors.transparent,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 29,
                  height: 29,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active ? AppColors.white : const Color(0xFFFBFBF8),
                    border: Border.all(
                      color: active ? AppColors.white : const Color(0xFFDEDED8),
                    ),
                  ),
                  child: Icon(
                    destination.icon,
                    size: 16,
                    color: active ? const Color(0xFF181816) : foreground,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 13,
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                ),
                if (destination.badge case final badge?) ...[
                  ExcludeSemantics(
                    child: Container(
                      height: 20,
                      constraints: const BoxConstraints(minWidth: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7A2F3C),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 10,
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (destination.trailingLabel case final label?)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    color: const Color(0xFFE7E7E1),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF6F6F68),
                        fontSize: 9,
                        fontWeight: AppTypography.bold,
                        letterSpacing: 0.72,
                      ),
                    ),
                  )
                else
                  Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: active
                        ? AppColors.whiteAlpha60
                        : const Color(0xFFA0A099),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerAccount extends StatelessWidget {
  const _DrawerAccount({
    required this.name,
    required this.email,
    required this.initials,
    required this.expanded,
    required this.onToggle,
    required this.onNavigate,
  });

  final String name;
  final String email;
  final String initials;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
    decoration: const BoxDecoration(
      color: Color(0xFFF8F8F5),
      border: Border(top: BorderSide(color: Color(0xFFDCDCD5))),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSize(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.bottomCenter,
          child: expanded
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _AccountQuickLink(
                              keyName: 'profile',
                              icon: LucideIcons.circleUserRound,
                              label: 'Profile & brand',
                              onTap: () => onNavigate(
                                AppRoutes.dashboardAccount,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _AccountQuickLink(
                              keyName: 'settings',
                              icon: LucideIcons.settings,
                              label: 'Settings',
                              onTap: () => onNavigate(AppRoutes.settings),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _AccountQuickLink(
                              keyName: 'billing',
                              icon: LucideIcons.diamond,
                              label: 'Billing',
                              onTap: () => onNavigate(
                                AppRoutes.dashboardBilling,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _AccountQuickLink(
                              keyName: 'support',
                              icon: LucideIcons.circleHelp,
                              label: 'Help',
                              onTap: () => onNavigate(
                                AppRoutes.dashboardSupport,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Semantics(
          button: true,
          expanded: expanded,
          label: email.isEmpty ? name : '$name, $email, manage account',
          child: Material(
            color: const Color(0xFFECECE6),
            child: InkWell(
              key: const ValueKey('dashboard-drawer-account'),
              onTap: onToggle,
              child: Container(
                constraints: const BoxConstraints(minHeight: 58),
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFDCDCD5)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      color: const Color(0xFF181816),
                      alignment: Alignment.center,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF181816),
                              fontSize: 12,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Manage account',
                            style: TextStyle(
                              color: Color(0xFF6F6F68),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 180),
                      child: const Icon(LucideIcons.chevronDown, size: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _AccountQuickLink extends StatelessWidget {
  const _AccountQuickLink({
    required this.keyName,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String keyName;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFECECE6),
    child: InkWell(
      key: ValueKey('dashboard-drawer-$keyName'),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 15, color: const Color(0xFF6F6F68)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF6F6F68),
                  fontSize: 10,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
