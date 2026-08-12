import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/features/onboarding/domain/onboarding_models.dart';

void main() {
  test('director_catalog_contains_complete_canonical_details', () {
    expect(
      directors.map((director) => director.id),
      [
        'clean-pro',
        'luxury-editorial',
        'bold-dramatic',
        'street-energy',
        'minimalist',
        'lifestyle-natural',
        'fine-jewelry',
        'editorial-jewelry',
        'heirloom-children',
      ],
    );

    final alex = directors.first;
    expect(alex.apiId, alex.id);
    expect(alex.brands, 'Uniqlo, Everlane, Gap, COS');
    expect(alex.story, contains("Uniqlo's Tokyo headquarters"));
    expect(alex.signature, contains('photography so clean'));
    expect(
      alex.portfolioDescriptions.first,
      contains('classic layering piece'),
    );

    final devon = directors[7];
    expect(devon.portfolioImages, hasLength(12));
    expect(devon.story, contains("Net-a-Porter's in-house studio"));

    final beatrice = directors.last;
    expect(
      beatrice.brands,
      'Bonpoint, Tartine et Chocolat, La Coqueta, Jacadi',
    );
    expect(beatrice.signature, contains('modest and real'));
  });
}
