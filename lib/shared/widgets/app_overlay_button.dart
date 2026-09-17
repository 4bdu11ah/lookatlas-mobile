import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/shared/widgets/app_tap_icon_button.dart';

class AppSmallOverlayButton extends StatelessWidget {
  const AppSmallOverlayButton({
    required this.icon,
    required this.onTap,
    this.label = '',
    super.key,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppTapIconButton(
      icon: icon,
      label: label,
      onTap: onTap,
      dimension: 32,
      size: 16,
      color: AppColors.black,
      backgroundColor: AppColors.whiteAlpha80,
    );
  }
}
