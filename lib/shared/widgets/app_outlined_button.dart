import 'package:flutter/material.dart';

class AppOutlinedButton extends StatelessWidget {
  const AppOutlinedButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconAlignment = IconAlignment.start,
    this.fitToContent = false,
    this.height = 48,
    this.borderColor,
    this.foregroundColor,
    this.backgroundColor,
    this.iconSize = 20,
    this.textStyle,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconAlignment iconAlignment;
  final bool fitToContent;
  final double height;
  final Color? borderColor;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final double iconSize;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveForeground = foregroundColor ?? scheme.onSurface;
    return SizedBox(
      width: fitToContent ? null : double.infinity,
      height: height,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(0, height),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          side: BorderSide(color: borderColor ?? scheme.outline),
          foregroundColor: effectiveForeground,
          backgroundColor: backgroundColor,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: fitToContent ? MainAxisSize.min : MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null && iconAlignment == IconAlignment.start) ...[
              Icon(icon, size: iconSize, color: effectiveForeground),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
            ),
            if (icon != null && iconAlignment == IconAlignment.end) ...[
              const SizedBox(width: 8),
              Icon(icon, size: iconSize, color: effectiveForeground),
            ],
          ],
        ),
      ),
    );
  }
}
