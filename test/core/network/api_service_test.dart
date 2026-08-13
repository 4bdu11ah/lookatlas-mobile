import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/core/network/dio_client.dart';

void main() {
  test('post_form_data_uses_multipart_content_type', () async {
    String? contentType;
    final dio = DioClient.create(baseUrl: 'https://example.com')
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            contentType = options.contentType;
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 201,
                data: const <String, dynamic>{},
              ),
            );
          },
        ),
      );
    final service = ApiService(baseUrl: 'https://example.com', dio: dio);

    await service.post<void>('/products', data: FormData());

    expect(contentType, startsWith(Headers.multipartFormDataContentType));
  });

  test('post_forwards_request_receive_timeout', () async {
    Duration? receiveTimeout;
    final dio = DioClient.create(baseUrl: 'https://example.com')
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            receiveTimeout = options.receiveTimeout;
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 201,
                data: const <String, dynamic>{},
              ),
            );
          },
        ),
      );
    final service = ApiService(baseUrl: 'https://example.com', dio: dio);

    await service.post<void>(
      '/jobs/v2/plan-shots',
      options: Options(receiveTimeout: const Duration(minutes: 2)),
    );

    expect(receiveTimeout, const Duration(minutes: 2));
  });

  test('map_dio_error_preserves_structured_server_fields', () {
    final options = RequestOptions(path: '/jobs/v2/create');
    final failure = mapDioError(
      DioException.badResponse(
        statusCode: 400,
        requestOptions: options,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: 400,
          data: {
            'error': {
              'code': 'RELAX_JOB_TOO_LARGE',
              'message': 'Too many images.',
              'maxImagesPerJob': 20,
            },
          },
        ),
      ),
    );

    expect(failure, isA<NetworkFailure>());
    final network = failure as NetworkFailure;
    expect(network.code, 'RELAX_JOB_TOO_LARGE');
    expect(network.details['maxImagesPerJob'], 20);
  });
}
