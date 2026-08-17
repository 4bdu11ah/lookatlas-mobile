import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/features/shoots/di/shoots_providers.dart';
import 'package:look_atlas/features/shoots/domain/entities/shoot_job.dart';
import 'package:look_atlas/features/studio_school/presentation/studio_school_controller.dart';

typedef DashboardCampaignKey = ({String userId, String jobId});

@immutable
class DashboardCampaignState {
  const DashboardCampaignState({
    this.job,
    this.isLoading = true,
    this.failure,
  });

  final ShootJob? job;
  final bool isLoading;
  final Failure? failure;

  List<ShootImage> get images {
    final value = job;
    if (value == null) return const [];
    if (value.shots.isNotEmpty) {
      return [for (final shot in value.shots) ...shot.images];
    }
    return value.images;
  }

  DashboardCampaignState copyWith({
    ShootJob? job,
    bool? isLoading,
    Failure? failure,
    bool clearFailure = false,
  }) => DashboardCampaignState(
    job: job ?? this.job,
    isLoading: isLoading ?? this.isLoading,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}

class DashboardCampaignController extends Notifier<DashboardCampaignState> {
  DashboardCampaignController(this.key);

  final DashboardCampaignKey key;
  bool _disposed = false;
  bool _requestInFlight = false;

  @override
  DashboardCampaignState build() {
    ref.onDispose(() => _disposed = true);
    unawaited(Future<void>.microtask(load));
    return const DashboardCampaignState();
  }

  Future<void> load({bool silent = false}) async {
    if (_requestInFlight) return;
    _requestInFlight = true;
    if (!silent) {
      state = state.copyWith(
        isLoading: state.job == null,
        clearFailure: true,
      );
    }
    final result = await ref.read(shootsRepositoryProvider).getJob(key.jobId);
    _requestInFlight = false;
    if (_disposed) return;
    final failure = result.failureOrNull;
    if (failure != null) {
      state = state.copyWith(isLoading: false, failure: failure);
      return;
    }
    state = DashboardCampaignState(job: result.valueOrNull, isLoading: false);
  }

  Future<Failure?> toggleKeep(
    ShootImage image, {
    required bool approved,
  }) async {
    final result = await ref
        .read(shootsRepositoryProvider)
        .setImageApproval(
          key.jobId,
          image.id,
          approved: approved,
        );
    if (_disposed) return null;
    final failure = result.failureOrNull;
    if (failure != null) return failure;
    await Future.wait<void>([
      load(silent: true),
      ref.read(studioSchoolControllerProvider.notifier).refresh(),
    ]);
    return null;
  }
}

// Riverpod's family provider type is inferred from the factory.
// ignore: specify_nonobvious_property_types
final dashboardCampaignControllerProvider = NotifierProvider.autoDispose
    .family<
      DashboardCampaignController,
      DashboardCampaignState,
      DashboardCampaignKey
    >(DashboardCampaignController.new);
