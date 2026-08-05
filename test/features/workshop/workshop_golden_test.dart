import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/features/subscription/presentation/subscription_controller.dart';
import 'package:look_atlas/features/workshop/di/workshop_providers.dart';
import 'package:look_atlas/features/workshop/domain/entities/workshop_models.dart';
import 'package:look_atlas/features/workshop/presentation/screens/workshop_screen.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/test_font_loader.dart';
import '../../helpers/tolerant_golden_file_comparator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadTestFonts);

  testWidgets('workshop_empty_matchesMobileReference', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workshopRepositoryProvider.overrideWithValue(
            FakeWorkshopRepository(),
          ),
          isPremiumProvider.overrideWithValue(true),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const WorkshopScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final previousComparator = goldenFileComparator;
    goldenFileComparator = TolerantGoldenFileComparator(
      Uri.parse('test/features/workshop/workshop_golden_test.dart'),
      precisionTolerance: 0.02,
    );
    addTearDown(() => goldenFileComparator = previousComparator);

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/workshop_empty.png'),
    );
  });

  testWidgets('workshop_historyPreview_matchesMobileReference', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const generation = WorkshopGeneration(
      id: 'history-1',
      status: WorkshopGenerationStatus.completed,
      prompt: 'Add this ring on the model finger',
      imageUrl: 'assets/images/onboarding/showcase-necklace-after.jpg',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workshopRepositoryProvider.overrideWithValue(
            FakeWorkshopRepository(history: [generation]),
          ),
          isPremiumProvider.overrideWithValue(true),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const WorkshopScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => precacheImage(
        const AssetImage(
          'assets/images/onboarding/showcase-necklace-after.jpg',
        ),
        tester.element(find.byType(WorkshopScreen)),
      ),
    );

    final history = find.byKey(const Key('workshop-history-history-1'));
    await tester.ensureVisible(history);
    await tester.tap(history);
    await tester.pumpAndSettle();

    expect(find.text('Add this ring on the model finger'), findsOneWidget);
    expect(find.text('1 of 1'), findsOneWidget);

    final previousComparator = goldenFileComparator;
    goldenFileComparator = TolerantGoldenFileComparator(
      Uri.parse('test/features/workshop/workshop_golden_test.dart'),
      precisionTolerance: 0.02,
    );
    addTearDown(() => goldenFileComparator = previousComparator);

    await expectLater(
      find.byKey(const Key('workshop-history-preview')),
      matchesGoldenFile('goldens/workshop_history_preview.png'),
    );
  });
}
