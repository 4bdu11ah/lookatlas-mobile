part of 'dashboard_shell.dart';

class _DashboardDrawer extends StatelessWidget {
  const _DashboardDrawer({
    required this.selected,
    required this.focusScopeNode,
    required this.closeFocusNode,
    required this.onClose,
    required this.onNavigate,
    this.selectedRoute,
  });

  final DashboardPage selected;
  final String? selectedRoute;
  final FocusScopeNode focusScopeNode;
  final FocusNode closeFocusNode;
  final VoidCallback onClose;
  final ValueChanged<String> onNavigate;

  static const _groups = <_DrawerGroup>[
    _DrawerGroup('Workspace', [
      _DrawerDestination(
        keyName: 'dashboard',
        label: 'Overview',
        icon: LucideIcons.layoutDashboard,
        route: AppRoutes.home,
      ),
      _DrawerDestination(
        keyName: 'jobs',
        label: 'Shoots',
        icon: LucideIcons.camera,
        route: AppRoutes.dashboardShoots,
      ),
      _DrawerDestination(
        keyName: 'brand-studio',
        label: 'Brand Studio',
        icon: LucideIcons.sparkles,
        disabled: true,
        trailingLabel: 'SOON',
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
        icon: LucideIcons.users,
        route: AppRoutes.dashboardModels,
      ),
      _DrawerDestination(
        keyName: 'design-boards',
        label: 'Design Boards',
        icon: LucideIcons.palette,
        disabled: true,
        trailingLabel: 'SOON',
      ),
    ]),
    _DrawerGroup('Tools', [
      _DrawerDestination(
        keyName: 'workshop',
        label: 'Workshop',
        icon: LucideIcons.wand2,
        route: AppRoutes.workshop,
      ),
      _DrawerDestination(
        keyName: 'lookbooks',
        label: 'Lookbooks',
        icon: LucideIcons.bookOpen,
        disabled: true,
        trailingLabel: 'SOON',
      ),
      _DrawerDestination(
        keyName: 'image-editor',
        label: 'Image Editor',
        icon: LucideIcons.image,
        disabled: true,
        trailingLabel: 'SOON',
      ),
      _DrawerDestination(
        keyName: 'video-editor',
        label: 'Video Editor',
        icon: LucideIcons.video,
        disabled: true,
        trailingLabel: 'SOON',
      ),
    ]),
    _DrawerGroup('Social Media', [
      _DrawerDestination(
        keyName: 'create-content',
        label: 'Create Content',
        icon: LucideIcons.megaphone,
        route: AppRoutes.createContent,
      ),
      _DrawerDestination(
        keyName: 'calendar',
        label: 'Calendar',
        icon: LucideIcons.calendarDays,
        route: AppRoutes.calendar,
      ),
    ]),
    _DrawerGroup('Services', [
      _DrawerDestination(
        keyName: 'touch-ups',
        label: 'Touch-ups',
        icon: LucideIcons.paintbrush,
        disabled: true,
        trailingLabel: 'SOON',
      ),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: double.infinity,
      shape: const RoundedRectangleBorder(),
      elevation: 0,
      backgroundColor: const Color(0xFFF8F8F6),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: FocusScope(
            node: focusScopeNode,
            child: Semantics(
              scopesRoute: true,
              namesRoute: true,
              label: 'App feature navigation',
              explicitChildNodes: true,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(6, 0, 6, 20),
                    child: Row(
                      children: [
                        const SizedBox.square(
                          dimension: 36,
                          child: AppImage('assets/images/logo.png'),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Look ',
                                  style: TextStyle(
                                    fontFamily: 'Satoshi',
                                    fontSize: 18,
                                    fontWeight: AppTypography.semiBold,
                                    letterSpacing: -0.45,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Atlas',
                                  style: TextStyle(
                                    fontFamily: 'InstrumentSerif',
                                    fontSize: 21,
                                    fontWeight: FontWeight.w400,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                            maxLines: 1,
                          ),
                        ),
                        SizedBox.square(
                          dimension: 34,
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
                            icon: const Icon(LucideIcons.x, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: _CreateShootButton(
                      onTap: () => onNavigate(AppRoutes.createShoot),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      key: const ValueKey('dashboard-drawer-scroll'),
                      padding: const EdgeInsets.only(right: 2),
                      itemCount: _groups.length,
                      itemBuilder: (context, index) => _DrawerNavGroup(
                        group: _groups[index],
                        drawTopBorder: index > 0,
                        selectedRoute: selectedRoute ?? selected.routePath,
                        onNavigate: onNavigate,
                      ),
                    ),
                  ),
                  _DrawerFooter(onNavigate: onNavigate),
                ],
              ),
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
          height: 44,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(LucideIcons.plus, size: 16, color: AppColors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Create a shoot',
                    style: TextStyle(
                      color: AppColors.white,
                      fontFamily: 'Satoshi',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 14,
                  color: AppColors.white,
                ),
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
    margin: EdgeInsets.only(top: drawTopBorder ? 12 : 0),
    padding: EdgeInsets.only(top: drawTopBorder ? 12 : 0),
    decoration: drawTopBorder
        ? const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0x80D4D4CE))),
          )
        : null,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 7),
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
          _DrawerNavTile(
            destination: group.destinations[index],
            active:
                group.destinations[index].route == selectedRoute &&
                !group.destinations[index].disabled,
            onTap: group.destinations[index].route == null
                ? null
                : () => onNavigate(group.destinations[index].route!),
          ),
        ],
      ],
    ),
  );
}

