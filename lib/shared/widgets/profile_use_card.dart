import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProfileUseCard extends StatelessWidget {
  const ProfileUseCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onPressed,
    this.mutuallyExclusive = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onPressed;
  final bool mutuallyExclusive;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    checked: mutuallyExclusive ? selected : null,
    toggled: mutuallyExclusive ? null : selected,
    inMutuallyExclusiveGroup: mutuallyExclusive,
    label: title,
    child: InkWell(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? AppColors.black : AppColors.transparent,
          border: Border.all(
            color: selected ? AppColors.black : AppColors.neutral200,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? AppColors.white : AppColors.black,
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    color: selected ? AppColors.white : AppColors.black,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: selected
                        ? AppColors.whiteAlpha70
                        : AppColors.neutral500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (selected)
              const Positioned(
                right: 0,
                top: 0,
                child: ColoredBox(
                  color: AppColors.white,
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: Icon(
                      LucideIcons.check,
                      size: 13,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
