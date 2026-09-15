import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/features/studio_school/presentation/controllers/learning_center_search_controller.dart';
import 'package:look_atlas/features/studio_school/presentation/widgets/learning_center_style.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LearningCenterSupport extends StatelessWidget {
  const LearningCenterSupport({super.key});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 60),
    padding: const EdgeInsets.only(top: 28),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: LearningCenterStyle.line)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LearningKicker('Still stuck?'),
        const SizedBox(height: 10),
        Text(
          'Tell us what you’re trying to do.',
          style: LearningCenterStyle.serif(32),
        ),
        const SizedBox(height: 6),
        Text(
          'A real person can help with the account, the workflow, or a result that does not look right.',
          style: LearningCenterStyle.body(13),
        ),
        const SizedBox(height: 20),
        LearningAction(
          'Get help',
          onPressed: () => unawaited(
            context.push<void>('${AppRoutes.dashboardSupport}?from=school'),
          ),
        ),
      ],
    ),
  );
}

class LearningSearchEmpty extends ConsumerWidget {
  const LearningSearchEmpty({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          LucideIcons.circleHelp,
          size: 26,
          color: LearningCenterStyle.muted,
        ),
        const SizedBox(height: 16),
        const LearningKicker('No exact match'),
        const SizedBox(height: 10),
        Text('Try a simpler search.', style: LearningCenterStyle.serif(36)),
        const SizedBox(height: 6),
        Text(
          'Search for credits, products, models, directions, fixes, or shoots.',
          style: LearningCenterStyle.body(12),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            LearningAction(
              'See everything',
              height: 40,
              icon: null,
              onPressed: ref.read(learningCenterSearchProvider.notifier).clear,
            ),
            LearningAction(
              'Ask support',
              height: 40,
              icon: null,
              outlined: true,
              onPressed: () => unawaited(
                context.push<void>('${AppRoutes.dashboardSupport}?from=school'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
