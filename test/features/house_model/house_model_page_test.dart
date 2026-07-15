import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/dashboard/presentation/screens/dashboard_screen.dart';

import '../../helpers/fake_repositories.dart';

void main() {
  Future<void> pumpModels(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(
              user: const AppUser(id: 'user-1', email: 'jane@example.com'),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const DashboardFeatureScreen.models(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('house model page expands the LookAtlas library', (tester) async {
    await pumpModels(tester);

    expect(find.text('House Models'), findsOneWidget);
    expect(find.text('Sofia'), findsOneWidget);
    expect(find.text('Imani'), findsNothing);

    await tester.ensureVisible(find.byKey(const ValueKey('show-more-models')));
    await tester.tap(find.byKey(const ValueKey('show-more-models')));
    await tester.pumpAndSettle();

    expect(find.text('Imani'), findsOneWidget);
    expect(find.text('Showing 6 of 6 models'), findsOneWidget);
  });

  testWidgets('house model page filters by gender', (tester) async {
    await pumpModels(tester);

    await tester.tap(find.byKey(const ValueKey('filter-models')));
    await tester.pumpAndSettle();
    expect(find.text('All genders'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
    expect(find.text('Non-binary'), findsOneWidget);
    expect(find.text('All body types'), findsOneWidget);
    expect(find.text('Average'), findsWidgets);
    expect(find.text('Petite'), findsWidgets);
    expect(find.text('Slim/Athletic'), findsWidgets);
    expect(find.text('Plus-size/Curvy'), findsWidgets);
    await tester.tap(find.text('Male'));
    await tester.ensureVisible(find.text('Show models'));
    await tester.tap(find.text('Show models'));
    await tester.pumpAndSettle();

    expect(find.text('Kai'), findsOneWidget);
    expect(find.text('Noah'), findsOneWidget);
    expect(find.text('Sofia'), findsNothing);
    expect(find.text('Showing 2 of 2 models'), findsOneWidget);
  });

  testWidgets('house model page clears filters and closes the sheet', (
    tester,
  ) async {
    await pumpModels(tester);

    await tester.tap(find.byKey(const ValueKey('filter-models')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Male'));
    await tester.ensureVisible(find.text('Show models'));
    await tester.tap(find.text('Show models'));
    await tester.pumpAndSettle();
    expect(find.text('Showing 2 of 2 models'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('filter-models')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(find.text('All genders'), findsNothing);
    expect(find.text('Sofia'), findsOneWidget);
    expect(find.text('Showing 4 of 6 models'), findsOneWidget);
  });

  testWidgets('house model page shows empty Your Models actions', (
    tester,
  ) async {
    await pumpModels(tester);

    await tester.ensureVisible(find.text('No models added yet'));

    expect(find.text('No models added yet'), findsOneWidget);
    expect(
      find.text(
        'Upload your first house model to get started with on-model image generation.',
      ),
      findsOneWidget,
    );
    expect(find.text('Add your first model'), findsOneWidget);
    expect(find.text('Create with AI (20 credits)'), findsOneWidget);
    // expect(find.text('3-5 clear photos work best'), findsOneWidget);
  });

  testWidgets('house model empty state actions open their flows', (
    tester,
  ) async {
    await pumpModels(tester);

    await tester.ensureVisible(find.text('Add your first model'));
    await tester.tap(find.text('Add your first model'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Add New Model'), findsOneWidget);

    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Create with AI (20 credits)'));
    await tester.tap(find.text('Create with AI (20 credits)'));
    await tester.pumpAndSettle();
    expect(find.text('Create your own model (AI)'), findsOneWidget);
  });

  testWidgets('house model grid changes angle by tap and swipe', (
    tester,
  ) async {
    await pumpModels(tester);

    expect(find.byIcon(Icons.more_horiz), findsNothing);
    expect(find.text('FRONT'), findsWidgets);
    expect(
      find.byKey(const ValueKey('model-sofia-angle-front-active')),
      findsOneWidget,
    );

    await tester.tap(find.text('Sofia'));
    await tester.pumpAndSettle();
    expect(find.text('Model profile'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('model-sofia-angle-left')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('model-sofia-angle-left-active')),
      findsOneWidget,
    );
    expect(find.text('LEFT'), findsWidgets);

    await tester.drag(
      find.byKey(const ValueKey('model-sofia-angle-pager')),
      const Offset(-220, 0),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('model-sofia-angle-right-active')),
      findsOneWidget,
    );
    expect(find.text('RIGHT'), findsWidgets);
  });

  testWidgets('house model page adds an uploaded model', (tester) async {
    await pumpModels(tester);

    await tester.tap(find.byKey(const ValueKey('add-model-fab')));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'Taylor Stone');
    await tester.enterText(find.byType(TextField).at(1), '174');
    await tester.ensureVisible(
      find.byKey(const ValueKey('model-photo-upload')),
    );
    await tester.tap(find.byKey(const ValueKey('model-photo-upload')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('submit-model-form')));
    await tester.tap(find.byKey(const ValueKey('submit-model-form')));
    await tester.pumpAndSettle();

    expect(find.text('Taylor Stone'), findsOneWidget);
    expect(find.text('Taylor Stone was added to Your Models'), findsOneWidget);
  });

  testWidgets('house model page creates an AI model', (tester) async {
    await pumpModels(tester);

    await tester.tap(find.text('Create with AI'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('ai-description')),
      'silver hair editorial model',
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('generate-ai-model')));
    await tester.tap(find.byKey(const ValueKey('generate-ai-model')));
    await tester.pumpAndSettle();

    expect(find.text('Model generated'), findsOneWidget);
    expect(find.text('Silver Hair'), findsOneWidget);
    expect(find.text('Silver Hair is ready'), findsOneWidget);
  });
}
