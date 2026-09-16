import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/features/dashboard/data/dashboard_overview_decoder.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_overview.dart';

Map<String, dynamic> _response() => {
  'credits': {'remaining': 240, 'total': 400, 'used': 160},
  'activity': {
    'activeCount': 1,
    'readyCount': 1,
    'active': [
      {
        'id': 'live',
        'name': 'Silk blouse',
        'status': 'processing',
        'progress': 65,
        'currentStep': 'Step 2/4',
        'updatedAt': '2026-09-15T10:32:00Z',
        'estimatedCompletion': '2026-09-15T10:35:00Z',
      },
    ],
    'ready': [
      {
        'id': 'ready',
        'name': 'Autumn Knitwear',
        'status': 'completed',
        'deliveredImageCount': 12,
        'renders': 99,
        'completedAt': '2026-09-12T08:15:00Z',
        'heroImage': 'assets/hero.jpg',
        'reviewedAt': null,
      },
    ],
    'recentCompleted': [
      {
        'id': 'archive',
        'status': 'completed',
        'renders': 18,
        'reviewedAt': '2026-09-10T14:00:00Z',
      },
    ],
  },
  'activation': {
    'stage': 'ready',
    'firstShootId': 'ready',
    'currentStep': 3,
    'completedStepCount': 3,
    'activatedAt': null,
  },
  'retention': {'ownedShootId': 'owned-outside-lists'},
  'products': {
    'total': 14,
    'newestTwo': [
      {
        'id': 'product',
        'name': 'Merino',
        'sku': 'KNT-804',
        'category': 'Knitwear',
      },
    ],
  },
  'modelPanel': {
    'title': 'Featured Look Atlas models',
    'total': 8,
    'models': [
      {
        'id': 'model',
        'name': 'Elena',
        'source': 'lookatlas',
        'height': '178 cm',
        'description': 'Editorial',
      },
    ],
  },
  'panelStatus': {
    'activity': {'state': 'ready'},
    'products': {'state': 'error'},
    'models': {'state': 'ready'},
  },
};

void main() {
  test('overview_contract_decodesCreditsAndActivation', () {
    final result = decodeDashboardOverview(_response());
    expect(result.credits.credits, 240);
    expect(result.credits.creditsTotal, 400);
    expect(result.credits.creditsUsed, 160);
    expect(result.activation.stage, DashboardActivationStage.ready);
    expect(result.activation.firstShootId, 'ready');
    expect(result.activation.currentStep, 3);
    expect(result.activation.completedStepCount, 3);
    expect(result.activation.activatedAt, isNull);
  });
  test('overview_activity_preservesProgressAndReviewBuckets', () {
    final activity = decodeDashboardOverview(_response()).activity;
    expect(activity.attentionLabel, '02');
    expect(activity.active.single.progress, 65);
    expect(activity.active.single.currentStep, 'Step 2/4');
    expect(activity.active.single.updatedAt, DateTime.utc(2026, 9, 15, 10, 32));
    expect(
      activity.active.single.estimatedCompletion,
      DateTime.utc(2026, 9, 15, 10, 35),
    );
    expect(activity.ready.single.renders, 12);
    expect(activity.ready.single.reviewedAt, isNull);
    expect(activity.ready.single.heroImage, 'assets/hero.jpg');
    expect(activity.recentCompleted.single.id, 'archive');
    expect(activity.recentCompleted.single.reviewedAt, isNotNull);
  });
  test('overview_collections_preserveTotalsAndFeaturedSource', () {
    final result = decodeDashboardOverview(_response());
    expect(result.products.total, 14);
    expect(result.products.items.single.description, 'KNT-804 • Knitwear');
    expect(result.models.title, 'Featured Look Atlas models');
    expect(result.models.items.single.featured, isTrue);
    expect(result.models.items.single.description, '178 cm • Editorial');
    expect(result.products.items.single.thumbnail, isEmpty);
  });
  test('overview_productOutage_doesNotHideOtherPanels', () {
    final result = decodeDashboardOverview(_response());
    expect(result.panelStatus.productsError, isTrue);
    expect(result.panelStatus.activityError, isFalse);
    expect(result.panelStatus.modelsError, isFalse);
    expect(result.activity.ready.single.id, 'ready');
    expect(result.credits.credits, 240);
  });
  test('overview_ownedShootOutsideBuckets_usesExactRetentionId', () {
    final result = decodeDashboardOverview(_response());
    expect(result.ownedShoot?.id, 'owned-outside-lists');
  });
  test('overview_noOwnedShoot_doesNotGuessFromReadyShoot', () {
    final response = _response()..['retention'] = <String, dynamic>{};
    expect(decodeDashboardOverview(response).ownedShoot, isNull);
  });
  test('overview_invalidTopLevel_rejectsMalformedResponse', () {
    for (final value in [
      null,
      <Object?>[],
      <String, dynamic>{},
      {'credits': 240, 'activity': <Object?>[]},
    ]) {
      expect(() => decodeDashboardOverview(value), throwsFormatException);
    }
  });
  test('activation_allStages_useSpecifiedCopyAndAction', () {
    final labels = [
      'Add your first product',
      'View shoot progress',
      'Review final images',
      'Create a shoot',
    ];
    for (final stage in DashboardActivationStage.values) {
      final activation = DashboardActivation(stage: stage);
      expect(activation.actionLabel, labels[stage.index]);
      expect(activation.intro, isNotEmpty);
      final response = _response()..['activation'] = {'stage': stage.name};
      expect(decodeDashboardOverview(response).activation.stage, stage);
    }
  });
}
