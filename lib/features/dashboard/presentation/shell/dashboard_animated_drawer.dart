part of 'dashboard_shell.dart';

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

  static const double _maximumDrawerWidth = 330;
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
          constraints.maxWidth * 0.86,
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
                        child: GestureDetector(
                          onHorizontalDragUpdate: (details) =>
                              onDragUpdate(details.delta.dx, drawerWidth),
                          onHorizontalDragEnd: (details) =>
                              onDragEnd(details.primaryVelocity ?? 0),
                          child: drawer,
                        ),
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
