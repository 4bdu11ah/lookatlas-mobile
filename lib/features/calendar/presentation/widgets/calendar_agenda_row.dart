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

class CalendarAgendaRow extends ConsumerWidget {
  const CalendarAgendaRow({required this.view, required this.item, super.key});

  final CalendarViewData view;
  final CalendarItem item;

  CalendarSession get s => view.session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
      calendarControllerProvider.select(
        (state) => (
          state.busy.contains(item.id),
          state.busy.contains('download:${item.id}'),
        ),
      ),
    );
    final actions = _itemActions();
    return Opacity(
      opacity: item.status == 'skipped' ? 0.45 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: CALENDAR_LINE),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
              child: Row(
                children: [
                  Expanded(child: calendarKicker(_dateLabel)),
                  calendarStatus(
                    item,
                    drafts: s.overview!.drafts,
                    emphasizeApproved: true,
                  ),
                ],
              ),
            ),
            calendarRule(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  calendarPhoto(view.imageFor(item), width: 76, height: 92),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        calendarBody(view.productName(item), size: 10),
                        const SizedBox(height: 5),
                        calendarDisplay(item.hook, 22),
                        const SizedBox(height: 9),
                        Wrap(
                          spacing: 8,
                          runSpacing: 7,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 4,
                              ),
                              color: CALENDAR_FIELD,
                              child: calendarBody(
                                calendarFormats[item.format]!,
                                size: 9,
                              ),
                            ),
                            calendarPlatformIcons(item.platforms),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (actions.isNotEmpty) ...[
              calendarRule(),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Wrap(spacing: 7, runSpacing: 7, children: actions),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String get _dateLabel {
    final time = item.localTime;
    if (time == null) return 'Unscheduled';
    return DateFormat('EEE d · HH:mm').format(time).toUpperCase();
  }

  List<Widget> _itemActions() {
    final busy = s.busy.contains(item.id);
    return [
      for (final action in item.actions.where(
        (action) =>
            action != 'back-to-review' &&
            (action != 'skip' || !{'ready', 'scheduled'}.contains(item.status)),
      ))
        calendarButton(
          calendarActionLabel(action, drafts: s.overview!.drafts),
          busy ? null : () => s.itemAction(item, action),
          compact: true,
          primary: action == 'looks-good' || action == 'build',
        ),
      if ({'idea', 'approved'}.contains(item.status))
        calendarButton(
          'Edit',
          busy ? null : () => view.actions.drawer('idea', item: item),
          compact: true,
          icon: LucideIcons.pencil,
        ),
      if (item.downloadable || item.editable)
        calendarButton(
          'Preview',
          () => view.actions.drawer('post', item: item),
          compact: true,
        ),
      if (item.status == 'ready' && item.generationId != null)
        calendarButton(
          'Open editor',
          () => view.actions.editor(item),
          compact: true,
        ),
      if (item.downloadable)
        calendarButton(
          '',
          s.busy.contains('download:${item.id}')
              ? null
              : () => view.actions.download(item),
          compact: true,
          icon: LucideIcons.download,
          label: 'Download this post',
        ),
    ];
  }
}
