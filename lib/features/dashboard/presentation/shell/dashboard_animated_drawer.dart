part of '../screens/dashboard_screen.dart';

class _DashboardDrawerTransition extends StatelessWidget {
  const _DashboardDrawerTransition({
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
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final drawerWidth = min(
          _maximumDrawerWidth,
          constraints.maxWidth * 0.82,
        );
        final travel = drawerWidth * 0.94;
        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) => _buildTransition(
            context,
            child!,
            drawerWidth,
            travel,
          ),
        );
      },
    );
  }

  Widget _buildTransition(
    BuildContext context,
    Widget content,
    double drawerWidth,
    double travel,
  ) {
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
                    Positioned.fill(child: content),
                    if (progress > 0)
                      Positioned.fill(
                        child: Semantics(
                          button: true,
                          label: 'Close navigation',
                          child: GestureDetector(
                            key: const ValueKey('dashboard-drawer-scrim'),
                            behavior: HitTestBehavior.opaque,
                            onTap: onClose,
                            onHorizontalDragUpdate: (details) => onDragUpdate(
                              details.delta.dx,
                              travel,
                            ),
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
              onHorizontalDragUpdate: (details) => onDragUpdate(
                details.delta.dx,
                travel,
              ),
              onHorizontalDragEnd: (details) => onDragEnd(
                details.primaryVelocity ?? 0,
              ),
            ),
          ),
      ],
    );
  }
}
