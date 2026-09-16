import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/providers/core_providers.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/dashboard/presentation/widgets/overview_helper_card.dart';
import 'package:look_atlas/features/studio_school/presentation/controllers/studio_school_controller.dart';
import 'package:look_atlas/features/studio_school/presentation/controllers/studio_school_state.dart';
import 'package:look_atlas/services/service_providers.dart';

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

    return OverviewHelperCard(
      key: const ValueKey('studio-school-dashboard-helper'),
      content: (
        label: 'Learning Center',
        title: 'New to Look Atlas? Start at Studio School.',
        body: 'Two-minute lessons on credits, directors, fixes and your image rights. Finish them all for 20 free credits.',
        photo: 'assets/images/dashboard/studio_school.jpg',
        action: 'Open Studio School →',
      ),
      dismissTooltip: 'Dismiss Studio School suggestion',
      onDismiss: () =>
          unawaited(ref.read(schoolHelperDismissalProvider.notifier).dismiss()),
      onOpen: () => context.push('${AppRoutes.studioSchool}?source=dashboard'),
    );
  }
}
