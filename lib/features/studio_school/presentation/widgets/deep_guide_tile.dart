import 'package:flutter/material.dart';
import 'package:look_atlas/features/studio_school/presentation/models/lesson_definition.dart';
import 'package:look_atlas/features/studio_school/presentation/widgets/learning_center_style.dart';
import 'package:look_atlas/features/studio_school/presentation/widgets/school_components.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DeepGuideTile extends StatelessWidget {
  const DeepGuideTile({required this.guide, required this.onTap, super.key});
  final DeepGuideDefinition guide;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      key: ValueKey('learning-guide-${guide.tabId}'),
      child: Container(
        constraints: const BoxConstraints(minHeight: 95),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: LearningCenterStyle.line)),
        ),
        child: Row(
          children: [
            SchoolSquareIcon(icon: guide.icon, size: 39, inverted: false),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    guide.kicker.toUpperCase(),
                    style: LearningCenterStyle.body(
                      11,
                      weight: FontWeight.w700,
                      height: 1.2,
                    ).copyWith(letterSpacing: 1.43),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    guide.title,
                    style: LearningCenterStyle.serif(21, tracking: -0.02),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    guide.description,
                    style: LearningCenterStyle.body(11, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: LearningCenterStyle.muted,
            ),
          ],
        ),
      ),
    ),
  );
}
