import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_session.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_tray_controller.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_components.dart';

class CalendarTraySchedule extends ConsumerWidget {
  const CalendarTraySchedule({
    required this.item,
    required this.session,
    super.key,
  });
  final CalendarItem item;
  final CalendarSession session;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calendarTrayProvider(item.id));
    final controller = ref.read(calendarTrayProvider(item.id).notifier);
    final busy = ref.watch(
      calendarControllerProvider.select(
        (state) => state.busy.contains(item.id),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        calendarFieldWidget(
          'Posting time',
          controller.time,
          onChanged: controller.setInput,
        ),
        if (state.error != null) calendarErrorBanner(state.error!),
        const SizedBox(height: 8),
        calendarButton(
          'Schedule',
          state.input.isEmpty || busy ? null : controller.schedule,
          compact: true,
          primary: true,
        ),
      ],
    );
  }
}
