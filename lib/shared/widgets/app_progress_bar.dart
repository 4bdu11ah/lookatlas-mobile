import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';

class AppProgressBar extends StatelessWidget {
  const AppProgressBar({required this.value, super.key});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Container(
        height: 10,
        color: AppColors.neutral200,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value,
          child: const ColoredBox(color: AppColors.black),
        ),
      ),
    );
  }
}
