import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/providers/core_providers.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/dashboard/data/data_sources/dashboard_remote_data_source.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:look_atlas/features/dashboard/domain/repositories/dashboard_repository.dart';

final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>(
  (ref) => DashboardRemoteDataSourceImpl(
    api: ref.watch(apiServiceProvider),
  ),
);

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => _DashboardRepository(
    ref.watch(dashboardRemoteDataSourceProvider),
  ),
);

final FutureProvider<DashboardStats> dashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) async {
      final result = await ref.watch(dashboardRepositoryProvider).getStats();
      return result.fold((stats) => stats, (failure) => throw failure);
    });

class _DashboardRepository implements DashboardRepository {
  const _DashboardRepository(this._remote);

  final DashboardRemoteDataSource _remote;

  @override
  Future<Result<DashboardStats>> getStats() => _remote.getStats();

  @override
  Future<Result<List<DashboardRecentJob>>> getRecentJobs() =>
      _remote.getRecentJobs();

  @override
  Future<Result<DashboardSubscription>> getSubscription() =>
      _remote.getSubscription();
}
