import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/providers/core_providers.dart';
import 'package:look_atlas/features/assistant/data/data_sources/assistant_remote_data_source.dart';
import 'package:look_atlas/features/assistant/data/repositories/assistant_repository_impl.dart';
import 'package:look_atlas/features/assistant/domain/repositories/assistant_repository.dart';

final assistantRemoteDataSourceProvider = Provider<AssistantRemoteDataSource>(
  (ref) => AssistantRemoteDataSourceImpl(ref.watch(apiServiceProvider)),
);

final assistantRepositoryProvider = Provider<AssistantRepository>(
  (ref) => AssistantRepositoryImpl(
    ref.watch(assistantRemoteDataSourceProvider),
  ),
);
