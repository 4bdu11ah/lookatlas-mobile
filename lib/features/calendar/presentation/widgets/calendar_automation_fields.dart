import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_drawer_controller.dart';
import 'package:look_atlas/features/calendar/presentation/models/calendar_drawer_state.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_components.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_drawer_body.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CalendarAutomationFields extends ConsumerWidget {
  const CalendarAutomationFields({required this.args, super.key});
  final CalendarDrawerArgs args;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calendarDrawerProvider(args));
    final controller = ref.read(calendarDrawerProvider(args).notifier);
    final s = args.view.session;

    final o = s.overview!;
    final automation = state.automation;
    final p = o.plan!;
    return CalendarDrawerBody(
      args: args,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(minHeight: 74),
          decoration: BoxDecoration(
            color: const Color(0xffedf1ed),
            border: Border.all(color: const Color(0xffc5d0c8)),
          ),
          child: Row(
            children: [
              const Icon(
                LucideIcons.shieldCheck,
                size: 20,
                color: Color(0xff426953),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.paused
                          ? 'Production is paused'
                          : automation == 'drafts'
                          ? 'Creating drafts only'
                          : automation == 'review'
                          ? 'Ask before posting'
                          : 'Auto-post approved content',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    calendarBody(
                      '${o.connections.where((c) => c['status'] == 'connected').length} accounts connected',
                      size: 10,
                    ),
                  ],
                ),
              ),
              calendarButton(
                p.paused ? 'Resume' : 'Pause',
                s.busy.contains('plan')
                    ? null
                    : () => s.updatePlan({'productionPaused': !p.paused}),
                compact: true,
              ),
            ],
          ),
        ),
        if (!o.publishingAvailable)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xfff7f1e5),
              border: Border(
                left: BorderSide(color: Color(0xffbd9552), width: 2),
              ),
            ),
            child: calendarBody(
              'Publishing connections aren’t open yet, so nothing can auto-post. Drafts only is the working mode today: approve a post and download it to publish yourself.',
              color: const Color(0xff624b26),
            ),
          ),
        const SizedBox(height: 28),
        calendarKicker('Choose one way of working'),
        const SizedBox(height: 10),
        for (final e in {
          'drafts': (
            'Create drafts only',
            'We make the content. You download or publish it yourself.',
          ),
          'review': (
            'Ask before posting',
            'Nothing is scheduled until you approve it; approved posts publish on time.',
          ),
          'auto': (
            'Auto-post approved content',
            'Finished posts go straight onto the schedule and publish on time.',
          ),
        }.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Opacity(
              opacity: e.key != 'drafts' && !o.publishingAvailable ? 0.45 : 1,
              child: InkWell(
                onTap: e.key != 'drafts' && !o.publishingAvailable
                    ? null
                    : () => controller.setAutomation(e.key),
                child: Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: automation == e.key ? Colors.white : CALENDAR_FIELD,
                    border: Border.all(
                      color: automation == e.key ? CALENDAR_INK : CALENDAR_LINE,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        automation == e.key
                            ? LucideIcons.circleDot
                            : LucideIcons.circle,
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.value.$1,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            calendarBody(
                              e.key != 'drafts' && !o.publishingAvailable
                                  ? 'Available once a publishing account can be connected.'
                                  : e.value.$2,
                              size: 11,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 21),
        calendarKicker('Connections'),
        for (final c in o.connections)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                calendarPlatformIcons([c['platform'] as String]),
                const SizedBox(width: 10),
                Expanded(
                  child: calendarBody(
                    '${calendarPlatforms[c['platform']]}\n${c['handle'] ?? c['status']}',
                    size: 11,
                  ),
                ),
                calendarButton(
                  c['status'] == 'connected'
                      ? 'Disconnect'
                      : c['available'] == true
                      ? 'Connect'
                      : 'Available soon',
                  s.busy.contains('connection:${c['platform']}') ||
                          c['available'] != true && c['status'] != 'connected'
                      ? null
                      : () => s.connection(
                          c['platform'] as String,
                          disconnect: c['status'] == 'connected',
                        ),
                  compact: true,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
