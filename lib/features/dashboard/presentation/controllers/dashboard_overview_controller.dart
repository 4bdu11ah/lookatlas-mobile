import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/dashboard/di/dashboard_providers.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_overview.dart';
import 'package:look_atlas/features/dashboard/domain/repositories/dashboard_repository.dart';

class DashboardOverviewState {
  const DashboardOverviewState({
    this.overview,
    this.subscription,
    this.isLoading = true,
    this.isStale = false,
    this.failure,
  });

  final DashboardOverview? overview;
  final DashboardSubscription? subscription;
  final bool isLoading;
  final bool isStale;
  final Failure? failure;

  DashboardStats? get stats => overview?.credits;
}

class DashboardOverviewController
    extends AsyncNotifier<DashboardOverviewState> {
  Timer? _pollTimer;
  bool _visible = false;
  bool _hasBeenVisible = false;
  bool _foreground = true;
  int _generation = 0;
  Future<void>? _pending;
  DashboardRepository? _repository;

  @override
  DashboardOverviewState build() {
    ref.watch(authStateProvider.select((auth) => auth.value?.id));
    _repository = ref.read(dashboardRepositoryProvider);
    final generation = ++_generation;
    _pending = null;
    ref.onDispose(() {
      ++_generation;
      _pollTimer?.cancel();
      _repository?.cancelOverviewRequest();
    });
    unawaited(
      Future<void>.microtask(() {
        if (generation == _generation) return refresh();
      }),
    );
    return const DashboardOverviewState();
  }

  Future<void> refresh({bool background = true}) {
    final pending = _pending;
    if (pending != null) return pending;
    final request = _load(++_generation);
    _pending = request;
    return request.whenComplete(() {
      if (identical(_pending, request)) _pending = null;
    });
  }

  DashboardOverviewState get _current =>
      state.asData?.value ?? const DashboardOverviewState();

  Future<void> _load(int generation) async {
    final repository = ref.read(dashboardRepositoryProvider);
    final subscription = _loadSubscription(generation);
    final result = await repository.getOverview();
    if (generation != _generation) return;
    if (result.failureOrNull is CancelledFailure) {
      await subscription;
      return;
    }
    final overview = result.valueOrNull;
    state = AsyncData(
      DashboardOverviewState(
        overview: overview ?? _current.overview,
        subscription: _current.subscription,
        isLoading: false,
        isStale: overview == null && _current.overview != null,
        failure: result.failureOrNull,
      ),
    );
    _syncPolling();
    await subscription;
  }

  Future<void> _loadSubscription(int generation) async {
    final result = await ref
        .read(dashboardRepositoryProvider)
        .getSubscription();
    if (generation != _generation) return;
    state = AsyncData(
      DashboardOverviewState(
        overview: _current.overview,
        subscription: result.valueOrNull ?? _current.subscription,
        isLoading: _current.isLoading,
        isStale: _current.isStale,
        failure: _current.failure,
      ),
    );
  }

  void setVisible({required bool visible}) {
    if (!ref.mounted || visible == _visible) return;
    _visible = visible;
    if (!visible) {
      ++_generation;
      _pending = null;
      _pollTimer?.cancel();
      _repository?.cancelOverviewRequest();
      return;
    }
    _syncPolling();
    if (_hasBeenVisible) unawaited(refresh());
    _hasBeenVisible = true;
  }

  void setForeground({required bool foreground}) {
    if (!ref.mounted) return;
    _foreground = foreground;
    _syncPolling();
    if (foreground && _visible && _current.overview != null) {
      unawaited(refresh());
    }
  }

  void _syncPolling() {
    _pollTimer?.cancel();
    if (!_visible ||
        !_foreground ||
        (_current.overview?.activity.activeCount ?? 0) == 0) {
      return;
    }
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      unawaited(refresh());
    });
  }
}

final dashboardOverviewControllerProvider =
    AsyncNotifierProvider<DashboardOverviewController, DashboardOverviewState>(
      DashboardOverviewController.new,
    );
