import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';

class AppTapIconButton extends StatelessWidget {
  const AppTapIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.size = 20,
    this.dimension = 44,
    this.backgroundColor = Colors.transparent,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final double size;
  final double dimension;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: Material(
        color: backgroundColor,
        child: InkWell(
          onTap: onTap,
          child: SizedBox.square(
            dimension: dimension,
            child: Icon(icon, size: size, color: color ?? AppColors.inkAlpha68),
          ),
        ),
      ),
    );
  }
}
