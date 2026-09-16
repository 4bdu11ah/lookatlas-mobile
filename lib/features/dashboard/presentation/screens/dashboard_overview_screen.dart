import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_overview.dart';
import 'package:look_atlas/features/dashboard/presentation/controllers/dashboard_overview_controller.dart';
import 'package:look_atlas/features/dashboard/presentation/controllers/dashboard_welcome_controller.dart';
import 'package:look_atlas/features/dashboard/presentation/models/dashboard_page.dart';
import 'package:look_atlas/features/dashboard/presentation/widgets/dashboard_welcome_block.dart';
import 'package:look_atlas/features/dashboard/presentation/widgets/overview_activity.dart';
import 'package:look_atlas/features/dashboard/presentation/widgets/overview_collection.dart';
import 'package:look_atlas/features/dashboard/presentation/widgets/overview_recent_work.dart';
import 'package:look_atlas/features/dashboard/presentation/widgets/overview_rooms.dart';
import 'package:look_atlas/features/dashboard/presentation/widgets/overview_style.dart';
import 'package:look_atlas/features/studio_school/di/studio_school_providers.dart';
import 'package:look_atlas/features/studio_school/presentation/widgets/school_dashboard_helper.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DashboardOverviewScreen extends ConsumerWidget {
  const DashboardOverviewScreen({required this.onNavigate, super.key});
  final ValueChanged<DashboardPage> onNavigate;

  static const _sections = <Widget>[
    _OverviewGuidance(),
    _OverviewStaleWarning(),
    _OverviewPageHeader(),
    OverviewActivity(),
    OverviewRecentWork(),
    OverviewBrandRoom(),
    OverviewCollection(),
    OverviewCreativeRooms(),
    OverviewLearningStrip(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failed = ref.watch(
      dashboardOverviewControllerProvider.select(
        (state) =>
            state.hasError ||
            (state.value?.overview == null && state.value?.failure != null),
      ),
    );
    return CustomScrollView(
      key: const ValueKey('dashboard-overview-scroll'),
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          sliver: failed
              ? const SliverToBoxAdapter(child: _OverviewLoadError())
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        index >= 3 && index < _sections.length - 1
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: _sections[index],
                          )
                        : _sections[index],
                    childCount: _sections.length,
                  ),
                ),
        ),
      ],
    );
  }
}

class _OverviewGuidance extends ConsumerStatefulWidget {
  const _OverviewGuidance();
  @override
  ConsumerState<_OverviewGuidance> createState() => _OverviewGuidanceState();
}

class _OverviewGuidanceState extends ConsumerState<_OverviewGuidance>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final guidance = ref.watch(
      dashboardOverviewControllerProvider.select(
        (state) => (
          subscription: state.value?.subscription,
          ownedShoot: state.value?.overview?.ownedShoot,
        ),
      ),
    );
    final subscription = guidance.subscription;
    if (subscription == null) return const SizedBox.shrink();
    final welcome = ref.watch(studioSchoolWelcomeProvider)?.dashboard;
    if (subscription.accessTier == 'subscriber' &&
        welcome != null &&
        ref
            .read(dashboardWelcomeControllerProvider.notifier)
            .shouldOpenIntro(welcome)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(AppRoutes.welcome);
      });
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (subscription.needsPaymentUpdate)
          const _OverviewAlert(
            text: 'Your subscription payment needs attention. Update your payment method in Billing.',
            error: true,
          )
        else if (subscription.cancelAtPeriodEnd)
          const _OverviewAlert(
            text: 'Your subscription is set to end after this billing period. You can manage your plan in Billing.',
            warn: true,
          )
        else if (subscription.accessTier == 'onetime_download' &&
            subscription.proUpsellActive)
          const _OverviewAlert(
            text: 'Your limited-time Pro offer is available in Billing.',
          ),
        if (DashboardWelcomeBlock.isVisible(
          ref,
          subscription: subscription,
          focusJob: guidance.ownedShoot,
        ))
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: DashboardWelcomeBlock(
              subscription: subscription,
              focusJob: guidance.ownedShoot,
            ),
          ),
        if (subscription.accessTier == 'subscriber' &&
            SchoolDashboardHelper.isVisible(ref))
          const Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: SchoolDashboardHelper(),
          ),
      ],
    );
  }
}

