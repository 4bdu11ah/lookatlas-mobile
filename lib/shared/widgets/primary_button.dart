import 'package:flutter/material.dart';
import 'package:look_atlas/shared/widgets/bar_spinner.dart';

/// Filled CTA button with a built-in loading state. Disabled and shows a
/// spinner while [isLoading] is true.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fitToContent = false,
    this.height = 48,
    this.backgroundColor,
    this.foregroundColor,
    this.iconSize = 20,
    this.textStyle,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool fitToContent;
  final double height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double iconSize;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fitToContent ? null : double.infinity,
      height: height,
      child: FilledButton(
        style: FilledButton.styleFrom(
          minimumSize: Size(0, height),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const ButtonLoader()
            : Row(
                mainAxisSize: fitToContent
                    ? MainAxisSize.min
                    : MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: iconSize),
                    const SizedBox(width: 8),
                  ],
                  if (fitToContent)
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle,
                    )
                  else
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textStyle,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
