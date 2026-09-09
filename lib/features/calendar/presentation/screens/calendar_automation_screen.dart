import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/calendar/presentation/models/calendar_drawer_state.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_automation_fields.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_drawer_frame.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_save_footer.dart';

class CalendarAutomationScreen extends ConsumerWidget {
  const CalendarAutomationScreen({required this.args, super.key});
  final CalendarDrawerArgs args;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CalendarDrawerFrame(
      args: args,
      title: 'How hands-on should we be?',
      eyebrow: 'Automation',
      body: CalendarAutomationFields(args: args),
      footer: CalendarSaveFooter(args: args, label: 'Save settings'),
    );
  }
}
