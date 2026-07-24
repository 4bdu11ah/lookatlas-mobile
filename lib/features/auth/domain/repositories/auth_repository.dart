import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/auth/domain/entities/register_attribution.dart';

/// Auth contract. The presentation layer depends only on this interface, so a
/// real backend (Supabase, custom API) can be swapped in by writing
/// a new implementation without touching the UI.
abstract interface class AuthRepository {
  /// Emits the current user, or null when signed out.
  Stream<AppUser?> authStateChanges();

  AppUser? get currentUser;

  /// Restores any persisted session. Call once at startup before the first
  /// frame so the router can redirect without a flash of the sign-in screen.
  Future<void> restore();

  /// Revalidates the current bearer session through `GET /auth/verify`.
  Future<Result<AppUser>> verifySession();

  Future<Result<AppUser>> signInWithEmail({
    required String email,
    required String password,
    String? captchaToken,
  });

  Future<Result<AppUser>> signUpWithEmail({
    required String email,
    required String password,
    required String companyName,
    RegisterAttribution? attribution,
  });

  /// Signs in with the user's Apple ID (Sign in with Apple).
  ///
  /// A dismissed sheet resolves to an `AuthFailure` with
  /// `userCancelled: true`, which callers treat as a non-error.
  Future<Result<AppUser>> signInWithApple();

  /// Signs in with the user's Google account.
  ///
  /// A dismissed sheet resolves to an `AuthFailure` with
  /// `userCancelled: true`, which callers treat as a non-error.
  Future<Result<AppUser>> signInWithGoogle();

  /// Starts a password reset for [email] (e.g. sends a reset link).
  Future<Result<void>> resetPassword({required String email});

  Future<Result<void>> signOut();

  /// Exchanges the stored refresh token for a new access token and persists
  /// it. Returns the new token, or null when the session cannot be refreshed
  /// (no refresh token, or the backend rejected it). Wired into the network
  /// layer's 401 interceptor via `tokenRefresherProvider`.
  Future<String?> refreshSession();

  /// Clears the local session after an unrecoverable 401 (refresh failed).
  /// Unlike [signOut] it never calls the backend — the session is already
  /// dead — and broadcasting the signed-out state routes the user to sign-in.
  Future<void> handleSessionExpired();
}
