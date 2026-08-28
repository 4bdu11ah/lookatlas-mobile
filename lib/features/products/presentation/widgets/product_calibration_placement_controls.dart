part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _PlacementFineControls extends StatelessWidget {
  const _PlacementFineControls({
    required this.onLeft,
    required this.onUp,
    required this.onRight,
    required this.onSmaller,
    required this.onCenter,
    required this.onLarger,
    required this.onRotateLeft,
    required this.onRotateRight,
  });

  final VoidCallback onLeft;
  final VoidCallback onUp;
  final VoidCallback onRight;
  final VoidCallback onSmaller;
  final VoidCallback onCenter;
  final VoidCallback onLarger;
  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.neutral100Alpha68,
      border: Border.all(color: AppColors.neutral200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Kicker('Fine placement controls'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _FineControl('Left', Icons.arrow_back, onLeft)),
            const SizedBox(width: 6),
            Expanded(child: _FineControl('Up', Icons.arrow_upward, onUp)),
            const SizedBox(width: 6),
            Expanded(
              child: _FineControl('Right', Icons.arrow_forward, onRight),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _FineControl(
                'Center',
                Icons.center_focus_strong,
                onCenter,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _FineControl('Smaller', Icons.remove, onSmaller)),
            const SizedBox(width: 6),
            Expanded(child: _FineControl('Larger', Icons.add, onLarger)),
            const SizedBox(width: 6),
            Expanded(
              child: _FineControl(
                'Rotate left',
                Icons.rotate_left,
                onRotateLeft,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _FineControl(
                'Rotate right',
                Icons.rotate_right,
                onRotateRight,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _FineControl extends StatelessWidget {
  const _FineControl(this.tooltip, this.icon, this.onTap);

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 44,
        child: Icon(icon, size: 17),
      ),
    ),
  );
}
