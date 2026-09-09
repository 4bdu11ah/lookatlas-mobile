import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';
import 'package:look_atlas/features/calendar/domain/errors/calendar_api_exception.dart';

enum CalendarMutationEntity { plan, item }

class ValidateCalendarMutationUseCase {
  const ValidateCalendarMutationUseCase();

  CalendarMutationResult call(
    CalendarMutationResult result,
    CalendarMutationEntity entity,
  ) {
    final isValid = switch (entity) {
      CalendarMutationEntity.plan => result.hasPlan,
      CalendarMutationEntity.item => result.hasItem,
    };
    if (!isValid) {
      throw const CalendarApiException(
        'The server returned an invalid mutation response.',
      );
    }
    return result;
  }
}
