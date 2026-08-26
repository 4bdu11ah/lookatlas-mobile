/// Centralized, compile-time application configuration.
///
/// Secrets and environment values are injected at build time via
/// `--dart-define` (or `--dart-define-from-file`). Nothing sensitive is ever
/// committed to the repository. See `.env.example` for the full list of keys
/// and `scripts/run.sh` for a convenient wrapper.
///
/// Every service is feature-flagged: if its key is absent the app still runs,
/// the service simply stays disabled. This keeps the look_atlas runnable with
/// zero configuration.
library;

import 'package:flutter/foundation.dart';

enum AppFlavor { dev, staging, prod }

abstract final class AppConfig {
  static const String _flavorName = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'dev',
  );

  static AppFlavor get flavor => switch (_flavorName) {
    'prod' => AppFlavor.prod,
    'staging' => AppFlavor.staging,
    _ => AppFlavor.dev,
  };

  static bool get isProd => flavor == AppFlavor.prod;
  static bool get isDev => flavor == AppFlavor.dev;

  /// Single source of truth for "is verbose diagnostics output allowed".
  ///
  /// True only in non-release builds of non-prod flavors. Use this for the
  /// log filter, SDK debug flags (PostHog, etc.) and similar diagnostics —
  /// never gate them on [kReleaseMode] or [isProd] individually, so the
  /// predicate can't drift between call sites.
  static bool get isDebugLoggingEnabled => !kReleaseMode && !isProd;

  static String get appName => switch (flavor) {
    AppFlavor.prod => 'look_atlas',
    AppFlavor.staging => 'look_atlas (Staging)',
    AppFlavor.dev => 'look_atlas (Dev)',
  };

  // --- Your backend API ---
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://catalogmock-api-production.up.railway.app',
  );

  // --- Crash reporting (Sentry) ---
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static bool get hasSentry => sentryDsn.isNotEmpty;

  // --- Product analytics (PostHog) ---
  static const String posthogApiKey = String.fromEnvironment('POSTHOG_API_KEY');
  static const String posthogHost = String.fromEnvironment(
    'POSTHOG_HOST',
    defaultValue: 'https://us.i.posthog.com',
  );
  static bool get hasPosthog => posthogApiKey.isNotEmpty;

  // --- Subscriptions (RevenueCat) ---
  static const String revenueCatAndroidKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
  );
  static const String revenueCatIosKey = String.fromEnvironment(
    'REVENUECAT_IOS_API_KEY',
  );
  static const String _revenueCatSubscriptionProductIds =
      String.fromEnvironment('REVENUECAT_SUBSCRIPTION_PRODUCT_IDS');
  static const String _revenueCatOneTimeProductIds = String.fromEnvironment(
    'REVENUECAT_ONE_TIME_PRODUCT_IDS',
  );

  static List<String> get revenueCatSubscriptionProductIds =>
      _splitCommaSeparated(_revenueCatSubscriptionProductIds);
  static List<String> get revenueCatOneTimeProductIds =>
      _splitCommaSeparated(_revenueCatOneTimeProductIds);

  /// Entitlement identifier configured in the RevenueCat dashboard that grants
  /// premium access.
  static const String premiumEntitlementId = String.fromEnvironment(
    'REVENUECAT_ENTITLEMENT_ID',
    defaultValue: 'premium',
  );

  static List<String> _splitCommaSeparated(String value) => [
    for (final item in value.split(','))
      if (item.trim().isNotEmpty) item.trim(),
  ];

  // --- Social sign-in (Google) ---
  //
  // The OAuth "Web application" client ID from the Google Cloud console. It is
  // passed to google_sign_in as `serverClientId` (required on Android, and the
  // ID tokens it mints are the ones a backend can verify). Leave blank and the
  // Google button reports "not configured" instead of invoking the SDK.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  /// The OAuth "iOS" client ID. Optional: only needed on iOS/macOS, where it
  /// is passed to google_sign_in as `clientId`.
  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );

  static bool get hasGoogleAuth => googleWebClientId.isNotEmpty;

  // --- Supabase social auth ---
  //
  // Supabase is initialized lazily on the first Apple/Google sign-in tap.
  // Replace these placeholders in the dart-define file before enabling the
  // providers in the Supabase dashboard.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-supabase-anon-key',
  );
  static bool get hasSupabaseAuth =>
      supabaseUrl != 'https://your-project.supabase.co' &&
      supabasePublishableKey != 'your-supabase-anon-key' &&
      supabaseUrl.isNotEmpty &&
      supabasePublishableKey.isNotEmpty;

  // --- Cloudflare Turnstile ---
  static const String turnstileSiteKey = String.fromEnvironment(
    'TURNSTILE_SITE_KEY',
    defaultValue: 'your-turnstile-site-key',
  );
  static const String turnstileBaseUrl = String.fromEnvironment(
    'TURNSTILE_BASE_URL',
    defaultValue: 'https://your-domain.example',
  );
  static bool get hasTurnstile =>
      turnstileSiteKey.isNotEmpty &&
      turnstileSiteKey != 'your-turnstile-site-key' &&
      turnstileBaseUrl.isNotEmpty &&
      turnstileBaseUrl != 'https://your-domain.example';

  // --- Social sign-in (Apple) ---
  //
  // Sign in with Apple needs no key here: it is enabled via the Xcode
  // "Sign in with Apple" capability (see .env.example for the steps).
  /// Whether the current platform can offer Sign in with Apple. Uses
  /// [defaultTargetPlatform] (not `dart:io`) so tests can override it with
  /// `debugDefaultTargetPlatformOverride`.
  static bool get isAppleSignInSupported =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}
