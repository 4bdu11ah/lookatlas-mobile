import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_components.dart';

class CalendarLoadingScreen extends ConsumerWidget {
  const CalendarLoadingScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      calendarControllerProvider.select(
        (state) => (state.loading, state.error),
      ),
    );
    final session = ref.read(calendarControllerProvider.notifier).session;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 90),
        child: Column(
          children: [
            calendarBody(
              state.$1
                  ? 'Loading your calendar…'
                  : state.$2 ?? 'Your calendar could not be loaded.',
            ),
            if (!state.$1) calendarButton('Try again', session.refresh),
          ],
        ),
      ),
    );
  }
}
