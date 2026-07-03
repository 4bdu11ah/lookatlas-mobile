import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/auth/domain/repositories/auth_repository.dart';

/// Starts a password reset for the given email.
///
/// A single-purpose domain action over [AuthRepository] so the presentation
/// layer depends on one intent, not the whole repository surface.
class ResetPasswordUseCase {
  const ResetPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({required String email}) =>
      _repository.resetPassword(email: email);
}
