import 'package:flutter/foundation.dart';
import 'package:look_atlas/features/auth/domain/entities/social_provider.dart';

/// Provider-agnostic identity returned by a successful social sign-in.
///
/// Normalizes the Apple and Google SDK payloads so the repository can build
/// an `AppUser` session without knowing which SDK produced it.
@immutable
class SocialCredential {
  const SocialCredential({
    required this.provider,
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    this.idToken,
  });

  final SocialProvider provider;

  /// The provider's stable user identifier.
  final String id;

  /// May be null: Apple only shares email (and name) on the FIRST
  /// authorization for an app; later sign-ins return null.
  final String? email;
  final String? displayName;
  final String? photoUrl;

  /// The provider-issued identity token (JWT) a backend can verify, when the
  /// SDK returned one.
  final String? idToken;
}
