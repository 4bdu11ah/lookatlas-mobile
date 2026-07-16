part of '../screens/dashboard_screen.dart';

class _Button extends StatelessWidget {
  const _Button({
    required this.label,
    required this.onTap,
    this.icon,
    this.iconAlignment = IconAlignment.start,
    this.full = false,
    this.danger = false,
  }) : compact = false,
       _secondary = false;

  const _Button.secondary({
    required this.label,
    required this.onTap,
    this.icon,
    this.iconAlignment = IconAlignment.start,
    this.full = false,
    this.compact = false,
  }) : danger = false,
       _secondary = true;

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final IconAlignment iconAlignment;
  final bool full;
  final bool compact;
  final bool danger;
  final bool _secondary;

  @override
  Widget build(BuildContext context) {
    final bg = danger
        ? AppColors.danger
        : (_secondary ? AppColors.white : AppColors.black);
    final fg = _secondary ? AppColors.black : AppColors.white;
    final iconWidget = icon == null ? null : Icon(icon, size: 16, color: fg);
    final labelWidget = Flexible(
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: compact ? 12 : 14,
          fontWeight: AppTypography.bold,
          color: fg,
        ),
      ),
    );
    return SizedBox(
      width: full ? double.infinity : null,
      height: compact ? 36 : 44,
      child: Material(
        color: bg,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: danger ? AppColors.danger : AppColors.black,
              ),
            ),
            child: Row(
              mainAxisSize: full ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (iconWidget != null &&
                    iconAlignment == IconAlignment.start) ...[
                  iconWidget,
                  const SizedBox(width: 8),
                ],
                labelWidget,
                if (iconWidget != null &&
                    iconAlignment == IconAlignment.end) ...[
                  const SizedBox(width: 8),
                  iconWidget,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
  const _SmallOverlayButton({required this.icon, required this.onTap});

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
