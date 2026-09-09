import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_components.dart';

class CalendarMessages extends ConsumerWidget {
  const CalendarMessages({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(
      calendarControllerProvider.select(
        (state) => (
          state.actionError,
          state.notice,
          state.overview != null,
          state.error,
        ),
      ),
    );
    final session = ref.read(calendarControllerProvider.notifier).session;
    return SliverToBoxAdapter(
      child: Column(
        children: [
          if (data.$1 != null)
            calendarErrorBanner(data.$1!, session.dismissError),
          if (data.$2 != null) calendarNote(data.$2!),
          if (data.$3 && data.$4 != null)
            calendarErrorBanner(data.$4!, session.refresh),
        ],
      ),
    );
  }
}
