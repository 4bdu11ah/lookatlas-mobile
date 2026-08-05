import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/providers/core_providers.dart';
import 'package:look_atlas/features/workshop/data/data_sources/workshop_remote_data_source.dart';
import 'package:look_atlas/features/workshop/data/repositories/workshop_repository_impl.dart';
import 'package:look_atlas/features/workshop/domain/repositories/workshop_repository.dart';

final workshopRemoteDataSourceProvider = Provider<WorkshopRemoteDataSource>(
  (ref) => WorkshopRemoteDataSourceImpl(
    api: ref.watch(apiServiceProvider),
    publicApi: ref.watch(publicApiServiceProvider),
  ),
);

final workshopRepositoryProvider = Provider<WorkshopRepository>(
  (ref) => WorkshopRepositoryImpl(
    ref.watch(workshopRemoteDataSourceProvider),
  ),
);
