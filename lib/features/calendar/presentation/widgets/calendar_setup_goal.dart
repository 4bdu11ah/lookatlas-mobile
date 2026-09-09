import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_session.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_view_controller.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_setup_controls.dart';

class CalendarSetupGoal extends ConsumerWidget {
  const CalendarSetupGoal({required this.s, super.key});
  final CalendarSession s;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
      calendarControllerProvider.select((state) => state.setup.objective),
    );
    final local = ref.read(calendarViewProvider.notifier);
    final controller = ref.read(calendarControllerProvider.notifier);
    void setupChange(VoidCallback change) =>
        controller.changeSetup(change, requote: true);
    final d = s.setup;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        calendarStep('01', 'Your goal', 'What do you want to achieve?', [
          for (final goal in calendarObjectives)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: calendarChoice(
                goal,
                () => setupChange(() {
                  d.objective = goal;
                  if (goal == 'Launch a product') {
                    local.setProductsOpen(value: true);
                  }
                }),
                selected: d.objective == goal,
              ),
            ),
        ]),
      ],
    );
  }
}
