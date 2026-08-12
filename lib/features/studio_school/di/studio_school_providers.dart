import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/providers/core_providers.dart';
import 'package:look_atlas/features/studio_school/data/studio_school_api.dart';
import 'package:look_atlas/features/studio_school/data/welcome_repository_impl.dart';
import 'package:look_atlas/features/studio_school/domain/welcome_repository.dart';

final studioSchoolApiProvider = Provider<StudioSchoolApi>(
  (ref) => StudioSchoolApiImpl(ref.watch(apiServiceProvider)),
);

final welcomeRepositoryProvider = Provider<WelcomeRepository>(
  (ref) => WelcomeRepositoryImpl(
    remote: ref.watch(studioSchoolApiProvider),
    store: ref.watch(keyValueStoreProvider),
  ),
);
