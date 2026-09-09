import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_controller.dart';

class CalendarTrayState {
  const CalendarTrayState({this.input = '', this.error});
  final String input;
  final String? error;
}

final NotifierProviderFamily<CalendarTrayController, CalendarTrayState, String>
calendarTrayProvider = NotifierProvider.autoDispose
    .family<CalendarTrayController, CalendarTrayState, String>(
      CalendarTrayController.new,
    );

class CalendarTrayController extends Notifier<CalendarTrayState> {
  CalendarTrayController(this.itemId);
  final String itemId;
  final time = TextEditingController();
  @override
  CalendarTrayState build() {
    ref.onDispose(time.dispose);
    return const CalendarTrayState();
  }

  void setInput(String value) =>
      state = CalendarTrayState(input: value, error: state.error);
  Future<void> schedule() async {
    final session = ref.read(calendarControllerProvider.notifier).session;
    if (session.busy.contains(itemId)) return;
    final value = state.input;
    final validation = calendarTimeError(
      value,
      session.overview!.plan!,
      session.now(),
    );
    if (validation != null) {
      state = CalendarTrayState(input: value, error: validation);
      return;
    }
    final ok = await session.updateItem(itemId, {
      'publishAt': calendarParseInput(value)!.toUtc().toIso8601String(),
    });
    if (ref.mounted) {
      state = CalendarTrayState(
        input: state.input,
        error: ok ? null : session.mutationErrors[itemId],
      );
    }
  }
}
