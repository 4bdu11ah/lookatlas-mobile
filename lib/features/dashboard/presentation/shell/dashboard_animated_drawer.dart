part of '../screens/dashboard_screen.dart';

/// Mobile modal-drawer motion from the design handoff: the application stays
/// in place under a dimmed scrim while the pearl navigation surface slides in.
class _DashboardDrawerTransition extends StatelessWidget {
  const _DashboardDrawerTransition({
    required this.animation,
    required this.drawer,
    required this.onClose,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.child,
  });

  static const double _maximumDrawerWidth = 360;
  static const double _edgeDragWidth = 24;

  final Animation<double> animation;
  final Widget drawer;
  final VoidCallback onClose;
  final void Function(double delta, double travel) onDragUpdate;
  final ValueChanged<double> onDragEnd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final drawerWidth = min(
          _maximumDrawerWidth,
          constraints.maxWidth * 0.88,
        );
        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, content) {
            final progress = animation.value;
            return Stack(
              children: [
                Transform.translate(
                  offset: Offset(14 * progress, 0),
                  child: ExcludeFocus(
                    excluding: progress > 0,
                    child: Semantics(
                      hidden: progress > 0,
                      child: content,
                    ),
                  ),
                ),
                if (progress > 0)
                  Positioned.fill(
                    child: GestureDetector(
                      key: const ValueKey('dashboard-drawer-scrim'),
                      behavior: HitTestBehavior.opaque,
                      onTap: onClose,
                      onHorizontalDragUpdate: (details) => onDragUpdate(
                        details.delta.dx,
                        drawerWidth,
                      ),
                      onHorizontalDragEnd: (details) => onDragEnd(
                        details.primaryVelocity ?? 0,
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 2 * progress,
                          sigmaY: 2 * progress,
                        ),
                        child: ColoredBox(
                          color: const Color(0xFF10100E).withValues(
                            alpha: 0.54 * progress,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (progress > 0)
                  Positioned(
                    key: const ValueKey('dashboard-drawer-surface'),
                    top: 0,
                    bottom: 0,
                    left: 0,
                    width: drawerWidth,
                    child: ClipPath(
                      clipper: _CircularDrawerRevealClipper(
                        progress: progress,
                        origin: Offset(
                          38,
                          MediaQuery.paddingOf(context).top + 34,
                        ),
                      ),
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x2410100E),
                              blurRadius: 50,
                              offset: Offset(18, 0),
                            ),
                          ],
                        ),
                        child: drawer,
                      ),
                    ),
                  ),
                if (progress == 0)
                  Positioned(
                    key: const ValueKey('dashboard-drawer-edge-drag'),
                    top: 0,
                    bottom: 0,
                    left: 0,
                    width: _edgeDragWidth,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragUpdate: (details) => onDragUpdate(
                        details.delta.dx,
                        drawerWidth,
                      ),
                      onHorizontalDragEnd: (details) => onDragEnd(
                        details.primaryVelocity ?? 0,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _CircularDrawerRevealClipper extends CustomClipper<Path> {
  const _CircularDrawerRevealClipper({
    required this.progress,
    required this.origin,
  });

  final double progress;
  final Offset origin;

  @override
  Path getClip(Size size) {
    final farthestX = max(origin.dx, size.width - origin.dx);
    final farthestY = max(origin.dy, size.height - origin.dy);
    final maximumRadius = sqrt(
      (farthestX * farthestX) + (farthestY * farthestY),
    );
    return Path()..addOval(
      Rect.fromCircle(center: origin, radius: maximumRadius * progress),
    );
  }

  @override
  bool shouldReclip(_CircularDrawerRevealClipper oldClipper) =>
      oldClipper.progress != progress || oldClipper.origin != origin;
}

/// The pre-existing wide-layout treatment is intentionally retained at the
/// desktop breakpoint; only compact layouts use the modal drawer above.
class _DashboardLegacyDrawerTransition extends StatelessWidget {
  const _DashboardLegacyDrawerTransition({
    required this.animation,
    required this.drawer,
    required this.onClose,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.child,
  });

  static const double _maximumDrawerWidth = 288;
  static const double _edgeDragWidth = 24;

  final Animation<double> animation;
  final Widget drawer;
  final VoidCallback onClose;
  final void Function(double delta, double travel) onDragUpdate;
  final ValueChanged<double> onDragEnd;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final drawerWidth = min(
        _maximumDrawerWidth,
        constraints.maxWidth * 0.82,
      );
      final travel = drawerWidth * 0.94;
      return AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, content) {
          final progress = animation.value;
          final radius = BorderRadius.circular(22 * progress);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              if (progress > 0)
                Positioned(
                  key: const ValueKey('dashboard-drawer-surface'),
                  top: 0,
                  bottom: 0,
                  left: 0,
                  width: drawerWidth,
                  child: Opacity(
                    opacity: (progress * 1.8).clamp(0, 1),
                    child: Transform.translate(
                      offset: Offset(-24 * (1 - progress), 0),
                      child: drawer,
                    ),
                  ),
                ),
              Transform.translate(
                key: const ValueKey('dashboard-drawer-content'),
                offset: Offset(travel * progress, 0),
                child: Transform.scale(
                  alignment: Alignment.centerRight,
                  scale: 1 - (0.035 * progress),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      boxShadow: progress == 0
                          ? const []
                          : const [
                              BoxShadow(
                                color: AppColors.inkAlpha12,
                                blurRadius: 24,
                                offset: Offset(-6, 0),
                              ),
                            ],
                    ),
                    child: ClipRRect(
                      borderRadius: radius,
                      child: Stack(
                        children: [
                          Positioned.fill(child: content!),
                          if (progress > 0)
                            Positioned.fill(
                              child: GestureDetector(
                                key: const ValueKey(
                                  'dashboard-drawer-scrim',
                                ),
                                behavior: HitTestBehavior.opaque,
                                onTap: onClose,
                                onHorizontalDragUpdate: (details) =>
                                    onDragUpdate(details.delta.dx, travel),
                                onHorizontalDragEnd: (details) => onDragEnd(
                                  details.primaryVelocity ?? 0,
                                ),
                                child: ColoredBox(
                                  color: AppColors.black.withValues(
                                    alpha: 0.035 * progress,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (progress < 1)
                Positioned(
                  key: const ValueKey('dashboard-drawer-edge-drag'),
                  top: 0,
                  bottom: 0,
                  left: 0,
                  width: _edgeDragWidth,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragUpdate: (details) =>
                        onDragUpdate(details.delta.dx, travel),
                    onHorizontalDragEnd: (details) =>
                        onDragEnd(details.primaryVelocity ?? 0),
                  ),
                ),
            ],
          );
        },
      );
    },
  );
}
