import 'package:dio/dio.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/core/network/request_cancellation.dart';
import 'package:look_atlas/features/calendar/data/data_sources/calendar_remote_data_source.dart';
import 'package:look_atlas/features/calendar/data/models/calendar_response_models.dart';
import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';
import 'package:look_atlas/features/calendar/domain/errors/calendar_api_exception.dart';
import 'package:look_atlas/features/calendar/domain/repositories/calendar_repository.dart';

class CalendarRepositoryImpl implements CalendarRepository {
  CalendarRepositoryImpl(ApiService api)
    : _remote = CalendarRemoteDataSource(api);

  final CalendarRemoteDataSource _remote;

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) rethrow;
      final detail = error.response?.data is Map
          ? (error.response!.data as Map)['error']
          : null;
      final code = detail is Map ? detail['code'] as String? : null;
      throw CalendarApiException(
        switch (error.response?.statusCode) {
          401 => 'Your session expired. Please sign in again.',
          402 => 'You need more credits for this action.',
          403 => 'Your plan does not include this feature.',
          409 =>
            code == 'PUBLISHING_UNAVAILABLE'
                ? 'Publishing connections aren’t open yet. Choose drafts only.'
                : 'The calendar changed. Review the refreshed state and try again.',
          _ =>
            code == null
                ? 'Could not complete the request. Check your connection and try again.'
                : calendarError(code),
        },
        code: code,
        status: error.response?.statusCode,
      );
    } on FormatException {
      throw const CalendarApiException(
        'The server returned an invalid or empty response.',
      );
    }
  }

  @override
  Future<CalendarOverview> overview(RequestCancellation cancellation) =>
      _guard(() async {
        try {
          return CalendarOverviewModel.fromJson(
            await _remote.overview(cancellation),
          ).toEntity();
        } on FormatException {
          throw const CalendarApiException(
            'The server returned an invalid Calendar overview.',
          );
        }
      });

  @override
  Future<List<CalendarProduct>> products(RequestCancellation cancellation) =>
      _guard(
        () async =>
            calendarObjects(
                  (await _remote.products(cancellation))['products'],
                )
                .map((json) => CalendarProductModel.fromJson(json).toEntity())
                .toList(),
      );

  @override
  Future<CalendarQuote> quote(
    CalendarSetup setup,
    RequestCancellation cancellation,
  ) => _guard(() async {
    final json = await _remote.quote(setup.quoteQuery, cancellation);
    if (json['postCount'] is! num ||
        json['estimate'] is! Map ||
        (json['estimate'] as Map)['total'] is! num) {
      throw const CalendarApiException('The server returned an invalid quote.');
    }
    return CalendarQuoteModel.fromJson(json).toEntity();
  });

  @override
  Future<CalendarMutationResult> createPlan(
    CalendarJson payload, {
    RequestCancellation? cancellation,
  }) => _guard(
    () async => CalendarMutationModel.fromJson(
      await _remote.createPlan(payload, cancellation: cancellation),
    ).toEntity(),
  );

  @override
  Future<CalendarMutationResult> changePlan(
    String planId,
    String method, {
    String? action,
    Object? data,
    RequestCancellation? cancellation,
  }) => _guard(
    () async => CalendarMutationModel.fromJson(
      await _remote.changePlan(
        planId,
        method,
        action: action,
        data: data,
        cancellation: cancellation,
      ),
    ).toEntity(),
  );

  @override
  Future<CalendarMutationResult> changeItem(
    String itemId, {
    String? action,
    CalendarJson? patch,
    RequestCancellation? cancellation,
  }) {
    if (action != null &&
        !{
          'skip',
          'unskip',
          'looks-good',
          'back-to-review',
          'retry',
          'swap',
          'build',
        }.contains(action)) {
      throw ArgumentError.value(action);
    }
    return _guard(
      () async => CalendarMutationModel.fromJson(
        await _remote.changeItem(
          itemId,
          action: action,
          patch: patch,
          cancellation: cancellation,
        ),
      ).toEntity(),
    );
  }

  @override
  Future<void> setConnection(
    String platform, {
    required bool connected,
    RequestCancellation? cancellation,
  }) => _guard(
    () => _remote.setConnection(
      platform,
      connected: connected,
      cancellation: cancellation,
    ),
  );

  @override
  Future<int> attention({RequestCancellation? cancellation}) =>
      _guard(() async {
        final json = await _remote.attention(cancellation: cancellation);
        return (json['needsReview'] as num).toInt() +
            (json['needsAttention'] as num).toInt();
      });
}
