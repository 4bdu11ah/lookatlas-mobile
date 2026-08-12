import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/features/shoots/data/models/shoots_api_codec.dart';
import 'package:look_atlas/features/shoots/domain/entities/shoot_create.dart';

void main() {
  test('custom_shot_payload_omits_empty_optional_fields', () {
    final payload = ShootsApiCodec.customShotPayload(
      const CustomShootShotRequest(
        selection: ShootSelection(
          products: [
            ShootCatalogItem(id: 'product-1', name: 'Bag', imageUrl: ''),
          ],
          models: [
            ShootCatalogItem(id: 'model-1', name: 'Mila', imageUrl: ''),
          ],
          settings: ShootSettings(),
        ),
        shotIdea: 'Close detail of stitching',
        existingShots: [],
      ),
    );

    expect(payload, isNot(contains('poseDirection')));
    expect(payload, isNot(contains('focusArea')));
    expect(payload, isNot(contains('backgroundNotes')));
  });

  test('plan_payload_sends_heirloom_styling_only_when_nonempty', () {
    final payload = ShootsApiCodec.planPayload(
      const ShootSelection(
        products: [
          ShootCatalogItem(id: 'product-1', name: 'Dress', imageUrl: ''),
        ],
        models: [
          ShootCatalogItem(id: 'model-1', name: 'Mila', imageUrl: ''),
        ],
        settings: ShootSettings(
          directorId: 'heirloom-children',
          stylingNotes: {'dressLength': '  Below knee  ', 'other': ' '},
        ),
      ),
    );

    expect(payload['stylingNotes'], {'dressLength': 'Below knee'});
  });

  test('plan_payload_omits_blank_director_feedback', () {
    final payload = ShootsApiCodec.planPayload(
      const ShootSelection(
        products: [
          ShootCatalogItem(id: 'product-1', name: 'Dress', imageUrl: ''),
        ],
        models: [
          ShootCatalogItem(id: 'model-1', name: 'Mila', imageUrl: ''),
        ],
        settings: ShootSettings(directorFeedback: '   '),
      ),
    );

    expect(payload, isNot(contains('directorFeedback')));
  });

  test('subscription_unlimited_eligibility_matches_director_spec', () {
    expect(
      const ShootSubscription(
        plan: 'pro',
        status: 'past_due',
      ).isUnlimitedEligible(relaxEnabled: true),
      isTrue,
    );
    expect(
      const ShootSubscription(
        plan: 'enterprise',
        status: 'trialing',
      ).isUnlimitedEligible(relaxEnabled: true),
      isFalse,
    );
  });

  test('create_payload_round_trips_shot_payload', () {
    final payload = ShootsApiCodec.createPayload(
      const CreateShootRequest(
        selection: ShootSelection(
          products: [
            ShootCatalogItem(id: 'product-1', name: 'Bag', imageUrl: ''),
          ],
          models: [
            ShootCatalogItem(id: 'model-1', name: 'Mila', imageUrl: ''),
          ],
          settings: ShootSettings(),
        ),
        shots: [
          PlannedShootShot(
            title: 'Hero',
            description: 'Front view',
            payload: {
              'id': 'shot-1',
              'prompt': 'Keep this prompt',
              'models': ['primary'],
              'products': ['product-1'],
              'productByModel': {'primary': 'product-1'},
            },
          ),
        ],
      ),
    );

    expect(payload, isNot(contains('demoGroupId')));
    expect(
      (payload['shots'] as List).single,
      containsPair('prompt', 'Keep this prompt'),
    );
    expect(
      (payload['shots'] as List).single,
      containsPair('productByModel', {'primary': 'product-1'}),
    );
  });

  test('create_payload_sends_demo_group_id_without_private_prompt', () {
    final payload = ShootsApiCodec.createPayload(
      const CreateShootRequest(
        demoGroupId: 'demo-group-id',
        selection: ShootSelection(
          products: [
            ShootCatalogItem(id: 'product-1', name: 'Bag', imageUrl: ''),
          ],
          models: [
            ShootCatalogItem(id: 'model-1', name: 'Mila', imageUrl: ''),
          ],
          settings: ShootSettings(),
        ),
        shots: [],
      ),
    );

    expect(payload['demoGroupId'], 'demo-group-id');
    expect(payload.toString(), isNot(contains('stylePrompt')));
  });
}
