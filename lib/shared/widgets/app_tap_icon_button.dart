import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';

class AppTapIconButton extends StatelessWidget {
  const AppTapIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tooltip,
    this.color,
    this.size = 20,
    this.dimension = 44,
    this.backgroundColor = Colors.transparent,
    this.border,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? tooltip;
  final Color? color;
  final double size;
  final double dimension;
  final Color backgroundColor;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    Widget button = Material(
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: dimension,
          height: dimension,
          decoration: border != null ? BoxDecoration(border: border) : null,
          alignment: Alignment.center,
          child: Icon(icon, size: size, color: color ?? AppColors.inkAlpha68),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip, child: button);
    }

    return Semantics(
      label: label,
      button: true,
      child: button,
    );
  }
}
