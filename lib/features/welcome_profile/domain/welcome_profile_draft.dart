import 'package:flutter/foundation.dart';

@immutable
class WelcomeProfileDraft {
  const WelcomeProfileDraft({
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

  Map<String, Object> toPayload() => {
    if (brandUrl.trim().isNotEmpty) 'brandUrl': normalizeBrandUrl(brandUrl),
    if (vertical.trim().isNotEmpty) 'vertical': vertical.trim(),
    if (primaryUses.isNotEmpty) 'primaryUses': primaryUses,
    if (dropCadence case final cadence? when cadence.isNotEmpty)
      'dropCadence': cadence,
    if (referral case final source? when source.isNotEmpty) 'referral': source,
    if (referralOther.trim().isNotEmpty) 'referralOther': referralOther.trim(),
  };
}

String normalizeBrandUrl(String value) {
  var normalized = value.trim().toLowerCase();
  normalized = normalized.replaceFirst(RegExp('^https?://'), '');
  normalized = normalized.replaceFirst(RegExp(r'^www\.'), '');
  return normalized.replaceFirst(RegExp(r'/+$'), '');
}

bool brandUrlLooksValid(String value) {
  final normalized = normalizeBrandUrl(value);
  if (normalized.isEmpty) return true;
  final host = normalized.split('/').first;
  return RegExp(
    r'^(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z]{2,}$',
  ).hasMatch(host);
}
