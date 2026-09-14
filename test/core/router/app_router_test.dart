import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/providers/core_providers.dart';
import 'package:look_atlas/core/router/app_router.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:look_atlas/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:look_atlas/features/billing/di/billing_api_providers.dart';
import 'package:look_atlas/features/billing/presentation/billing_feature.dart';
import 'package:look_atlas/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:look_atlas/features/create_content/di/content_providers.dart';
import 'package:look_atlas/features/create_content/presentation/screens/create_content_screen.dart';
import 'package:look_atlas/features/dashboard/di/dashboard_providers.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_welcome.dart';
import 'package:look_atlas/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:look_atlas/features/guides/presentation/guides_feature.dart';
import 'package:look_atlas/features/house_model/presentation/house_model_feature.dart';
import 'package:look_atlas/features/onboarding/di/onboarding_providers.dart';
import 'package:look_atlas/features/onboarding/presentation/screens/onboarding_wizard_screen.dart';
import 'package:look_atlas/features/products/di/products_providers.dart';
import 'package:look_atlas/features/products/presentation/products_feature.dart';
import 'package:look_atlas/features/settings/presentation/account_settings_feature.dart';
import 'package:look_atlas/features/shoots/di/shoots_providers.dart';
import 'package:look_atlas/features/shoots/presentation/shoots_feature.dart';
import 'package:look_atlas/features/studio_school/di/studio_school_providers.dart';
import 'package:look_atlas/features/studio_school/presentation/screens/studio_school_screen.dart';
import 'package:look_atlas/features/subscription/di/subscription_providers.dart';
import 'package:look_atlas/features/subscription/presentation/screens/paywall_screen.dart';
import 'package:look_atlas/features/support/presentation/support_feature.dart';
import 'package:look_atlas/features/welcome_profile/presentation/screens/welcome_profile_screen.dart';
import 'package:look_atlas/features/workshop/di/workshop_providers.dart';
import 'package:look_atlas/features/workshop/presentation/screens/workshop_screen.dart';
import 'package:look_atlas/shared/widgets/custom_app_bar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/create_content/content_test_backend.dart';
import '../../helpers/fake_repositories.dart';
import '../../helpers/fake_shoots_repository.dart';
import '../../helpers/fake_welcome_repository.dart';

