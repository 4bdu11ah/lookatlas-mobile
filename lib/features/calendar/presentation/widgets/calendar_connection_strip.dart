import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_session.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_components.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_theme.dart';

class CalendarConnectionStrip extends ConsumerWidget {
  const CalendarConnectionStrip({required this.s, super.key});
  final CalendarSession s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
      calendarControllerProvider.select(
        (state) => (state.overview, state.busy),
      ),
    );
    final o = s.overview!;
    final connected = o.connections
        .where((c) => c['status'] == 'connected')
        .toList();
    final available = o.connections
        .where((c) => c['available'] == true && c['status'] != 'connected')
        .toList();
    final title = connected.isNotEmpty
        ? '${connected.length} accounts connected'
        : o.publishingAvailable
        ? 'Connect your publishing accounts'
        : 'Publishing connections open soon';
    final detail = connected.isNotEmpty
        ? 'Ready when your approved posts reach their day.'
        : o.publishingAvailable
        ? 'Connect an account when you’re ready to publish.'
        : 'Your calendar keeps building in draft mode.';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: CALENDAR_LINE),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                color: CALENDAR_FIELD,
                alignment: Alignment.center,
                child: SizedBox(
                  width: 40,
                  child: calendarPlatformIcons(
                    o.connections
                        .map((connection) => connection['platform'] as String)
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    calendarKicker('Publishing'),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    calendarBody(detail, size: 10),
                  ],
                ),
              ),
            ],
          ),
          if (available.isNotEmpty) ...[
            const SizedBox(height: 12),
            calendarButton(
              'Connect ${available.length} ${available.length == 1 ? 'account' : 'accounts'}',
              () => s.connection(available.first['platform'] as String),
              compact: true,
            ),
          ],
        ],
      ),
    );
  }
}
