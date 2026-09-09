import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/account_deletion/domain/use_cases/delete_account_use_case.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';

final deleteAccountUseCaseProvider = Provider<DeleteAccountUseCase>(
  (ref) => DeleteAccountUseCase(ref.watch(authRepositoryProvider)),
);