class _OverviewAlert extends StatelessWidget {
  const _OverviewAlert({
    required this.text,
    this.error = false,
    this.warn = false,
  });
  final String text;
  final bool error;
  final bool warn;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.push(AppRoutes.dashboardBilling),
    child: Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: error
            ? const Color(0xFFFDF2F2)
            : warn
            ? const Color(0xFFFFFBEB)
            : OverviewStyle.soft,
        border: Border.all(
          color: error
              ? const Color(0xFFF87171)
              : warn
              ? const Color(0xFFFCD34D)
              : OverviewStyle.line,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            error
                ? LucideIcons.circleAlert
                : warn
                ? Icons.warning_amber
                : Icons.info_outline,
            size: 16,
            color: error
                ? const Color(0xFF991B1B)
                : warn
                ? const Color(0xFF92400E)
                : OverviewStyle.ink,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: OverviewStyle.body(
                11.5,
                height: 1.4,
                color: error
                    ? const Color(0xFF991B1B)
                    : warn
                    ? const Color(0xFF92400E)
                    : OverviewStyle.ink,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _OverviewStaleWarning extends ConsumerWidget {
  const _OverviewStaleWarning();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stale = ref.watch(
      dashboardOverviewControllerProvider.select(
        (state) => state.value?.isStale ?? false,
      ),
    );
    if (!stale) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(border: Border.all(color: OverviewStyle.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Some dashboard information may be out of date. Network latency detected.',
            style: OverviewStyle.body(11),
          ),
          const SizedBox(height: 6),
          OverviewLink(
            'Reload',
            onTap: () => ref
                .read(dashboardOverviewControllerProvider.notifier)
                .refresh(),
          ),
        ],
      ),
    );
  }
}

class _OverviewPageHeader extends ConsumerWidget {
  const _OverviewPageHeader();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activation = ref.watch(
      dashboardOverviewControllerProvider.select(
        (state) => state.value?.overview?.activation,
      ),
    );
    final config = activation ?? const DashboardActivation();
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OverviewLabel('Workspace overview'),
          const SizedBox(height: 4),
          Text(
            'Overview',
            style: OverviewStyle.serif(44, height: .98, spacing: -1.54),
          ),
          const SizedBox(height: 8),
          Text(config.intro, style: OverviewStyle.body(13, height: 1.6)),
          const SizedBox(height: 16),
          OverviewButton(
            config.actionLabel,
            icon: switch (config.stage) {
              DashboardActivationStage.setup => LucideIcons.package,
              DashboardActivationStage.generating => LucideIcons.camera,
              DashboardActivationStage.ready => LucideIcons.arrowRight,
              DashboardActivationStage.active => LucideIcons.plus,
            },
            onPressed: activation == null
                ? null
                : () => unawaited(
                    context.push<void>(switch (config.stage) {
                      DashboardActivationStage.setup =>
                        '${AppRoutes.dashboardProducts}?create=1',
                      DashboardActivationStage.generating ||
                      DashboardActivationStage.ready =>
                        config.firstShootId == null
                            ? AppRoutes.dashboardShoots
                            : AppRoutes.shootDetail(
                                config.firstShootId!,
                                fromDashboard: true,
                              ),
                      DashboardActivationStage.active => AppRoutes.createShoot,
                    }),
                  ),
          ),
        ],
      ),
    );
  }
}

class _OverviewLoadError extends ConsumerWidget {
  const _OverviewLoadError();
  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    decoration: BoxDecoration(border: Border.all(color: OverviewStyle.line)),
    child: OverviewPanelState(
      title: 'Your workspace did not load.',
      serif: true,
      error: true,
      body: 'We could not load your workspace overview due to a temporary network issue.',
      action: OverviewButton(
        'Try again',
        onPressed: () =>
            ref.read(dashboardOverviewControllerProvider.notifier).refresh(),
      ),
    ),
  );
}
