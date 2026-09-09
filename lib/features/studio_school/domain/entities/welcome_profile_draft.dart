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
