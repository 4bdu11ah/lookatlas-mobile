import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/features/shoots/data/models/shoot_draft_codec.dart';
import 'package:look_atlas/features/shoots/domain/entities/shoot_draft.dart';

void main() {
  test('draft_list_decodes_server_summary_fields', () {
    final drafts = ShootDraftCodec.decodeList({
      'drafts': [
        {
          'id': 'draft-1',
          'title': 'Autumn Tailored Blazer',
          'currentStep': 'director',
          'thumbnailUrl': 'https://example.com/blazer.jpg',
          'updatedAt': '2026-09-16T10:30:00.000Z',
        },
      ],
    });

    expect(drafts.single.id, 'draft-1');
    expect(drafts.single.title, 'Autumn Tailored Blazer');
    expect(drafts.single.currentStep, 'director');
    expect(drafts.single.thumbnailUrl, 'https://example.com/blazer.jpg');
    expect(drafts.single.updatedAt, DateTime.utc(2026, 9, 16, 10, 30));
  });

  test('draft_snapshot_round_trips_every_wizard_selection', () {
    const snapshot = ShootDraftSnapshot(
      currentStep: 'planning',
      productMode: 'variant',
      selectedProductIds: ['product-1', 'product-2'],
      selectedModelIds: ['user:model-1'],
      directorId: 'clean-pro',
      settings: {
        'useCase': 'social',
        'aspectRatio': '4:5',
        'variations': 3,
      },
      plannedShots: [
        {
          'title': 'Hero',
          'shortDescription': 'Front view',
          'prompt': 'Studio hero',
        },
      ],
      selectedShots: [0],
    );

    expect(
      ShootDraftSnapshot.fromJson(snapshot.toJson()).toJson(),
      snapshot.toJson(),
    );
    expect(ShootDraftCodec.savePayload(snapshot), {'state': snapshot.toJson()});
  });

  test('local_mirror_key_is_scoped_to_the_authenticated_user', () {
    expect(
      ShootDraftMirror.storageKey('user-123'),
      'lookatlas:create-shoot:mirror:user-123',
    );
  });
}
