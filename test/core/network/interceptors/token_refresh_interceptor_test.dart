import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/network/interceptors/token_refresh_interceptor.dart';

void main() {
  test('concurrent_401s_share_one_refresh_and_replay', () async {
    final adapter = _TokenAdapter();
    final refreshCompleter = Completer<String?>();
    String? currentToken = 'expired-token';
    var refreshCalls = 0;
    var authFailureCalls = 0;
    final dio = _createDio(
      adapter,
      tokenProvider: () async => currentToken,
      refreshToken: () async {
        refreshCalls++;
        return currentToken = await refreshCompleter.future;
      },
      onAuthFailure: () async {
        authFailureCalls++;
        currentToken = null;
      },
    );
    addTearDown(() => dio.close(force: true));

    final requests = [
      dio.get<dynamic>('/first', options: _expiredTokenOptions()),
      dio.get<dynamic>('/second', options: _expiredTokenOptions()),
    ];
    await adapter.twoRequests;
    refreshCompleter.complete('fresh-token');

    final responses = await Future.wait(requests);

    expect(responses.map((response) => response.statusCode), everyElement(200));
    expect(refreshCalls, 1);
    expect(authFailureCalls, 0);
    expect(adapter.authorizationHeaders, contains('Bearer fresh-token'));
  });

  test('failed_refresh_clears_session_once_for_concurrent_401s', () async {
    final adapter = _TokenAdapter();
    final refreshCompleter = Completer<String?>();
    String? currentToken = 'expired-token';
    var refreshCalls = 0;
    var authFailureCalls = 0;
    final dio = _createDio(
      adapter,
      tokenProvider: () async => currentToken,
      refreshToken: () async {
        refreshCalls++;
        return currentToken = await refreshCompleter.future;
      },
      onAuthFailure: () async {
        authFailureCalls++;
        currentToken = null;
      },
    );
    addTearDown(() => dio.close(force: true));

    final requests = [
      _capture(dio.get<dynamic>('/first', options: _expiredTokenOptions())),
      _capture(dio.get<dynamic>('/second', options: _expiredTokenOptions())),
    ];
    await adapter.twoRequests;
    refreshCompleter.complete(null);

    final results = await Future.wait(requests);

    expect(results, everyElement(isA<DioException>()));
    expect(refreshCalls, 1);
    expect(authFailureCalls, 1);
  });

  test('rejected_refreshed_token_clears_session_without_looping', () async {
    final adapter = _TokenAdapter(acceptFreshToken: false);
    String? currentToken = 'expired-token';
    var refreshCalls = 0;
    var authFailureCalls = 0;
    final dio = _createDio(
      adapter,
      tokenProvider: () async => currentToken,
      refreshToken: () async {
        refreshCalls++;
        return currentToken = 'fresh-token';
      },
      onAuthFailure: () async {
        authFailureCalls++;
        currentToken = null;
      },
    );
    addTearDown(() => dio.close(force: true));

    await expectLater(
      dio.get<dynamic>('/protected', options: _expiredTokenOptions()),
      throwsA(isA<DioException>()),
    );

    expect(adapter.requestCount, 2);
    expect(refreshCalls, 1);
    expect(authFailureCalls, 1);
  });
}

Options _expiredTokenOptions() => Options(
  headers: const {'Authorization': 'Bearer expired-token'},
);

Dio _createDio(
  HttpClientAdapter adapter, {
  required Future<String?> Function() tokenProvider,
  required Future<String?> Function() refreshToken,
  required Future<void> Function() onAuthFailure,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
    ..httpClientAdapter = adapter;
  dio.interceptors.add(
    TokenRefreshInterceptor(
      dio: dio,
      tokenProvider: tokenProvider,
      refreshToken: refreshToken,
      onAuthFailure: onAuthFailure,
    ),
  );
  return dio;
}

Future<Object> _capture(Future<Response<dynamic>> request) async {
  try {
    return await request;
  } on Object catch (error) {
    return error;
  }
}

class _TokenAdapter implements HttpClientAdapter {
  _TokenAdapter({this.acceptFreshToken = true});

  final bool acceptFreshToken;
  final authorizationHeaders = <String?>[];
  final _twoRequests = Completer<void>();
  int requestCount = 0;

  Future<void> get twoRequests => _twoRequests.future;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount++;
    final authorization = options.headers['Authorization'] as String?;
    authorizationHeaders.add(authorization);
    if (requestCount == 2 && !_twoRequests.isCompleted) {
      _twoRequests.complete();
    }
    final isAuthorized =
        acceptFreshToken && authorization == 'Bearer fresh-token';
    return ResponseBody.fromString(
      '{}',
      isAuthorized ? 200 : 401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
