import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/router/access_destination.dart';

void main() {
  test('resolveDestination_paidAccess_opensDashboard', () {
    for (final tier in [AccessTier.subscriber, AccessTier.onetimeDownload]) {
      expect(
        resolveDestination(AccessState(accessTier: tier, freeShootUsed: true)),
        AppDestination.dashboard,
      );
    }
  });

  test('resolveDestination_freeShootStates_routeToExpectedFlow', () {
    expect(
      resolveDestination(
        const AccessState(accessTier: AccessTier.none, freeShootUsed: false),
      ),
      AppDestination.onboardingWizard,
    );
    expect(
      resolveDestination(
        const AccessState(
          accessTier: AccessTier.none,
          freeShootUsed: true,
          onboardingJobStatus: TrialJobStatus.generating,
        ),
      ),
      AppDestination.onboardingResults,
    );
    expect(
      resolveDestination(
        const AccessState(accessTier: AccessTier.none, freeShootUsed: true),
      ),
      AppDestination.selectPlan,
    );
  });

  test('AccessState_fromJson_mapsBackendValues', () {
    final state = AccessState.fromJson({
      'accessTier': 'onetime_download',
      'freeShootUsed': true,
      'onboardingJobStatus': 'completed',
    });

    expect(state.accessTier, AccessTier.onetimeDownload);
    expect(state.onboardingJobStatus, TrialJobStatus.completed);
  });
}
