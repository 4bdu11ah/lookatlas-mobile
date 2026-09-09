import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_session.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_setup_controls.dart';

class CalendarSetupMode extends ConsumerWidget {
  const CalendarSetupMode({required this.s, super.key});
  final CalendarSession s;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(calendarControllerProvider.select((state) => state.setup.mode));
    final controller = ref.read(calendarControllerProvider.notifier);
    void setupChange(VoidCallback change) =>
        controller.changeSetup(change, requote: true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        calendarStep(null, null, null, [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: calendarMode(
                  s,
                  (value) => setupChange(() => s.setup.mode = value),
                  'scheduled',
                  'A scheduled plan',
                  'We plan the days and post on time',
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: calendarMode(
                  s,
                  (value) => setupChange(() => s.setup.mode = value),
                  'batch',
                  'A batch of posts',
                  'You pick concepts and schedule them yourself',
                ),
              ),
            ],
          ),
        ]),
      ],
    );
  }
}
