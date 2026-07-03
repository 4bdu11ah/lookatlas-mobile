/// Central registry of every API endpoint path the app calls.
///
/// Data sources reference these constants instead of inlining path literals,
/// so the full API surface is visible in one place and a backend route change
/// is a one-line edit. Paths are relative — the base URL comes from
/// `AppConfig` (`apiBaseUrl` for the Look Atlas backend, `aiBaseUrl` for the
/// AI proxy).
abstract final class ApiEndpoints {
  // --- Auth (Look Atlas backend, see the Postman collection) --------------
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authLogout = '/auth/logout';
  static const String authRefresh = '/auth/refresh';
  static const String authForgotPassword = '/auth/forgot-password';

  /// Sets a new password with a recovery token from the reset email. Unused
  /// by the app today: the email's link targets the web app.
  static const String authResetPassword = '/auth/reset-password';

  // --- AI (Anthropic-compatible API or backend proxy) ---------------------
  static const String aiMessages = '/v1/messages';
}
