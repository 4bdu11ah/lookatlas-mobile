/// Single source of truth for auth input rules.
///
/// The form validators ([validateEmail], [validatePassword]) are shaped for
/// `TextFormField.validator`; the boolean helpers ([isValidEmail],
/// [isValidPassword]) serve repositories and use cases. Every screen and
/// data-layer check goes through this class so the rules cannot drift.
abstract final class AuthValidators {
  /// Minimum accepted password length.
  static const int minPasswordLength = 8;

  /// Pragmatic email shape check: one `@` with a dotted domain. Full RFC 5322
  /// validation is intentionally avoided; the backend is the final arbiter.
  static final RegExp _emailPattern = RegExp(
    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
  );

  /// Whether [email] looks like a valid address.
  static bool isValidEmail(String email) =>
      _emailPattern.hasMatch(email.trim());

  /// Whether [password] satisfies the minimum length rule.
  static bool isValidPassword(String password) =>
      password.length >= minPasswordLength;

  /// Form-field validator for email inputs. Returns the error to display, or
  /// null when valid.
  static String? validateEmail(String? value) =>
      (value == null || !isValidEmail(value))
      ? 'Please enter a valid email address.'
      : null;

  /// Form-field validator for password inputs. Returns the error to display,
  /// or null when valid.
  static String? validatePassword(String? value) =>
      (value == null || !isValidPassword(value))
      ? 'Password must be at least $minPasswordLength characters.'
      : null;

  /// Form-field validator for the company name at sign-up. Returns the error
  /// to display, or null when valid.
  static String? validateCompanyName(String? value) =>
      (value == null || value.trim().isEmpty)
      ? 'Please enter your company name.'
      : null;
}
