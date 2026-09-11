import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/logging/app_logger.dart';
import 'package:look_atlas/core/router/analytics_route_observer.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/router/app_transition_page.dart';
import 'package:look_atlas/features/assistant/presentation/screens/assistant_screen.dart';
import 'package:look_atlas/features/assistant/presentation/screens/assistant_transition_page.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:look_atlas/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:look_atlas/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:look_atlas/features/billing/presentation/billing_feature.dart';
import 'package:look_atlas/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:look_atlas/features/create_content/presentation/screens/create_content_screen.dart';
import 'package:look_atlas/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:look_atlas/features/guides/presentation/guides_feature.dart';
import 'package:look_atlas/features/house_model/presentation/house_model_feature.dart';
import 'package:look_atlas/features/onboarding/presentation/screens/activate_paywall_screen.dart';
import 'package:look_atlas/features/onboarding/presentation/screens/billing_success_screen.dart';
import 'package:look_atlas/features/onboarding/presentation/screens/onboarding_wizard_screen.dart';
import 'package:look_atlas/features/onboarding/presentation/screens/onetime_success_screen.dart';
import 'package:look_atlas/features/onboarding/presentation/screens/starting_shoot_screen.dart';
import 'package:look_atlas/features/onboarding/presentation/screens/swipe_results_screen.dart';
import 'package:look_atlas/features/onboarding/presentation/screens/swipe_screen.dart';
import 'package:look_atlas/features/products/presentation/products_feature.dart';
import 'package:look_atlas/features/settings/presentation/account_settings_feature.dart';
import 'package:look_atlas/features/settings/presentation/screens/settings_screen.dart';
import 'package:look_atlas/features/shoots/presentation/shoots_feature.dart';
import 'package:look_atlas/features/splash/presentation/screens/splash_screen.dart';
import 'package:look_atlas/features/studio_school/presentation/screens/studio_school_screen.dart';
import 'package:look_atlas/features/subscription/presentation/screens/paywall_screen.dart';
import 'package:look_atlas/features/support/presentation/support_feature.dart';
import 'package:look_atlas/features/welcome_profile/presentation/screens/welcome_profile_screen.dart';
import 'package:look_atlas/features/workshop/presentation/screens/workshop_screen.dart';
import 'package:look_atlas/services/service_providers.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

