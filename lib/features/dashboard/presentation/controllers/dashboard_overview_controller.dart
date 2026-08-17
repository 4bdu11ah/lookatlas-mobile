part of '../screens/dashboard_screen.dart';

class _DashboardOverviewState {
  const _DashboardOverviewState({
    required this.stats,
    required this.shoots,
    required this.subscription,
    required this.recentJobs,
  });

  final DashboardStats stats;
  final List<_Shoot> shoots;
  final DashboardSubscription subscription;
  final List<DashboardRecentJob> recentJobs;
}

class _DashboardOverviewController
    extends AsyncNotifier<_DashboardOverviewState> {
  @override
  Future<_DashboardOverviewState> build() => _load();

  Future<void> refresh() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    try {
      state = AsyncData(await _load());
    } on Object catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<_DashboardOverviewState> _load() async {
    final repository = ref.read(dashboardRepositoryProvider);
    final (stats, recentJobs, subscription) = await (
      repository.getStats(),
      repository.getRecentJobs(),
      repository.getSubscription(),
    ).wait;
    final failure =
        stats.failureOrNull ??
        recentJobs.failureOrNull ??
        subscription.failureOrNull;
    if (failure != null) throw failure;
    return _DashboardOverviewState(
      stats: stats.valueOrNull!,
      shoots: recentJobs.valueOrNull!.map(_toShoot).toList(growable: false),
      subscription: subscription.valueOrNull!,
      recentJobs: recentJobs.valueOrNull!,
    );
  }

  _Shoot _toShoot(DashboardRecentJob job) => _Shoot(
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

final _dashboardOverviewControllerProvider =
    AsyncNotifierProvider<
      _DashboardOverviewController,
      _DashboardOverviewState
    >(
      _DashboardOverviewController.new,
    );
