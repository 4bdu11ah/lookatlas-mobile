part of 'dashboard_shell.dart';

class FeatureNavigationScaffold extends ConsumerStatefulWidget {
  const FeatureNavigationScaffold({
    required this.title,
    required this.child,
    super.key,
  });
  final String title;
  final Widget child;

  @override
  ConsumerState<FeatureNavigationScaffold> createState() =>
      _FeatureNavigationScaffoldState();
}

class _FeatureNavigationScaffoldState
    extends ConsumerState<FeatureNavigationScaffold>
    with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(vsync: this);
  final _menuFocus = FocusNode();
  final _closeFocus = FocusNode();
  final _scope = FocusScopeNode();
  double _dragDistance = 0;

  @override
  void dispose() {
    _animation.dispose();
    _menuFocus.dispose();
    _closeFocus.dispose();
    _scope.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _closeFocus.requestFocus();
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      _animation.value = 1;
      return;
    }
    await _animation.animateTo(
      1,
      duration: const Duration(milliseconds: 420),
      curve: const Cubic(0.2, 0.8, 0.2, 1),
    );
  }

  Future<void> _close() async {
    if (MediaQuery.disableAnimationsOf(context)) {
      _animation.value = 0;
    } else {
      await _animation.animateBack(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInCubic,
      );
    }
    if (mounted) _menuFocus.requestFocus();
  }

  void _drag(double delta, double travel) {
    _dragDistance += delta;
    _animation.value = (_animation.value + delta / travel).clamp(0, 1);
  }

  void _endDrag(double velocity) {
    final open =
        _dragDistance > -60 &&
        (velocity > 350 || (velocity >= -350 && _animation.value >= 0.5));
    _dragDistance = 0;
    unawaited(open ? _open() : _close());
  }

  Future<void> _navigate(String route) async {
    await _close();
    if (!mounted) return;
    if (route == AppRoutes.home) {
      context.go(route);
    } else if (route != GoRouterState.of(context).uri.toString()) {
      unawaited(context.push<void>(route));
    }
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.escape): () {
        if (!_animation.isDismissed) unawaited(_close());
      },
    },
    child: FocusTraversalGroup(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) => PopScope(
          canPop: _animation.isDismissed,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) unawaited(_close());
          },
          child: child!,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFFFFFEFA),
          body: _DashboardDrawerTransition(
            animation: _animation,
            onClose: () => unawaited(_close()),
            onDragUpdate: _drag,
            onDragEnd: _endDrag,
            drawer: _DashboardDrawer(
              selected: DashboardPage.dashboard,
              selectedRoute: widget.title == 'Learning Center'
                  ? AppRoutes.studioSchool
                  : widget.title == 'Guides'
                  ? AppRoutes.dashboardGuides
                  : AppRoutes.dashboardSupport,
              focusScopeNode: _scope,
              closeFocusNode: _closeFocus,
              onClose: () => unawaited(_close()),
              onNavigate: (route) => unawaited(_navigate(route)),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _FeatureNavigationBar(
                    title: widget.title,
                    menuFocus: _menuFocus,
                    onOpen: () => unawaited(_open()),
                  ),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _FeatureNavigationBar extends ConsumerWidget {
  const _FeatureNavigationBar({
    required this.title,
    required this.menuFocus,
    required this.onOpen,
  });
  final String title;
  final FocusNode menuFocus;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credits =
        ref.watch(learningCreditBalanceProvider) ??
        ref.watch(dashboardStatsProvider).value?.credits;
    final label = credits == null
        ? 'Credits unavailable'
        : '${NumberFormat.decimalPattern('en_US').format(credits)} credits';
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFEFA),
        border: Border(bottom: BorderSide(color: Color(0xFFD9D8D0))),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 36,
            child: IconButton(
              focusNode: menuFocus,
              tooltip: 'Open navigation',
              onPressed: onOpen,
              style: IconButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: const RoundedRectangleBorder(),
                side: const BorderSide(color: Color(0xFFD9D8D0)),
              ),
              icon: const Icon(LucideIcons.menu, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () =>
                unawaited(context.push<void>(AppRoutes.dashboardBilling)),
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F1EB),
                border: Border.all(color: const Color(0xFFD9D8D0)),
              ),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
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
