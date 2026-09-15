import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/dashboard/di/dashboard_providers.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:look_atlas/features/studio_school/presentation/controllers/learning_credit_balance_controller.dart';

void main() {
  const stats = DashboardStats(
    credits: 1250,
    creditsTotal: 1500,
    creditsUsed: 250,
    totalRenders: 10,
    activeJobs: 1,
    completedJobs: 2,
  );

  test('creditBalance_rewardSuccess_showsGrantedCreditsUntilRefresh', () async {
    final refreshed = Completer<DashboardStats>();
    var calls = 0;
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWithValue(
          const AsyncData(AppUser(id: 'user-1', email: 'jane@example.com')),
        ),
        dashboardStatsProvider.overrideWith(
          (ref) async => ++calls == 1 ? stats : await refreshed.future,
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(learningCreditBalanceProvider, (_, _) {});
    await container.read(dashboardStatsProvider.future);

    container.read(learningCreditBalanceProvider.notifier).applyReward(20);
    container.invalidate(dashboardStatsProvider);
    expect(container.read(learningCreditBalanceProvider), 1270);

    refreshed.complete(stats);
    await container.read(dashboardStatsProvider.future);
    expect(container.read(learningCreditBalanceProvider), isNull);
  });

  test('creditBalance_alreadyClaimed_doesNotAddCredits', () async {
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWithValue(const AsyncData<AppUser?>(null)),
        dashboardStatsProvider.overrideWith((ref) async => stats),
      ],
    );
    addTearDown(container.dispose);
    container.listen(learningCreditBalanceProvider, (_, _) {});
    await container.read(dashboardStatsProvider.future);

    container.read(learningCreditBalanceProvider.notifier).applyReward(0);
    expect(container.read(learningCreditBalanceProvider), isNull);
  });
}
