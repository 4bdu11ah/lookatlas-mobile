import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/features/support/data/repositories/support_repository_impl.dart';
import 'package:look_atlas/features/support/domain/entities/support_ticket.dart';

void main() {
  const ticket = SupportTicketRequest(title: '[How to use Look Atlas] Credit rollover', name: 'Acme Studios', priority: 'low', message: 'Can I pause my subscription and keep my credits?');
  test('repository_submit_sendsAuthenticatedContractAndDecodesReceipt', () async {
    final api = ApiService(baseUrl: 'https://example.invalid', tokenProvider: () async => 'test-session');
    addTearDown(api.raw.close);
    RequestOptions? sent;
    api.raw.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      sent = options;
      handler.resolve(Response<dynamic>(requestOptions: options, statusCode: 200, data: {'message': 'Support ticket sent', 'provider': 'linear', 'id': 'LA-1042'}));
    }));
    final result = await SupportRepositoryImpl(api).submitTicket(ticket);
    expect(sent?.path, '/support/tickets');
    expect(sent?.method, 'POST');
    expect(sent?.headers['Authorization'], 'Bearer test-session');
    expect(sent?.data, {'title': ticket.title, 'name': 'Acme Studios', 'priority': 'low', 'message': ticket.message});
    expect(result.valueOrNull?.id, 'LA-1042');
  });
  test('repository_rateLimit_preservesServerRetryMetadata', () async {
    final api = ApiService(baseUrl: 'https://example.invalid');
    addTearDown(api.raw.close);
    api.raw.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      handler.reject(DioException(requestOptions: options, type: DioExceptionType.badResponse, response: Response<dynamic>(requestOptions: options, statusCode: 429, data: {'error': {'code': 'RATE_LIMIT_EXCEEDED', 'message': 'Please wait before submitting.', 'retryAfterSeconds': 45}})));
    }));
    final result = await SupportRepositoryImpl(api).submitTicket(ticket);
    final failure = result.failureOrNull! as NetworkFailure;
    expect(failure.code, 'RATE_LIMIT_EXCEEDED');
    expect(failure.details['retryAfterSeconds'], 45);
  });
  test('repository_malformedReceipt_returnsFailure', () async {
    final api = ApiService(baseUrl: 'https://example.invalid');
    addTearDown(api.raw.close);
    api.raw.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      handler.resolve(Response<dynamic>(requestOptions: options, statusCode: 200, data: {'id': 123}));
    }));
    expect((await SupportRepositoryImpl(api).submitTicket(ticket)).isErr, isTrue);
  });
}
