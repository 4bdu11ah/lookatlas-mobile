import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/calendar/di/calendar_providers.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_session.dart';
import 'package:look_atlas/features/calendar/presentation/models/calendar_state.dart';

final NotifierProvider<CalendarController, CalendarState>
calendarControllerProvider =
    NotifierProvider.autoDispose<CalendarController, CalendarState>(
      CalendarController.new,
    );

class CalendarController extends Notifier<CalendarState> {
  late final CalendarSession session;
  @override
  CalendarState build() {
    session = ref.read(calendarSessionFactoryProvider)();
    session.addListener(_refreshState);
    ref.onDispose(() {
      session.removeListener(_refreshState);
      session.dispose();
    });
    unawaited(
      Future<void>.microtask(() async {
        if (ref.mounted) await session.initialize();
      }),
    );
    return CalendarState.fromSession(session);
  }

  void _refreshState() {
    if (ref.mounted) state = CalendarState.fromSession(session);
  }

  void changeSetup(VoidCallback change, {bool invalidatesQuote = false}) {
    change();
    if (invalidatesQuote) session.clearQuote();
    session.emit();
  }

  void selectIdea(String id, {required bool selected}) {
    if (selected) {
      session.picked.add(id);
    } else {
      session.picked.remove(id);
    }
    session.emit();
  }
}