class _DrawerNavTile extends ConsumerWidget {
  const _DrawerNavTile({
    required this.destination,
    required this.active,
    required this.onTap,
  });

  final _DrawerDestination destination;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attention = destination.keyName == 'calendar'
        ? ref.watch(calendarAttentionProvider).asData?.value
        : null;
    final badgeValue = attention == null || attention <= 0 ? null : attention;
    final foreground = active
        ? AppColors.white
        : destination.disabled
        ? const Color(0xFF9A9A94)
        : const Color(0xFF5F5F59);
    return Semantics(
      button: true,
      enabled: !destination.disabled,
      selected: active,
      label: badgeValue == null
          ? destination.label
          : '${destination.label}, $badgeValue posts need attention',
      child: Material(
        color: active ? const Color(0xFF181816) : AppColors.transparent,
        child: InkWell(
          key: ValueKey('dashboard-drawer-${destination.keyName}'),
          onTap: destination.disabled ? null : onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 39),
            padding: const EdgeInsets.fromLTRB(7, 6, 8, 6),
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
                SizedBox.square(
                  dimension: 26,
                  child: Icon(destination.icon, size: 16, color: foreground),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontFamily: 'Satoshi',
                      fontSize: 14,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (badgeValue case final badge?) ...[
                  ExcludeSemantics(
                    child: Container(
                      height: 18,
                      constraints: const BoxConstraints(minWidth: 18),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE24A4A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        calendarBadge(badge),
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
                    color: const Color(0x24585852),
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
                    size: 14,
                    color: active
                        ? AppColors.white.withValues(alpha: 0.35)
                        : AppColors.transparent,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerFooter extends ConsumerWidget {
  const _DrawerFooter({required this.onNavigate});

  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final links = [
      (
        'profile',
        LucideIcons.circleUserRound,
        'Profile & brand',
        AppRoutes.dashboardAccount,
      ),
      (
        'settings',
        LucideIcons.settings,
        'Account Settings',
        AppRoutes.settings,
      ),
      (
        'billing',
        LucideIcons.creditCard,
        'Billing & credits',
        AppRoutes.dashboardBilling,
      ),
      (
        'school',
        LucideIcons.bookOpen,
        'Learning Center',
        AppRoutes.studioSchool,
      ),
      (
        'support',
        LucideIcons.circleHelp,
        'Help & support',
        AppRoutes.dashboardSupport,
      ),
      ('sign-out', LucideIcons.logOut, 'Sign out', ''),
    ];
    return Container(
      padding: const EdgeInsets.only(top: 13),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFD4D4CE))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var row = 0; row < 3; row++)
            Padding(
              padding: EdgeInsets.only(top: row == 0 ? 0 : 6),
              child: Row(
                children: [
                  for (var column = 0; column < 2; column++) ...[
                    if (column > 0) const SizedBox(width: 6),
                    Expanded(
                      child: _AccountQuickLink(
                        keyName: links[row * 2 + column].$1,
                        icon: links[row * 2 + column].$2,
                        label: links[row * 2 + column].$3,
                        onTap: links[row * 2 + column].$4.isEmpty
                            ? user == null
                                  ? null
                                  : () => unawaited(_logOut(context, ref))
                            : () => onNavigate(links[row * 2 + column].$4),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
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
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFEBEBE7),
    child: InkWell(
      key: ValueKey('dashboard-drawer-$keyName'),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF585852)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  color: Color(0xFF585852),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
