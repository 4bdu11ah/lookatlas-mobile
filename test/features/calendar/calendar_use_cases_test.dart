import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/network/request_cancellation.dart';
import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';
import 'package:look_atlas/features/calendar/domain/errors/calendar_api_exception.dart';
import 'package:look_atlas/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:look_atlas/features/calendar/domain/use_cases/calendar_plan_use_cases.dart';
import 'package:look_atlas/features/calendar/domain/use_cases/validate_calendar_mutation_use_case.dart';

void main() {
  late _FakeCalendarRepository repository;

  setUp(() => repository = _FakeCalendarRepository());

  test('create_validSetup_buildsTimezoneAndCreditPayload', () async {
    final setup = CalendarSetup()
      ..mode = 'batch'
      ..batchCount = 4;
    final useCase = CalendarPlanUseCases(
      repository,
      timeZone: () async => 'Asia/Karachi',
    );

    await useCase.create(
      setup,
      const CalendarQuote(
        postCount: 4,
        totalCredits: 8,
        creditsRemaining: 2,
        fitTotal: 2,
        downgradedPosts: 1,
      ),
      RequestCancellation(),
    );

    expect(repository.createdPayload, containsPair('timeZone', 'Asia/Karachi'));
    expect(repository.createdPayload, containsPair('batchCount', 4));
    expect(repository.createdPayload, containsPair('fitToCredits', true));
  });

  test('create_emptyTimezone_preservesDomainError', () async {
    final useCase = CalendarPlanUseCases(
      repository,
      timeZone: () async => ' ',
    );

    expect(
      useCase.create(CalendarSetup(), null, RequestCancellation()),
      throwsA(
        isA<CalendarApiException>().having(
          (error) => error.message,
          'message',
          'Could not read your device time zone. Please try again.',
        ),
      ),
    );
  });

  test('approvalItemIds_batch_excludesSkippedAndUnpickedItems', () {
    final useCase = CalendarPlanUseCases(
      repository,
      timeZone: () async => 'Asia/Karachi',
    );

    final selected = useCase.approvalItemIds(
      _plan(batch: true),
      [
        _item('picked', 'idea'),
        _item('ignored', 'idea'),
        _item('skip', 'skipped'),
      ],
      {'picked', 'skip'},
    );

    expect(selected, ['picked']);
  });

  test('revisionInstruction_surroundingWhitespace_trimsValue', () {
    final useCase = CalendarPlanUseCases(
      repository,
      timeZone: () async => 'Asia/Karachi',
    );

    expect(useCase.revisionInstruction('  More detail  '), 'More detail');
  });

  test('revisionInstruction_whitespaceOnly_rejectsValue', () {
    final useCase = CalendarPlanUseCases(
      repository,
      timeZone: () async => 'Asia/Karachi',
    );

    expect(useCase.revisionInstruction('   '), isNull);
  });

  test('validateMutation_missingRequiredEntity_throwsContractError', () {
    const validate = ValidateCalendarMutationUseCase();
    const result = CalendarMutationResult(
      hasPlan: false,
      hasItem: false,
      creditWarning: false,
    );

    expect(
      () => validate(result, CalendarMutationEntity.plan),
      throwsA(
        isA<CalendarApiException>().having(
          (error) => error.message,
          'message',
          'The server returned an invalid mutation response.',
        ),
      ),
    );
  });
}

CalendarPlan _plan({required bool batch}) => CalendarPlan({
  'id': 'plan-1',
  'status': 'plan_ready',
  'objective': 'Post consistently',
  'cadence': '5_per_week',
  'startsOn': '2026-09-01',
  'endsOn': '2026-09-30',
  'platforms': ['instagram'],
  'settings': {'mode': batch ? 'batch' : 'scheduled'},
  'productModes': <String, dynamic>{},
  'chapters': <dynamic>[],
  'automationMode': 'review',
});

CalendarItem _item(String id, String status) => CalendarItem({
  'id': id,
  'status': status,
  'format': 'single',
  'hook': 'Hook',
  'position': 1,
  'platforms': ['instagram'],
});

class _FakeCalendarRepository implements CalendarRepository {
  CalendarJson? createdPayload;

  @override
  Future<CalendarMutationResult> createPlan(
    CalendarJson payload, {
    RequestCancellation? cancellation,
  }) async {
    createdPayload = payload;
    return _success;
  }

  @override
  Future<CalendarMutationResult> changePlan(
    String planId,
    String method, {
    String? action,
    Object? data,
    RequestCancellation? cancellation,
  }) async => _success;

  @override
  Future<int> attention({RequestCancellation? cancellation}) =>
      throw UnsupportedError('Not used');

  @override
  Future<CalendarMutationResult> changeItem(
    String itemId, {
    String? action,
    CalendarJson? patch,
    RequestCancellation? cancellation,
  }) => throw UnsupportedError('Not used');

  @override
  Future<CalendarOverview> overview(RequestCancellation cancellation) =>
      throw UnsupportedError('Not used');

  @override
  Future<List<CalendarProduct>> products(RequestCancellation cancellation) =>
      throw UnsupportedError('Not used');

  @override
  Future<CalendarQuote> quote(
    CalendarSetup setup,
    RequestCancellation cancellation,
  ) => throw UnsupportedError('Not used');

  @override
  Future<void> setConnection(
    String platform, {
    required bool connected,
    RequestCancellation? cancellation,
  }) => throw UnsupportedError('Not used');
}

const _success = CalendarMutationResult(
  hasPlan: true,
  hasItem: true,
  creditWarning: false,
);
