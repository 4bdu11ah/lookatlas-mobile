import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';

class AppSmallOverlayButton extends StatelessWidget {
  const AppSmallOverlayButton({required this.icon, required this.onTap, super.key,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.whiteAlpha80,
      child: InkWell(
        onTap: onTap,
        child: SizedBox.square(
          dimension: 32,
          child: Icon(icon, size: 16, color: AppColors.black),
        ),
      ),
    );
  }
}
