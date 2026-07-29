import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/providers/core_providers.dart';
import 'package:look_atlas/features/shoots/data/data_sources/shoots_remote_data_source.dart';
import 'package:look_atlas/features/shoots/data/repositories/shoots_repository_impl.dart';
import 'package:look_atlas/features/shoots/domain/repositories/shoots_repository.dart';

final shootsRemoteDataSourceProvider = Provider<ShootsRemoteDataSource>(
  (ref) => ShootsRemoteDataSourceImpl(api: ref.watch(apiServiceProvider)),
);

final shootsRepositoryProvider = Provider<ShootsRepository>(
  (ref) => ShootsRepositoryImpl(ref.watch(shootsRemoteDataSourceProvider)),
);
