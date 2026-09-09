import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';

class AppTapIconButton extends StatelessWidget {
  const AppTapIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: SizedBox.square(
          dimension: 44,
          child: Icon(icon, size: 20, color: AppColors.inkAlpha68),
        ),
      ),
    );
  }
}
