import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/providers/core_providers.dart';
import 'package:look_atlas/features/studio_school/data/data_sources/studio_school_api.dart';
import 'package:look_atlas/features/studio_school/data/repositories/welcome_repository_impl.dart';
import 'package:look_atlas/features/studio_school/domain/entities/welcome_lesson.dart';
import 'package:look_atlas/features/studio_school/domain/repositories/welcome_repository.dart';
import 'package:look_atlas/features/studio_school/domain/use_cases/complete_welcome_profile_use_case.dart';
import 'package:look_atlas/features/studio_school/presentation/controllers/studio_school_controller.dart';
import 'package:look_atlas/features/studio_school/presentation/controllers/studio_school_state.dart';

final studioSchoolApiProvider = Provider<StudioSchoolApi>(
  (ref) => StudioSchoolApiImpl(ref.watch(apiServiceProvider)),
);

final welcomeRepositoryProvider = Provider<WelcomeRepository>(
  (ref) => WelcomeRepositoryImpl(
    remote: ref.watch(studioSchoolApiProvider),
    store: ref.watch(keyValueStoreProvider),
  ),
);

final completeWelcomeProfileUseCaseProvider =
    Provider<CompleteWelcomeProfileUseCase>(
      (ref) => CompleteWelcomeProfileUseCase(
        ref.watch(welcomeRepositoryProvider),
      ),
    );

/// Public read boundary for features composing welcome progress.
final studioSchoolWelcomeProvider = Provider<WelcomeState?>((ref) {
  return switch (ref.watch(studioSchoolControllerProvider)) {
    SchoolReady(:final welcome) ||
    SchoolOfflineCached(:final welcome) => welcome,
    _ => null,
  };
});

/// Public command boundary for cross-feature refresh coordination.
final refreshStudioSchoolProvider = Provider<Future<void> Function()>(
  (ref) => ref.read(studioSchoolControllerProvider.notifier).refresh,
);
