import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';

class AppHairline extends StatelessWidget {
  const AppHairline({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 1,
      width: double.infinity,
      child: ColoredBox(color: AppColors.neutral200),
    );
  }
}
