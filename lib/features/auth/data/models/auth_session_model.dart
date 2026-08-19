import 'dart:convert';

import 'package:look_atlas/features/auth/data/models/app_user_model.dart';

/// An authenticated session returned by `POST /auth/login` and
/// `POST /auth/register`: the token pair plus the user profile.
///
/// Parsing is deliberately tolerant about field names (`accessToken`, `token`,
/// `session.access_token`, ...) — mirroring the Postman collection's own test
/// scripts, which probe the same aliases — so minor backend response changes
/// don't brick sign-in.
class AuthSessionModel {
  const AuthSessionModel({
    required this.accessToken,
    required this.user,
    this.refreshToken,
  });

  /// Parses a login/register response body.
  ///
  /// [fallbackEmail] and [fallbackCompanyName] come from the submitted form
  /// and fill any profile field the response omits; the user id falls back to
  /// the JWT `sub` claim. Throws [FormatException] when no access token can
  /// be found — callers surface that as a failure.
  factory AuthSessionModel.fromJson(
    Map<String, dynamic> json, {
    required String fallbackEmail,
    String? fallbackCompanyName,
  }) {
    final accessToken = extractAccessToken(json);
    if (accessToken == null) {
      throw const FormatException('Auth response contains no access token.');
    }

    final session = _asMap(json['session']);
    final refreshToken =
        _asString(json['refreshToken']) ??
        _asString(json['refresh_token']) ??
        _asString(session?['refresh_token']) ??
        _asString(session?['refreshToken']);

    final profile =
        _asMap(json['user']) ?? _asMap(session?['user']) ?? const {};
    final email = _asString(profile['email']) ?? fallbackEmail;
    return AuthSessionModel(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: AppUserModel(
        id:
            _asString(profile['id']) ??
            _asString(profile['user_id']) ??
            _jwtSubject(accessToken) ??
            email,
        email: email,
        displayName:
            _asString(profile['display_name']) ??
            _asString(profile['displayName']) ??
            _asString(profile['name']) ??
            _asString(profile['full_name']),
        photoUrl:
            _asString(profile['photo_url']) ?? _asString(profile['avatar_url']),
        companyName:
            _asString(profile['company_name']) ??
            _asString(profile['companyName']) ??
            fallbackCompanyName,
      ),
    );
  }

  final String accessToken;

  /// Null when the backend omits it (e.g. `/auth/refresh` never returns one).
  final String? refreshToken;
  final AppUserModel user;

  /// Finds the access token in a response body under any of its known
  /// aliases. Also used alone for `/auth/refresh` responses.
  static String? extractAccessToken(Map<String, dynamic> json) {
    final session = _asMap(json['session']);
    return _asString(json['accessToken']) ??
        _asString(json['access_token']) ??
        _asString(json['token']) ??
        _asString(session?['access_token']) ??
        _asString(session?['accessToken']);
  }

  static Map<String, dynamic>? _asMap(dynamic value) =>
      value is Map<String, dynamic> ? value : null;

  static String? _asString(dynamic value) =>
      value is String && value.isNotEmpty ? value : null;

  /// The `sub` claim of a JWT access token, or null when the token is opaque
  /// or malformed. Used as the user-id fallback when the response has no
  /// profile object.
  static String? _jwtSubject(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      return _asString((jsonDecode(payload) as Map<String, dynamic>)['sub']);
    } on FormatException {
      return null;
    }
  }
}

/// The rotated token pair returned by `POST /auth/refresh`.
///
/// A refresh token is single-use, so callers must replace both stored values
/// before replaying the failed request.
class AuthRefreshModel {
  const AuthRefreshModel({
    required this.accessToken,
    required this.refreshToken,
    this.expiresIn,
  });

  factory AuthRefreshModel.fromJson(Map<String, dynamic> json) {
    final accessToken = AuthSessionModel.extractAccessToken(json);
    final refreshToken = json['refreshToken'] ?? json['refresh_token'];
    if (accessToken == null ||
        refreshToken is! String ||
        refreshToken.isEmpty) {
      throw const FormatException('Refresh response contains no token pair.');
    }
    return AuthRefreshModel(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: ((json['expiresIn'] ?? json['expires_in']) as num?)?.toInt(),
    );
  }

  final String accessToken;
  final String refreshToken;
  final int? expiresIn;
}
