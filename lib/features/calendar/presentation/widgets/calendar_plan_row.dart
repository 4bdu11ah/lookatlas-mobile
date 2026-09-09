import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_session.dart';
import 'package:look_atlas/features/calendar/presentation/models/calendar_actions.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_components.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CalendarPlanRow extends ConsumerWidget {
  const CalendarPlanRow({
    required this.view,
    required this.item,
    required this.batch,
    super.key,
  });
  final CalendarViewData view;
  final CalendarItem item;
  final bool batch;
  CalendarSession get s => view.session;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i = item;
    ref.watch(
      calendarControllerProvider.select(
        (state) => (state.busy.contains(i.id), state.picked.contains(i.id)),
      ),
    );
    final skipped = i.status == 'skipped';
    final busy = s.busy.contains(i.id) || s.revising;
    return Opacity(
      opacity: skipped || (batch && !s.picked.contains(i.id)) ? 0.45 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: CALENDAR_LINE)),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (batch)
                  SizedBox(
                    width: 26,
                    child: Checkbox(
                      value: s.picked.contains(i.id) && !skipped,
                      onChanged: skipped
                          ? null
                          : (v) => ref
                                .read(calendarControllerProvider.notifier)
                                .selectIdea(i.id, selected: v!),
                    ),
                  ),
                SizedBox(
                  width: 42,
                  child: Column(
                    children: [
                      calendarBody(
                        i.localTime == null
                            ? '№${i.position + 1}'
                            : DateFormat('EEE')
                                  .format(i.localTime!)
                                  .toUpperCase(),
                        size: 9,
                      ),
                      if (i.localTime != null)
                        calendarDisplay('${i.localTime!.day}', 30),
                    ],
                  ),
                ),
                calendarPhoto(view.imageFor(i), width: 66, height: 78),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      calendarBody(view.productName(i), size: 10),
                      const SizedBox(height: 5),
                      calendarDisplay(i.hook, 18),
                      const SizedBox(height: 6),
                      calendarBody(
                        '${calendarFormats[i.format]} · ${i.purpose ?? 'Part of the story'}${i.angle == null ? '' : ' · ${i.angle}'}${i.locked ? ' · Locked in' : ''}',
                        size: 10,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const SizedBox(width: 42),
                calendarPlatformIcons(i.platforms),
                const Spacer(),
                if (skipped)
                  calendarButton(
                    'Bring back',
                    busy ? null : () => s.itemAction(i, 'unskip'),
                    compact: true,
                  )
                else ...[
                  calendarButton(
                    'Change',
                    busy ? null : () => view.actions.drawer('idea', item: i),
                    compact: true,
                    icon: LucideIcons.pencil,
                  ),
                  const SizedBox(width: 5),
                  calendarButton(
                    '',
                    busy ? null : () => s.itemAction(i, 'swap'),
                    compact: true,
                    icon: LucideIcons.refreshCw,
                    label: 'Try another idea',
                  ),
                  if (!batch) ...[
                    const SizedBox(width: 5),
                    calendarButton(
                      '',
                      busy ? null : () => s.itemAction(i, 'skip'),
                      compact: true,
                      icon: LucideIcons.x,
                      label: 'Skip this day',
                    ),
                  ],
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
