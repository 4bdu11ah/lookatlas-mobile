import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/features/studio_school/data/models/welcome_profile_model.dart';
import 'package:look_atlas/features/studio_school/domain/entities/welcome_profile_draft.dart';

void main() {
  test('normalizeBrandUrl_removesTransportAndPreservesMarketplacePath', () {
    expect(
      normalizeBrandUrl(' HTTPS://WWW.ETSY.COM/Shop/Atlas/// '),
      'etsy.com/shop/atlas',
    );
  });

  test('brandUrlLooksValid_rejectsTextWithoutDomain', () {
    expect(brandUrlLooksValid('my store'), isFalse);
    expect(brandUrlLooksValid('shop.example.com/products'), isTrue);
    expect(brandUrlLooksValid(''), isTrue);
  });

  test('payload_omitsEmptyAnswers', () {
    const draft = WelcomeProfileDraft(
      brandUrl: ' example.com ',
      primaryUses: ['ads'],
      dropCadence: 'ongoing_drops',
      referral: 'other',
    );

    expect(WelcomeProfileModel.toJson(draft), {
      'brandUrl': 'example.com',
      'primaryUses': ['ads'],
      'dropCadence': 'ongoing_drops',
      'referral': 'other',
    });
  });
}
