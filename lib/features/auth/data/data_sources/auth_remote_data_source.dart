import 'package:dio/dio.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/network/api_endpoints.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/auth/data/models/app_user_model.dart';
import 'package:look_atlas/features/auth/data/models/auth_session_model.dart';
import 'package:look_atlas/features/auth/domain/entities/register_attribution.dart';

/// The backend's `/auth/*` endpoints (see the Postman collection): register,
/// login, logout, refresh and forgot-password.
abstract interface class AuthRemoteDataSource {
  /// `POST /auth/register` — creates the account and returns a session (201).
  /// [attribution] carries the optional marketing fields (fbc/fbp, UTM,
  /// Google Ads click IDs, invite) exactly like the web client.
  Future<Result<AuthSessionModel>> register({
    required String companyName,
    required String email,
    required String password,
    RegisterAttribution? attribution,
    String? captchaToken,
  });

  /// `POST /auth/login` — 401 for bad credentials, 404 when the auth user has
  /// no profile row. [captchaToken] is the optional Turnstile token, only
  /// checked by the backend when the challenge is enabled.
  Future<Result<AuthSessionModel>> login({
    required String email,
    required String password,
    String? captchaToken,
  });

  /// `GET /auth/verify` validates the restored bearer session.
  Future<Result<AppUserModel>> verify();

  /// `POST /auth/logout` — bearer-authenticated; invalidates the refresh
  /// token server-side.
  Future<Result<void>> logout();

  /// `POST /auth/refresh` — exchanges a single-use refresh token for a new
  /// access/refresh pair.
  Future<Result<AuthRefreshModel>> refresh(String refreshToken);

  /// `POST /auth/forgot-password` — always 200, regardless of whether the
  /// email exists (anti-enumeration).
  Future<Result<void>> forgotPassword(String email);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({
    required ApiService api,
    required ApiService publicApi,
    Future<Map<String, Object?>> Function()? registrationContext,
  }) : _api = api,
       _publicApi = publicApi,
       _registrationContext = registrationContext;

  /// The shared bearer-authenticated client — only [logout] needs it.
  final ApiService _api;

  /// A bare client with no auth/token-refresh interceptors for the public
  /// endpoints. Critical for [refresh]: it is called FROM the shared client's
  /// 401 interceptor, so routing it through that same client could re-enter
  /// the (queued) interceptor and deadlock.
  final ApiService _publicApi;
  final Future<Map<String, Object?>> Function()? _registrationContext;

  @override
  Future<Result<AuthSessionModel>> register({
    required String companyName,
    required String email,
    required String password,
    RegisterAttribution? attribution,
    String? captchaToken,
  }) async {
    Map<String, Object?>? deviceContext;
    try {
      deviceContext = await _registrationContext?.call();
    } on Object {
      // Registration accepts these abuse-detection signals as optional.
      // Native device lookup must never prevent account creation.
    }
    final result = await _publicApi.post<AuthSessionModel>(
      ApiEndpoints.authRegister,
      data: {
        'companyName': companyName,
        'email': email,
        'password': password,
        'plan': 'starter',
        'captchaToken': ?captchaToken,
        ...?deviceContext,
        ...?attribution?.toJson(),
      },
      decoder: (data) => AuthSessionModel.fromJson(
        _bodyAsMap(data),
        fallbackEmail: email,
        fallbackCompanyName: companyName,
      ),
    );
    // Same fallback copy as the web client's register handler.
    return result.mapErr(
      (failure) => _authFailure(failure, fallback: 'Registration failed'),
    );
  }

  @override
  Future<Result<AuthSessionModel>> login({
    required String email,
    required String password,
    String? captchaToken,
  }) async {
    final result = await _publicApi.post<AuthSessionModel>(
      ApiEndpoints.authLogin,
      data: {
        'email': email,
        'password': password,
        'captchaToken': ?captchaToken,
      },
      decoder: (data) =>
          AuthSessionModel.fromJson(_bodyAsMap(data), fallbackEmail: email),
    );
    // Same fallback copy as the web client's login handler.
    return result.mapErr(
      (failure) => _authFailure(failure, fallback: 'Login failed'),
    );
  }

  @override
  Future<Result<AppUserModel>> verify() => _api.get<AppUserModel>(
    ApiEndpoints.authVerify,
    decoder: (data) {
      final body = _bodyAsMap(data);
      final user = body['user'];
      if (user is! Map<String, dynamic>) {
        throw const FormatException('Verify response contains no user.');
      }
      final id = user['id'] ?? user['user_id'];
      final email = user['email'];
      if (id is! String || id.isEmpty || email is! String || email.isEmpty) {
        throw const FormatException('Verify user is invalid.');
      }
      return AppUserModel(
        id: id,
        email: email,
        displayName:
            user['display_name'] as String? ?? user['displayName'] as String?,
        photoUrl: user['photo_url'] as String? ?? user['photoUrl'] as String?,
        companyName:
            user['company_name'] as String? ?? user['companyName'] as String?,
      );
    },
  );

  @override
  Future<Result<void>> logout() => _api.post<void>(
    ApiEndpoints.authLogout,
    decoder: (_) {},
    data: const {},
  );

  @override
  Future<Result<AuthRefreshModel>> refresh(String refreshToken) async {
    final result = await _publicApi.post<AuthRefreshModel>(
      ApiEndpoints.authRefresh,
      data: {'refreshToken': refreshToken},
      decoder: (data) => AuthRefreshModel.fromJson(_bodyAsMap(data)),
    );
    return result;
  }

  @override
  Future<Result<void>> forgotPassword(String email) async {
    final result = await _publicApi.post<void>(
      ApiEndpoints.authForgotPassword,
      data: {'email': email},
      decoder: (_) {},
    );
    return result.mapErr(
      (failure) => _authFailure(
        failure,
        fallback: 'Could not send the reset email. Please try again.',
      ),
    );
  }

  static Map<String, dynamic> _bodyAsMap(dynamic data) =>
      data is Map<String, dynamic> ? data : const {};

  /// Turns a transport failure into a user-facing [AuthFailure], mirroring
  /// the web client's `result.error?.message || fallback` handling: the
  /// backend's own `error.message` body field first (its messages are written
  /// for end users), then [fallback]. Connectivity failures (no HTTP status)
  /// and message-less 5xx responses pass through untouched — `mapDioError`
  /// already gave them a friendly message.
  static Failure _authFailure(Failure failure, {required String fallback}) {
    if (failure is! NetworkFailure) {
      return failure is UnknownFailure
          ? AuthFailure(
              fallback,
              cause: failure.cause,
              stackTrace: failure.stackTrace,
            )
          : failure;
    }
    final status = failure.statusCode;
    if (status == null) return failure;
    final serverMessage = _serverMessage(failure.cause);
    if (serverMessage == null && status >= 500) return failure;
    return AuthFailure(
      serverMessage ?? fallback,
      cause: failure.cause,
      stackTrace: failure.stackTrace,
    );
  }

  /// The error message from a response body: `error.message` first (the
  /// web client's shape), then flat `error` / `message` strings.
  static String? _serverMessage(Object? cause) {
    if (cause is! DioException) return null;
    final data = cause.response?.data;
    if (data is! Map<String, dynamic>) return null;
    final error = data['error'];
    final message =
        (error is Map<String, dynamic> ? error['message'] : null) ??
        (error is String ? error : null) ??
        data['message'];
    return message is String && message.isNotEmpty ? message : null;
  }
}
