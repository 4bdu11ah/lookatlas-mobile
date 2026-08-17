import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_welcome.dart';
import 'package:look_atlas/features/dashboard/presentation/widgets/dashboard_step_guide.dart';

void main() {
  test('guideCatalog_containsExactSixStepContracts', () {
    expect(dashboardGuideContent.length, 6);
    expect(
      dashboardGuideContent[DashboardWelcomeStepId.product]?.tip,
      'Phone photos are fine. What matters is even light and a plain background.',
    );
    expect(
      dashboardGuideContent[DashboardWelcomeStepId.calibration]
          ?.sections
          .length,
      3,
    );
    expect(
      dashboardGuideContent[DashboardWelcomeStepId.angles]?.sections.length,
      2,
    );
    expect(
      dashboardGuideContent[DashboardWelcomeStepId.firstShoot]?.cta,
      'Start a shoot',
    );
  });

  testWidgets('calibrationGuide_320px_keepsHeaderAndFooterVisible', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: DashboardStepGuideDialog(
                step: DashboardWelcomeStepId.calibration,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Calibrate sizes'), findsOneWidget);
    expect(find.text('Go to Products'), findsOneWidget);
    expect(find.text('Screenshot coming soon'), findsWidgets);
    expect(find.byType(ListView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('availableGuideAsset_replacesItsPlaceholder', (tester) async {
    final bundle = _GuideAssetBundle();

    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: bundle,
        child: const MaterialApp(
          home: Scaffold(
            body: DashboardStepGuideDialog(
              step: DashboardWelcomeStepId.product,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      bundle.requested,
      contains('assets/images/guides/addProduct-1.png'),
    );
    expect(find.byType(Image), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

class _GuideAssetBundle extends CachingAssetBundle {
  final requested = <String>[];

  @override
  Future<ByteData> load(String key) {
    requested.add(key);
    return rootBundle.load('assets/images/logo.png');
  }
}
