import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/features/onboarding/domain/look_atlas_model.dart';
import 'package:look_atlas/features/onboarding/domain/onboarding_models.dart';

void main() {
  group('LookAtlasModel.fromJson', () {
    test('parses the full backend payload', () {
      final model = LookAtlasModel.fromJson(const {
        'id': 'm-1',
        'name': 'Amara',
        'gender': 'female',
        'ethnicity': 'Black',
        'bodyType': 'Athletic',
        'ageRange': '20-30',
        'height': "5'9\"",
        'displayOrder': 3,
        'photos': ['https://cdn/a.jpg', 'https://cdn/b.jpg'],
        'coverThumbnail': 'https://cdn/cover.jpg',
      });

      expect(model.id, 'm-1');
      expect(model.name, 'Amara');
      expect(model.gender, ModelGender.women);
      expect(model.ethnicity, 'Black');
      expect(model.bodyType, 'Athletic');
      expect(model.ageRange, '20-30');
      expect(model.height, "5'9\"");
      expect(model.displayOrder, 3);
      expect(model.photos, hasLength(2));
      expect(model.imageUrl, 'https://cdn/cover.jpg');
    });

    test('falls back to the first photo without a cover thumbnail', () {
      final model = LookAtlasModel.fromJson(const {
        'id': 'm-2',
        'name': 'James',
        'gender': 'MALE',
        'displayOrder': 1,
        'photos': ['https://cdn/james.jpg'],
        'coverThumbnail': null,
      });

      expect(model.gender, ModelGender.men);
      expect(model.imageUrl, 'https://cdn/james.jpg');
    });

    test('tolerates nulls and unknown genders', () {
      final model = LookAtlasModel.fromJson(const {'id': 'm-3'});

      expect(model.name, 'Model');
      expect(model.gender, isNull);
      expect(model.photos, isEmpty);
      expect(model.imageUrl, isEmpty);
      expect(model.displayOrder, 0);
    });
  });
}
