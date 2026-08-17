import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/features/dashboard/presentation/widgets/campaign_flip_card.dart';

void main() {
  const shots = [
    CampaignShot(id: 'image-1', url: null, approved: false),
    CampaignShot(id: 'image-2', url: null, approved: false),
  ];

  Future<void> pumpCard(
    WidgetTester tester, {
    List<CampaignShot> images = shots,
    bool claimed = true,
    bool reduceMotion = false,
    ToggleCampaignShot? onToggle,
    VoidCallback? onWorkshop,
  }) => tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: CampaignFlipCard(
              jobId: 'job-1',
              images: images,
              checklistClaimed: claimed,
              claiming: false,
              imagesLoading: false,
              onClaim: () {},
              onToggleKeep: onToggle ?? (_, {required approved}) async => null,
              onOpenShoot: () {},
              onOpenWorkshop: onWorkshop ?? () {},
              onDone: () {},
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('rewardAndRetirement_visibilityFollowsClaimState', (
    tester,
  ) async {
    await pumpCard(tester, claimed: false);

    expect(
      find.text('Studio built. Claim your 20 free credits'),
      findsOneWidget,
    );
    expect(find.text("I'm all set, hide this"), findsNothing);

    await pumpCard(tester);

    expect(
      find.text('Studio built. Claim your 20 free credits'),
      findsNothing,
    );
    expect(find.text("I'm all set, hide this"), findsOneWidget);
  });

  testWidgets('rapidSelection_keepsIndependentRequestsDisabled', (
    tester,
  ) async {
    final pending = <String, Completer<Failure?>>{};
    await pumpCard(
      tester,
      onToggle: (shot, {required approved}) {
        final completer = Completer<Failure?>();
        pending[shot.id] = completer;
        return completer.future;
      },
    );

    await tester.tap(find.byKey(const ValueKey('image-1')));
    await tester.pump();
    expect(find.text('Open shoot (1 kept)'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('image-2')));
    await tester.pump();
    expect(find.text('Open shoot (2 kept)'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNWidgets(2));

    pending['image-1']!.complete(null);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pending['image-2']!.complete(null);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('failedSelection_revertsOnlyFailedImageAndShowsError', (
    tester,
  ) async {
    final result = Completer<Failure?>();
    await pumpCard(
      tester,
      onToggle: (_, {required approved}) => result.future,
    );

    await tester.tap(find.byKey(const ValueKey('image-1')));
    await tester.pump();
    expect(find.text('Open shoot (1 kept)'), findsOneWidget);
    result.complete(const NetworkFailure('Approval failed'));
    await tester.pump();

    expect(find.text('Open the shoot'), findsOneWidget);
    expect(find.text("Couldn't save that. Try again."), findsOneWidget);
  });

  testWidgets('workshop_inlineAndButton_useSameNavigationAction', (
    tester,
  ) async {
    var opens = 0;
    await pumpCard(tester, onWorkshop: () => opens++);

    await tester.tap(find.text('fix it in Workshop'));
    await tester.tap(find.text('Fix a small flaw'));

    expect(opens, 2);
  });

  testWidgets('reducedMotion_disablesSelectionOpacityAnimation', (
    tester,
  ) async {
    await pumpCard(tester, reduceMotion: true);

    final opacity = tester.widget<AnimatedOpacity>(
      find.descendant(
        of: find.byKey(const ValueKey('image-1')),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(opacity.duration, Duration.zero);
  });

  testWidgets('imageStrip_limitsSpecificJobResultsToTenStableIds', (
    tester,
  ) async {
    final images = List.generate(
      11,
      (index) => CampaignShot(
        id: 'shot-$index',
        url: null,
        approved: false,
      ),
    );
    await pumpCard(tester, images: images);

    expect(find.byKey(const ValueKey('shot-0')), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(-1000, 0));
    await tester.pump();
    expect(find.byKey(const ValueKey('shot-9')), findsOneWidget);
    expect(find.byKey(const ValueKey('shot-10')), findsNothing);
  });

  testWidgets('compactPhone_rendersWithoutOverflow', (tester) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpCard(tester);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Your first shoot is done.'), findsOneWidget);
  });
}
