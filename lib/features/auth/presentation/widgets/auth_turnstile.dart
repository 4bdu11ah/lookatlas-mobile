import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';
import 'package:flutter/material.dart';
import 'package:look_atlas/core/config/app_config.dart';

enum AuthTurnstileAction { login, signup }

/// Rendered Turnstile challenge used before email/password authentication.
class AuthTurnstile extends StatelessWidget {
  const AuthTurnstile({
    required this.action,
    required this.onTokenChanged,
    super.key,
  });

  final AuthTurnstileAction action;
  final ValueChanged<String?> onTokenChanged;

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.hasTurnstile) {
      return Text(
        'Security check is not configured. Please contact support.',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
        textAlign: TextAlign.center,
      );
    }

    return Center(
      child: CloudflareTurnstile(
        siteKey: AppConfig.turnstileSiteKey,
        baseUrl: AppConfig.turnstileBaseUrl,
        action: action.name,
        onTokenReceived: onTokenChanged,
        onTokenExpired: () => onTokenChanged(null),
        onError: (_) => onTokenChanged(null),
        onTimeout: () => onTokenChanged(null),
      ),
    );
  }
}
