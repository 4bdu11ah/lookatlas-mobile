import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_drawer_controller.dart';
import 'package:look_atlas/features/calendar/presentation/models/calendar_drawer_state.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_components.dart';

class CalendarDrawerBody extends ConsumerWidget {
  const CalendarDrawerBody({
    required this.args,
    required this.children,
    super.key,
  });
  final CalendarDrawerArgs args;
  final List<Widget> children;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = ref.watch(
      calendarDrawerProvider(args).select((state) => state.error),
    );
    final actionError = ref.watch(
      calendarControllerProvider.select((state) => state.actionError),
    );
    final fields = [
      if (error != null) calendarErrorBanner(error),
      if (actionError != null && actionError != error)
        calendarErrorBanner(actionError),
      ...children,
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: fields.length,
      itemBuilder: (context, index) => fields[index],
    );
  }
}
