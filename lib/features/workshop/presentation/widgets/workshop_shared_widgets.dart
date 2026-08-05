part of '../screens/workshop_screen.dart';

double _orientationRatio(WorkshopImageOrientation? orientation) =>
    switch (orientation) {
      WorkshopImageOrientation.landscape => 3 / 2,
      WorkshopImageOrientation.square => 1,
      WorkshopImageOrientation.portrait || null => 2 / 3,
    };

class _WorkshopFieldLabel extends StatelessWidget {
  const _WorkshopFieldLabel({
    required this.title,
    this.isRequired = false,
    this.optional,
    this.tooltip,
  });

  final String title;
  final bool isRequired;
  final String? optional;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            height: 16 / 12,
            fontWeight: AppTypography.bold,
            letterSpacing: 0.3,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(fontSize: 12, color: AppColors.danger),
          ),
        ],
        if (optional != null) ...[
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              optional!,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                height: 16 / 12,
                color: AppColors.neutral500,
              ),
            ),
          ),
        ],
        if (tooltip != null) ...[
          const SizedBox(width: 6),
          Tooltip(
            message: tooltip,
            triggerMode: TooltipTriggerMode.tap,
            child: const Icon(
              Icons.info_outline,
              size: 14,
              color: AppColors.neutral500,
            ),
          ),
        ],
      ],
    );
  }
}

class _WorkshopShell extends StatelessWidget {
  const _WorkshopShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.neutral100Alpha30,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: child,
    );
  }
}

class _WorkshopErrorBox extends StatelessWidget {
  const _WorkshopErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: const BoxDecoration(
        color: AppColors.dangerLight,
        border: Border(left: BorderSide(color: AppColors.danger, width: 4)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 14,
          height: 20 / 14,
          fontWeight: AppTypography.medium,
          color: AppColors.dangerDark,
        ),
      ),
    );
  }
}

class _WorkshopIconButton extends StatelessWidget {
  const _WorkshopIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.dark = false,
    this.dimension = 32,
    this.iconSize = 18,
    this.backgroundColor,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool dark;
  final double dimension;
  final double iconSize;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color:
            backgroundColor ??
            (dark ? AppColors.blackAlpha90 : AppColors.white),
        child: InkWell(
          onTap: onTap,
          child: SizedBox.square(
            dimension: dimension,
            child: Icon(
              icon,
              size: iconSize,
              color: dark ? AppColors.white : AppColors.black,
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkshopOutlineButton extends StatelessWidget {
  const _WorkshopOutlineButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.height = 40,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const foreground = AppColors.black;
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20),
          decoration: BoxDecoration(
            border: Border.all(color: foreground, width: compact ? 1 : 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: compact ? 16 : 18, color: foreground),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 12 : 14,
                  height: compact ? 16 / 12 : 20 / 14,
                  fontWeight: AppTypography.semiBold,
                  letterSpacing: compact ? 0.6 : 0,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkshopPrimaryButton extends StatelessWidget {
  const _WorkshopPrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.black,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 48,
          width: double.infinity,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: AppTypography.semiBold,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewActionButton extends StatelessWidget {
  const _PreviewActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.dark = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final foreground = dark ? AppColors.white : AppColors.black;
    return Material(
      color: dark ? AppColors.transparent : AppColors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: dark ? 40 : 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: dark
              ? BoxDecoration(
                  border: Border.all(
                    color: AppColors.whiteAlpha50,
                    width: 2,
                  ),
                )
              : null,
          child: Row(
            mainAxisSize: dark ? MainAxisSize.min : MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: AppTypography.semiBold,
                    color: foreground,
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
