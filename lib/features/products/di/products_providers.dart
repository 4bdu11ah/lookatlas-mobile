import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/providers/core_providers.dart';
import 'package:look_atlas/features/products/data/data_sources/products_remote_data_source.dart';
import 'package:look_atlas/features/products/data/repositories/products_repository_impl.dart';
import 'package:look_atlas/features/products/domain/repositories/products_repository.dart';

final productsRemoteDataSourceProvider = Provider<ProductsRemoteDataSource>(
  (ref) => ProductsRemoteDataSourceImpl(
    api: ref.watch(apiServiceProvider),
    publicApi: ref.watch(publicApiServiceProvider),
  ),
);

final productsRepositoryProvider = Provider<ProductsRepository>(
  (ref) => ProductsRepositoryImpl(
    ref.watch(productsRemoteDataSourceProvider),
  ),
);
