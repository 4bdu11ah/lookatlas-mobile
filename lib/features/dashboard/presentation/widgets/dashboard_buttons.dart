part of '../screens/dashboard_screen.dart';

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.dimension = 44,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double dimension;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: SizedBox.square(
          dimension: dimension,
          child: Icon(icon, size: 20, color: AppColors.inkAlpha68),
        ),
      ),
    );
  }
}

class _SmallOverlayButton extends StatelessWidget {
  const _SmallOverlayButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.whiteAlpha80,
      child: InkWell(
        onTap: onTap,
        child: SizedBox.square(
          dimension: 32,
          child: Icon(icon, size: 16, color: AppColors.black),
        ),
      ),
    );
  }
}
