import 'package:dio/dio.dart';

/// Attaches a bearer token to outgoing requests.
///
/// The token is resolved lazily per request via [tokenProvider] so it always
/// reflects the current session without recreating the Dio instance.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this.tokenProvider);

  final Future<String?> Function() tokenProvider;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await tokenProvider();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
