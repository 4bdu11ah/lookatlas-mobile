import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';

class AppSquareIcon extends StatelessWidget {
  const AppSquareIcon(
    this.icon, {
    this.child,
    this.backgroundColor = AppColors.black,
    this.iconColor = AppColors.white,
    this.borderColor,
    this.size = 40,
    this.iconSize = 20,
    super.key,
  });

  final IconData? icon;
  final Widget? child;
  final Color backgroundColor;
  final Color iconColor;
  final Color? borderColor;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: borderColor != null ? Border.all(color: borderColor!) : null,
      ),
      alignment: Alignment.center,
      child: child ??
          (icon != null
              ? Icon(icon, size: iconSize, color: iconColor)
              : const SizedBox.shrink()),
    );
  }
}
