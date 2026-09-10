import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:look_atlas/features/dashboard/presentation/controllers/dashboard_overview_controller.dart';
import 'package:look_atlas/features/dashboard/presentation/controllers/dashboard_welcome_controller.dart';
import 'package:look_atlas/features/dashboard/presentation/models/dashboard_page.dart';
import 'package:look_atlas/features/dashboard/presentation/widgets/dashboard_welcome_block.dart';
import 'package:look_atlas/features/shoots/presentation/shoots_feature.dart';
import 'package:look_atlas/features/studio_school/di/studio_school_providers.dart';
import 'package:look_atlas/features/studio_school/presentation/widgets/school_dashboard_helper.dart';
import 'package:look_atlas/shared/widgets/app_card.dart';
import 'package:look_atlas/shared/widgets/app_feedback.dart';
import 'package:look_atlas/shared/widgets/app_hairline.dart';
import 'package:look_atlas/shared/widgets/app_media_widgets.dart';
import 'package:look_atlas/shared/widgets/app_outlined_button.dart';
import 'package:look_atlas/shared/widgets/app_spaced_column.dart';
import 'package:look_atlas/shared/widgets/app_text.dart';
import 'package:look_atlas/shared/widgets/bar_spinner.dart';
import 'package:look_atlas/shared/widgets/shimmer_box.dart';

part '../widgets/dashboard_quick_actions.dart';

class DashboardOverviewScreen extends ConsumerWidget {
  const DashboardOverviewScreen({
    required this.onNavigate,
    super.key,
  });

  final ValueChanged<DashboardPage> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardOverviewControllerProvider);
    final welcome = ref.watch(studioSchoolWelcomeProvider)?.dashboard;
    final shouldOpenIntro = switch (state) {
      AsyncData(:final value)
          when value.subscription?.accessTier == 'subscriber' &&
              welcome != null =>
        ref
            .read(dashboardWelcomeControllerProvider.notifier)
            .shouldOpenIntro(welcome),
      _ => false,
    };
    if (shouldOpenIntro) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(AppRoutes.welcome);
      });
    }
    return AppSpacedColumn(
      gap: 32,
      children: [
        const AppPageHeader(
          title: 'Dashboard',
          body: "Welcome back! Here's your Look Atlas overview.",
        ),
        switch (state) {
          AsyncData(:final value) => _DashboardOverviewContent(
            state: value,
            onNavigate: onNavigate,
            onOpenShoot: (shoot) => unawaited(
              context.push<void>(AppRoutes.shootDetail(shoot.id)),
            ),
          ),
          _ => const _DashboardOverviewContent(
            state: DashboardOverviewState(),
            onNavigate: _ignoreDashboardNavigation,
            onOpenShoot: _ignoreDashboardShoot,
          ),
        },
      ],
    );
  }
}

class _DashboardOverviewContent extends StatelessWidget {
  const _DashboardOverviewContent({
    required this.state,
    required this.onNavigate,
    required this.onOpenShoot,
  });

  final DashboardOverviewState state;
  final ValueChanged<DashboardPage> onNavigate;
  final ValueChanged<ShootViewModel> onOpenShoot;

  @override
  Widget build(BuildContext context) {
    return AppSpacedColumn(
      gap: 32,
      children: [
        if (state.subscription?.needsPaymentUpdate ?? false)
          const AppAlert(
            kind: AppAlertKind.error,
            text: 'Your subscription payment needs attention.',
          )
        else if (state.subscription?.cancelAtPeriodEnd ?? false)
          const AppAlert(
            kind: AppAlertKind.warn,
            text: 'Your subscription is set to end after this billing period.',
          )
        else if (state.subscription?.accessTier == 'onetime_download' &&
            (state.subscription?.proUpsellActive ?? false))
          const AppAlert(
            kind: AppAlertKind.info,
            text: 'Your limited-time Pro offer is available in Billing.',
          ),
        _DashboardGuidanceAndStats(
          subscription: state.subscription,
          focusJob: state.recentJobs.firstOrNull,
          stats: state.stats,
        ),
        _RecentShoots(
          shoots: state.shoots,
          isLoading: state.isLoadingRecentJobs,
          onNavigate: onNavigate,
          onOpenShoot: onOpenShoot,
        ),
        _QuickActions(onNavigate: onNavigate),
      ],
    );
  }
}

class _DashboardGuidanceAndStats extends ConsumerWidget {
  const _DashboardGuidanceAndStats({
    required this.subscription,
    required this.focusJob,
    required this.stats,
  });