String? _validatedInternalReturnTo(String? value) {
  if (value == null ||
      !value.startsWith('/') ||
      value.startsWith('//') ||
      Uri.tryParse(value)?.hasScheme != false) {
    return null;
  }
  return value;
}

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
    onException: (_, state, router) {
      AppLogger.warning('Navigation error at ${state.uri}: ${state.error}');
      final loggedIn = ref.read(authRepositoryProvider).currentUser != null;
      router.go(loggedIn ? AppRoutes.home : AppRoutes.signIn);
    },
    redirect: (context, state) {
      final loggedIn = ref.read(authRepositoryProvider).currentUser != null;
      // Auth forms hand signed-in users to the authenticated onboarding flow.
      const authRoutes = {
        AppRoutes.signIn,
        AppRoutes.signUp,
        AppRoutes.resetPassword,
      };
      // Routes reachable while signed out. Onboarding needs a bearer session,
      // while the standalone paywall remains public.
      const publicRoutes = {
        ...authRoutes,
        AppRoutes.paywall,
        AppRoutes.splash,
      };

      if (!loggedIn) {
        if (publicRoutes.contains(state.matchedLocation)) return null;
        // Preserve the target so the checkout callback can resume after auth.
        return Uri(
          path: AppRoutes.signIn,
          queryParameters: {'from': state.matchedLocation},
        ).toString();
      }
      if (authRoutes.contains(state.matchedLocation)) {
        // Preserve the checkout callback only. All normal auth entries must
        // pass through onboarding before reaching protected app features.
        final from = state.uri.queryParameters['from'];
        if (from == AppRoutes.calendar ||
            from == AppRoutes.billingSuccess ||
            from == AppRoutes.studioSchool ||
            (from != null &&
                from.startsWith('${AppRoutes.createContent}/item/') &&
                _validatedInternalReturnTo(from) != null)) {
          return from;
        }
        return AppRoutes.onboarding;
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
        path: AppRoutes.welcome,
        name: 'welcome_profile',
        pageBuilder: (_, state) => buildAppTransitionPage(
          state: state,
          child: const WelcomeProfileScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboardingStarting,
        name: 'onboarding_starting',
        pageBuilder: (_, state) => buildAppTransitionPage(
          state: state,
          child: const StartingShootScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboardingSwipe,
        name: 'onboarding_swipe',
        pageBuilder: (_, state) =>
            buildAppTransitionPage(state: state, child: const SwipeScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboardingResults,
        name: 'onboarding_results',
        pageBuilder: (_, state) => buildAppTransitionPage(
          state: state,
          child: const SwipeResultsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboardingActivate,
        name: 'onboarding_activate',
        pageBuilder: (_, state) => buildAppTransitionPage(
          state: state,
          child: const ActivatePaywallScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboardingSuccess,
        name: 'onboarding_success',
        pageBuilder: (_, state) => buildAppTransitionPage(
          state: state,
          child: OnetimeSuccessScreen(
            sessionId: state.uri.queryParameters['session_id'],
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.billingSuccess,
        name: 'billing_success',
        pageBuilder: (_, state) => buildAppTransitionPage(
          state: state,
          child: const BillingSuccessScreen(),
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
        path: AppRoutes.workshop,
        name: 'workshop',
        pageBuilder: (_, state) => buildAppTransitionPage(
          state: state,
          child: const WorkshopScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.workshopGuide,
        name: 'workshop_guide',
        pageBuilder: (_, state) => buildAppTransitionPage(
          state: state,
          child: const WorkshopGuideScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.createShoot,
        name: 'create_shoot',
        pageBuilder: (_, state) => buildAppTransitionPage(
          state: state,
          child: const CreateShootScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.calendar,
        name: 'calendar',
        pageBuilder: (_, state) =>
            buildAppTransitionPage(state: state, child: const CalendarScreen()),
      ),
      GoRoute(
        path: AppRoutes.createContent,
        name: 'create_content',
        pageBuilder: (_, state) => buildAppTransitionPage(
          state: state,
          child: const CreateContentScreen(),
        ),
        routes: [
          GoRoute(
            path: 'single',
            name: 'create_content_single',
            pageBuilder: (_, state) => buildAppTransitionPage(
              state: state,
              child: const CreateContentScreen(initialFormat: 'single'),
            ),
          ),
          GoRoute(
            path: 'slideshow',
            name: 'create_content_slideshow',
            pageBuilder: (_, state) => buildAppTransitionPage(
              state: state,
              child: const CreateContentScreen(initialFormat: 'slideshow'),
            ),
          ),
          GoRoute(
            path: 'video',
            name: 'create_content_video',
            pageBuilder: (_, state) => buildAppTransitionPage(
              state: state,
              child: const CreateContentScreen(initialFormat: 'video'),
            ),
          ),
          GoRoute(
            path: 'item/:contentId',
            name: 'create_content_item',
            pageBuilder: (_, state) => buildAppTransitionPage(
              state: state,
              child: CreateContentScreen(
                contentId: state.pathParameters['contentId'],
                previewImageUrl: state.extra is String
                    ? state.extra! as String
                    : null,
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.dashboardShoots,
        name: 'dashboard_shoots',
        pageBuilder: (_, state) => buildAppTransitionPage(
          state: state,
          child: const ShootsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.shootDetailPath,
        name: 'shoot_detail',
        pageBuilder: (_, state) => buildAppTransitionPage(
          state: state,
          child: ShootDetailScreen(
            jobId: state.pathParameters['jobId']!,
            fromDashboard: state.uri.queryParameters['from'] == 'dashboard',
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.productSizeStagePath,
        name: 'product_size_stage',
        pageBuilder: (_, state) => buildAppTransitionPage(
          state: state,
          child: ProductsScreen(
            calibrateProductId: state.pathParameters['productId'],
            calibrationStage: state.pathParameters['stage'],
            directCalibrationRoute: true,
            returnTo: _validatedInternalReturnTo(
              state.uri.queryParameters['returnTo'],
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.productSizePath,
        name: 'product_size',
        pageBuilder: (_, state) => buildAppTransitionPage(
          state: state,
          child: ProductsScreen(
            calibrateProductId: state.pathParameters['productId'],
            directCalibrationRoute: true,
            returnTo: _validatedInternalReturnTo(
              state.uri.queryParameters['returnTo'],
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.dashboardProducts,
        name: 'dashboard_products',
        pageBuilder: (_, state) {
          final returnTo = _validatedInternalReturnTo(
            state.uri.queryParameters['returnTo'],
          );
          return buildAppTransitionPage(
            state: state,
            child: ProductsScreen(
              openCreate: state.uri.queryParameters['create'] == '1',
              productId:
                  state.uri.queryParameters['product'] ??
                  state.uri.queryParameters['productId'],
              calibrateProductId: state.uri.queryParameters['calibrate'],
              returnTo: returnTo,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.dashboardModels,
        name: 'dashboard_models',
        pageBuilder: (_, state) => buildAppTransitionPage(
          state: state,
          child: const HouseModelsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.dashboardBilling,
        name: 'dashboard_billing',
        pageBuilder: (_, state) => buildAppTransitionPage(
          state: state,
          child: const BillingScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.dashboardAccount,
        name: 'dashboard_account',
        pageBuilder: (_, state) => buildAppTransitionPage(
          state: state,
          child: const AccountSettingsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.dashboardSupport,
        name: 'dashboard_support',
        pageBuilder: (_, state) => buildAppTransitionPage(
          state: state,
          child: const SupportScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.studioSchool,
        name: 'studio_school',
        pageBuilder: (_, state) => buildAppTransitionPage(
          state: state,
          child: StudioSchoolScreen(
            entrySource: state.uri.queryParameters['source'] ?? 'deep_link',
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.dashboardGuides,
        name: 'dashboard_guides',
        pageBuilder: (_, state) => buildAppTransitionPage(
          state: state,
          child: GuidesScreen(initialTab: state.uri.queryParameters['tab']),
        ),
      ),
      GoRoute(
        path: AppRoutes.assistant,
        name: 'assistant',
        pageBuilder: (_, state) => buildAssistantTransitionPage(
          state: state,
          child: const AssistantScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.paywall,
        name: 'paywall',
        pageBuilder: (_, state) =>
            buildAppTransitionPage(state: state, child: const PaywallScreen()),
      ),
      GoRoute(
        path: AppRoutes.selectPlan,
        name: 'select_plan',
        pageBuilder: (_, state) => buildAppTransitionPage(
          state: state,
          child: const PaywallScreen(),
        ),
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
