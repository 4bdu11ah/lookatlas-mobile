import 'package:look_atlas/features/studio_school/domain/entities/welcome_profile_draft.dart';

class WelcomeProfileModel {
  const WelcomeProfileModel._();

  static Map<String, Object> toJson(WelcomeProfileDraft profile) => {
    if (profile.brandUrl.trim().isNotEmpty)
      'brandUrl': normalizeBrandUrl(profile.brandUrl),
    if (profile.vertical.trim().isNotEmpty) 'vertical': profile.vertical.trim(),
    if (profile.primaryUses.isNotEmpty) 'primaryUses': profile.primaryUses,
    if (profile.dropCadence case final cadence? when cadence.isNotEmpty)
      'dropCadence': cadence,
    if (profile.referral case final source? when source.isNotEmpty)
      'referral': source,
    if (profile.referralOther.trim().isNotEmpty)
      'referralOther': profile.referralOther.trim(),
  };
}
