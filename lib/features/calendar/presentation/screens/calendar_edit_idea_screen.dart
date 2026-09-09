import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_drawer_controller.dart';
import 'package:look_atlas/features/calendar/presentation/models/calendar_drawer_state.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_drawer_frame.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_idea_fields.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_save_footer.dart';

class CalendarEditIdeaScreen extends ConsumerWidget {
  const CalendarEditIdeaScreen({required this.args, super.key});
  final CalendarDrawerArgs args;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(
      calendarDrawerProvider(args).select((state) => state.item),
    );
    return CalendarDrawerFrame(
      args: args,
      title: item!.localTime == null
          ? 'Concept ${item.position + 1}'
          : DateFormat('EEE · d').format(item.localTime!),
      eyebrow: 'Edit idea',
      body: CalendarIdeaFields(args: args),
      footer: CalendarSaveFooter(args: args, label: 'Save changes'),
    );
  }
}
