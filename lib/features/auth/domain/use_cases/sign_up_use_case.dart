import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/auth/domain/entities/register_attribution.dart';
import 'package:look_atlas/features/auth/domain/repositories/auth_repository.dart';
import 'package:look_atlas/features/auth/domain/validators/auth_validators.dart';

/// Registers a new user with email + password.
///
/// A single-purpose domain action over [AuthRepository] so the presentation
/// layer depends on one intent, not the whole repository surface.
class SignUpUseCase {
  const SignUpUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AppUser>> call({
    required String email,
    required String password,
    required String companyName,
    RegisterAttribution? attribution,
    String? captchaToken,
  }) {
    final emailError = AuthValidators.validateEmail(email);
    if (emailError != null) return Future.value(Err(AuthFailure(emailError)));
    final passwordError = AuthValidators.validatePassword(password);
    if (passwordError != null) {
      return Future.value(Err(AuthFailure(passwordError)));
    }
    final companyError = AuthValidators.validateCompanyName(companyName);
    if (companyError != null) {
      return Future.value(Err(AuthFailure(companyError)));
    }
    return _repository.signUpWithEmail(
      email: email.trim(),
      password: password,
      companyName: companyName.trim(),
      attribution: attribution,
      captchaToken: captchaToken,
    );
  }
}
