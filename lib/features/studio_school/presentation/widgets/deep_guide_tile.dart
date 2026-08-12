import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/studio_school/domain/lesson_definition.dart';
import 'package:look_atlas/features/studio_school/presentation/widgets/school_components.dart';

class DeepGuideTile extends StatelessWidget {
  const DeepGuideTile({required this.guide, required this.onTap, super.key});

  final DeepGuideDefinition guide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: AppColors.neutral200),
      ),
      child: InkWell(
        key: ValueKey('studio-school-guide-${guide.tabId}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SchoolSquareIcon(icon: guide.icon, inverted: false),
              const SizedBox(height: 13),
              Text(
                guide.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: AppTypography.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                guide.description,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.neutral500,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'READ THE GUIDE →',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 0.8,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
