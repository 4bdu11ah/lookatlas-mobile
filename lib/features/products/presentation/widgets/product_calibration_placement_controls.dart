part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _PlacementFineControls extends StatelessWidget {
  const _PlacementFineControls({
    required this.onLeft,
    required this.onRight,
    required this.onSmaller,
    required this.onCenter,
    required this.onLarger,
    required this.onRotateLeft,
    required this.onRotateRight,
  });

  final VoidCallback onLeft;
  final VoidCallback onRight;
  final VoidCallback onSmaller;
  final VoidCallback onCenter;
  final VoidCallback onLarger;
  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.neutral100Alpha68,
      border: Border.all(color: AppColors.neutral200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fine placement controls',
          style: TextStyle(fontSize: 12, fontWeight: AppTypography.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Drag the product, or use the controls below.',
          style: TextStyle(fontSize: 11, color: AppColors.neutral500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _FineControl('← Left', onLeft),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _FineControl('Center', onCenter),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _FineControl('Right →', onRight),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _FineControl('− Smaller', onSmaller),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _FineControl('＋ Larger', onLarger),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: _FineControl('↶ Rotate left', onRotateLeft),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _FineControl('↷ Rotate right', onRotateRight),
            ),
          ],
        ),
      ],
    ),
  );
}

class _FineControl extends StatelessWidget {
  const _FineControl(this.label, this.onTap);

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.black, width: 2),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: AppTypography.bold,
        ),
      ),
    ),
  );
}
