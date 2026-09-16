import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:look_atlas/core/layout/app_responsive.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/presentation/controllers/auth_controller.dart';
import 'package:look_atlas/features/calendar/di/calendar_providers.dart';
import 'package:look_atlas/features/dashboard/di/dashboard_providers.dart';
import 'package:look_atlas/features/dashboard/presentation/controllers/dashboard_overview_controller.dart';
import 'package:look_atlas/features/dashboard/presentation/controllers/dashboard_shell_controller.dart';
import 'package:look_atlas/features/dashboard/presentation/models/dashboard_page.dart';
import 'package:look_atlas/features/dashboard/presentation/screens/dashboard_overview_screen.dart';
import 'package:look_atlas/features/dashboard/presentation/widgets/overview_shell_header.dart';
import 'package:look_atlas/features/dashboard/presentation/widgets/overview_style.dart';
import 'package:look_atlas/features/studio_school/di/studio_school_providers.dart';
import 'package:look_atlas/features/studio_school/presentation/controllers/learning_credit_balance_controller.dart';
import 'package:look_atlas/shared/widgets/app_hairline.dart';
import 'package:look_atlas/shared/widgets/app_icon_button.dart';
import 'package:look_atlas/shared/widgets/app_image.dart';
import 'package:look_atlas/shared/widgets/app_snack_bar.dart';
import 'package:look_atlas/shared/widgets/app_text.dart';
import 'package:look_atlas/shared/widgets/bar_spinner.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

part 'dashboard_animated_drawer.dart';
part 'dashboard_feature_drawer.dart';
part 'feature_navigation_scaffold.dart';
part '../widgets/dashboard_navigation_widgets.dart';

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
    ref.read(dashboardShellControllerProvider.notifier).openNavigation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _drawerCloseFocusNode.requestFocus();
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      _drawerController.value = 1;
      return Future.value();
    }
    final mobile = MediaQuery.sizeOf(context).width < 1024;
    return _drawerController.animateTo(
      1,
      duration: mobile ? const Duration(milliseconds: 420) : null,
      curve: mobile ? const Cubic(0.2, 0.8, 0.2, 1) : Curves.easeOutCubic,
    );
  }

  Future<void> _closeDrawer() async {
    ref.read(dashboardShellControllerProvider.notifier).closeNavigation();
    if (MediaQuery.disableAnimationsOf(context)) {
      _drawerController.value = 0;
    } else {
      final mobile = MediaQuery.sizeOf(context).width < 1024;
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

  double _drawerDragDistance = 0;

  void _dragDrawer(double delta, double travel) {
    _drawerDragDistance += delta;
    _drawerController.value = (_drawerController.value + delta / travel).clamp(
      0,
      1,
    );
  }

  void _finishDrawerDrag(double velocity) {
    final shouldOpen =
        _drawerDragDistance > -60 &&
        (velocity > 350 ||
            (velocity >= -350 && _drawerController.value >= 0.5));
    _drawerDragDistance = 0;
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

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 1024;
    final state = ref.watch(dashboardShellControllerProvider);
    final controller = ref.read(dashboardShellControllerProvider.notifier);
    final screen = DashboardOverviewScreen(
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
    final welcome = ref.watch(studioSchoolWelcomeProvider);
    final showCompleteProfile =
        welcome?.eligible == true &&
        (welcome?.dashboard?.profileIncomplete ?? false);
    final content = SafeArea(
      bottom: false,
      child: ResponsiveContent(
        child: Stack(
          children: [
            Column(
              children: [
                if (mobile)
                  OverviewShellHeader(
                    menuFocusNode: _menuFocusNode,
                    onOpenNavigation: () => unawaited(_openDrawer()),
                    onOpenBilling: () => _navigateDashboard(
                      context,
                      ref,
                      DashboardPage.billing,
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
                            dashboardOverviewControllerProvider.notifier,
                          )
                          .refresh(),
                      ref.read(refreshStudioSchoolProvider)(),
                    ]),
                    child: screen,
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
                    DashboardPage.settings,
                  ),
                  onBilling: () => _navigateDashboard(
                    context,
                    ref,
                    DashboardPage.billing,
                  ),
                  onLogOut: () => _logOut(context, ref),
                ),
              ),
          ],
        ),
      ),
    );
    final scaffold = Scaffold(
      backgroundColor: OverviewStyle.paper,
      body: _DashboardDrawerTransition(
        animation: _drawerController,
        drawer: _DashboardDrawer(
          selected: DashboardPage.dashboard,
          focusScopeNode: _drawerFocusScopeNode,
          closeFocusNode: _drawerCloseFocusNode,
          onClose: () => unawaited(_closeDrawer()),
          onNavigate: (route) => unawaited(_selectDrawerRoute(route)),
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
  DashboardOverviewController? _overview;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    _overview = ref.read(dashboardOverviewControllerProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _overview?.setVisible(visible: route?.isCurrent ?? true);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _overview?.setVisible(visible: false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _overview?.setForeground(foreground: state == AppLifecycleState.resumed);
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(refreshStudioSchoolProvider)());
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void _navigateDashboard(
  BuildContext context,
  WidgetRef ref,
  DashboardPage page,
) {
  ref.read(dashboardShellControllerProvider.notifier).closeUserMenu();
  if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
    Navigator.pop(context);
  }
  if (page == DashboardPage.dashboard) {
    context.go(page.routePath);
  } else {
    unawaited(context.push<void>(page.routePath));
  }
}

Future<void> _logOut(BuildContext context, WidgetRef ref) async {
  final succeeded = await ref.read(authControllerProvider.notifier).signOut();
  if (!succeeded && context.mounted) {
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

class _DrawerDestination {
  const _DrawerDestination({
    required this.keyName,
    required this.label,
    required this.icon,
    this.route,
    this.disabled = false,
    this.trailingLabel,
  });

  final String keyName;
  final String label;
  final IconData icon;
  final String? route;
  final bool disabled;
  final String? trailingLabel;
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
              children: [AppEyebrow('Credits'), _DashboardCredits()],
            ),
          ),
          const AppHairline(),
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
    final state = ref.watch(dashboardOverviewControllerProvider);
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