void main() {
  const user = AppUser(id: 'user-1', email: 'jane@example.com');

  /// Builds the real app router against a fake auth session and pumps it.
  Future<GoRouter> pumpRouter(
    WidgetTester tester, {
    AppUser? user,
    FakeWelcomeRepository? welcomeRepository,
    FakeShootsRepository? shootsRepository,
    ContentTestBackend? contentBackend,
    bool settle = true,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        contentRepositoryProvider.overrideWithValue(
          (contentBackend ?? ContentTestBackend()).repository,
        ),
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(user: user),
        ),
        subscriptionRepositoryProvider.overrideWithValue(
          FakeSubscriptionRepository(),
        ),
        dashboardRepositoryProvider.overrideWithValue(
          const FakeDashboardRepository(),
        ),
        welcomeRepositoryProvider.overrideWithValue(
          welcomeRepository ?? FakeWelcomeRepository(),
        ),
        shootsRepositoryProvider.overrideWithValue(
          shootsRepository ?? FakeShootsRepository(),
        ),
        productsRepositoryProvider.overrideWithValue(
          const FakeProductsRepository(),
        ),
        workshopRepositoryProvider.overrideWithValue(
          FakeWorkshopRepository(),
        ),
        billingHistoryProvider.overrideWith((ref) async => const []),
        onboardingStatusProvider.overrideWith(
          (ref) =>
              Future.error(StateError('Status unavailable in router test')),
        ),
        onboardingProductsProvider.overrideWith((ref) async => const []),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }
    return router;
  }

  Uri currentUri(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri;

  group('logged out', () {
    testWidgets(
      'protected path redirects to sign-in preserving the deep link',
      (tester) async {
        final router = await pumpRouter(tester);

        router.go('/chat');
        await tester.pumpAndSettle();

        final uri = currentUri(router);
        expect(uri.path, '/sign-in');
        expect(uri.queryParameters['from'], '/chat');
        expect(find.byType(SignInScreen), findsOneWidget);
      },
    );

    testWidgets('public path is reachable without a redirect', (tester) async {
      final router = await pumpRouter(tester);

      router.go('/reset-password');
      await tester.pumpAndSettle();

      expect(currentUri(router).path, '/reset-password');
      expect(find.byType(ResetPasswordScreen), findsOneWidget);
    });

    testWidgets('onboarding redirects to sign-in', (tester) async {
      final router = await pumpRouter(tester);

      router.go(AppRoutes.onboarding);
      await tester.pumpAndSettle();

      expect(currentUri(router).path, AppRoutes.signIn);
      expect(find.byType(SignInScreen), findsOneWidget);
    });

    testWidgets('paywall is public so anonymous users can purchase', (
      tester,
    ) async {
      final router = await pumpRouter(tester);

      router.go('/paywall');
      await tester.pumpAndSettle();

      expect(currentUri(router).path, '/paywall');
      expect(find.byType(PaywallScreen), findsOneWidget);
    });
  });

  group('logged in', () {
    testWidgets('sign-in with a missing from opens onboarding', (
      tester,
    ) async {
      final router = await pumpRouter(tester, user: user);

      router.go('/sign-in');
      await tester.pumpAndSettle();

      expect(currentUri(router).path, AppRoutes.onboarding);
      expect(find.byType(OnboardingWizardScreen), findsOneWidget);
    });

    testWidgets('sign-in with a non-path from opens onboarding', (
      tester,
    ) async {
      final router = await pumpRouter(tester, user: user);

      router.go('/sign-in?from=https%3A%2F%2Fevil.example');
      await tester.pumpAndSettle();

      expect(currentUri(router).path, AppRoutes.onboarding);
      expect(find.byType(OnboardingWizardScreen), findsOneWidget);
    });

    testWidgets('paywall stays reachable when signed in', (tester) async {
      final router = await pumpRouter(tester, user: user);

      router.go('/paywall');
      await tester.pumpAndSettle();

      expect(currentUri(router).path, '/paywall');
      expect(find.byType(PaywallScreen), findsOneWidget);
    });

    testWidgets('welcome route opens the standalone profile flow', (
      tester,
    ) async {
      final router = await pumpRouter(tester, user: user);

      router.go(AppRoutes.welcome);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(currentUri(router).path, AppRoutes.welcome);
      expect(find.byType(WelcomeProfileScreen), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);
    });

    testWidgets('school deep link restores after sign-in', (tester) async {
      final router = await pumpRouter(tester, user: user);

      router.go('/sign-in?from=%2Fschool');
      await tester.pumpAndSettle();

      expect(currentUri(router).path, AppRoutes.studioSchool);
      expect(find.byType(StudioSchoolScreen), findsOneWidget);
    });

    testWidgets('unknown route redirects to dashboard', (tester) async {
      final router = await pumpRouter(tester, user: user);

      router.go('/not-a-real-route');
      await tester.pumpAndSettle();

      expect(currentUri(router).path, AppRoutes.home);
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('dashboard feature paths render the matching section', (
      tester,
    ) async {
      final router = await pumpRouter(tester, user: user);

      final cases = {
        AppRoutes.dashboardShoots: 'Shoots',
        AppRoutes.shootDetail('job-bag'): 'Tan Leather Bag',
        AppRoutes.dashboardProducts: 'Products',
        AppRoutes.dashboardModels: 'House Models',
        AppRoutes.dashboardBilling: 'Billing',
        AppRoutes.dashboardAccount: 'Settings',
        AppRoutes.dashboardSupport: 'Support',
        AppRoutes.dashboardGuides: 'Guides',
      };
      final screens = <String, Type>{
        AppRoutes.dashboardShoots: ShootsScreen,
        AppRoutes.shootDetail('job-bag'): ShootDetailScreen,
        AppRoutes.dashboardProducts: ProductsScreen,
        AppRoutes.dashboardModels: HouseModelsScreen,
        AppRoutes.dashboardBilling: BillingScreen,
        AppRoutes.dashboardAccount: AccountSettingsScreen,
        AppRoutes.dashboardSupport: SupportScreen,
        AppRoutes.dashboardGuides: GuidesScreen,
      };

      for (final entry in cases.entries) {
        router.go(entry.key);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(currentUri(router).path, entry.key);
        expect(find.byType(screens[entry.key]!), findsOneWidget);
        expect(find.byType(Drawer), findsNothing);
        expect(find.byIcon(Icons.menu), findsNothing);
        expect(find.byType(CustomAppBar), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(CustomAppBar),
            matching: find.byIcon(Icons.arrow_back),
          ),
          findsOneWidget,
        );
        expect(find.text(entry.value), findsWidgets);
      }
    });

    testWidgets('create shoot path renders its standalone screen', (
      tester,
    ) async {
      final router = await pumpRouter(tester, user: user);

      router.go(AppRoutes.createShoot);
      await tester.pumpAndSettle();

      expect(currentUri(router).path, AppRoutes.createShoot);
      expect(find.byType(CreateShootScreen), findsOneWidget);
      expect(find.byType(CustomAppBar), findsOneWidget);
      expect(find.text('Create Shoot'), findsWidgets);
    });

    testWidgets('campaignActions_openFocusedShootBackAndWorkshopRoutes', (
      tester,
    ) async {
      final welcomeRepository = FakeWelcomeRepository(
        state: fakeEligibleWelcomeState(
          dashboard: fakeDashboardWelcomeState(
            completed: 6,
            rewardClaimedAt: DateTime(2026, 8, 17),
            campaign: const DashboardWelcomeCampaign(
              jobId: 'job-bag',
              keptImages: 1,
              images: [],
            ),
          ),
        ),
      );
      final router = await pumpRouter(
        tester,
        user: user,
        welcomeRepository: welcomeRepository,
        settle: false,
      );

      router.go(AppRoutes.home);
      final openShoot = find.text('Open shoot (1 kept)');
      for (
        var attempt = 0;
        attempt < 20 && openShoot.evaluate().isEmpty;
        attempt++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(openShoot, findsOneWidget);
      await tester.ensureVisible(openShoot);
      await tester.pump(const Duration(milliseconds: 300));
      tester
          .widget<FilledButton>(
            find.ancestor(of: openShoot, matching: find.byType(FilledButton)),
          )
          .onPressed!();
      expect(currentUri(router).path, '/shoots/job-bag');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(currentUri(router).path, '/shoots/job-bag');
      expect(currentUri(router).queryParameters['from'], 'dashboard');
      expect(find.text('Back to Dashboard'), findsOneWidget);

      await tester.tap(find.text('Back to Dashboard'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(currentUri(router).path, AppRoutes.home);
      expect(
        find.byKey(const ValueKey('dashboard-campaign-hero')),
        findsOneWidget,
      );

      final workshop = find.text('Fix a small flaw');
      await tester.ensureVisible(workshop);
      await tester.pump(const Duration(milliseconds: 300));
      tester
          .widget<OutlinedButton>(
            find.ancestor(of: workshop, matching: find.byType(OutlinedButton)),
          )
          .onPressed!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(currentUri(router).path, AppRoutes.workshop);
    });

    testWidgets('workshop route renders as a standalone feature', (
      tester,
    ) async {
      final router = await pumpRouter(tester, user: user);

      router.go(AppRoutes.workshop);
      await tester.pumpAndSettle();

      expect(currentUri(router).path, AppRoutes.workshop);
      expect(find.byType(WorkshopScreen), findsOneWidget);
      expect(find.byType(Drawer), findsNothing);
      expect(find.byIcon(Icons.menu), findsNothing);
      expect(
        find.textContaining('Reshape any photo with a sentence'),
        findsOneWidget,
      );
    });

    testWidgets('workshop guide opens and returns through GoRouter', (
      tester,
    ) async {
      final router = await pumpRouter(tester, user: user);

      router.go(AppRoutes.workshop);
      await tester.pumpAndSettle();
      final guideButton = find.text('HOW DOES THIS WORK?');
      await tester.ensureVisible(guideButton);
      await tester.pumpAndSettle();
      await tester.tap(
        find.ancestor(of: guideButton, matching: find.byType(InkWell)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WorkshopGuideScreen), findsOneWidget);
      expect(find.byType(Drawer), findsNothing);
      expect(find.text('One image, one prompt, one credit.'), findsOneWidget);

      final restyle = find.text('Restyle a product');
      for (var i = 0; i < 5 && restyle.evaluate().isEmpty; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();
      }
      expect(restyle, findsOneWidget);

      final gotIt = find.text('Got it', skipOffstage: false);
      await tester.scrollUntilVisible(
        gotIt,
        600,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      expect(currentUri(router).path, AppRoutes.workshop);
      expect(find.byType(WorkshopScreen), findsOneWidget);
    });

    testWidgets('workshop upgrade sheet opens the real paywall route', (
      tester,
    ) async {
      final router = await pumpRouter(tester, user: user);

      router.go(AppRoutes.workshop);
      await tester.pumpAndSettle();
      final generate = find.byKey(const Key('workshop-generate-button'));
      await tester.scrollUntilVisible(
        generate,
        500,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(generate);
      await tester.pumpAndSettle();

      expect(find.text('SUBSCRIBER FEATURE'), findsOneWidget);
      await tester.tap(find.text('View plans'));
      await tester.pumpAndSettle();

      expect(currentUri(router).path, AppRoutes.paywall);
      expect(find.byType(PaywallScreen), findsOneWidget);
    });

    testWidgets('dashboard actions navigate through GoRouter paths', (
      tester,
    ) async {
      final router = await pumpRouter(tester, user: user);

      router.go(AppRoutes.home);
      await tester.pumpAndSettle();
      final modelsButton = find.text('Go to Models');
      await tester.ensureVisible(modelsButton);
      await tester.pumpAndSettle();
      await tester.tap(
        find.ancestor(of: modelsButton, matching: find.byType(InkWell)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('House Models'), findsOneWidget);
    });

    testWidgets('guide actions navigate to their app routes', (tester) async {
      final router = await pumpRouter(tester, user: user);

      router.go(AppRoutes.dashboardGuides);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('guide-tab-productPhotos')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Go to Products'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.ancestor(
          of: find.text('Go to Products'),
          matching: find.byType(InkWell),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Products'), findsWidgets);
    });

    testWidgets('drawer pushes the selected feature over the dashboard', (
      tester,
    ) async {
      final router = await pumpRouter(tester, user: user, settle: false);

      router.go(AppRoutes.home);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byIcon(LucideIcons.menu));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.byKey(const ValueKey('dashboard-drawer-models')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(Drawer), findsNothing);
      expect(find.byType(HouseModelsScreen), findsOneWidget);
      expect(find.text('House Models'), findsOneWidget);

      router.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets(
      'drawer navigates to Create Content and displays CustomAppBar with back button and only title',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final router = await pumpRouter(tester, user: user, settle: false);

        router.go(AppRoutes.home);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.byIcon(LucideIcons.menu));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.drag(
          find.byKey(const ValueKey('dashboard-drawer-scroll')),
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('dashboard-drawer-create-content')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(Drawer), findsNothing);
        expect(find.byType(CreateContentScreen), findsOneWidget);
        final customAppBar = tester.widget<CustomAppBar>(
          find.byType(CustomAppBar),
        );
        expect(customAppBar.title, 'Create Content');
        expect(customAppBar.showBackButton, isTrue);
        expect(customAppBar.actions, isEmpty);

        await tester.tap(find.byTooltip('Back'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(DashboardScreen), findsOneWidget);
      },
    );

    testWidgets(
      'drawer navigates to Calendar and displays CustomAppBar with back button and only title',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final router = await pumpRouter(tester, user: user, settle: false);

        router.go(AppRoutes.home);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.byIcon(LucideIcons.menu));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.drag(
          find.byKey(const ValueKey('dashboard-drawer-scroll')),
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('dashboard-drawer-calendar')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(Drawer), findsNothing);
        expect(find.byType(CalendarScreen), findsOneWidget);
        final customAppBar = tester.widget<CustomAppBar>(
          find.byType(CustomAppBar),
        );
        expect(customAppBar.title, 'Calendar');
        expect(customAppBar.showBackButton, isTrue);
        expect(customAppBar.actions, isEmpty);

        await tester.tap(find.byTooltip('Back'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(DashboardScreen), findsOneWidget);
      },
    );
  });

  testWidgets(
    'Create Content formats and Calendar generation deep links resolve',
    (tester) async {
      final router = await pumpRouter(tester, user: user, settle: false);
      for (final path in [
        AppRoutes.createContent,
        AppRoutes.createContentSingle,
        AppRoutes.createContentSlideshow,
        AppRoutes.createContentVideo,
        '/create-content/item/generation-1',
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(find.byType(CreateContentScreen), findsOneWidget);
        expect(router.routeInformationProvider.value.uri.path, path);
      }
      expect(find.text('CAPTION & HASHTAGS'), findsNothing);
      router.go('/create-content/item/generation-1?panel=caption');
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.queryParameters['panel'],
        'caption',
      );
      expect(find.text('CAPTION & HASHTAGS'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back to Create Content'));
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        AppRoutes.createContent,
      );
    },
  );

  testWidgets('leaving Create Content waits for saves and stays on failure', (
    tester,
  ) async {
    final backend = ContentTestBackend();
    final router = await pumpRouter(
      tester,
      user: user,
      contentBackend: backend,
      settle: false,
    );
    router.go(AppRoutes.createContentSlideshow);
    await tester.pumpAndSettle();
    backend.handler = (request) {
      if (request.method == 'POST' && request.path == '/content/drafts') {
        throw StateError('Offline');
      }
      return backend.respond(request);
    };
    await tester.tap(find.text('Brief'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Utility Bomber'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back to Create Content'));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.createContentSlideshow,
    );
    expect(
      find.text('Your changes are not saved. Retry saving before leaving.'),
      findsOneWidget,
    );
    backend.handler = null;
    await tester.tap(find.byTooltip('Back to Create Content'));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.createContent,
    );
  });
}
