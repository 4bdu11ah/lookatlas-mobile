import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_drawer_controller.dart';
import 'package:look_atlas/features/calendar/presentation/models/calendar_drawer_state.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_components.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CalendarSaveFooter extends ConsumerWidget {
  const CalendarSaveFooter({
    required this.args,
    required this.label,
    super.key,
  });
  final CalendarDrawerArgs args;
  final String label;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calendarDrawerProvider(args));
    final controller = ref.read(calendarDrawerProvider(args).notifier);
    return calendarButton(
      state.saving ? 'Saving…' : label,
      state.saving
          ? null
          : () async {
              if (await controller.save() && context.mounted) {
                Navigator.of(context).pop();
              }
            },
      primary: true,
      icon: LucideIcons.arrowRight,
    );
  }
}
