import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/auth/domain/repositories/auth_repository.dart';
import 'package:look_atlas/features/auth/domain/validators/auth_validators.dart';

/// Starts a password reset for the given email.
///
/// A single-purpose domain action over [AuthRepository] so the presentation
/// layer depends on one intent, not the whole repository surface.
class ResetPasswordUseCase {
  const ResetPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({required String email}) {
    final error = AuthValidators.validateEmail(email);
    if (error != null) return Future.value(Err(AuthFailure(error)));
    return _repository.resetPassword(email: email.trim());
  }
}
