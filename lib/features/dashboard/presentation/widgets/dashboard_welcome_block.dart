import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/auth/presentation/auth_controller.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_welcome.dart';
import 'package:look_atlas/features/dashboard/presentation/controllers/dashboard_campaign_controller.dart';
import 'package:look_atlas/features/dashboard/presentation/controllers/dashboard_welcome_controller.dart';
import 'package:look_atlas/features/dashboard/presentation/widgets/campaign_flip_card.dart';
import 'package:look_atlas/features/dashboard/presentation/widgets/dashboard_step_guide.dart';
import 'package:look_atlas/features/dashboard/presentation/widgets/studio_scene_animation.dart';
import 'package:look_atlas/features/studio_school/presentation/studio_school_controller.dart';
import 'package:look_atlas/features/studio_school/presentation/studio_school_state.dart';
import 'package:look_atlas/features/studio_school/presentation/widgets/school_components.dart';
import 'package:look_atlas/services/service_providers.dart';
import 'package:look_atlas/shared/widgets/app_bottom_sheet.dart';
import 'package:look_atlas/shared/widgets/app_image.dart';
import 'package:look_atlas/shared/widgets/app_outlined_button.dart';
import 'package:look_atlas/shared/widgets/app_snack_bar.dart';
import 'package:look_atlas/shared/widgets/primary_button.dart';

part 'dashboard_welcome_hero.dart';
part 'dashboard_welcome_helpers.dart';

class DashboardWelcomeBlock extends ConsumerWidget {
  const DashboardWelcomeBlock({
    required this.subscription,
    required this.focusJob,
    super.key,
  });

  final DashboardSubscription subscription;
  final DashboardRecentJob? focusJob;

  static bool isVisible(
    WidgetRef ref, {
    required DashboardSubscription subscription,
    required DashboardRecentJob? focusJob,
  }) {
    if (subscription.accessTier == 'onetime_download' && focusJob != null) {
      return true;
    }
    if (subscription.accessTier != 'subscriber') return false;
    final school = ref.watch(studioSchoolControllerProvider);
    final welcome = switch (school) {
      SchoolReady(:final welcome) ||
      SchoolOfflineCached(:final welcome) => welcome.dashboard,
      _ => null,
    };
    if (welcome == null) return false;
    final preferences = ref.watch(dashboardWelcomeControllerProvider);
    final flipDismissed = welcome.flipDismissed || preferences.flipDismissed;
    final campaignVisible =
        welcome.checklistComplete && welcome.campaign != null && !flipDismissed;
    final studioVisible =
        welcome.checklistRewardClaimedAt == null ||
        (welcome.campaign != null && !flipDismissed);
    final consultVisible =
        !welcome.checklistComplete &&
        !preferences.consultDismissed &&
        !(welcome.callBooked || preferences.callBooked);
    return studioVisible || campaignVisible || consultVisible;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (subscription.accessTier == 'onetime_download' && focusJob != null) {
      return _OneTimeHero(
        job: focusJob!,
        offerActive: subscription.proUpsellActive,
        offerExpiresAt: subscription.proUpsellExpiresAt,
      );
    }
    if (subscription.accessTier != 'subscriber') return const SizedBox.shrink();
    final school = ref.watch(studioSchoolControllerProvider);
    final welcome = switch (school) {
      SchoolReady(:final welcome) ||
      SchoolOfflineCached(:final welcome) => welcome.dashboard,
      _ => null,
    };
    if (welcome == null) return const SizedBox.shrink();
    final preferences = ref.watch(dashboardWelcomeControllerProvider);
    final controller = ref.read(dashboardWelcomeControllerProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(controller.markSeen());
      controller.syncRescue(welcome);
    });
    final callBooked = welcome.callBooked || preferences.callBooked;
    final flipDismissed = welcome.flipDismissed || preferences.flipDismissed;
    final userId = ref.watch(authStateProvider).value?.id;
    final campaignVisible =
        welcome.checklistComplete && welcome.campaign != null && !flipDismissed;
    final studioRetired =
        welcome.checklistRewardClaimedAt != null &&
        (welcome.campaign == null || flipDismissed);
    final studioVisible = !studioRetired && !campaignVisible;
    final consultVisible =
        !welcome.checklistComplete &&
        !preferences.consultDismissed &&
        !callBooked;
    if (!studioVisible && !campaignVisible && !consultVisible) {
      return const SizedBox.shrink();
    }
    if (campaignVisible && userId == null) return const SizedBox.shrink();
    return Column(
      key: const ValueKey('dashboard-welcome-block'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (campaignVisible)
          _CampaignHero(
            welcome: welcome,
            showRescue: preferences.showRescue,
            userId: userId!,
          )
        else if (studioVisible && preferences.collapsed)
          _CollapsedSetup(
            completed: welcome.completedCount,
            onExpand: controller.expand,
          )
        else if (studioVisible)
          _StudioSetupHero(welcome: welcome),
        if ((studioVisible || campaignVisible) && consultVisible)
          const SizedBox(height: 16),
        if (consultVisible) _ConsultHelper(showRescue: preferences.showRescue),
      ],
    );
  }
}

class _CollapsedSetup extends StatelessWidget {
  const _CollapsedSetup({required this.completed, required this.onExpand});

  final int completed;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Expand studio setup, $completed of 6 complete',
      child: InkWell(
        key: const ValueKey('dashboard-welcome-collapsed'),
        onTap: onExpand,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: AppColors.black,
          child: Row(
            children: [
              Row(
                children: List.generate(
                  6,
                  (index) => Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 4),
                    color: index < completed
                        ? AppColors.white
                        : AppColors.whiteAlpha25,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Studio setup: $completed of 6',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, color: AppColors.white),
            ],
          ),
        ),
      ),
    );
  }
}
