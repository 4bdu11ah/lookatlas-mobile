import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/auth/domain/repositories/auth_repository.dart';

/// Ends the current session.
///
/// A single-purpose domain action over [AuthRepository]. Presentation-side
/// side effects (analytics reset, crash-reporter user clear) stay in the
/// controller, not here.
class SignOutUseCase {
  const SignOutUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call() => _repository.signOut();
}
