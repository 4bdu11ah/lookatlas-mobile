import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/auth/domain/entities/register_attribution.dart';
import 'package:look_atlas/features/auth/domain/repositories/auth_repository.dart';

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
  }) => _repository.signUpWithEmail(
    email: email,
    password: password,
    companyName: companyName,
    attribution: attribution,
  );
}
