import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_models.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/steps/product_step.dart';

void main() {
  Widget buildTestWidget({
    VoidCallback? onContinue,
    VoidCallback? onBack,
    Size size = const Size(390, 844),
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: Scaffold(
            body: ProductStep(
              phase: ProductPhase.category,
              onContinueCategory: onContinue,
              onBackCategory: onBack,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'phone layout renders branding, 7 segments, filters, and categories',
    (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('LOOK ATLAS'), findsOneWidget);
      expect(find.text('CATEGORY'), findsOneWidget);
      expect(find.text('Step 1 of 7'), findsOneWidget);
      expect(find.text('What are you shooting?'), findsOneWidget);
      expect(
        find.text(
          'This helps us show you the best way to photograph your product.',
        ),
        findsOneWidget,
      );

      // Filter chips present
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Apparel'), findsOneWidget);
      expect(find.text('Accessories'), findsWidgets);
      expect(find.text('Footwear'), findsOneWidget);
      expect(find.text('Other'), findsWidgets);

      // Initial categories present
      expect(find.text('Tops'), findsOneWidget);
      expect(find.text('Dresses'), findsOneWidget);
      expect(find.text('Outwear'), findsOneWidget);
      expect(find.text('Bottoms'), findsOneWidget);
      expect(find.text('Shoes'), findsOneWidget);
      expect(find.text('Jewelry'), findsOneWidget);

      // Bottom navigation buttons present
      expect(find.text('BACK'), findsOneWidget);
      expect(find.text('CONTINUE'), findsOneWidget);
    },
  );

  testWidgets(
    'filter chips filter displayed categories via Riverpod state without setState',
    (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap Footwear filter
      await tester.ensureVisible(find.text('Footwear'));
      await tester.tap(find.text('Footwear'));
      await tester.pumpAndSettle();

      // Only Shoes should appear
      expect(find.text('Shoes'), findsOneWidget);
      expect(find.text('Tops'), findsNothing);
      expect(find.text('Dresses'), findsNothing);

      // Tap Apparel filter
      await tester.ensureVisible(find.text('Apparel'));
      await tester.tap(find.text('Apparel'));
      await tester.pumpAndSettle();

      expect(find.text('Tops'), findsOneWidget);
      expect(find.text('Dresses'), findsOneWidget);
      expect(find.text('Outwear'), findsOneWidget);
      expect(find.text('Bottoms'), findsOneWidget);
      expect(find.text('Shoes'), findsNothing);

      // Tap All filter
      await tester.ensureVisible(find.text('All'));
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(find.text('Tops'), findsOneWidget);
      expect(find.text('Shoes'), findsOneWidget);
    },
  );

  testWidgets('selecting category highlights tile and triggers onContinue', (
    tester,
  ) async {
    var continued = false;
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildTestWidget(onContinue: () => continued = true),
    );
    await tester.pumpAndSettle();

    // Tap Tops category
    await tester.tap(find.text('Tops'));
    await tester.pumpAndSettle();

    // Checkmark appears for selected category
    expect(find.byIcon(Icons.check), findsOneWidget);

    // Tap CONTINUE
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    expect(continued, isTrue);
  });

  testWidgets(
    'wide layout renders 3-column split view (sidebar, content, hero)',
    (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestWidget(size: const Size(1024, 768)),
      );
      await tester.pumpAndSettle();

      // Sidebar
      expect(find.text('STEP 01 • SELECT CATEGORY'), findsOneWidget);
      expect(find.text('Select product category'), findsOneWidget);
      expect(find.text('Step 1 of 7 - about 6 minutes'), findsOneWidget);

      // Hero Panel
      expect(
        find.text('Studio quality outputs.\nFor every product.'),
        findsOneWidget,
      );
    },
  );
}
