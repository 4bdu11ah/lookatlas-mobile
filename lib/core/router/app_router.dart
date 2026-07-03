import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/logging/app_logger.dart';
import 'package:look_atlas/core/router/analytics_route_observer.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/router/app_transition_page.dart';
import 'package:look_atlas/features/ai/presentation/screens/chat_screen.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/presentation/auth_controller.dart';
import 'package:look_atlas/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:look_atlas/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:look_atlas/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:look_atlas/features/home/presentation/screens/dashboard_screen.dart';
import 'package:look_atlas/features/onboarding/presentation/screens/onboarding_wizard_screen.dart';
import 'package:look_atlas/features/settings/presentation/screens/settings_screen.dart';
import 'package:look_atlas/features/splash/presentation/screens/splash_screen.dart';
import 'package:look_atlas/features/subscription/presentation/screens/paywall_screen.dart';
import 'package:look_atlas/services/service_providers.dart';
import 'package:look_atlas/shared/widgets/not_found_screen.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Re-evaluates redirects whenever the auth session changes.
  final refresh = ValueNotifier<int>(0);
  ref
    ..onDispose(refresh.dispose)
    ..listen(authStateProvider, (_, _) => refresh.value++);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    // Sentry adds navigation breadcrumbs; the analytics observer logs screen
    // views automatically on every push/replace/pop.
    observers: [
      SentryNavigatorObserver(),
      AnalyticsRouteObserver(ref.watch(analyticsServiceProvider)),
    ],
    errorBuilder: (context, state) {
      // Never surface raw GoException text in the UI; log it and let
      // NotFoundScreen show its friendly default message.
      AppLogger.warning('Navigation error at ${state.uri}: ${state.error}');
      return const NotFoundScreen();
    },
    redirect: (context, state) {
      final loggedIn = ref.read(authRepositoryProvider).currentUser != null;
      // Auth-flow routes: reachable signed out, redirected away once signed
      // in (a logged-in user has no business on the sign-in form or the
      // pre-login onboarding funnel).
      // The onboarding sub-routes below have no GoRoute while their
      // screens are parked (see restore_parked_features.sh); keeping
      // them listed is harmless and avoids churn on restore.
      const authRoutes = {
        AppRoutes.onboarding,
        AppRoutes.onboardingStarting,
        AppRoutes.onboardingGeneration,
        AppRoutes.onboardingSwipe,
        AppRoutes.onboardingResults,
        AppRoutes.onboardingActivate,
        AppRoutes.onboardingSuccess,
        AppRoutes.signIn,
        AppRoutes.signUp,
        AppRoutes.resetPassword,
      };
      // Routes reachable while signed out. The paywall is public so an
      // anonymous visitor can purchase before registering (see the flow doc
      // in subscription_controller.dart) — but unlike the auth routes it
      // stays reachable when signed in. The splash screen is public for both
      // states: it is the initial route and hands off to home itself.
      const publicRoutes = {...authRoutes, AppRoutes.paywall, AppRoutes.splash};

      if (!loggedIn) {
        if (publicRoutes.contains(state.matchedLocation)) return null;
        // Preserve the deep link so sign-in can return to it afterwards.
        return Uri(
          path: AppRoutes.signIn,
          queryParameters: {'from': state.matchedLocation},
        ).toString();
      }
      if (authRoutes.contains(state.matchedLocation)) {
        // Follow a preserved deep link, accepting only in-app paths so an
        // arbitrary `from` value can't cause open-redirect-style weirdness.
        final from = state.uri.queryParameters['from'];
        final isSafe = from != null && from.startsWith('/');
        return isSafe ? from : AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (_, state) =>
            buildAppTransitionPage(state: state, child: const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        pageBuilder: (_, state) => buildAppTransitionPage(
          state: state,
          child: const OnboardingWizardScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        name: 'sign_in',
        pageBuilder: (_, state) =>
            buildAppTransitionPage(state: state, child: const SignInScreen()),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        name: 'sign_up',
        pageBuilder: (_, state) =>
            buildAppTransitionPage(state: state, child: const SignUpScreen()),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        name: 'reset_password',
        pageBuilder: (_, state) => buildAppTransitionPage(
          state: state,
          child: const ResetPasswordScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (_, state) => buildAppTransitionPage(
          state: state,
          child: const DashboardScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.chat,
        name: 'chat',
        pageBuilder: (_, state) =>
            buildAppTransitionPage(state: state, child: const ChatScreen()),
      ),
      GoRoute(
        path: AppRoutes.paywall,
        name: 'paywall',
        pageBuilder: (_, state) =>
            buildAppTransitionPage(state: state, child: const PaywallScreen()),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder: (_, state) => buildAppTransitionPage(
          state: state,
          child: const SettingsScreen(),
        ),
      ),
    ],
  );
});
