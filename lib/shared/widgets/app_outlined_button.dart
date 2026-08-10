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
    this.iconAngle = 0,
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

  /// Icon rotation in radians, matching [Transform.rotate].
  final double iconAngle;
  final TextStyle? textStyle;

  Widget _buildIcon(Color color) {
    final iconWidget = Icon(icon, size: iconSize, color: color);
    return iconAngle == 0
        ? iconWidget
        : Transform.rotate(angle: iconAngle, child: iconWidget);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveForeground = foregroundColor ?? scheme.onSurface;
    final labelStyle = textStyle ?? Theme.of(context).textTheme.labelLarge;
    return SizedBox(
      width: fitToContent ? null : double.infinity,
      height: height,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(0, height),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          side: BorderSide(color: borderColor ?? scheme.primary),
          foregroundColor: effectiveForeground,
          backgroundColor: backgroundColor,
          textStyle: labelStyle,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: fitToContent ? MainAxisSize.min : MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null && iconAlignment == IconAlignment.start) ...[
              _buildIcon(effectiveForeground),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: labelStyle,
              ),
            ),
            if (icon != null && iconAlignment == IconAlignment.end) ...[
              const SizedBox(width: 8),
              _buildIcon(effectiveForeground),
            ],
          ],
        ),
      ),
    );
  }
}
