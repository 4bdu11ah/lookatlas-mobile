import 'dart:async';

import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/logging/app_logger.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/core/storage/auth_token_cache.dart';
import 'package:look_atlas/core/storage/secure_storage.dart';
import 'package:look_atlas/features/auth/data/data_sources/auth_local_data_source.dart';
import 'package:look_atlas/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:look_atlas/features/auth/data/data_sources/social_auth_data_source.dart';
import 'package:look_atlas/features/auth/data/models/app_user_model.dart';
import 'package:look_atlas/features/auth/data/models/auth_session_model.dart';
import 'package:look_atlas/features/auth/data/models/social_credential.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/auth/domain/entities/register_attribution.dart';
import 'package:look_atlas/features/auth/domain/repositories/auth_repository.dart';
import 'package:look_atlas/features/auth/domain/validators/auth_validators.dart';

/// [AuthRepository] backed by the Look Atlas API (`/auth/*` endpoints).
///
/// Owns the whole session lifecycle: the user profile is cached via
/// [AuthLocalDataSource], the access token lives in [AuthTokenCache] (which
/// the network layer reads per request), and the refresh token sits in
/// [SecureStorage] until [refreshSession] exchanges it.
///
/// Apple/Google sign-in still authenticates with the provider SDKs only — the
/// backend has no social token-exchange endpoint yet. Those sessions are
/// app-local: the provider's identity token is used as the bearer token so it
/// can be verified server-side once an endpoint exists.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    this._remote,
    this._local,
    this._tokenCache,
    this._secureStorage,
    this._socialAuth,
  );

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final SocialAuthDataSource _socialAuth;
  final AuthTokenCache _tokenCache;
  final SecureStorage _secureStorage;

  /// Placeholder bearer for social sessions whose provider returned no
  /// identity token; real API calls will 401 until a backend exchange exists.
  static const _socialFallbackToken = 'social-session-token';

  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  Future<void> restore() async {
    _currentUser = await _local.readUser();
    _controller.add(_currentUser);
  }

  @override
  Future<Result<AppUser>> signInWithEmail({
    required String email,
    required String password,
    String? captchaToken,
  }) async {
    final invalid = _validateCredentials(email, password);
    if (invalid != null) return Err(invalid);
    final result = await _remote.login(
      email: email.trim(),
      password: password,
      captchaToken: captchaToken,
    );
    return _completeSession(result);
  }

  @override
  Future<Result<AppUser>> signUpWithEmail({
    required String email,
    required String password,
    required String companyName,
    RegisterAttribution? attribution,
  }) async {
    final invalid = _validateCredentials(email, password);
    if (invalid != null) return Err(invalid);
    final companyError = AuthValidators.validateCompanyName(companyName);
    if (companyError != null) return Err(AuthFailure(companyError));
    final result = await _remote.register(
      companyName: companyName.trim(),
      email: email.trim(),
      password: password,
      attribution: attribution,
    );
    return _completeSession(result);
  }

  @override
  Future<Result<AppUser>> signInWithApple() async =>
      _completeSocialSignIn(await _socialAuth.signInWithApple());

  @override
  Future<Result<AppUser>> signInWithGoogle() async =>
      _completeSocialSignIn(await _socialAuth.signInWithGoogle());

  /// `POST /auth/forgot-password`. The backend intentionally answers 200
  /// whether or not the address exists, so success only means "email sent if
  /// the account exists".
  @override
  Future<Result<void>> resetPassword({required String email}) async {
    final emailError = AuthValidators.validateEmail(email);
    if (emailError != null) return Err(AuthFailure(emailError));
    return _remote.forgotPassword(email.trim());
  }

  /// Signs out, mirroring the web client: with no access token the backend
  /// call is skipped entirely; otherwise `POST /auth/logout` runs best-effort
  /// (a failure is only logged — the user asked to leave, so a dead network
  /// must not trap them in the session) and the local session is always
  /// cleared.
  @override
  Future<Result<void>> signOut() async {
    final accessToken = await _tokenCache.get();
    if (accessToken != null && accessToken.isNotEmpty) {
      final result = await _remote.logout();
      if (result case Err(:final failure)) {
        AppLogger.warning('Logout error: ${failure.message}');
      }
    }
    await _clearSession();
    return const Result.ok(null);
  }

  @override
  Future<String?> refreshSession() async {
    final refreshToken = await _secureStorage.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return null;
    final result = await _remote.refresh(refreshToken);
    // A failure (including a rejected/expired refresh token) reports "no
    // token"; the caller reacts via handleSessionExpired.
    final token = result.valueOrNull;
    if (token == null) return null;
    await _tokenCache.set(token);
    return token;
  }

  @override
  Future<void> handleSessionExpired() => _clearSession();

  /// Persists a fresh session from login/register and broadcasts it.
  Future<Result<AppUser>> _completeSession(
    Result<AuthSessionModel> result,
  ) async {
    switch (result) {
      case Err(:final failure):
        return Result.err(failure);
      case Ok(value: final session):
        await _local.cacheUser(session.user);
        await _tokenCache.set(session.accessToken);
        final refreshToken = session.refreshToken;
        if (refreshToken != null) {
          await _secureStorage.setRefreshToken(refreshToken);
        }
        _currentUser = session.user;
        _controller.add(session.user);
        return Result.ok(session.user);
    }
  }

  /// Persists a social session. Failures (including `userCancelled` ones)
  /// pass through untouched so the presentation layer can tell a dismissed
  /// sheet from a real error.
  Future<Result<AppUser>> _completeSocialSignIn(
    Result<SocialCredential> result,
  ) async {
    switch (result) {
      case Err(:final failure):
        return Result.err(failure);
      case Ok(value: final credential):
        final user = AppUserModel(
          id: '${credential.provider.name}-${credential.id}',
          // Apple omits the email after the first authorization; a backend
          // exchange endpoint would look the account up by provider id.
          email: credential.email ?? '',
          displayName: credential.displayName,
          photoUrl: credential.photoUrl,
        );
        await _local.cacheUser(user);
        await _tokenCache.set(credential.idToken ?? _socialFallbackToken);
        _currentUser = user;
        _controller.add(user);
        return Result.ok(user);
    }
  }

  /// Client-side pre-checks so obviously bad input never leaves the device.
  Failure? _validateCredentials(String email, String password) {
    final emailError = AuthValidators.validateEmail(email);
    if (emailError != null) return AuthFailure(emailError);
    final passwordError = AuthValidators.validatePassword(password);
    if (passwordError != null) return AuthFailure(passwordError);
    return null;
  }

  /// Clears every trace of the session (profile, both tokens) and broadcasts
  /// the signed-out state.
  Future<void> _clearSession() async {
    await _local.clear();
    await _tokenCache.set(null);
    _tokenCache.invalidate();
    _currentUser = null;
    _controller.add(null);
  }

  void dispose() => _controller.close();
}
