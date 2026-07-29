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
    required this.accessToken,
    required this.refreshToken,
    this.email,
    this.displayName,
    this.photoUrl,
  });

  final SocialProvider provider;

  /// The provider's stable user identifier.
  final String id;

  /// May be null: Apple only shares email (and name) on the FIRST
  /// authorization for an app; later sign-ins return null.
  final String? email;
  final String? displayName;
  final String? photoUrl;

  /// Supabase session tokens returned after the provider token exchange.
  final String accessToken;
  final String refreshToken;
}

@immutable
class SocialSessionTokens {
  const SocialSessionTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;
}
