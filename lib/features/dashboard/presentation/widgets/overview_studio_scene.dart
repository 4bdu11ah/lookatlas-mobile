import 'package:flutter/material.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_welcome.dart';
import 'package:look_atlas/features/dashboard/presentation/widgets/overview_style.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class OverviewStudioScene extends StatelessWidget {
  const OverviewStudioScene({required this.welcome, super.key});
  final DashboardWelcomeState welcome;
  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    excludeSemantics: true,
    label:
        'Studio setup illustration, ${welcome.completedCount} of 6 steps complete',
    child: Container(
      height: 140,
      decoration: BoxDecoration(
        color: OverviewStyle.paper.withValues(alpha: .04),
        border: Border.all(color: OverviewStyle.paper.withValues(alpha: .12)),
      ),
      child: CustomPaint(
        painter: const _SceneGrid(),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SceneNode(
                  label: 'Product',
                  icon: LucideIcons.package,
                  active:
                      welcome.steps[DashboardWelcomeStepId.product] ?? false,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _SceneConnection(),
                ),
                _SceneNode(
                  label: 'Model',
                  icon: LucideIcons.userRound,
                  active: welcome.steps[DashboardWelcomeStepId.model] ?? false,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _SceneConnection(),
                ),
                _SceneNode(
                  label: 'Shoot',
                  icon: LucideIcons.camera,
                  active:
                      welcome.steps[DashboardWelcomeStepId.firstShoot] ?? false,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _SceneNode extends StatelessWidget {
  const _SceneNode({
    required this.label,
    required this.icon,
    required this.active,
  });
  final String label;
  final IconData icon;
  final bool active;
  @override
  Widget build(BuildContext context) {
    final color = OverviewStyle.paper.withValues(alpha: active ? 1 : .5);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(border: Border.all(color: color)),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: OverviewStyle.body(
            9,
            color: color,
          ).copyWith(letterSpacing: .45),
        ),
      ],
    );
  }
}

class _SceneConnection extends StatefulWidget {
  const _SceneConnection();
  @override
  State<_SceneConnection> createState() => _SceneConnectionState();
}

class _SceneConnectionState extends State<_SceneConnection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 30,
    height: 1,
    child: AnimatedBuilder(
      animation: _controller,
      child: const ColoredBox(color: OverviewStyle.paper),
      builder: (context, child) =>
          Opacity(opacity: .2 + .5 * _controller.value, child: child),
    ),
  );
}

class _SceneGrid extends CustomPainter {
  const _SceneGrid();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = OverviewStyle.paper.withValues(alpha: .12)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 16) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += 16) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_SceneGrid oldDelegate) => false;
}
