part of '../screens/dashboard_screen.dart';

class _FabButton extends StatelessWidget {
  const _FabButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.black,
      elevation: 8,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, size: 16, color: AppColors.white),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    super.key,
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
