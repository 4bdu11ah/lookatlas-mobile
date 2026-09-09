import 'package:look_atlas/core/network/request_cancellation.dart';
import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';

abstract interface class CalendarRepository {
  Future<CalendarOverview> overview(RequestCancellation cancellation);
  Future<List<CalendarProduct>> products(RequestCancellation cancellation);
  Future<CalendarQuote> quote(
    CalendarSetup setup,
    RequestCancellation cancellation,
  );
  Future<CalendarMutationResult> createPlan(
    CalendarJson payload, {
    RequestCancellation? cancellation,
  });
  Future<CalendarMutationResult> changePlan(
    String planId,
    String method, {
    String? action,
    Object? data,
    RequestCancellation? cancellation,
  });
  Future<CalendarMutationResult> changeItem(
    String itemId, {
    String? action,
    CalendarJson? patch,
    RequestCancellation? cancellation,
  });
  Future<void> setConnection(
    String platform, {
    required bool connected,
    RequestCancellation? cancellation,
  });
  Future<int> attention({RequestCancellation? cancellation});
}
