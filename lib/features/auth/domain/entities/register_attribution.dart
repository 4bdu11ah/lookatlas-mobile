/// Marketing-attribution fields sent with `POST /auth/register`, mirroring
/// the web client byte-for-byte (fbc/fbp cookies, stored UTM params, Google
/// Ads click IDs and the invite slug).
///
/// All fields are optional; [toJson] omits nulls the same way the web
/// client's `|| undefined` drops them from the JSON body. Mobile has no
/// cookies or localStorage, so populate this from wherever the values arrive
/// on device (install referrer, deferred deep link, campaign link) and pass
/// it to `AuthController.signUp`.
class RegisterAttribution {
  const RegisterAttribution({
    this.fbc,
    this.fbp,
    this.utmSource,
    this.utmMedium,
    this.utmCampaign,
    this.utmContent,
    this.utmTerm,
    this.gclid,
    this.gbraid,
    this.wbraid,
    this.invite,
  });

  final String? fbc;
  final String? fbp;
  final String? utmSource;
  final String? utmMedium;
  final String? utmCampaign;
  final String? utmContent;
  final String? utmTerm;
  final String? gclid;
  final String? gbraid;
  final String? wbraid;
  final String? invite;

  /// The request-body fields, with the API's exact key names and every null
  /// omitted.
  Map<String, String> toJson() => {
    if (fbc != null) 'fbc': fbc!,
    if (fbp != null) 'fbp': fbp!,
    if (utmSource != null) 'utm_source': utmSource!,
    if (utmMedium != null) 'utm_medium': utmMedium!,
    if (utmCampaign != null) 'utm_campaign': utmCampaign!,
    if (utmContent != null) 'utm_content': utmContent!,
    if (utmTerm != null) 'utm_term': utmTerm!,
    if (gclid != null) 'gclid': gclid!,
    if (gbraid != null) 'gbraid': gbraid!,
    if (wbraid != null) 'wbraid': wbraid!,
    if (invite != null) 'invite': invite!,
  };
}
