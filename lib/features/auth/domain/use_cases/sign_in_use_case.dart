import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/auth/domain/repositories/auth_repository.dart';
import 'package:look_atlas/features/auth/domain/validators/auth_validators.dart';

/// Signs an existing user in with email + password.
///
/// A single-purpose domain action over [AuthRepository] so the presentation
/// layer depends on one intent, not the whole repository surface.
class SignInUseCase {
  const SignInUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AppUser>> call({
    required String email,
    required String password,
    String? captchaToken,
  }) {
    final invalid = _validateCredentials(email, password);
    if (invalid != null) return Future.value(Err(invalid));
    return _repository.signInWithEmail(
      email: email.trim(),
      password: password,
      captchaToken: captchaToken,
    );
  }

  AuthFailure? _validateCredentials(String email, String password) {
    final emailError = AuthValidators.validateEmail(email);
    if (emailError != null) return AuthFailure(emailError);
    final passwordError = AuthValidators.validatePassword(password);
    return passwordError == null ? null : AuthFailure(passwordError);
  }
}
