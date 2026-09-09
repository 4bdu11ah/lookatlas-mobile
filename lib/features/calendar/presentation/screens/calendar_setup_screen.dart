import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_session.dart';
import 'package:look_atlas/features/calendar/presentation/models/calendar_actions.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_campaign.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_channels.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_components.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_product_priorities.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_setup_cadence.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_setup_channels.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_setup_estimate.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_setup_goal.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_setup_mode.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CalendarSetupScreen extends ConsumerWidget {
  const CalendarSetupScreen({required this.view, super.key});
  final CalendarViewData view;
  CalendarSession get s => view.session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
      calendarControllerProvider.select(
        (state) => (
          state.overview?.productCount,
          state.overview?.plan?.status,
          state.setupOverride,
        ),
      ),
    );
    final controller = ref.read(calendarControllerProvider.notifier);
    final o = s.overview!;
    if (o.productCount == 0) {
      return SliverToBoxAdapter(
        child: Column(
          children: [
            calendarHeading(
              '30-day content plan',
              'First, add a product.',
              'Your month is planned from your real product library. Add at least one product with photos and we’ll take it from there.',
            ),
            const SizedBox(height: 27),
            calendarButton(
              'Add your first product',
              () => context.push<void>(AppRoutes.dashboardProducts),
              primary: true,
              icon: LucideIcons.arrowRight,
            ),
          ],
        ),
      );
    }
    return calendarLazySections([
      calendarHeading(
        'Content runway',
        'Plan your posts.',
        'Tell us your goal and how you want to work, a scheduled plan, or a batch you place yourself. You approve everything before we create it.',
        actions: [
          if (s.setupOverride && o.plan?.status == 'plan_ready')
            calendarButton(
              'Back to the plan',
              () => controller.changeSetup(() => s.setupOverride = false),
            ),
        ],
      ),
      if (o.plan?.status == 'plan_failed')
        calendarErrorBanner(
          calendarError(o.plan!.json['errorCode'] as String?),
        ),
      const SizedBox(height: 48),
      calendarSetupWidth(
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: CALENDAR_LINE),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CalendarSetupMode(s: s),
              CalendarSetupGoal(s: s),
              CalendarSetupCadence(s: s),
              CalendarSetupChannels(s: s),
              CalendarProductPriorities(s: s),
              CalendarSetupEstimate(s: s),
            ],
          ),
        ),
      ),
      const SizedBox(height: 18),
      calendarSetupWidth(CalendarCampaign(s: s)),
    ]);
  }
}
