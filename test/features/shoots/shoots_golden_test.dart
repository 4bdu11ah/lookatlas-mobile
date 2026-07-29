import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:look_atlas/features/shoots/di/shoots_providers.dart';
import 'package:look_atlas/features/subscription/presentation/subscription_controller.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/fake_shoots_repository.dart';
import '../../helpers/test_font_loader.dart';
import '../../helpers/tolerant_golden_file_comparator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadTestFonts);

  testWidgets('shoots_page_matches_mobile_golden', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(
              user: const AppUser(id: 'user-1', email: 'creator@example.com'),
            ),
          ),
          isPremiumProvider.overrideWithValue(true),
          shootsRepositoryProvider.overrideWithValue(
            FakeShootsRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const DashboardFeatureScreen.shoots(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(Scaffold));
    await tester.runAsync(() async {
      for (final asset in const [
        'assets/images/onboarding/showcase-bag-before.jpg',
        'assets/images/onboarding/showcase-shoes-before.jpg',
        'assets/images/onboarding/showcase-dress-after.jpg',
        'assets/images/onboarding/showcase-tshirt-after.jpg',
      ]) {
        await precacheImage(AssetImage(asset), context);
      }
    });
    await tester.pump();

    final previousComparator = goldenFileComparator;
    goldenFileComparator = TolerantGoldenFileComparator(
      Uri.parse('test/features/shoots/shoots_golden_test.dart'),
      precisionTolerance: 0.028,
    );
    addTearDown(() => goldenFileComparator = previousComparator);

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/shoots_page.png'),
    );
  });
}
