import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:look_atlas/core/config/app_config.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/logging/app_logger.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/auth/data/models/social_credential.dart';
import 'package:look_atlas/features/auth/domain/entities/social_provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps the Apple and Google sign-in SDKs behind one seam so the repository
/// never touches platform plugins directly (and tests can mock this).
///
/// Every method returns a [Result]: SDK exceptions are translated to typed
/// [AuthFailure]s here. A dismissed sheet becomes `userCancelled: true`, which
/// callers treat as a non-error.
abstract interface class SocialAuthDataSource {
  Future<Result<SocialCredential>> signInWithApple();

  Future<Result<SocialCredential>> signInWithGoogle();

  Future<Result<SocialSessionTokens>> refreshSession(String refreshToken);
}

class SocialAuthDataSourceImpl implements SocialAuthDataSource {
  static const _appleFailedMessage = 'Apple sign-in failed. Please try again.';
  static const _googleFailedMessage =
      'Google sign-in failed. Please try again.';
  static const _cancelledMessage = 'Sign-in was cancelled.';

  /// Set only after [GoogleSignIn.initialize] completes, so a failed attempt
  /// (e.g. bad configuration) is retried on the next tap.
  bool _googleInitialized = false;

  Future<SupabaseClient>? _supabaseInitialization;

