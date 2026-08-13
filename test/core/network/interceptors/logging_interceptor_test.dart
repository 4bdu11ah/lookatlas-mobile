import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/network/interceptors/logging_interceptor.dart';

void main() {
  final interceptor = LoggingInterceptor();

  test('formatRequestLog_get_omitsBody', () {
    final log = interceptor.formatRequestLog(
      RequestOptions(path: '/products', method: 'GET', data: 'not logged'),
    );

    expect(log, contains('GET /products'));
    expect(log, isNot(contains('body:')));
    expect(log, isNot(contains('not logged')));
  });

  test('formatRequestLog_mutatingMethods_includeBody', () {
    for (final method in ['POST', 'PUT', 'PATCH', 'DELETE']) {
      final log = interceptor.formatRequestLog(
        RequestOptions(path: '/products', method: method, data: 'payload'),
      );

      expect(log, contains('body: payload'), reason: method);
    }
  });

  test('formatRequestBody_json_redactsNestedSecrets', () {
    final body = interceptor.formatRequestBody(
      RequestOptions(
        path: '/login',
        data: {
          'email': 'creator@example.com',
          'credentials': {'password': 'secret', 'access_token': 'token'},
        },
      ),
    );

    expect(body, {
      'email': 'c***@example.com',
      'credentials': {'password': '***', 'access_token': '***'},
    });
  });

  test('formatRequestBody_rawBody_logsContentAndRedactsSecrets', () {
    final plainText = interceptor.formatRequestBody(
      RequestOptions(path: '/notes', data: 'plain request body'),
    );
    final formEncoded = interceptor.formatRequestBody(
      RequestOptions(path: '/login', data: 'email=a@b.com&password=secret'),
    );

    expect(plainText, 'plain request body');
    expect(formEncoded, 'email=a***@b.com&password=***');
  });

  test('formatRequestBody_formData_logsFieldsAndFileMetadata', () {
    final formData = FormData()
      ..fields.addAll(const [
        MapEntry('name', 'Look Atlas'),
        MapEntry('refresh_token', 'secret'),
      ])
      ..files.add(
        MapEntry(
          'image',
          MultipartFile.fromBytes(
            [1, 2, 3],
            filename: 'look.jpg',
            contentType: DioMediaType('image', 'jpeg'),
          ),
        ),
      );

    final body =
        interceptor.formatRequestBody(
              RequestOptions(path: '/upload', data: formData),
            )!
            as Map<String, Object?>;

    expect(body['fields'], [
      {'name': 'Look Atlas'},
      {'refresh_token': '***'},
    ]);
    expect(body['files'], [
      {
        'field': 'image',
        'filename': 'look.jpg',
        'contentType': 'image/jpeg',
        'length': 3,
      },
    ]);
  });

  test('formatResponseLog_includesCompleteSanitizedBody', () {
    final content = List.filled(5000, 'x').join();
    final options = RequestOptions(path: '/shoots');

    final log = interceptor.formatResponseLog(
      Response<dynamic>(
        requestOptions: options,
        statusCode: 200,
        data: {
          'content': content,
          'email': 'creator@example.com',
          'access_token': 'secret',
        },
      ),
    );

    expect(log, contains('← 200 /shoots'));
    expect(log, contains(content));
    expect(log, contains('c***@example.com'));
    expect(log, contains('access_token: ***'));
    expect(log, isNot(contains('creator@example.com')));
    expect(log, isNot(contains('access_token: secret')));
  });
}
