import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/calendar/presentation/models/calendar_drawer_state.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_drawer_frame.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_idea_fields.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_save_footer.dart';

class CalendarAddPostScreen extends ConsumerWidget {
  const CalendarAddPostScreen({required this.args, super.key});
  final CalendarDrawerArgs args;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CalendarDrawerFrame(
      args: args,
      title: 'One more for the month.',
      eyebrow: 'Add a post',
      body: CalendarIdeaFields(args: args),
      footer: CalendarSaveFooter(args: args, label: 'Add to the month'),
    );
  }
}
