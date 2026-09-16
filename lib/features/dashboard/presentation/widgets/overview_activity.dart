import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:look_atlas/features/dashboard/presentation/controllers/dashboard_overview_controller.dart';
import 'package:look_atlas/features/dashboard/presentation/controllers/retention_countdown_controller.dart';
import 'package:look_atlas/features/dashboard/presentation/widgets/overview_style.dart';
import 'package:look_atlas/shared/widgets/bar_spinner.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class OverviewActivity extends ConsumerWidget {
  const OverviewActivity({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(
      dashboardOverviewControllerProvider.select(
        (state) => state.value?.overview,
      ),
    );
    final activity = data?.activity;
    final error = data?.panelStatus.activityError ?? false;
    final isEmpty =
        !error &&
        activity != null &&
        activity.ready.isEmpty &&
        activity.active.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OverviewSectionHeading(
          index: '01',
          label: 'Studio activity',
          title: 'What’s happening now.',
        ),
        const SizedBox(height: 14),
        if (isEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: OverviewLink(
              'Start a shoot',
              onTap: () => context.push(AppRoutes.createShoot),
            ),
          )
        else
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: OverviewStyle.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: OverviewStyle.line),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const OverviewLabel('Needs attention'),
                            const SizedBox(height: 4),
                            Text(
                              error || activity == null
                                  ? '—'
                                  : activity.attentionLabel,
                              style: OverviewStyle.serif(32, height: 1),
                            ),
                          ],
                        ),
                      ),
                      OverviewLink(
                        'View all',
                        onTap: () => context.push(AppRoutes.dashboardShoots),
                      ),
                    ],
                  ),
                ),
                if (error)
                  OverviewPanelState(
                    title: 'Shoot activity is temporarily unavailable.',
                    body: 'Your shoots are still running. Reload this panel to check their latest state.',
                    error: true,
                    action: OverviewLink(
                      'Try again',
                      onTap: () => ref
                          .read(dashboardOverviewControllerProvider.notifier)
                          .refresh(),
                    ),
                  )
                else if (activity == null)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: BarSpinner()),
                  )
                else ...[
                  for (final job in activity.ready)
                    _ActivityRow(job: job, ready: true),
                  for (final job in activity.active)
                    _ActivityRow(job: job, ready: false),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _ActivityRow extends ConsumerWidget {
  const _ActivityRow({required this.job, required this.ready});
  final DashboardRecentJob job;
  final bool ready;

  @override
  Widget build(BuildContext context, WidgetRef ref) => InkWell(
    key: ValueKey('dashboard-activity-${job.id}'),
    onTap: () =>
        context.push(AppRoutes.shootDetail(job.id, fromDashboard: true)),
    child: Container(
      constraints: const BoxConstraints(minHeight: 86),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: ready ? OverviewStyle.soft.withValues(alpha: .7) : null,
        border: Border(
          left: BorderSide(
            width: ready ? 2 : 0,
            color: ready ? OverviewStyle.ink : Colors.transparent,
          ),
          bottom: const BorderSide(color: OverviewStyle.line),
        ),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 58,
            child: OverviewImage(job.productThumbnail, label: job.name),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OverviewStyle.body(
                    13,
                    color: OverviewStyle.ink,
                    bold: true,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                if (ready)
                  const _ReadyStatus()
                else
                  _LiveStatus(step: job.currentStep),
                const SizedBox(height: 4),
                Text(
                  ready
                      ? '${job.renders} final images • Completed ${overviewDate(job.completedAt)}'
                      : '${job.progress}% complete${job.updatedAt == null ? '' : ' • Updated ${overviewUpdated(job.updatedAt!, ref.read(dashboardClockProvider)())}'}',
                  style: OverviewStyle.body(11, height: 1.2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (ready)
            OverviewLink(
              'Review',
              size: 10.5,
              underline: true,
              onTap: () => context.push(
                AppRoutes.shootDetail(job.id, fromDashboard: true),
              ),
            )
          else
            const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: OverviewStyle.muted,
            ),
        ],
      ),
    ),
  );
}

class _ReadyStatus extends StatelessWidget {
  const _ReadyStatus();
  @override
  Widget build(BuildContext context) => Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 6,
    children: [
      Container(
        color: OverviewStyle.ink,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          'NEW',
          style: OverviewStyle.body(
            8,
            color: OverviewStyle.paper,
            bold: true,
            height: 1.2,
          ).copyWith(letterSpacing: .64),
        ),
      ),
      Text(
        'Ready to review',
        style: OverviewStyle.body(
          10,
          height: 1.2,
          color: OverviewStyle.ink,
          bold: true,
        ),
      ),
    ],
  );
}

class _LiveStatus extends StatelessWidget {
  const _LiveStatus({this.step});
  final String? step;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const OverviewLiveDot(),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          step == null
              ? 'Generating'
              : step!.startsWith('Generating')
              ? step!
              : 'Generating ($step)',
          style: OverviewStyle.body(
            10,
            height: 1.2,
            color: OverviewStyle.live,
            bold: true,
          ),
        ),
      ),
    ],
  );
}

class OverviewLiveDot extends StatefulWidget {
  const OverviewLiveDot({super.key});
  @override
  State<OverviewLiveDot> createState() => _OverviewLiveDotState();
}

class _OverviewLiveDotState extends State<OverviewLiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1550),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: const SizedBox.square(
      dimension: 6,
      child: ColoredBox(color: OverviewStyle.live),
    ),
    builder: (context, child) {
      final pulse = Curves.easeInOut.transform(
        _controller.value < .5
            ? _controller.value * 2
            : (1 - _controller.value) * 2,
      );
      return Opacity(
        opacity: .45 + .55 * pulse,
        child: Transform.scale(scale: .9 + .2 * pulse, child: child),
      );
    },
  );
}

String overviewDate(DateTime? date) =>
    date == null ? 'just now' : DateFormat.MMMd().format(date.toLocal());

String overviewUpdated(DateTime date, DateTime now) {
  final elapsed = now.difference(date);
  if (elapsed.inMinutes < 1) return 'just now';
  if (elapsed.inHours < 1) return '${elapsed.inMinutes}m ago';
  if (elapsed.inDays < 1) return '${elapsed.inHours}h ago';
  return overviewDate(date);
}
