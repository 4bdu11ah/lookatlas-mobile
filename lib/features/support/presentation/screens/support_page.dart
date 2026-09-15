import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/features/dashboard/presentation/shell/dashboard_shell.dart';
import 'package:look_atlas/features/studio_school/presentation/widgets/learning_center_style.dart';
import 'package:look_atlas/features/support/domain/entities/support_ticket.dart';
import 'package:look_atlas/features/support/presentation/controllers/support_controller.dart';
import 'package:look_atlas/features/support/presentation/models/support_screen_state.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

part '../dialogs/support_success_dialog.dart';
part '../widgets/support_form.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const FeatureNavigationScaffold(title: 'Support', child: _SupportPage());
}

void _backToSchool(BuildContext context) {
  if (context.canPop() &&
      GoRouterState.of(context).uri.queryParameters['from'] == 'school') {
    context.pop();
  } else {
    context.go(AppRoutes.studioSchool);
  }
}

class _SupportPage extends ConsumerWidget {
  const _SupportPage();
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 84),
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: LearningAction(
          'Studio School',
          outlined: true,
          height: 42,
          icon: LucideIcons.chevronLeft,
          onPressed: () => _backToSchool(context),
        ),
      ),
      const SizedBox(height: 18),
      const LearningKicker('Help & Support'),
      const SizedBox(height: 8),
      Text(
        "Tell us what you're trying to do.",
        style: LearningCenterStyle.serif(38),
      ),
      const SizedBox(height: 6),
      Text(
        'A real person will reply to your account email shortly.',
        style: LearningCenterStyle.body(13),
      ),
      const SizedBox(height: 24),
      const _SupportCategories(),
      const SizedBox(height: 20),
      const _SupportForm(),
    ],
  );
}

class _SupportCategories extends ConsumerWidget {
  const _SupportCategories();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      supportControllerProvider.select((state) => state.category),
    );
    final saving = ref.watch(
      supportControllerProvider.select((state) => state.isSubmitting),
    );
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final category in SupportCategory.values)
          Semantics(
            selected: category == selected,
            button: true,
            child: InkWell(
              key: ValueKey('support-category-${category.name}'),
              onTap: saving
                  ? null
                  : () => ref
                        .read(supportControllerProvider.notifier)
                        .setCategory(category),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 11,
                ),
                decoration: BoxDecoration(
                  color: category == selected
                      ? LearningCenterStyle.ink
                      : LearningCenterStyle.soft,
                  border: Border.all(
                    color: category == selected
                        ? LearningCenterStyle.ink
                        : LearningCenterStyle.line,
                  ),
                ),
                child: Text(
                  category.label,
                  style: LearningCenterStyle.body(
                    11.5,
                    color: category == selected
                        ? LearningCenterStyle.paper
                        : LearningCenterStyle.ink,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
