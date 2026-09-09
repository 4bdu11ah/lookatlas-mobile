import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:look_atlas/features/calendar/presentation/models/calendar_actions.dart';
import 'package:look_atlas/features/calendar/presentation/screens/calendar_loading_screen.dart';
import 'package:look_atlas/features/calendar/presentation/screens/calendar_operating_screen.dart';
import 'package:look_atlas/features/calendar/presentation/screens/calendar_plan_review_screen.dart';
import 'package:look_atlas/features/calendar/presentation/screens/calendar_setup_screen.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_messages.dart';

class CalendarBody extends ConsumerWidget {
  const CalendarBody({required this.view, super.key});
  final CalendarViewData view;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stage = ref.watch(
      calendarControllerProvider.select((state) => state.stage),
    );
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 58),
          sliver: SliverMainAxisGroup(
            slivers: [
              const CalendarMessages(),
              switch (stage) {
                'setup' => CalendarSetupScreen(view: view),
                'plan' => CalendarPlanReviewScreen(view: view),
                'operating' => CalendarOperatingScreen(view: view),
                _ => const CalendarLoadingScreen(),
              },
            ],
          ),
        ),
      ],
    );
  }
}
