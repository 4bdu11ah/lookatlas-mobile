import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_session.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_channels.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_components.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_setup_controls.dart';

class CalendarSetupChannels extends ConsumerWidget {
  const CalendarSetupChannels({required this.s, super.key});
  final CalendarSession s;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
      calendarControllerProvider.select(
        (state) => state.setup.platforms.join(','),
      ),
    );
    final controller = ref.read(calendarControllerProvider.notifier);
    final d = s.setup;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        calendarStep('03', 'Channels', 'Where should these posts go?', [
          calendarChannelChoices(
            d.platforms,
            (p) => controller.changeSetup(() {
              d.platforms.contains(p)
                  ? d.platforms.remove(p)
                  : d.platforms.add(p);
            }),
          ),
          const SizedBox(height: 13),
          calendarBody(
            'You don’t need to connect any account to plan. We’ll ask when it’s time to publish, until then you can download everything.',
          ),
        ]),
      ],
    );
  }
}
