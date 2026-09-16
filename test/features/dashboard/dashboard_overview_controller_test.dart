import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/dashboard/di/dashboard_providers.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_overview.dart';
import 'package:look_atlas/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:look_atlas/features/dashboard/presentation/controllers/campaign_selection_controller.dart';
import 'package:look_atlas/features/dashboard/presentation/controllers/dashboard_overview_controller.dart';
import 'package:look_atlas/features/dashboard/presentation/controllers/retention_countdown_controller.dart';
import 'package:look_atlas/features/dashboard/presentation/models/campaign_shot.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fake_repositories.dart';

class _Repository extends Mock implements DashboardRepository {}

const _overview = DashboardOverview(
  credits: DashboardStats(
    credits: 240,
    creditsTotal: 400,
    creditsUsed: 160,
    totalRenders: 0,
    activeJobs: 1,
    completedJobs: 1,
  ),
  activity: DashboardActivity(activeCount: 1, readyCount: 1),
);

void main() {
  late _Repository repository;
  late ProviderContainer container;
  setUp(() {
    repository = _Repository();
    when(() => repository.getOverview())
        .thenAnswer((_) async => const Result.ok(_overview));
    when(() => repository.getSubscription()).thenAnswer(
      (_) async => const Result.ok(
        DashboardSubscription(
          status: 'active',
          cancelAtPeriodEnd: false,
          accessTier: 'subscriber',
          proUpsellActive: false,
        ),
      ),
    );
    container = ProviderContainer.test(
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(repository),
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      ],
    );
  });

  Future<DashboardOverviewController> load(WidgetTester tester) async {
    final controller = container.read(
      dashboardOverviewControllerProvider.notifier,
    );
    await tester.pump();
    await controller.refresh();
    return controller;
  }

  testWidgets('refresh_failure_preservesPreviouslyLoadedDataAsStale', (
    tester,
  ) async {
    final controller = await load(tester);
    when(() => repository.getOverview())
        .thenAnswer((_) async => const Result.err(NetworkFailure('Offline')));
    await controller.refresh();
    final state = container.read(dashboardOverviewControllerProvider).value!;
    expect(state.overview, same(_overview));
    expect(state.isStale, isTrue);
    expect(state.isLoading, isFalse);
    expect(state.failure, isA<NetworkFailure>());
  });
  testWidgets('initialLoad_failure_hasNoFabricatedEmptyOverview', (
    tester,
  ) async {
    when(() => repository.getOverview())
        .thenAnswer((_) async => const Result.err(NetworkFailure('Offline')));
    await load(tester);
    final state = container.read(dashboardOverviewControllerProvider).value!;
    expect(state.overview, isNull);
    expect(state.isStale, isFalse);
    expect(state.failure, isA<NetworkFailure>());
  });
  testWidgets('polling_visibleActiveStudio_refreshesAfterTwentySeconds', (
    tester,
  ) async {
    final controller = await load(tester);
    clearInteractions(repository);
    controller.setVisible(visible: true);
    await tester.pump();
    clearInteractions(repository);
    await tester.pump(const Duration(seconds: 19));
    verifyNever(() => repository.getOverview());
    await tester.pump(const Duration(seconds: 1));
    verify(() => repository.getOverview()).called(1);
    controller.setVisible(visible: false);
  });
  testWidgets('polling_backgroundOrHiddenStudio_doesNotRefresh', (
    tester,
  ) async {
    final controller = await load(tester);
    controller
      ..setVisible(visible: true)
      ..setForeground(foreground: false);
    clearInteractions(repository);
    await tester.pump(const Duration(seconds: 40));
    verifyNever(() => repository.getOverview());
    controller.setForeground(foreground: true);
    await tester.pump();
    verify(() => repository.getOverview()).called(1);
    controller.setVisible(visible: false);
    clearInteractions(repository);
    await tester.pump(const Duration(seconds: 40));
    verifyNever(() => repository.getOverview());
  });
  testWidgets('polling_noActiveShoots_doesNotScheduleTimer', (tester) async {
    when(() => repository.getOverview()).thenAnswer(
      (_) async => Result.ok(DashboardOverview(credits: _overview.credits)),
    );
    final controller = await load(tester);
    controller.setVisible(visible: true);
    await tester.pump();
    clearInteractions(repository);
    await tester.pump(const Duration(seconds: 40));
    verifyNever(() => repository.getOverview());
  });
  testWidgets('refresh_concurrentRequests_shareOneNetworkCall', (tester) async {
    final controller = await load(tester);
    clearInteractions(repository);
    final pending = Completer<Result<DashboardOverview>>();
    when(() => repository.getOverview()).thenAnswer((_) => pending.future);
    final first = controller.refresh();
    final second = controller.refresh();
    verify(() => repository.getOverview()).called(1);
    pending.complete(const Result.ok(_overview));
    await Future.wait([first, second]);
  });
  test('selection_fourthHero_rejectsWithoutSaving', () async {
    final subscription = container.listen(
      campaignSelectionControllerProvider('job'),
      (_, _) {},
    );
    addTearDown(subscription.close);
    final controller = container.read(
      campaignSelectionControllerProvider('job').notifier,
    );
    final shots = List.generate(
      4,
      (index) => CampaignShot(id: '$index', url: null, approved: index < 3),
    );
    var calls = 0;
    final failure = await controller.toggle(shots.last, shots, (
      _, {
      required approved,
    }) async {
      calls++;
      return null;
    });
    expect(failure, isA<ValidationFailure>());
    expect(calls, 0);
  });
  test('selection_failedSave_rollsBackOnlyFailedShot', () async {
    final subscription = container.listen(
      campaignSelectionControllerProvider('job'),
      (_, _) {},
    );
    addTearDown(subscription.close);
    final controller = container.read(
      campaignSelectionControllerProvider('job').notifier,
    );
    const shots = [
      CampaignShot(id: 'one', url: null, approved: false),
      CampaignShot(id: 'two', url: null, approved: false),
    ];
    await controller.toggle(
      shots.first,
      shots,
      (_, {required approved}) async => null,
    );
    await controller.toggle(
      shots.last,
      shots,
      (_, {required approved}) async => const NetworkFailure('Offline'),
    );
    final state = container.read(campaignSelectionControllerProvider('job'));
    expect(state.overrides, {'one': true, 'two': false});
    expect(state.inflight, isEmpty);
  });
  testWidgets('retention_countdown_usesClockAndStopsAtZero', (tester) async {
    var now = DateTime.utc(2026, 9, 15, 12);
    final scoped = ProviderContainer.test(
      overrides: [dashboardClockProvider.overrideWithValue(() => now)],
    );
    final expiry = now.add(const Duration(seconds: 2));
    final subscription = scoped.listen(
      retentionCountdownProvider(expiry),
      (_, _) {},
    );
    addTearDown(subscription.close);
    expect(
      scoped.read(retentionCountdownProvider(expiry)),
      const Duration(seconds: 2),
    );
    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(
      scoped.read(retentionCountdownProvider(expiry)),
      const Duration(seconds: 1),
    );
    now = now.add(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(scoped.read(retentionCountdownProvider(expiry)), Duration.zero);
  });
}
