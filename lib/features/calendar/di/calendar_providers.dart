import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/network/request_cancellation.dart';
import 'package:look_atlas/core/providers/core_providers.dart';
import 'package:look_atlas/features/calendar/data/repositories/calendar_repository_impl.dart';
import 'package:look_atlas/features/calendar/domain/errors/calendar_api_exception.dart';
import 'package:look_atlas/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:look_atlas/features/calendar/domain/use_cases/calendar_plan_use_cases.dart';
import 'package:look_atlas/features/calendar/domain/use_cases/validate_calendar_mutation_use_case.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_session.dart';
import 'package:look_atlas/features/dashboard/di/dashboard_providers.dart';

final calendarRepositoryProvider = Provider<CalendarRepository>(
  (ref) => CalendarRepositoryImpl(ref.watch(apiServiceProvider)),
);
final calendarTimeZoneProvider = Provider<Future<String> Function()>(
  (ref) => () async {
    final value = await const MethodChannel('com.lookatlas/calendar')
        .invokeMethod<String>('timeZone');
    if (value == null || value.isEmpty) {
      throw const CalendarApiException('Device time zone is unavailable.');
    }
    return value;
  },
);
final calendarPlanUseCasesProvider = Provider<CalendarPlanUseCases>(
  (ref) => CalendarPlanUseCases(
    ref.watch(calendarRepositoryProvider),
    timeZone: ref.watch(calendarTimeZoneProvider),
  ),
);
final calendarMutationValidatorProvider =
    Provider<ValidateCalendarMutationUseCase>(
      (ref) => const ValidateCalendarMutationUseCase(),
    );
final calendarSessionFactoryProvider = Provider<CalendarSession Function()>(
  (ref) =>
      () => CalendarSession(
        ref.read(calendarRepositoryProvider),
        planUseCases: ref.read(calendarPlanUseCasesProvider),
        validateMutation: ref.read(calendarMutationValidatorProvider),
        onRefresh: () {
          ref
            ..invalidate(calendarAttentionProvider)
            ..invalidate(dashboardStatsProvider);
        },
      ),
);
final FutureProvider<int> calendarAttentionProvider =
    FutureProvider.autoDispose<int>((ref) async {
      final token = RequestCancellation();
      ref.onDispose(token.cancel);
      return ref
          .watch(calendarRepositoryProvider)
          .attention(cancellation: token);
    });
String calendarBadge(int count) => count > 9 ? '9+' : '$count';
