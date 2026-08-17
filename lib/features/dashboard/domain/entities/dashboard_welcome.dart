import 'package:flutter/foundation.dart';

enum DashboardWelcomeStepId {
  product,
  calibration,
  angles,
  model,
  direction,
  firstShoot;

  static DashboardWelcomeStepId? fromApi(String value) => switch (value) {
    'product' || 'addProduct' || 'add_product' || 'hasProduct' => product,
    'calibration' ||
    'calibrate' ||
    'calibrate_sizes' ||
    'hasCalibration' => calibration,
    'angles' || 'pickAngles' || 'label_angles' || 'hasLabeledAngles' => angles,
    'model' || 'createModel' || 'create_model' || 'hasModel' => model,
    'direction' ||
    'chooseDirection' ||
    'choose_direction' ||
    'hasDirection' => direction,
    'firstShoot' ||
    'runShoot' ||
    'first_shoot' ||
    'run_first_shoot' ||
    'hasFirstShoot' => firstShoot,
    _ => null,
  };
}

@immutable
class DashboardWelcomeCampaign {
  const DashboardWelcomeCampaign({
    required this.jobId,
    required this.keptImages,
    required this.images,
  });

  final String jobId;
  final int keptImages;
  final List<String> images;
}

@immutable
class DashboardWelcomeProfile {
  const DashboardWelcomeProfile({
    this.brandUrl = '',
    this.vertical = '',
    this.primaryUses = const [],
    this.dropCadence,
    this.referral,
    this.referralOther = '',
  });

  final String brandUrl;
  final String vertical;
  final List<String> primaryUses;
  final String? dropCadence;
  final String? referral;
  final String referralOther;

  bool get isIncomplete =>
      (dropCadence?.isEmpty ?? true) ||
      primaryUses.isEmpty ||
      (brandUrl.isEmpty && vertical.isEmpty);

  bool get isFullyEmpty =>
      brandUrl.isEmpty &&
      vertical.isEmpty &&
      primaryUses.isEmpty &&
      (dropCadence?.isEmpty ?? true) &&
      (referral?.isEmpty ?? true) &&
      referralOther.isEmpty;
}

@immutable
class DashboardWelcomeState {
  const DashboardWelcomeState({
    required this.steps,
    required this.callBooked,
    required this.flipDismissed,
    required this.introSeen,
    this.calibrationOptional = false,
    this.profileIncomplete = false,
    this.profileFullyEmpty = false,
    this.profile = const DashboardWelcomeProfile(),
    this.checklistRewardClaimedAt,
    this.campaign,
  });

  final Map<DashboardWelcomeStepId, bool> steps;
  final DateTime? checklistRewardClaimedAt;
  final DashboardWelcomeCampaign? campaign;
  final bool callBooked;
  final bool flipDismissed;
  final bool introSeen;
  final bool calibrationOptional;
  final bool profileIncomplete;
  final bool profileFullyEmpty;
  final DashboardWelcomeProfile profile;

  int get completedCount => steps.values.where((value) => value).length;
  bool get checklistComplete =>
      completedCount == DashboardWelcomeStepId.values.length;

  bool get studioHidden =>
      checklistRewardClaimedAt != null && (campaign == null || flipDismissed);

  DashboardWelcomeState copyWith({
    DateTime? checklistRewardClaimedAt,
    DashboardWelcomeCampaign? campaign,
    bool? callBooked,
    bool? flipDismissed,
    bool? introSeen,
    bool? calibrationOptional,
    bool? profileIncomplete,
    bool? profileFullyEmpty,
    DashboardWelcomeProfile? profile,
  }) => DashboardWelcomeState(
    steps: steps,
    checklistRewardClaimedAt:
        checklistRewardClaimedAt ?? this.checklistRewardClaimedAt,
    campaign: campaign ?? this.campaign,
    callBooked: callBooked ?? this.callBooked,
    flipDismissed: flipDismissed ?? this.flipDismissed,
    introSeen: introSeen ?? this.introSeen,
    calibrationOptional: calibrationOptional ?? this.calibrationOptional,
    profileIncomplete: profileIncomplete ?? this.profileIncomplete,
    profileFullyEmpty: profileFullyEmpty ?? this.profileFullyEmpty,
    profile: profile ?? this.profile,
  );
}

@immutable
class DashboardChecklistClaim {
  const DashboardChecklistClaim({
    required this.granted,
    required this.alreadyClaimed,
  });

  final int granted;
  final bool alreadyClaimed;
}
