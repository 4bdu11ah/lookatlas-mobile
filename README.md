# Flutter Production look_atlas

A batteries-included Flutter starter built for apps that need to be **fast, reliable, scalable, and secure**. It ships with a clean feature-first architecture, Riverpod state management, a hardened networking layer, and the services most apps need wired in and ready: subscriptions, analytics, crash reporting, local notifications, and a streaming AI client.

Everything is **feature-flagged**: drop in your keys to enable a service, or leave it blank and the app still builds and runs with zero configuration.

## Contents

- [Stack](#stack)
- [Architecture](#architecture)
- [Getting started](#getting-started)
- [Configuration & secrets](#configuration--secrets)
- [Networking (ApiService)](#networking-apiservice)
- [Services](#services)
- [State management](#state-management)
- [Scripts](#scripts)
- [Quality & CI](#quality--ci)
- [Extending the look_atlas](#extending-the-look_atlas)

## Stack

| Concern | Choice |
| --- | --- |
| Language / SDK | Dart 3.9, Flutter 3.44.8 |
| State management + DI | [Riverpod](https://riverpod.dev) 3 |
| Routing | [go_router](https://pub.dev/packages/go_router) (auth-aware redirects) |
| Networking | [Dio](https://pub.dev/packages/dio) + `ApiService` (retry, auth, logging interceptors) |
| Subscriptions | [RevenueCat](https://www.revenuecat.com) (`purchases_flutter`) |
| Crash reporting | [Sentry](https://sentry.io) |
| Analytics | [PostHog](https://posthog.com) (swappable behind an interface) |
| Notifications | `flutter_local_notifications` (local) |
| AI | Anthropic Claude streaming client (SSE) |
| Secure storage | `flutter_secure_storage` (Keychain / EncryptedSharedPreferences) |
| Lints | `very_good_analysis` (strict) |
| Tests | `flutter_test` + `mocktail` |

## Architecture

Feature-first clean architecture. Each feature owns its `domain` (models + repository interfaces), `data` (implementations), and `presentation` (controllers + screens). The UI depends only on domain interfaces, so swapping a backend never touches a screen.

```
lib/
  main.dart                 # entry point -> bootstrap()
  bootstrap.dart            # composition root: init services, runApp in error zone
  app/app.dart              # MaterialApp.router, theming
  core/
    config/                 # AppConfig: compile-time config via --dart-define
    network/                # Dio client, ApiService, interceptors (auth/retry/logging)
    error/  result/         # sealed Failure + Result<T> (no exceptions to the UI)
    router/                 # go_router config + route constants
    storage/                # SecureStorage (secrets) + KeyValueStore (prefs)
    theme/                  # Material 3 light/dark from one brand seed
    logging/  providers/    # AppLogger, shared core providers
  features/
    auth/                   # email auth (local stub, swap for a real backend)
    subscription/           # RevenueCat paywall + entitlement gating
    ai/                     # Claude streaming chat
    home/  settings/        # shell screens, theme switcher
  services/
    analytics/  crash/  notifications/   # cross-cutting integrations
  shared/widgets/           # reusable UI
```

**Design principles applied:** typed `Failure`s instead of raw exceptions, `Result<T>` return types, repository pattern, immutable models with hand-written `copyWith`, `const` widgets, and the smallest-possible rebuild scope via Riverpod `select` / leaf consumers. Conventions are enforced repo-wide in `AGENTS.md`.

**Request lifecycle:** `Screen` → Riverpod controller → repository (interface) → `ApiService` → Dio (interceptors) → typed `Result<T>` back up. The UI pattern-matches the result; it never catches an exception.

## Getting started

```bash
flutter pub get
cp .env.example .env        # fill in only the keys you need
./scripts/run.sh            # runs with --dart-define-from-file=.env
```

No keys? It still runs: auth uses a local stub, and analytics / crash / AI / subscriptions degrade gracefully to no-ops.

## Configuration & secrets

All config is injected at **build time** via `--dart-define` (read in `lib/core/config/app_config.dart`). Nothing sensitive is committed. `.env` is git-ignored; `.env.example` documents every key.

| Key | Purpose | Default | Required for |
| --- | --- | --- | --- |
| `FLAVOR` | Build flavor: `dev` / `staging` / `prod` | `dev` | — |
| `API_BASE_URL` | Your backend base URL (`ApiService`) | `https://api.example.com` | your API |
| `SENTRY_DSN` | Sentry crash reporting | _empty_ | crash reporting |
| `POSTHOG_API_KEY` | PostHog project key | _empty_ | analytics |
| `POSTHOG_HOST` | PostHog ingestion host | `https://us.i.posthog.com` | analytics |
| `REVENUECAT_IOS_API_KEY` | RevenueCat iOS key | _empty_ | subscriptions (iOS) |
| `REVENUECAT_ANDROID_API_KEY` | RevenueCat Android key | _empty_ | subscriptions (Android) |
| `REVENUECAT_SUBSCRIPTION_PRODUCT_IDS` | Comma-separated monthly subscription product IDs | _empty_ | direct RevenueCat product lookup |
| `REVENUECAT_ONE_TIME_PRODUCT_IDS` | Comma-separated one-time product IDs | _empty_ | direct RevenueCat product lookup |
| `REVENUECAT_ENTITLEMENT_ID` | Entitlement that grants premium | `premium` | subscriptions |
| `AI_BASE_URL` | Anthropic base URL or your proxy | `https://api.anthropic.com` | AI |
| `AI_API_KEY` | Anthropic key (dev only) | _empty_ | AI (dev) |
| `AI_MODEL` | Claude model id | `claude-sonnet-4-6` | AI |

```bash
./scripts/run.sh .env.staging              # run a specific flavor file
./scripts/build.sh appbundle .env.prod     # release build with prod config
```

> **Security note:** for the AI feature in production, point `AI_BASE_URL` at your own backend proxy that holds the Anthropic key server-side and leave `AI_API_KEY` blank. Shipping a raw key inside the app binary lets anyone extract it.

## Networking (`ApiService`)

`core/network/ApiService` is the single Dio-backed HTTP service. It owns the interceptor stack so feature code never touches Dio directly:

- **AuthInterceptor** attaches the bearer token, read *per request* from secure storage so it always reflects the current session.
- **RetryInterceptor** retries **idempotent** requests (GET/HEAD) on timeouts, connection drops, and 5xx/429 with exponential backoff (400ms → 800ms → 1600ms). A half-sent POST is never replayed.
- **LoggingInterceptor** logs requests in dev with sensitive headers (`Authorization`, `x-api-key`, `cookie`) redacted.

Every call returns a `Result<T>` so failures are explicit:

```dart
final result = await ref.read(apiServiceProvider).get<List<Post>>(
  '/posts',
  decoder: (data) => (data as List).map(Post.fromJson).toList(),
);
result.fold(
  (posts) => /* use posts */,
  (failure) => showError(failure.message),
);
```

`ApiService` exposes `get` / `post` / `put` / `patch` / `delete`, each accepting an optional `decoder` and a `CancelToken`. Use `apiService.raw` for streaming or downloads.

## Services

Enable each by adding its key(s); otherwise it stays off.

- **RevenueCat** (`features/subscription`) — set the iOS/Android keys, configure offerings and a `premium` entitlement in the dashboard. The paywall, purchase, restore, and live entitlement gating (`isPremiumProvider`) are wired.
- **Sentry** (`services/crash`) — set `SENTRY_DSN`. Captures uncaught Flutter and platform errors; `runApp` runs inside a guarded zone.
- **PostHog** (`services/analytics`) — set `POSTHOG_API_KEY`. Behind an `AnalyticsService` interface, so swapping providers is one class.
- **AI / Claude** (`features/ai`) — set `AI_API_KEY` (dev) or an `AI_BASE_URL` proxy (prod). Token-by-token SSE streaming chat.
- **Notifications** (`services/notifications`) — local notifications via `flutter_local_notifications`, no setup required.

## State management

This look_atlas uses **Riverpod** for state and dependency injection. Rationale:

- Less boilerplate than BLoC, with compile-safe DI built in (no separate service locator).
- First-class async ergonomics (`AsyncNotifier`, `FutureProvider`, `StreamProvider`) — a good fit for data-fetching apps.
- Trivially testable: override any provider in `ProviderScope` (see `test/`).
- Fine-grained rebuilds via `select` / leaf consumers keep the UI fast.

Prefer **BLoC** instead if your domain is genuinely state-machine-heavy or your team already standardizes on it; both are production-grade and `AGENTS.md` documents rebuild best-practices for either.

## Scripts

| Command | What it does |
| --- | --- |
| `./scripts/run.sh [env-file] [flutter args]` | Run with `--dart-define-from-file` (defaults to `.env`) |
| `./scripts/build.sh <apk\|appbundle\|ipa> [env-file]` | Release build with config injected |
| `flutter analyze` | Strict static analysis (expects zero issues) |
| `flutter test` | Unit + widget tests |
| `dart format .` | Format the codebase |

## Quality & CI

- **Lints:** `very_good_analysis` (strict) with `strict-casts` / `strict-raw-types`; unused imports/locals are errors.
- **Tests:** unit tests for `Result` and the auth repository (mocked with `mocktail`), plus a widget smoke test. Run `flutter test`.
- **Pre-commit/push:** `lefthook.yml` runs format + analyze on commit and tests on push. Install with `lefthook install`.
- **CI:** `.github/workflows/ci.yaml` verifies formatting, runs `flutter analyze --fatal-infos`, and runs tests with coverage on every push/PR.

## Extending the look_atlas

**Swap in a real backend.** Auth ships as a local stub (`LocalAuthRepository`) behind the `AuthRepository` interface. To use Supabase/your API, write a new implementation and change the one line in `authRepositoryProvider` (`features/auth/presentation/auth_controller.dart`). No screen changes needed.

**Add a feature.** Create `features/<name>/{domain,data,presentation}`, expose a repository interface in `domain`, implement it in `data`, drive it with a Riverpod controller in `presentation`, then register the screen in `core/router/app_router.dart` and add a path to `AppRoutes`.

**Rebrand.** Change `AppColors.brandSeed` in `core/theme/app_colors.dart` — Material 3 regenerates the full light/dark palette from that one seed.
