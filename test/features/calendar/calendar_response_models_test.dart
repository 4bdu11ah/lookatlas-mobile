import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/features/calendar/data/models/calendar_response_models.dart';

void main() {
  test('calendarQuoteModel_validPayload_mapsCreditEstimate', () {
    final quote = CalendarQuoteModel.fromJson({
      'postCount': 22,
      'estimate': {'total': 132},
      'creditsRemaining': 100,
      'fitPreview': {'total': 90, 'downgraded': 4},
    }).toEntity();

    expect(quote.postCount, 22);
    expect(quote.totalCredits, 132);
    expect(quote.fitTotal, 90);
    expect(quote.downgradedPosts, 4);
  });

  test('calendarMutationModel_mapsResponsePresenceAndWarning', () {
    final result = CalendarMutationModel.fromJson({
      'item': <String, dynamic>{},
      'creditWarning': true,
    }).toEntity();

    expect(result.hasPlan, isFalse);
    expect(result.hasItem, isTrue);
    expect(result.creditWarning, isTrue);
  });
}
