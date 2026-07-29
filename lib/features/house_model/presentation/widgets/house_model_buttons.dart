part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _ModelFab extends StatelessWidget {
  const _ModelFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _ModelActionButton(
      key: const ValueKey('add-model-fab'),
      label: 'Add Model',
      icon: Icons.people_alt_outlined,
      onTap: onTap,
    );
  }
}

class _ModelActionButton extends StatelessWidget {
  const _ModelActionButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.full = false,
    this.isLoading = false,
    super.key,
  }) : iconAlignment = IconAlignment.start,
       compact = false,
       _kind = _ModelButtonKind.primary;

  const _ModelActionButton.secondary({
    required this.label,
    required this.onTap,
    this.icon,
    this.full = false,
  }) : iconAlignment = IconAlignment.start,
       compact = false,
       isLoading = false,
       _kind = _ModelButtonKind.secondary,
       super();

  const _ModelActionButton.ghost({
    required this.label,
    required this.onTap,
    this.icon,
    this.iconAlignment = IconAlignment.start,
    this.full = false,
    this.compact = false,
    super.key,
  }) : isLoading = false,
       _kind = _ModelButtonKind.ghost;

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final IconAlignment iconAlignment;
  final bool full;
  final bool compact;
  final bool isLoading;
  final _ModelButtonKind _kind;

  @override
  Widget build(BuildContext context) {
    final isPrimary = _kind == _ModelButtonKind.primary;
    final bg = isPrimary ? AppColors.black : AppColors.white;
    final border = _kind == _ModelButtonKind.ghost
        ? AppColors.neutral200
        : AppColors.black;
    final fg = isPrimary ? AppColors.white : AppColors.black;
    return SizedBox(
      width: full ? double.infinity : null,
      height: compact ? 36 : 48,
      child: Material(
        color: bg,
        elevation: isPrimary && !full ? 8 : 0,
        shape: Border.all(color: border, width: compact ? 1 : 2),
        child: InkWell(
          onTap: isLoading ? null : onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 11 : 18),
            child: isLoading
                ? Center(child: BarSpinner(size: 18, color: fg))
                : Row(
                    mainAxisSize: full ? MainAxisSize.max : MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null &&
                          iconAlignment == IconAlignment.start) ...[
                        Icon(icon, size: compact ? 15 : 18, color: fg),
                        SizedBox(width: compact ? 7 : 9),
                      ],
                      Flexible(
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
                      ),
                      if (icon != null &&
                          iconAlignment == IconAlignment.end) ...[
                        SizedBox(width: compact ? 7 : 9),
                        Icon(icon, size: compact ? 15 : 18, color: fg),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

enum _ModelButtonKind { primary, secondary, ghost }
