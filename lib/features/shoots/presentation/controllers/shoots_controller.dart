part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _ShootsScreenState {
  const _ShootsScreenState({
    this.shoots = const [],
    this.query = '',
    this.status = 'all',
    this.page = 1,
    this.totalPages = 1,
    this.isLoading = true,
    this.isRefreshing = false,
    this.failure,
  });

  final List<_Shoot> shoots;
  final String query;
  final String status;
  final int page;
  final int totalPages;
  final bool isLoading;
  final bool isRefreshing;
  final Failure? failure;

  _ShootsScreenState copyWith({
    List<_Shoot>? shoots,
    String? query,
    String? status,
    int? page,
    int? totalPages,
    bool? isLoading,
    bool? isRefreshing,
    Failure? failure,
    bool clearFailure = false,
  }) => _ShootsScreenState(
    shoots: shoots ?? this.shoots,
    query: query ?? this.query,
    status: status ?? this.status,
    page: page ?? this.page,
    totalPages: totalPages ?? this.totalPages,
    isLoading: isLoading ?? this.isLoading,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}

class _ShootsController extends Notifier<_ShootsScreenState> {
  Timer? _pollTimer;
  Timer? _searchTimer;
  bool _requestInFlight = false;
  bool _disposed = false;

  ShootsRepository get _repository => ref.read(shootsRepositoryProvider);

  @override
  _ShootsScreenState build() {
    ref.onDispose(() {
      _disposed = true;
      _pollTimer?.cancel();
      _searchTimer?.cancel();
    });
    unawaited(Future<void>.microtask(load));
    return const _ShootsScreenState();
  }

  Future<void> load({bool silent = false}) async {
    if (_requestInFlight) return;
    _requestInFlight = true;
    if (!silent) {
      state = state.copyWith(
        isLoading: state.shoots.isEmpty,
        isRefreshing: state.shoots.isNotEmpty,
        clearFailure: true,
      );
    }
    final result = await _repository.getJobs(
      status: state.status == 'all' ? '' : state.status,
      page: state.page,
      search: state.query.trim(),
    );
    if (_disposed) return;
    _requestInFlight = false;
    if (result case Err(:final failure)) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        failure: failure,
      );
      _schedulePolling(false);
      return;
    }
    final page = result.valueOrNull!;
    final completedJobIds = {
      for (final shoot in state.shoots)
        if (shoot.status == 'processing') shoot.id,
    };
    final shoots = [
      for (final job in page.jobs) _Shoot.fromJob(job),
    ];
    state = state.copyWith(
      shoots: shoots,
      page: page.page,
      totalPages: page.totalPages,
      isLoading: false,
      isRefreshing: false,
      clearFailure: true,
    );
    for (final job in page.jobs) {
      if (completedJobIds.contains(job.id) && job.isCompleted) {
        unawaited(
          ref
              .read(localNotificationServiceProvider)
              .showCompletion(
                taskId: 'shoot-${job.id}',
                title: 'Shoot completed',
                body: 'Your shoot is ready to review.',
                destination: AppRoutes.shootDetail(job.id, fromDashboard: true),
              ),
        );
      }
    }
    _schedulePolling(page.jobs.any((job) => job.isActive));
  }

  void setQuery(String query) {
    state = state.copyWith(query: query, page: 1);
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 300), load);
  }

  void setStatus(String status) {
    state = state.copyWith(status: status, page: 1);
    unawaited(load());
  }

  void setPage(int page) {
    if (page < 1 || page > state.totalPages || page == state.page) return;
    state = state.copyWith(page: page);
    unawaited(load());
  }

  void _schedulePolling(bool hasActiveJob) {
    _pollTimer?.cancel();
    if (!hasActiveJob) return;
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => unawaited(load(silent: true)),
    );
  }
}

final NotifierProvider<_ShootsController, _ShootsScreenState>
_shootsControllerProvider =
    NotifierProvider.autoDispose<_ShootsController, _ShootsScreenState>(
      _ShootsController.new,
    );
