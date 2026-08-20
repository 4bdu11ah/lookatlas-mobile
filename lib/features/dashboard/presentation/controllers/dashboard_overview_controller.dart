part of '../screens/dashboard_screen.dart';

class _DashboardOverviewState {
  const _DashboardOverviewState({
    this.stats,
    this.shoots = const [],
    this.subscription,
    this.recentJobs = const [],
    this.isLoadingStats = true,
    this.isLoadingRecentJobs = true,
    this.isLoadingSubscription = true,
  });

  final DashboardStats? stats;
  final List<_Shoot> shoots;
  final DashboardSubscription? subscription;
  final List<DashboardRecentJob> recentJobs;
  final bool isLoadingStats;
  final bool isLoadingRecentJobs;
  final bool isLoadingSubscription;

  _DashboardOverviewState copyWith({
    DashboardStats? stats,
    List<_Shoot>? shoots,
    DashboardSubscription? subscription,
    List<DashboardRecentJob>? recentJobs,
    bool? isLoadingStats,
    bool? isLoadingRecentJobs,
    bool? isLoadingSubscription,
  }) => _DashboardOverviewState(
    stats: stats ?? this.stats,
    shoots: shoots ?? this.shoots,
    subscription: subscription ?? this.subscription,
    recentJobs: recentJobs ?? this.recentJobs,
    isLoadingStats: isLoadingStats ?? this.isLoadingStats,
    isLoadingRecentJobs: isLoadingRecentJobs ?? this.isLoadingRecentJobs,
    isLoadingSubscription: isLoadingSubscription ?? this.isLoadingSubscription,
  );
}

class _DashboardOverviewController
    extends AsyncNotifier<_DashboardOverviewState> {
  int _loadGeneration = 0;

  @override
  _DashboardOverviewState build() {
    final generation = ++_loadGeneration;
    unawaited(Future<void>.microtask(() => _loadAll(generation)));
    return const _DashboardOverviewState();
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

  _DashboardOverviewState get _current =>
      state.asData?.value ?? const _DashboardOverviewState();

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
