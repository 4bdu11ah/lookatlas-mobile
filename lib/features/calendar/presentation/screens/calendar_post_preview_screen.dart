import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_drawer_controller.dart';
import 'package:look_atlas/features/calendar/presentation/models/calendar_drawer_state.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_components.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_drawer_frame.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_post_fields.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_post_footer.dart';

class CalendarPostPreviewScreen extends ConsumerWidget {
  const CalendarPostPreviewScreen({required this.args, super.key});
  final CalendarDrawerArgs args;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(
      calendarDrawerProvider(args).select((state) => state.item),
    );
    return CalendarDrawerFrame(
      args: args,
      title: item!.hook,
      eyebrow: calendarWhen(item),
      body: CalendarPostFields(args: args),
      footer: CalendarPostFooter(args: args),
    );
  }
}
