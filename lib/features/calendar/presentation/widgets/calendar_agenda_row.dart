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
    final i = item;
    ref.watch(
      calendarControllerProvider.select(
        (state) => (
          state.busy.contains(i.id),
          state.busy.contains('download:${i.id}'),
        ),
      ),
    );
    return Opacity(
      opacity: i.status == 'skipped' ? 0.45 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: CALENDAR_LINE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 48,
                  child: Column(
                    children: [
                      calendarBody(
                        i.localTime == null
                            ? 'None'
                            : DateFormat('EEE')
                                  .format(i.localTime!)
                                  .toUpperCase(),
                        size: 9,
                      ),
                      if (i.localTime != null) ...[
                        calendarDisplay('${i.localTime!.day}', 30),
                        calendarBody(
                          DateFormat('HH:mm').format(i.localTime!),
                          size: 9,
                        ),
                      ],
                    ],
                  ),
                ),
                calendarPhoto(view.imageFor(i), width: 68, height: 80),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      calendarBody(view.productName(i), size: 10),
                      const SizedBox(height: 5),
                      calendarDisplay(i.hook, 18),
                      const SizedBox(height: 6),
                      calendarBody(calendarFormats[i.format]!, size: 10),
                      const SizedBox(height: 6),
                      calendarPlatformIcons(i.platforms),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                calendarStatus(i, drafts: s.overview!.drafts),
                ..._itemActions(i),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _itemActions(CalendarItem i) {
    final busy = s.busy.contains(i.id);
    return [
      for (final action in i.actions.where(
        (a) => a != 'skip' || !{'ready', 'scheduled'}.contains(i.status),
      ))
        calendarButton(
          calendarActionLabel(action, drafts: s.overview!.drafts),
          busy ? null : () => s.itemAction(i, action),
          compact: true,
          primary: action == 'looks-good' || action == 'build',
        ),
      if ({'idea', 'approved'}.contains(i.status))
        calendarButton(
          'Edit',
          busy ? null : () => view.actions.drawer('idea', item: i),
          compact: true,
        ),
      if (i.downloadable || i.editable)
        calendarButton(
          'Preview',
          () => view.actions.drawer('post', item: i),
          compact: true,
        ),
      if (i.status == 'ready' && i.generationId != null)
        calendarButton('Edit', () => view.actions.editor(i), compact: true),
      if (i.downloadable)
        calendarButton(
          '',
          s.busy.contains('download:${i.id}')
              ? null
              : () => view.actions.download(i),
          compact: true,
          icon: LucideIcons.download,
          label: 'Download this post',
        ),
    ];
  }
}
