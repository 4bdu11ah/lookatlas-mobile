import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_session.dart';
import 'package:look_atlas/features/calendar/presentation/models/calendar_actions.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_components.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CalendarMonthScreen extends ConsumerWidget {
  const CalendarMonthScreen({required this.view, super.key});
  final CalendarViewData view;
  CalendarSession get s => view.session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(calendarControllerProvider.select((state) => state.overview));
    final days = calendarDays(s.overview!, s.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        calendarBody('Swipe sideways to see the whole week.', size: 11),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 980,
            child: Table(
              defaultColumnWidth: const FixedColumnWidth(140),
              border: TableBorder.all(color: CALENDAR_LINE),
              children: [
                TableRow(
                  children: [
                    for (final d in [
                      'MON',
                      'TUE',
                      'WED',
                      'THU',
                      'FRI',
                      'SAT',
                      'SUN',
                    ])
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: calendarKicker(d),
                      ),
                  ],
                ),
                for (var row = 0; row < 6; row++)
                  TableRow(
                    children: [
                      for (final day in days.skip(row * 7).take(7))
                        Container(
                          constraints: const BoxConstraints(minHeight: 151),
                          padding: const EdgeInsets.all(9),
                          color: Colors.white,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              calendarBody('${day.date.day}', size: 10),
                              if (day.items.isEmpty)
                                SizedBox(
                                  height: 112,
                                  width: double.infinity,
                                  child: day.addable
                                      ? IconButton(
                                          tooltip:
                                              'Add post on ${calendarDateKey(day.date)}',
                                          onPressed: () => view.actions.drawer(
                                            'add',
                                            day: day.date,
                                          ),
                                          icon: const Icon(
                                            LucideIcons.plus,
                                            size: 15,
                                            color: CALENDAR_MUTED,
                                          ),
                                        )
                                      : null,
                                ),
                              for (final i in day.items)
                                InkWell(
                                  onTap: () =>
                                      view.actions.drawer('post', item: i),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      top: 5,
                                      bottom: 5,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        calendarPhoto(
                                          view.imageFor(i),
                                          height: 56,
                                          width: double.infinity,
                                        ),
                                        calendarBody(
                                          '${calendarFormats[i.format]} · ${i.hook}',
                                          size: 9,
                                        ),
                                        calendarBody(
                                          i.label(drafts: s.overview!.drafts),
                                          size: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
