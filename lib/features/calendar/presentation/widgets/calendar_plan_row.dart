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
    ref.watch(
      calendarControllerProvider.select(
        (state) => (
          state.busy.contains(item.id),
          state.picked.contains(item.id),
        ),
      ),
    );
    final skipped = item.status == 'skipped';
    final busy = s.busy.contains(item.id) || s.revising;
    return Opacity(
      opacity: skipped || (batch && !s.picked.contains(item.id)) ? 0.45 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: CALENDAR_LINE),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(ref, skipped),
            calendarRule(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  calendarPhoto(view.imageFor(item), width: 72, height: 88),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        calendarDisplay(item.hook, 22),
                        const SizedBox(height: 9),
                        _metadata(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            calendarRule(),
            Padding(
              padding: const EdgeInsets.all(10),
              child: _actions(busy, skipped),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(WidgetRef ref, bool skipped) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 9),
    child: Row(
      children: [
        Expanded(child: calendarKicker(_dateLabel())),
        Flexible(child: calendarBody(view.productName(item), size: 10)),
        if (batch) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 28,
            height: 28,
            child: Checkbox(
              value: s.picked.contains(item.id) && !skipped,
              onChanged: skipped
                  ? null
                  : (value) => ref
                        .read(calendarControllerProvider.notifier)
                        .selectIdea(item.id, selected: value!),
            ),
          ),
        ],
      ],
    ),
  );

  Widget _metadata() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 7,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            color: CALENDAR_FIELD,
            child: calendarBody(calendarFormats[item.format]!, size: 9),
          ),
          calendarPlatformIcons(item.platforms),
          if (item.locked)
            const Icon(LucideIcons.lock, size: 13, color: CALENDAR_MUTED),
        ],
      ),
      const SizedBox(height: 8),
      calendarBody(
        '${item.purpose ?? 'Part of the story'}${item.angle == null ? '' : ' · ${item.angle}'}',
        size: 10,
      ),
    ],
  );

  Widget _actions(bool busy, bool skipped) {
    if (skipped) {
      return SizedBox(
        width: double.infinity,
        child: calendarButton(
          'Bring back',
          busy ? null : () => s.itemAction(item, 'unskip'),
          compact: true,
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: calendarButton(
            'Change',
            busy ? null : () => view.actions.drawer('idea', item: item),
            compact: true,
            icon: LucideIcons.pencil,
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 42,
          child: calendarButton(
            '',
            busy ? null : () => s.itemAction(item, 'swap'),
            compact: true,
            icon: LucideIcons.refreshCw,
            label: 'Try another idea',
          ),
        ),
        if (!batch) ...[
          const SizedBox(width: 6),
          SizedBox(
            width: 42,
            child: calendarButton(
              '',
              busy ? null : () => s.itemAction(item, 'skip'),
              compact: true,
              icon: LucideIcons.x,
              label: 'Skip this day',
            ),
          ),
        ],
      ],
    );
  }

  String _dateLabel() {
    final time = item.localTime;
    if (time == null) {
      return 'Idea ${(item.position + 1).toString().padLeft(2, '0')}';
    }
    return '${DateFormat('EEE d').format(time)} · ${DateFormat('MMM').format(time)}'
        .toUpperCase();
  }
}
