import 'package:dio/dio.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/core/network/dio_cancellation.dart';
import 'package:look_atlas/core/network/request_cancellation.dart';
import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';

class CalendarRemoteDataSource {
  const CalendarRemoteDataSource(this._api);

  final ApiService _api;

  String _id(String value) => Uri.encodeComponent(value);

  Future<CalendarJson> _request(
    String method,
    String path, {
    Object? data,
    CalendarJson? query,
    RequestCancellation? cancellation,
  }) async {
    final binding = DioCancellation(cancellation);
    try {
      final response = await _api.raw.request<dynamic>(
        path,
        data: data,
        queryParameters: query,
        cancelToken: binding.token,
        options: Options(
          method: method,
          contentType: data == null ? null : Headers.jsonContentType,
        ),
      );
      final json = calendarObject(response.data);
      if (json.isEmpty) throw const FormatException();
      return json;
    } finally {
      binding.dispose();
    }
  }

  Future<CalendarJson> overview(RequestCancellation cancellation) =>
      _request('GET', '/runway/overview', cancellation: cancellation);

  Future<CalendarJson> products(RequestCancellation cancellation) => _request(
    'GET',
    '/products',
    query: {'includePhotos': false},
    cancellation: cancellation,
  );

  Future<CalendarJson> quote(
    CalendarJson query,
    RequestCancellation cancellation,
  ) => _request(
    'GET',
    '/runway/quote',
    query: query,
    cancellation: cancellation,
  );

  Future<CalendarJson> createPlan(
    CalendarJson payload, {
    RequestCancellation? cancellation,
  }) => _request(
    'POST',
    '/runway/plans',
    data: payload,
    cancellation: cancellation,
  );

  Future<CalendarJson> changePlan(
    String planId,
    String method, {
    String? action,
    Object? data,
    RequestCancellation? cancellation,
  }) => _request(
    method,
    '/runway/plans/${_id(planId)}${action == null ? '' : '/$action'}',
    data: data,
    cancellation: cancellation,
  );

  Future<CalendarJson> changeItem(
    String itemId, {
    String? action,
    CalendarJson? patch,
    RequestCancellation? cancellation,
  }) => _request(
    action == null ? 'PATCH' : 'POST',
    '/runway/items/${_id(itemId)}${action == null ? '' : '/$action'}',
    data: patch,
    cancellation: cancellation,
  );

  Future<void> setConnection(
    String platform, {
    required bool connected,
    RequestCancellation? cancellation,
  }) async {
    await _request(
      connected ? 'POST' : 'DELETE',
      '/runway/connections/${_id(platform)}',
      cancellation: cancellation,
    );
  }

  Future<CalendarJson> attention({RequestCancellation? cancellation}) =>
      _request('GET', '/runway/attention', cancellation: cancellation);
}
