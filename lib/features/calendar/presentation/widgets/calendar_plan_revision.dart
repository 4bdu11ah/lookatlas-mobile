import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_session.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_view_controller.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_components.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CalendarPlanRevision extends ConsumerWidget {
  const CalendarPlanRevision({required this.s, super.key});
  final CalendarSession s;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
      calendarControllerProvider.select(
        (state) =>
            (state.overview?.plan?.revision, state.busy.contains('plan')),
      ),
    );
    final local = ref.watch(
      calendarViewProvider.select(
        (state) => (state.revisionOpen, state.instruction),
      ),
    );
    final revisionOpen = local.$1;
    final revision = ref.watch(calendarRevisionTextProvider);
    final p = s.overview!.plan!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => ref
              .read(calendarViewProvider.notifier)
              .setRevisionOpen(value: !revisionOpen),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: CALENDAR_LINE),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  color: CALENDAR_INK,
                  alignment: Alignment.center,
                  child: const Icon(
                    LucideIcons.wandSparkles,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Want different ideas?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      calendarBody(
                        'Tell us what to shift. Your own edits stay untouched.',
                        size: 11,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  revisionOpen
                      ? LucideIcons.chevronUp
                      : LucideIcons.chevronDown,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        if (revisionOpen) ...[
          calendarFieldWidget(
            'Tell us what to change',
            revision,
            onChanged: ref.read(calendarViewProvider.notifier).setInstruction,
          ),
          const SizedBox(height: 8),
          calendarButton(
            s.revising || s.busy.contains('plan')
                ? 'Updating ideas…'
                : 'Update my plan',
            s.revising ||
                    s.busy.contains('plan') ||
                    revision.text.trim().isEmpty
                ? null
                : () async {
                    await s.revise(revision.text);
                  },
            primary: true,
          ),
          if (p.revision == 'failed')
            calendarErrorBanner(
              'We couldn’t update the ideas just now. Try again.',
            ),
          if (p.revision == 'applied')
            calendarNote('Your plan has been updated.'),
        ],
      ],
    );
  }
}
