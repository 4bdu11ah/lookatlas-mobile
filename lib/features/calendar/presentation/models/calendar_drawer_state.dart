import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_caption.dart';
import 'package:look_atlas/features/calendar/presentation/models/calendar_actions.dart';
import 'package:look_atlas/features/create_content/domain/entities/content_models.dart';

class CalendarDrawerArgs {
  const CalendarDrawerArgs({
    required this.type,
    required this.view,
    this.item,
    this.day,
  });
  final String type;
  final CalendarViewData view;
  final CalendarItem? item;
  final DateTime? day;
}

class CalendarCaptionState {
  CalendarCaptionState.fromController(CalendarCaption? controller)
    : loaded = controller?.loaded ?? false,
      saving = controller?.saving ?? false,
      saved = controller?.saved ?? false,
      error = controller?.error,
      generation = controller?.generation,
      hashtags = List.unmodifiable(controller?.hashtags ?? <String>[]);
  final bool loaded;
  final bool saving;
  final bool saved;
  final String? error;
  final ContentGeneration? generation;
  final List<String> hashtags;
}

class CalendarDrawerState {
  CalendarDrawerState({
    required this.productId,
    required this.format,
    required this.automation,
    required List<String> platforms,
    required this.savedTime,
    required this.caption,
    this.item,
    this.error,
    this.saving = false,
  }) : platforms = List.unmodifiable(platforms);
  final String? productId;
  final String format;
  final String automation;
  final List<String> platforms;
  final String savedTime;
  final String? error;
  final bool saving;
  final CalendarItem? item;
  final CalendarCaptionState caption;
  CalendarDrawerState copyWith({
    String? productId,
    String? format,
    String? automation,
    List<String>? platforms,
    String? savedTime,
    String? error,
    bool clearError = false,
    bool? saving,
    CalendarItem? item,
    CalendarCaptionState? caption,
  }) => CalendarDrawerState(
    productId: productId ?? this.productId,
    format: format ?? this.format,
    automation: automation ?? this.automation,
    platforms: platforms ?? this.platforms,
    savedTime: savedTime ?? this.savedTime,
    error: clearError ? null : error ?? this.error,
    saving: saving ?? this.saving,
    item: item ?? this.item,
    caption: caption ?? this.caption,
  );
}
