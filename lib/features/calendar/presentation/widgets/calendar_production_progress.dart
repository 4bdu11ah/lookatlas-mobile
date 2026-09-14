import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_session.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_components.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CalendarProductionProgress extends ConsumerWidget {
  const CalendarProductionProgress({required this.s, super.key});
  final CalendarSession s;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
      calendarControllerProvider.select(
        (state) => (state.overview, state.busy.contains('plan')),
      ),
    );
    final o = s.overview!;
    final p = o.plan!;
    final r = o.rollup;
    final items = o.items.where((i) => i.status != 'skipped').toList();
    final produced = items
        .where(
          (i) => {
            'ready',
            'scheduled',
            'publishing',
            'published',
          }.contains(i.status),
        )
        .length;
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(18),
      color: CALENDAR_INK,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          calendarBody(
            'MONTHLY PRODUCTION',
            size: 10,
            color: Colors.white54,
          ),
          const SizedBox(height: 8),
          calendarDisplay(
            p.paused
                ? 'Production paused safely'
                : '$produced of ${items.length} posts ready',
            29,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _ProductionStat('$produced', 'Ready')),
              Expanded(
                child: _ProductionStat('${r['producing']}', 'Creating'),
              ),
              Expanded(
                child: _ProductionStat(
                  '${r['queuedForProduction']}',
                  'Queued',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: produced / (items.isEmpty ? 1 : items.length),
            color: const Color(0xff9daf97),
            backgroundColor: Colors.white24,
            semanticsLabel: 'Monthly content ready',
          ),
          const SizedBox(height: 12),
          calendarBody(
            p.paused ? 'Your place in the queue is preserved.' : 'Posts are created one at a time so you can keep using the studio.',
            color: Colors.white54,
            size: 11,
          ),
          const SizedBox(height: 12),
          calendarButton(
            p.paused ? 'Resume production' : 'Pause production',
            s.busy.contains('plan')
                ? null
                : () => s.updatePlan({'productionPaused': !p.paused}),
            icon: p.paused ? LucideIcons.play : LucideIcons.pause,
          ),
        ],
      ),
    );
  }
}

class _ProductionStat extends StatelessWidget {
  const _ProductionStat(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
      calendarBody(label, size: 10, color: Colors.white54),
    ],
  );
}
