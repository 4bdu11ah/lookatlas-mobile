import 'package:dio/dio.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/network/dio_client.dart';
import 'package:look_atlas/core/result/result.dart';

/// Decodes a raw JSON response body into a typed model.
typedef JsonDecoder<T> = T Function(dynamic data);

/// High-level HTTP service built on a single configured [Dio] instance.
///
/// Every method returns a [Result] so callers handle failures explicitly
/// instead of catching exceptions. The Dio instance owns the interceptor
/// stack (auth, retry, logging) via [DioClient.create], so this service stays
/// focused on request/response shaping and error mapping.
class ApiService {
  ApiService({
    required String baseUrl,
    Future<String?> Function()? tokenProvider,
    Future<String?> Function()? refreshToken,
    Future<void> Function()? onAuthFailure,
    Map<String, String>? headers,
    Dio? dio,
  }) : _dio =
           dio ??
           DioClient.create(
             baseUrl: baseUrl,
             tokenProvider: tokenProvider,
             refreshToken: refreshToken,
             onAuthFailure: onAuthFailure,
             headers: headers,
           );

  final Dio _dio;

  /// Escape hatch for advanced use (streaming, downloads, raw responses).
  Dio get raw => _dio;

  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    JsonDecoder<T>? decoder,
    CancelToken? cancelToken,
  }) {
    return _send(
      () => _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      ),
      decoder,
    );
  }

  Future<Result<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    JsonDecoder<T>? decoder,
    CancelToken? cancelToken,
    Options? options,
  }) {
    return _send(
      () => _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: options,
      ),
      decoder,
    );
  }

  Future<Result<T>> put<T>(
    String path, {
    Object? data,
    JsonDecoder<T>? decoder,
    CancelToken? cancelToken,
    Options? options,
  }) {
    return _send(
      () => _dio.put<dynamic>(
        path,
        data: data,
        cancelToken: cancelToken,
        options: options,
      ),
      decoder,
    );
  }

  Future<Result<T>> patch<T>(
    String path, {
    Object? data,
    JsonDecoder<T>? decoder,
    CancelToken? cancelToken,
  }) {
    return _send(
      () => _dio.patch<dynamic>(
        path,
        data: data,
        cancelToken: cancelToken,
      ),
      decoder,
    );
  }

  Future<Result<T>> delete<T>(
    String path, {
    Object? data,
    JsonDecoder<T>? decoder,
    CancelToken? cancelToken,
  }) {
    return _send(
      () => _dio.delete<dynamic>(
        path,
        data: data,
        cancelToken: cancelToken,
      ),
      decoder,
    );
  }

  Future<Result<T>> _send<T>(
    Future<Response<dynamic>> Function() request,
    JsonDecoder<T>? decoder,
  ) async {
    try {
      final response = await request();
      final data = response.data;
      return Ok(decoder != null ? decoder(data) : data as T);
    } on DioException catch (error) {
      // A cancelled request maps to CancelledFailure (see mapDioError) so
      // callers can pattern-match and treat it as an intentional no-op.
      return Err(mapDioError(error));
    } on Object catch (error, stack) {
      return Err(
        UnknownFailure(
          'Something went wrong. Please try again.',
          cause: error,
          stackTrace: stack,
        ),
      );
    }
  }
}
