import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_session.dart';
import 'package:look_atlas/features/calendar/presentation/models/calendar_actions.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_agenda_row.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_components.dart';

class CalendarAgendaScreen extends ConsumerWidget {
  const CalendarAgendaScreen({required this.view, super.key});
  final CalendarViewData view;
  CalendarSession get s => view.session;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(
      calendarControllerProvider.select((state) => state.overview),
    )!;
    final items = overview.items.where((i) => i.publishAt != null).toList()
      ..sort((a, b) => a.localTime!.compareTo(b.localTime!));
    return SliverList.builder(
      itemCount: items.isEmpty ? 1 : items.length,
      itemBuilder: (context, index) => items.isEmpty
          ? calendarNote('No posts have a date yet.')
          : CalendarAgendaRow(view: view, item: items[index]),
    );
  }
}
