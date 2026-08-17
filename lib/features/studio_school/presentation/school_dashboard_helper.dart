import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/providers/core_providers.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/auth/presentation/auth_controller.dart';
import 'package:look_atlas/features/studio_school/presentation/studio_school_controller.dart';
import 'package:look_atlas/features/studio_school/presentation/studio_school_state.dart';
import 'package:look_atlas/features/studio_school/presentation/widgets/school_components.dart';
import 'package:look_atlas/services/service_providers.dart';
import 'package:look_atlas/shared/widgets/app_outlined_button.dart';

class SchoolHelperDismissalController extends Notifier<bool> {
  String? _userId;

  @override
  bool build() {
    _userId = ref.watch(authStateProvider).value?.id;
    final userId = _userId;
    if (userId == null) return true;
    try {
      return ref.read(keyValueStoreProvider).getBool(_key(userId)) ?? false;
    } on Object {
      return true;
    }
  }

  Future<void> dismiss() async {
    final userId = _userId;
    if (userId == null || state) return;
    state = true;
    try {
      await ref.read(keyValueStoreProvider).setBool(_key(userId), value: true);
    } on Object {
      return;
    }
    unawaited(
      ref.read(analyticsServiceProvider).track('welcome.school_dismissed'),
    );
  }

  String _key(String userId) => 'la_welcome_school_dismissed:$userId';
}

final NotifierProvider<SchoolHelperDismissalController, bool>
schoolHelperDismissalProvider =
    NotifierProvider.autoDispose<SchoolHelperDismissalController, bool>(
      SchoolHelperDismissalController.new,
    );

class SchoolDashboardHelper extends ConsumerWidget {
  const SchoolDashboardHelper({super.key});

  static bool isVisible(WidgetRef ref) {
    final dismissed = ref.watch(schoolHelperDismissalProvider);
    final school = ref.watch(studioSchoolControllerProvider);
    return school is SchoolReady &&
        school.welcome.eligible &&
        school.welcome.lessonsRewardClaimedAt == null &&
        !dismissed;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isVisible(ref)) return const SizedBox.shrink();

    return Container(
      key: const ValueKey('studio-school-dashboard-helper'),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SchoolSquareIcon(
                icon: Icons.school_outlined,
                size: 44,
                inverted: false,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'New to Look Atlas? Start at Studio School.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Two-minute lessons on credits, directors, fixes and '
                      'your image rights. Finish them all for 20 free credits.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.neutral500,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Padding(
            padding: const EdgeInsets.only(left: 58),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: AppOutlinedButton(
                    label: 'Open Studio School',
                    height: 40,
                    onPressed: () => context.push(
                      '${AppRoutes.studioSchool}?source=dashboard',
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                IconButton(
                  tooltip: 'Dismiss Studio School suggestion',
                  onPressed: () => unawaited(
                    ref.read(schoolHelperDismissalProvider.notifier).dismiss(),
                  ),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
