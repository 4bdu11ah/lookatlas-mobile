import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_drawer_controller.dart';
import 'package:look_atlas/features/calendar/presentation/models/calendar_drawer_state.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_components.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CalendarDrawerFrame extends ConsumerWidget {
  const CalendarDrawerFrame({
    required this.args,
    required this.title,
    required this.eyebrow,
    required this.body,
    required this.footer,
    super.key,
  });
  final CalendarDrawerArgs args;
  final String title;
  final String eyebrow;
  final Widget body;
  final Widget footer;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(
      calendarDrawerProvider(args)
          .select((state) => (state.saving, state.caption.saving)),
    );
    final saving = activity.$1;
    final captionSaving = activity.$2;
    Future<void> close() async {
      if (await ref.read(calendarDrawerProvider(args).notifier).canClose() &&
          context.mounted) {
        Navigator.of(context).pop();
      }
    }

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: CALENDAR_INK,
          surface: CALENDAR_PAPER,
        ),
        textTheme: Theme.of(context).textTheme
            .apply(fontFamily: 'Satoshi', bodyColor: CALENDAR_INK),
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) unawaited(close());
        },
        child: Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width <= 640
                ? MediaQuery.sizeOf(context).width
                : 440,
            child: Material(
              color: CALENDAR_PAPER,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: Column(
                    children: [
                      Container(
                        constraints: const BoxConstraints(minHeight: 94),
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: CALENDAR_LINE),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  calendarKicker(eyebrow),
                                  const SizedBox(height: 6),
                                  calendarDisplay(title, 29),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            calendarButton(
                              '',
                              saving || captionSaving ? null : close,
                              compact: true,
                              icon: LucideIcons.x,
                              label: 'Close',
                            ),
                          ],
                        ),
                      ),
                      Expanded(child: body),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: CALENDAR_LINE)),
                        ),
                        child: SizedBox(width: double.infinity, child: footer),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
