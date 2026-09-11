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

class CalendarMonthScreen extends ConsumerWidget {
  const CalendarMonthScreen({required this.view, super.key});
  final CalendarViewData view;
  CalendarSession get s => view.session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(calendarControllerProvider.select((state) => state.overview));
    final days = calendarDays(s.overview!, s.now());
    return SliverLayoutBuilder(
      builder: (context, constraints) => constraints.crossAxisExtent < 600
          ? _mobileMonth(days)
          : SliverToBoxAdapter(child: _desktopMonth(days)),
    );
  }

  Widget _mobileMonth(List<CalendarDay> days) {
    final plan = s.overview!.plan!;
    final visibleDays = days.where((day) {
      final key = calendarDateKey(day.date);
      return key.compareTo(plan.startsOn) >= 0 &&
          key.compareTo(plan.endsOn) <= 0;
    }).toList();
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: calendarBody('Your month, day by day.', size: 11),
          ),
        ),
        SliverList.builder(
          itemCount: visibleDays.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: _MobileCalendarDay(day: visibleDays[index], view: view),
          ),
        ),
      ],
    );
  }

  Widget _desktopMonth(List<CalendarDay> days) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      calendarBody('Your month at a glance.', size: 11),
      const SizedBox(height: 10),
      Table(
        border: TableBorder.all(color: CALENDAR_LINE),
        children: [
          TableRow(
            children: [
              for (final weekday in const [
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
                  child: calendarKicker(weekday),
                ),
            ],
          ),
          for (var row = 0; row < 6; row++)
            TableRow(
              children: [
                for (final day in days.skip(row * 7).take(7))
                  _DesktopCalendarDay(day: day, view: view),
              ],
            ),
        ],
      ),
    ],
  );
}

class _MobileCalendarDay extends StatelessWidget {
  const _MobileCalendarDay({required this.day, required this.view});
  final CalendarDay day;
  final CalendarViewData view;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: CALENDAR_LINE),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 47,
          child: Column(
            children: [
              calendarKicker(DateFormat('EEE').format(day.date)),
              const SizedBox(height: 3),
              calendarDisplay('${day.date.day}', 27),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: day.items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: calendarBody('No post planned', size: 11),
                )
              : Column(
                  children: [
                    for (final item in day.items)
                      _MobileCalendarItem(item: item, view: view),
                  ],
                ),
        ),
        if (day.addable)
          IconButton(
            tooltip: 'Add post on ${calendarDateKey(day.date)}',
            onPressed: () => view.actions.drawer('add', day: day.date),
            icon: const Icon(LucideIcons.plus, size: 16),
          ),
      ],
    ),
  );
}

class _MobileCalendarItem extends StatelessWidget {
  const _MobileCalendarItem({required this.item, required this.view});
  final CalendarItem item;
  final CalendarViewData view;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => view.actions.drawer('post', item: item),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          calendarPhoto(view.imageFor(item), width: 45, height: 53),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.hook,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                calendarBody(calendarFormats[item.format]!, size: 9),
                calendarBody(
                  item.label(drafts: view.session.overview!.drafts),
                  size: 9,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _DesktopCalendarDay extends StatelessWidget {
  const _DesktopCalendarDay({required this.day, required this.view});
  final CalendarDay day;
  final CalendarViewData view;

  @override
  Widget build(BuildContext context) => Container(
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
                    tooltip: 'Add post on ${calendarDateKey(day.date)}',
                    onPressed: () => view.actions.drawer('add', day: day.date),
                    icon: const Icon(
                      LucideIcons.plus,
                      size: 15,
                      color: CALENDAR_MUTED,
                    ),
                  )
                : null,
          ),
        for (final item in day.items)
          InkWell(
            onTap: () => view.actions.drawer('post', item: item),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  calendarPhoto(
                    view.imageFor(item),
                    height: 56,
                    width: double.infinity,
                  ),
                  calendarBody(
                    '${calendarFormats[item.format]} · ${item.hook}',
                    size: 9,
                  ),
                  calendarBody(
                    item.label(drafts: view.session.overview!.drafts),
                    size: 8,
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
