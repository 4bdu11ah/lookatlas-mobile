import 'package:look_atlas/core/network/request_cancellation.dart';
import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';
import 'package:look_atlas/features/calendar/domain/errors/calendar_api_exception.dart';
import 'package:look_atlas/features/calendar/domain/repositories/calendar_repository.dart';

class CalendarPlanUseCases {
  CalendarPlanUseCases(
    this._repository, {
    required this._timeZone,
  });

  final CalendarRepository _repository;
  final Future<String> Function() _timeZone;

  Future<CalendarMutationResult> create(
    CalendarSetup setup,
    CalendarQuote? quote,
    RequestCancellation cancellation,
  ) async {
    final zone = await _timeZone();
    if (zone.trim().isEmpty) {
      throw const CalendarApiException(
        'Could not read your device time zone. Please try again.',
      );
    }
    return _repository.createPlan(
      setup.payload(zone, overBudget: quote?.hasFitPreview ?? false),
      cancellation: cancellation,
    );
  }

  List<String> approvalItemIds(
    CalendarPlan plan,
    Iterable<CalendarItem> items,
    Set<String> picked,
  ) => items
      .where(
        (item) =>
            item.status != 'skipped' &&
            (!plan.batch || picked.contains(item.id)),
      )
      .map((item) => item.id)
      .toList();

  Future<CalendarMutationResult> approve(
    CalendarPlan plan,
    List<String> itemIds,
    RequestCancellation cancellation,
  ) => _repository.changePlan(
    plan.id,
    'POST',
    action: 'approve',
    data: plan.batch ? {'itemIds': itemIds} : <String, dynamic>{},
    cancellation: cancellation,
  );

  String? revisionInstruction(String value) {
    final instruction = value.trim();
    return instruction.isEmpty ? null : instruction;
  }

  Future<CalendarMutationResult> revise(
    CalendarPlan plan,
    String instruction,
    RequestCancellation cancellation,
  ) => _repository.changePlan(
    plan.id,
    'POST',
    action: 'revise',
    data: {'instruction': instruction},
    cancellation: cancellation,
  );
}
