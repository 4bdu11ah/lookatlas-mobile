import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_session.dart';

class CalendarActions {
  const CalendarActions({
    required this.drawer,
    required this.editor,
    required this.download,
  });
  final Future<void> Function(String, {CalendarItem? item, DateTime? day})
  drawer;
  final Future<void> Function(CalendarItem) editor;
  final Future<void> Function(CalendarItem) download;
}

class CalendarViewData {
  const CalendarViewData(this.session, this.actions);
  final CalendarSession session;
  final CalendarActions actions;
  CalendarProduct? product(String? id) =>
      session.products.where((product) => product.id == id).firstOrNull;
  String productName(CalendarItem item) =>
      product(item.productId)?.name ?? 'From your library';
  String? imageFor(CalendarItem item) =>
      item.previewUrl ?? product(item.productId)?.thumbnail;
}
