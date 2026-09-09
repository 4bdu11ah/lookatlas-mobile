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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border.all(color: CALENDAR_LINE)),
            child: Row(
              children: [
                const Icon(LucideIcons.wandSparkles, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Want different ideas?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      calendarBody(
                        'Tell us once and we’ll update every idea you haven’t changed yourself.',
                        size: 11,
                      ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronDown, size: 16),
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
