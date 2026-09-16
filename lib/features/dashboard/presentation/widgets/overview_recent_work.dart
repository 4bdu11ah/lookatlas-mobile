import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/features/dashboard/presentation/controllers/dashboard_overview_controller.dart';
import 'package:look_atlas/features/dashboard/presentation/widgets/overview_activity.dart';
import 'package:look_atlas/features/dashboard/presentation/widgets/overview_style.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class OverviewRecentWork extends ConsumerWidget {
  const OverviewRecentWork({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(
      dashboardOverviewControllerProvider.select(
        (state) => state.value?.overview,
      ),
    );
    final jobs = data?.activity.recentCompleted ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OverviewSectionHeading(
          index: '02',
          label: 'Recent work',
          title: 'From the studio floor.',
          action: OverviewLink(
            'All shoots',
            onTap: () =>
                context.push('${AppRoutes.dashboardShoots}?bucket=archive'),
          ),
        ),
        const SizedBox(height: 14),
        if (jobs.isEmpty)
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: OverviewStyle.line),
            ),
            child: const OverviewPanelState(
              title: 'Your first collection will live here.',
              body: 'Reviewed shoots become a visual archive you can return to at any time.',
              serif: true,
            ),
          )
        else
          for (var index = 0; index < jobs.length; index++) ...[
            if (index > 0) const SizedBox(height: 16),
            InkWell(
              key: ValueKey('dashboard-recent-${jobs[index].id}'),
              onTap: () => context.push(
                AppRoutes.shootDetail(jobs[index].id, fromDashboard: true),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: OverviewStyle.line),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          OverviewImage(
                            jobs[index].heroImage.isEmpty
                                ? jobs[index].productThumbnail
                                : jobs[index].heroImage,
                            label: jobs[index].name,
                          ),
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              color: OverviewStyle.ink,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              child: Text(
                                (index + 1).toString().padLeft(2, '0'),
                                style: OverviewStyle.serif(
                                  11,
                                  italic: true,
                                  color: OverviewStyle.paper,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              jobs[index].name,
                              style: OverviewStyle.body(
                                13,
                                color: OverviewStyle.ink,
                                bold: true,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${jobs[index].renders} final images • ${overviewDate(jobs[index].completedAt)}',
                              style: OverviewStyle.body(11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        LucideIcons.arrowRight,
                        size: 15,
                        color: OverviewStyle.ink,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
      ],
    );
  }
}