  /// Note: Apple shares `email`, `givenName` and `familyName` only on the
  /// FIRST authorization for this app. Later sign-ins return null for all
  /// three, so persist them the first time (see Apple's documentation).
  @override
  Future<Result<SocialCredential>> signInWithApple() async {
    if (!AppConfig.isAppleSignInSupported) {
      return const Result.err(
        AuthFailure('Sign in with Apple is only available on Apple devices.'),
      );
    }
    if (!AppConfig.hasSupabaseAuth) return _unconfiguredFailure();
    try {
      final supabase = await _supabaseClient();
      final rawNonce = supabase.auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
      final idToken = credential.identityToken;
      if (idToken == null) {
        return const Result.err(
          AuthFailure('Apple did not return an ID token.'),
        );
      }
      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
      return _credentialFromResponse(response, SocialProvider.apple);
    } on SignInWithAppleAuthorizationException catch (error, stackTrace) {
      if (error.code == AuthorizationErrorCode.canceled) {
        return Result.err(
          AuthFailure(
            _cancelledMessage,
            userCancelled: true,
            cause: error,
            stackTrace: stackTrace,
          ),
        );
      }
      return Result.err(
        AuthFailure(_appleFailedMessage, cause: error, stackTrace: stackTrace),
      );
    } on AuthException catch (error, stackTrace) {
      return Result.err(
        AuthFailure(error.message, cause: error, stackTrace: stackTrace),
      );
    } on Exception catch (error, stackTrace) {
      // Missing capability/entitlement, unsupported OS version, etc.
      return Result.err(
        AuthFailure(_appleFailedMessage, cause: error, stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<Result<SocialCredential>> signInWithGoogle() async {
    // Checked BEFORE touching the SDK: with no client ID configured the
    // native layer would throw an opaque platform error (or crash on iOS).
    if (!AppConfig.hasGoogleAuth) {
      return _googleUnconfiguredFailure();
    }
    if (!AppConfig.hasSupabaseAuth) {
      return _unconfiguredFailure();
    }
    var stage = 'supabase_initialization';
    try {
      final supabase = await _supabaseClient();
      final signIn = GoogleSignIn.instance;
      if (!_googleInitialized) {
        stage = 'google_sdk_initialization';
        await signIn.initialize(
          clientId: AppConfig.googleIosClientId.isEmpty
              ? null
              : AppConfig.googleIosClientId,
          serverClientId: AppConfig.googleWebClientId,
        );
        _googleInitialized = true;
      }
      if (!signIn.supportsAuthenticate()) {
        AppLogger.error(
          'Google sign-in failed at platform_support. '
          'supportsAuthenticate=false',
        );
        return const Result.err(
          AuthFailure('Google sign-in is not available on this platform.'),
        );
      }
      stage = 'account_authentication';
      final account = await signIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        AppLogger.error(
          'Google sign-in failed at id_token. idTokenPresent=false',
        );
        return const Result.err(
          AuthFailure('Google did not return an ID token.'),
        );
      }
      stage = 'scope_authorization';
      final authorization = await account.authorizationClient
          .authorizationForScopes(const <String>[
            'https://www.googleapis.com/auth/userinfo.email',
          ]);
      stage = 'supabase_token_exchange';
      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: authorization?.accessToken,
      );
      return _credentialFromResponse(response, SocialProvider.google);
    } on GoogleSignInException catch (error, stackTrace) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return Result.err(
          AuthFailure(
            _cancelledMessage,
            userCancelled: true,
            cause: error,
            stackTrace: stackTrace,
          ),
        );
      }
      AppLogger.error(
        'Google sign-in failed at $stage. '
        'sdkCode=${error.code.name}; '
        'description=${_safeDiagnostic(error.description)}',
        stackTrace: stackTrace,
      );
      return Result.err(
        AuthFailure(_googleFailedMessage, cause: error, stackTrace: stackTrace),
      );
    } on AuthException catch (error, stackTrace) {
      AppLogger.error(
        'Google sign-in failed at $stage. '
        'supabase=${_safeDiagnostic(error.message)}',
        stackTrace: stackTrace,
      );
      return Result.err(
        AuthFailure(error.message, cause: error, stackTrace: stackTrace),
      );
    } on Exception catch (error, stackTrace) {
      AppLogger.error(
        'Google sign-in failed at $stage. '
        'exception=${_safeDiagnostic(error)}',
        stackTrace: stackTrace,
      );
      return Result.err(
        AuthFailure(_googleFailedMessage, cause: error, stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<Result<SocialSessionTokens>> refreshSession(
    String refreshToken,
  ) async {
    if (!AppConfig.hasSupabaseAuth) {
      return const Result.err(
        AuthFailure('Supabase social sign-in is not configured yet.'),
      );
    }
    try {
      final supabase = await _supabaseClient();
      final response = await supabase.auth.refreshSession(refreshToken);
      return _tokensFromResponse(response);
    } on AuthException catch (error, stackTrace) {
      return Result.err(
        AuthFailure(error.message, cause: error, stackTrace: stackTrace),
      );
    } on Exception catch (error, stackTrace) {
      return Result.err(
        AuthFailure(
          'Your social session has expired.',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<SupabaseClient> _supabaseClient() {
    final existing = _supabaseInitialization;
    if (existing != null) return existing;

    final initialization = _initializeSupabase();
    _supabaseInitialization = initialization;
    return initialization;
  }

  Future<SupabaseClient> _initializeSupabase() async {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabasePublishableKey,
        authOptions: const FlutterAuthClientOptions(
          autoRefreshToken: false,
          localStorage: EmptyLocalStorage(),
        ),
      );
      return Supabase.instance.client;
    } on Object {
      _supabaseInitialization = null;
      rethrow;
    }
  }

  Result<SocialCredential> _credentialFromResponse(
    AuthResponse response,
    SocialProvider provider,
  ) {
    final session = response.session;
    final user = response.user;
    final refreshToken = session?.refreshToken;
    if (session == null ||
        user == null ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      return const Result.err(
        AuthFailure('Supabase did not return a complete session.'),
      );
    }
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    return Result.ok(
      SocialCredential(
        provider: provider,
        id: user.id,
        email: user.email,
        displayName:
            metadata['full_name'] as String? ?? metadata['name'] as String?,
        photoUrl:
            metadata['avatar_url'] as String? ?? metadata['picture'] as String?,
        accessToken: session.accessToken,
        refreshToken: refreshToken,
      ),
    );
  }

  Result<SocialSessionTokens> _tokensFromResponse(AuthResponse response) {
    final session = response.session;
    final refreshToken = session?.refreshToken;
    if (session == null || refreshToken == null || refreshToken.isEmpty) {
      return const Result.err(
        AuthFailure('Supabase did not return refreshed session tokens.'),
      );
    }
    return Result.ok(
      SocialSessionTokens(
        accessToken: session.accessToken,
        refreshToken: refreshToken,
      ),
    );
  }

  Result<SocialCredential> _unconfiguredFailure() => const Result.err(
    AuthFailure('Supabase social sign-in is not configured yet.'),
  );

  Result<SocialCredential> _googleUnconfiguredFailure() => const Result.err(
    AuthFailure('Google sign-in is not configured yet.'),
  );

  String _safeDiagnostic(Object? value) {
    if (value == null) return 'none';
    var text = value.toString();
    text = text.replaceAll(
      RegExp(r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}', caseSensitive: false),
      '[email-redacted]',
    );
    text = text.replaceAll(
      RegExp(r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'),
      '[token-redacted]',
    );
    return text.length <= 500 ? text : '${text.substring(0, 500)}…';
  }
}
