import 'package:google_sign_in/google_sign_in.dart';
import 'package:look_atlas/core/config/app_config.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/auth/data/models/social_credential.dart';
import 'package:look_atlas/features/auth/domain/entities/social_provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Wraps the Apple and Google sign-in SDKs behind one seam so the repository
/// never touches platform plugins directly (and tests can mock this).
///
/// Every method returns a [Result]: SDK exceptions are translated to typed
/// [AuthFailure]s here. A dismissed sheet becomes `userCancelled: true`, which
/// callers treat as a non-error.
abstract interface class SocialAuthDataSource {
  Future<Result<SocialCredential>> signInWithApple();

  Future<Result<SocialCredential>> signInWithGoogle();
}

class SocialAuthDataSourceImpl implements SocialAuthDataSource {
  static const _appleFailedMessage = 'Apple sign-in failed. Please try again.';
  static const _googleFailedMessage =
      'Google sign-in failed. Please try again.';
  static const _cancelledMessage = 'Sign-in was cancelled.';

  /// Set only after [GoogleSignIn.initialize] completes, so a failed attempt
  /// (e.g. bad configuration) is retried on the next tap.
  bool _googleInitialized = false;

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
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final userIdentifier = credential.userIdentifier;
      if (userIdentifier == null) {
        return const Result.err(AuthFailure(_appleFailedMessage));
      }
      final displayName = [
        credential.givenName,
        credential.familyName,
      ].whereType<String>().join(' ');
      return Result.ok(
        SocialCredential(
          provider: SocialProvider.apple,
          id: userIdentifier,
          email: credential.email,
          displayName: displayName.isEmpty ? null : displayName,
          idToken: credential.identityToken,
        ),
      );
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
      return const Result.err(
        AuthFailure('Google sign-in is not configured yet.'),
      );
    }
    try {
      final signIn = GoogleSignIn.instance;
      if (!_googleInitialized) {
        await signIn.initialize(
          clientId: AppConfig.googleIosClientId.isEmpty
              ? null
              : AppConfig.googleIosClientId,
          serverClientId: AppConfig.googleWebClientId,
        );
        _googleInitialized = true;
      }
      if (!signIn.supportsAuthenticate()) {
        return const Result.err(
          AuthFailure('Google sign-in is not available on this platform.'),
        );
      }
      final account = await signIn.authenticate();
      return Result.ok(
        SocialCredential(
          provider: SocialProvider.google,
          id: account.id,
          email: account.email,
          displayName: account.displayName,
          photoUrl: account.photoUrl,
          idToken: account.authentication.idToken,
        ),
      );
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
      return Result.err(
        AuthFailure(_googleFailedMessage, cause: error, stackTrace: stackTrace),
      );
    } on Exception catch (error, stackTrace) {
      return Result.err(
        AuthFailure(_googleFailedMessage, cause: error, stackTrace: stackTrace),
      );
    }
  }
}
