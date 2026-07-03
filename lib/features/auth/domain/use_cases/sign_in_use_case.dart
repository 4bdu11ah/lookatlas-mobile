import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/auth/domain/repositories/auth_repository.dart';

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
  }) => _repository.signInWithEmail(
    email: email,
    password: password,
    captchaToken: captchaToken,
  );
}
