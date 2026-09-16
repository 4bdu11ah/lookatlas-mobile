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

  static const double _maximumDrawerWidth = 320;
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
          constraints.maxWidth * 0.84,
        );
        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, content) {
            final progress = animation.value;
            return Stack(
              children: [
                Transform.translate(
                  offset: Offset.zero,
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
                    child: Transform.translate(
                      offset: Offset(-drawerWidth * (1 - progress), 0),
                      child: GestureDetector(
                        onHorizontalDragUpdate: (details) =>
                            onDragUpdate(details.delta.dx, drawerWidth),
                        onHorizontalDragEnd: (details) =>
                            onDragEnd(details.primaryVelocity ?? 0),
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
