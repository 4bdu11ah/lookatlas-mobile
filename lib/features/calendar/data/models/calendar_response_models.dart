import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';

class CalendarOverviewModel {
  CalendarOverviewModel.fromJson(Object? value) : json = calendarObject(value);
  final CalendarJson json;
  CalendarOverview toEntity() => CalendarOverview(json);
}

class CalendarProductModel {
  CalendarProductModel.fromJson(Object? value) : json = calendarObject(value);
  final CalendarJson json;
  CalendarProduct toEntity() => CalendarProduct(
    id: json['id'] as String,
    name: json['name'] as String,
    sku: json['sku'] as String? ?? '',
    thumbnail: json['thumbnail'] as String?,
  );
}

class CalendarQuoteModel {
  CalendarQuoteModel.fromJson(Object? value) : json = calendarObject(value);
  final CalendarJson json;
  CalendarQuote toEntity() {
    final estimate = calendarObject(json['estimate']);
    final fit = json['fitPreview'] == null
        ? null
        : calendarObject(json['fitPreview']);
    return CalendarQuote(
      postCount: (json['postCount'] as num).toInt(),
      totalCredits: (estimate['total'] as num).toInt(),
      creditsRemaining: (json['creditsRemaining'] as num).toInt(),
      fitTotal: (fit?['total'] as num?)?.toInt(),
      downgradedPosts: (fit?['downgraded'] as num?)?.toInt(),
    );
  }
}

class CalendarMutationModel {
  CalendarMutationModel.fromJson(Object? value) : json = calendarObject(value);
  final CalendarJson json;
  CalendarMutationResult toEntity() => CalendarMutationResult(
    hasPlan: json['plan'] is Map,
    hasItem: json['item'] is Map,
    creditWarning: json['creditWarning'] == true,
  );
}
