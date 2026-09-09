import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_typography.dart';

/// App-wide bordered text action with a leading icon.
class AppTextButton extends StatelessWidget {
  const AppTextButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.fitToContent = false,
    this.showBorder = true,
    this.height = 42,
    this.padding,
    this.textColor,
    this.textStyle,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fitToContent;
  final bool showBorder;
  final double height;
  final EdgeInsetsGeometry? padding;
  final Color? textColor;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveColor = textColor ?? scheme.onSurface;
    final buttonLabel = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: (textStyle ?? Theme.of(context).textTheme.labelMedium)?.copyWith(
        fontWeight: AppTypography.bold,
        color: effectiveColor,
      ),
    );
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: fitToContent ? null : double.infinity,
        height: height,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 12),
        decoration: showBorder
            ? BoxDecoration(
                color: scheme.surface,
                border: Border.all(color: scheme.outline),
              )
            : null,
        child: Row(
          mainAxisSize: fitToContent ? MainAxisSize.min : MainAxisSize.max,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: effectiveColor),
              const SizedBox(width: 7),
            ],
            if (fitToContent)
              buttonLabel
            else
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: buttonLabel,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
