import 'package:flutter/material.dart';
import 'package:look_atlas/shared/widgets/bar_spinner.dart';

/// Filled CTA button with a built-in loading state. Disabled and shows a
/// spinner while [isLoading] is true.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.onPressed,
    this.label,
    this.isLoading = false,
    this.icon,
    this.iconAlignment = IconAlignment.start,
    this.fitToContent = false,
    this.height = 48,
    this.backgroundColor,
    this.foregroundColor,
    this.iconSize = 20,
    this.textStyle,
    this.child,
    this.loadingChild,
    super.key,
  }) : assert(label != null || child != null, 'Provide a label or child.');

  final String? label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final IconAlignment iconAlignment;
  final bool fitToContent;
  final double height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double iconSize;
  final TextStyle? textStyle;
  final Widget? child;
  final Widget? loadingChild;

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
          disabledBackgroundColor: backgroundColor,
          disabledForegroundColor: foregroundColor,
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? loadingChild ?? const ButtonLoader()
            : child ??
                  Row(
                    mainAxisSize: fitToContent
                        ? MainAxisSize.min
                        : MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null &&
                          iconAlignment == IconAlignment.start) ...[
                        Icon(icon, size: iconSize),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          label!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textStyle,
                        ),
                      ),
                      if (icon != null &&
                          iconAlignment == IconAlignment.end) ...[
                        const SizedBox(width: 8),
                        Icon(icon, size: iconSize),
                      ],
                    ],
                  ),
      ),
    );
  }
}
