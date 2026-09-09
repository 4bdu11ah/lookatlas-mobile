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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: CALENDAR_LINE),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 43,
            child: calendarPlatformIcons(
              o.connections.map((c) => c['platform'] as String).toList(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              connected.isNotEmpty
                  ? '${connected.length} accounts connected'
                  : o.publishingAvailable
                  ? 'No accounts connected yet'
                  : 'Publishing connections open soon',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: calendarButton(
              available.isNotEmpty
                  ? 'Connect ${available.length} more'
                  : connected.isNotEmpty
                  ? 'All connected'
                  : 'Available soon',
              available.isEmpty
                  ? null
                  : () => s.connection(available.first['platform'] as String),
              compact: true,
            ),
          ),
        ],
      ),
    );
  }
}
