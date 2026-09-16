import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/providers/core_providers.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/dashboard/di/dashboard_providers.dart';
import 'package:look_atlas/features/dashboard/presentation/controllers/retention_countdown_controller.dart';
import 'package:look_atlas/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:look_atlas/features/dashboard/presentation/widgets/overview_collection.dart';
import 'package:look_atlas/features/dashboard/presentation/widgets/overview_rooms.dart';
import 'package:look_atlas/features/studio_school/di/studio_school_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/dashboard_gallery_fixture.dart';
import '../../helpers/fake_repositories.dart';
import '../../helpers/fake_welcome_repository.dart';
import '../../helpers/learning_center_test_fonts.dart';
import '../../helpers/tolerant_golden_file_comparator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadLearningCenterTestFonts);
  for (final section in ['overview', 'collection', 'creative_rooms', 'setup']) {
    testWidgets('dashboard_${section}_matchesMobileGallery', (tester) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
            dashboardRepositoryProvider.overrideWithValue(
              FakeDashboardRepository(overview: dashboardGalleryFixture()),
            ),
            authRepositoryProvider.overrideWithValue(
              FakeAuthRepository(
                user: const AppUser(
                  id: 'golden-user',
                  email: 'studio@example.com',
                ),
              ),
            ),
            welcomeRepositoryProvider.overrideWithValue(
              FakeWelcomeRepository(
                state: section == 'setup'
                    ? fakeEligibleWelcomeState(
                        dashboard: fakeDashboardWelcomeState(),
                      )
                    : null,
              ),
            ),
            dashboardClockProvider.overrideWithValue(
              () => DateTime.utc(2026, 9, 15, 12),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: const DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(DashboardScreen));
      await tester.runAsync(() async {
        for (final image in [
          'assets/images/onboarding/showcase-tshirt-before.jpg',
          'assets/images/onboarding/showcase-dress-before.jpg',
          'assets/images/onboarding/showcase-dress-after.jpg',
          'assets/images/onboarding/showcase-bag-before.jpg',
          'assets/images/onboarding/showcase-tshirt-after.jpg',
          'assets/images/dashboard/brand_studio.jpg',
          'assets/images/dashboard/design_boards.jpg',
          'assets/images/dashboard/lookbooks.jpg',
          'assets/images/dashboard/social_studio.jpg',
          'assets/images/dashboard/human_finishing.jpg',
        ]) {
          await precacheImage(AssetImage(image), context);
        }
      });
      if (section == 'collection' || section == 'creative_rooms') {
        final target = section == 'collection'
            ? find.byType(OverviewCollection)
            : find.byType(OverviewCreativeRooms);
        await tester.scrollUntilVisible(
          target,
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(target);
      }
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        for (final element in find.byType(Image).evaluate()) {
          await precacheImage((element.widget as Image).image, element);
        }
      });
      await tester.pumpAndSettle();
      final previous = goldenFileComparator;
      goldenFileComparator = TolerantGoldenFileComparator(
        Uri.parse('test/features/dashboard/dashboard_gallery_golden_test.dart'),
        precisionTolerance: .02,
      );
      addTearDown(() => goldenFileComparator = previous);
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/dashboard_$section.png'),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
