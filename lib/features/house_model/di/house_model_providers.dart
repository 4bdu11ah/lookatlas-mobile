import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/providers/core_providers.dart';
import 'package:look_atlas/features/house_model/data/data_sources/house_models_remote_data_source.dart';
import 'package:look_atlas/features/house_model/data/repositories/house_models_repository_impl.dart';
import 'package:look_atlas/features/house_model/domain/repositories/house_models_repository.dart';

final houseModelsRemoteDataSourceProvider =
    Provider<HouseModelsRemoteDataSource>(
      (ref) => HouseModelsRemoteDataSourceImpl(
        api: ref.watch(apiServiceProvider),
      ),
    );

final houseModelsRepositoryProvider = Provider<HouseModelsRepository>(
  (ref) => HouseModelsRepositoryImpl(
    ref.watch(houseModelsRemoteDataSourceProvider),
  ),
);
