import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/auth/presentation/controllers/auth_controller.dart';

final authOperationProvider = Provider<AsyncValue<void>>(
  (ref) => ref.watch(authControllerProvider),
);

final authSignOutProvider = Provider<Future<void> Function()>(
  (ref) => ref.read(authControllerProvider.notifier).signOut,
);
