import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:look_atlas/features/dashboard/di/dashboard_providers.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:look_atlas/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:look_atlas/features/shoots/presentation/models/shoot_view_model.dart';

class DashboardOverviewState {
  const DashboardOverviewState({
    this.stats,
    this.shoots = const [],
    this.subscription,
    this.recentJobs = const [],
    this.isLoadingStats = true,
    this.isLoadingRecentJobs = true,
    this.isLoadingSubscription = true,
  });

  final DashboardStats? stats;
  final List<ShootViewModel> shoots;
  final DashboardSubscription? subscription;
  final List<DashboardRecentJob> recentJobs;
  final bool isLoadingStats;
  final bool isLoadingRecentJobs;
  final bool isLoadingSubscription;

  DashboardOverviewState copyWith({
    DashboardStats? stats,
    List<ShootViewModel>? shoots,
    DashboardSubscription? subscription,
    List<DashboardRecentJob>? recentJobs,
    bool? isLoadingStats,
    bool? isLoadingRecentJobs,
    bool? isLoadingSubscription,
  }) => DashboardOverviewState(
    stats: stats ?? this.stats,
    shoots: shoots ?? this.shoots,
    subscription: subscription ?? this.subscription,
    recentJobs: recentJobs ?? this.recentJobs,
    isLoadingStats: isLoadingStats ?? this.isLoadingStats,
    isLoadingRecentJobs: isLoadingRecentJobs ?? this.isLoadingRecentJobs,
    isLoadingSubscription: isLoadingSubscription ?? this.isLoadingSubscription,
  );
}

class DashboardOverviewController
    extends AsyncNotifier<DashboardOverviewState> {
  int _loadGeneration = 0;

  @override
  DashboardOverviewState build() {
    final generation = ++_loadGeneration;
    unawaited(Future<void>.microtask(() => _loadAll(generation)));
    return const DashboardOverviewState();
  }

  Future<void> refresh() => _loadAll(++_loadGeneration);

  Future<void> _loadAll(int generation) async {
    state = AsyncData(
      _current.copyWith(
        isLoadingStats: true,
        isLoadingRecentJobs: true,
        isLoadingSubscription: true,
      ),
    );
    final repository = ref.read(dashboardRepositoryProvider);
    await Future.wait([
      _loadStats(repository, generation),
      _loadRecentJobs(repository, generation),
      _loadSubscription(repository, generation),
    ]);
  }

  DashboardOverviewState get _current =>
      state.asData?.value ?? const DashboardOverviewState();

  Future<void> _loadStats(
    DashboardRepository repository,
    int generation,
  ) async {
    final result = await repository.getStats();
    if (generation != _loadGeneration) return;
    state = AsyncData(
      _current.copyWith(
        stats: result.valueOrNull,
        isLoadingStats: false,
      ),
    );
  }

  Future<void> _loadRecentJobs(
    DashboardRepository repository,
    int generation,
  ) async {
    final result = await repository.getRecentJobs();
    if (generation != _loadGeneration) return;
    final jobs = result.valueOrNull;
    state = AsyncData(
      _current.copyWith(
        shoots: jobs?.map(_toShoot).toList(growable: false),
        recentJobs: jobs,
        isLoadingRecentJobs: false,
      ),
    );
  }

  Future<void> _loadSubscription(
    DashboardRepository repository,
    int generation,
  ) async {
    final result = await repository.getSubscription();
    if (generation != _loadGeneration) return;
    state = AsyncData(
      _current.copyWith(
        subscription: result.valueOrNull,
        isLoadingSubscription: false,
      ),
    );
  }

  ShootViewModel _toShoot(DashboardRecentJob job) => ShootViewModel(
    id: job.id,
    name: job.name,
    status: job.status,
    renders: job.renders,
    date: job.date == null
        ? 'Date unavailable'
        : DateFormat.yMMMd().format(job.date!.toLocal()),
    productAsset: job.productThumbnail,
    modelAsset: job.modelThumbnail,
  );
}

final dashboardOverviewControllerProvider =
    AsyncNotifierProvider<DashboardOverviewController, DashboardOverviewState>(
      DashboardOverviewController.new,
    );
