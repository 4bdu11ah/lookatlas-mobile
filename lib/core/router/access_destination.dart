enum AccessTier { none, onetimeDownload, subscriber }

enum TrialJobStatus { pending, onboarding, generating, completed, unknown }

enum AppDestination {
  dashboard,
  onboardingWizard,
  onboardingResults,
  selectPlan,
}

class AccessState {
  const AccessState({
    required this.accessTier,
    required this.freeShootUsed,
    this.onboardingJobStatus,
  });

  factory AccessState.fromJson(Map<String, dynamic> json) => AccessState(
    accessTier: switch (json['accessTier']) {
      'subscriber' => AccessTier.subscriber,
      'onetime_download' => AccessTier.onetimeDownload,
      _ => AccessTier.none,
    },
    freeShootUsed: json['freeShootUsed'] as bool? ?? false,
    onboardingJobStatus: switch (json['onboardingJobStatus']) {
      'pending' => TrialJobStatus.pending,
      'onboarding' => TrialJobStatus.onboarding,
      'generating' => TrialJobStatus.generating,
      'completed' => TrialJobStatus.completed,
      null => null,
      _ => TrialJobStatus.unknown,
    },
  );

  final AccessTier accessTier;
  final bool freeShootUsed;
  final TrialJobStatus? onboardingJobStatus;
}

AppDestination resolveDestination(AccessState state) {
  if (state.accessTier == AccessTier.subscriber ||
      state.accessTier == AccessTier.onetimeDownload) {
    return AppDestination.dashboard;
  }
  if (state.onboardingJobStatus == TrialJobStatus.generating ||
      state.onboardingJobStatus == TrialJobStatus.completed) {
    return AppDestination.onboardingResults;
  }
  return state.freeShootUsed
      ? AppDestination.selectPlan
      : AppDestination.onboardingWizard;
}
