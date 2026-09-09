import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_session.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_components.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_setup_controls.dart';

class CalendarSetupCadence extends ConsumerWidget {
  const CalendarSetupCadence({required this.s, super.key});
  final CalendarSession s;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
      calendarControllerProvider.select(
        (state) => (
          state.setup.mode,
          state.setup.cadence,
          state.setup.horizonDays,
          state.setup.batchCount,
        ),
      ),
    );
    final controller = ref.read(calendarControllerProvider.notifier);
    void setupChange(VoidCallback change) =>
        controller.changeSetup(change, requote: true);
    final d = s.setup;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (d.mode == 'scheduled')
          calendarStep(
            '02',
            'Posting pace',
            'How far ahead, and how often?',
            [
              Row(
                children: [
                  for (final e in {
                    7: '1 week',
                    14: '2 weeks',
                    30: '30 days',
                  }.entries)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: calendarChoice(
                          e.value,
                          () => setupChange(() => d.horizonDays = e.key),
                          selected: d.horizonDays == e.key,
                          height: 40,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 21),
              for (final c in calendarCadences.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: calendarChoice(
                    c.value,
                    () => setupChange(() => d.cadence = c.key),
                    selected: d.cadence == c.key,
                    help: c.key == '5_per_week' ? 'Recommended' : null,
                  ),
                ),
            ],
          )
        else
          calendarStep(
            '02',
            'How many',
            'How many posts should we concept?',
            [
              for (final count in [5, 10, 15, 20])
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: calendarChoice(
                    '$count posts',
                    () => setupChange(() => d.batchCount = count),
                    selected: d.batchCount == count,
                  ),
                ),
              calendarBody(
                'You’ll see every concept first and only pay for the ones you choose to create.',
              ),
            ],
          ),
      ],
    );
  }
}
