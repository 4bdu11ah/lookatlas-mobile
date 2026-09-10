import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';

class ShootOptionWrap extends StatelessWidget {
  const ShootOptionWrap({
    required this.options,
    required this.selected,
    super.key,
  });

  final List<String> options;
  final int selected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 7,
    runSpacing: 7,
    children: List.generate(
      options.length,
      (index) => Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: index == selected ? AppColors.black : AppColors.white,
          border: Border.all(color: AppColors.black),
        ),
        child: Text(
          options[index],
          style: TextStyle(
            color: index == selected ? AppColors.white : AppColors.black,
            fontSize: 10,
            fontWeight: AppTypography.bold,
          ),
        ),
      ),
    ),
  );
}