  final DashboardSubscription? subscription;
  final DashboardRecentJob? focusJob;
  final DashboardStats? stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppSpacedColumn(
    gap: 32,
    children: [
      if (subscription != null &&
          DashboardWelcomeBlock.isVisible(
            ref,
            subscription: subscription!,
            focusJob: focusJob,
          ))
        DashboardWelcomeBlock(
          subscription: subscription!,
          focusJob: focusJob,
        ),
      if (SchoolDashboardHelper.isVisible(ref)) const SchoolDashboardHelper(),
      if (stats case final stats?)
        _StatsList(stats: stats)
      else
        const _DashboardStatsLoading(),
    ],
  );
}

class _StatsList extends StatelessWidget {
  const _StatsList({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCard(Icons.trending_up, 'Credits Remaining', '${stats.credits}'),
      _StatCard(
        Icons.inventory_2_outlined,
        'Total Renders',
        '${stats.totalRenders}',
      ),
      _StatCard(Icons.schedule, 'Active Shoots', '${stats.activeJobs}'),
      _StatCard(
        Icons.check_circle_outline,
        'Completed Shoots',
        '${stats.completedJobs}',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cards.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _dashboardStatColumns(constraints.maxWidth),
          mainAxisExtent: 192,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemBuilder: (context, index) => cards[index],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => AppCard(
        padding: EdgeInsets.all(constraints.maxWidth < 140 ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            AppSquareIcon(icon),
            const SizedBox(height: 16),
            AppEyebrow(label, maxLines: 2),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                height: 1.1,
                fontWeight: AppTypography.bold,
                letterSpacing: -0.64,
                color: AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentShoots extends StatelessWidget {
  const _RecentShoots({
    required this.shoots,
    required this.isLoading,
    required this.onNavigate,
    required this.onOpenShoot,
  });

  final List<ShootViewModel> shoots;
  final bool isLoading;
  final ValueChanged<DashboardPage> onNavigate;
  final ValueChanged<ShootViewModel> onOpenShoot;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Expanded(child: AppSectionTitle('Recent Shoots')),
                const SizedBox(width: 12),
                AppOutlinedButton(
                  label: 'View all',
                  icon: Icons.arrow_forward,
                  iconAlignment: IconAlignment.end,
                  fitToContent: true,
                  onPressed: () => onNavigate(DashboardPage.jobs),
                ),
              ],
            ),
          ),
          const AppHairline(),
          if (isLoading && shoots.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: BarSpinner(),
            )
          else if (shoots.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: AppBodyText('No recent shoots yet.'),
            )
          else
            for (var i = 0; i < shoots.length; i++)
              ShootRow(
                shoot: shoots[i],
                striped: i.isOdd,
                onTap: () => onOpenShoot(shoots[i]),
              ),
        ],
      ),
    );
  }
}

class _DashboardStatsLoading extends StatelessWidget {
  const _DashboardStatsLoading();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => AppSpacedColumn(
        gap: 12,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _dashboardStatColumns(constraints.maxWidth),
              mainAxisExtent: 192,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemBuilder: (_, _) => const ShimmerBox(),
          ),
        ],
      ),
    );
  }
}

int _dashboardStatColumns(double width) => width >= 600 ? 3 : 2;

void _ignoreDashboardNavigation(DashboardPage _) {}

void _ignoreDashboardShoot(ShootViewModel _) {}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onNavigate});

  final ValueChanged<DashboardPage> onNavigate;

  @override
  Widget build(BuildContext context) {
    return AppSpacedColumn(
      gap: 12,
      children: [
        const AppSectionTitle('Quick Actions'),
        _ActionCard(
          icon: Icons.groups_outlined,
          title: 'Manage Models',
          body: 'Upload and manage house models for consistent photography.',
          subtitle: 'Go to Models',
          onTap: () => onNavigate(DashboardPage.models),
        ),
        _ActionCard(
          icon: Icons.inventory_2_outlined,
          title: 'Upload Products',
          body: 'Add products for AI-generated photo shoots.',
          subtitle: 'Manage Products',
          onTap: () => onNavigate(DashboardPage.products),
        ),
        _ActionCard(
          icon: Icons.auto_fix_high_outlined,
          title: 'Workshop',
          body: 'Edit a photo with a prompt, references, and AI.',
          subtitle: 'Open Workshop',
          onTap: () => onNavigate(DashboardPage.workshop),
        ),
        _ActionCard(
          icon: Icons.check_circle_outline,
          title: 'New Shoot',
          subtitle: 'Create Shoot',
          body: 'Generate new on-model product photos with AI.',
          onTap: () => unawaited(context.push<void>(AppRoutes.createShoot)),
        ),
      ],
    );
  }
}
