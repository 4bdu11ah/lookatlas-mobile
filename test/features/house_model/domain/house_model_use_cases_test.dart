import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/house_model/domain/entities/house_model_profile.dart';
import 'package:look_atlas/features/house_model/domain/repositories/house_models_repository.dart';
import 'package:look_atlas/features/house_model/domain/use_cases/complete_house_model_generation_use_case.dart';
import 'package:look_atlas/features/house_model/domain/use_cases/create_house_model_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockHouseModelsRepository extends Mock
    implements HouseModelsRepository {}

void main() {
  test('create_missingName_returnsValidationWithoutRepositoryCall', () async {
    final repository = _MockHouseModelsRepository();
    final draft = HouseModelDraft(
      name: ' ',
      gender: 'female',
      heightCm: 170,
      heightEstimated: false,
      photos: [HouseModelUpload(bytes: Uint8List(1), fileName: 'model.jpg')],
    );

    final result = await CreateHouseModelUseCase(repository)(draft);

    expect(result.failureOrNull, isA<ValidationFailure>());
    verifyNever(() => repository.createModel(draft));
  });

  test('create_missingGender_returnsValidationWithoutRepositoryCall', () async {
    final repository = _MockHouseModelsRepository();
    final draft = _draft(gender: '');

    final result = await CreateHouseModelUseCase(repository)(draft);

    expect(result.failureOrNull, isA<ValidationFailure>());
    verifyNever(() => repository.createModel(draft));
  });

  test('create_invalidHeight_returnsValidationWithoutRepositoryCall', () async {
    final repository = _MockHouseModelsRepository();
    final draft = _draft(heightCm: 99);

    final result = await CreateHouseModelUseCase(repository)(draft);

    expect(result.failureOrNull, isA<ValidationFailure>());
    verifyNever(() => repository.createModel(draft));
  });

  test('create_missingPhoto_returnsValidationWithoutRepositoryCall', () async {
    final repository = _MockHouseModelsRepository();
    final draft = _draft(photoCount: 0);

    final result = await CreateHouseModelUseCase(repository)(draft);

    expect(result.failureOrNull, isA<ValidationFailure>());
    verifyNever(() => repository.createModel(draft));
  });

  test('create_tooManyPhotos_returnsValidationWithoutRepositoryCall', () async {
    final repository = _MockHouseModelsRepository();
    final draft = _draft(photoCount: 5);

    final result = await CreateHouseModelUseCase(repository)(draft);

    expect(result.failureOrNull, isA<ValidationFailure>());
    verifyNever(() => repository.createModel(draft));
  });

  test('completeGeneration_waitsThenLoadsCanonicalCatalog', () async {
    final repository = _MockHouseModelsRepository();
    const generation = HouseModelGeneration(
      id: 'generation-1',
      status: HouseModelGenerationStatus.processing,
    );
    const catalog = HouseModelCatalog(libraryModels: [], userModels: []);
    when(
      () => repository.waitForModelGeneration(generation),
    ).thenAnswer((_) async => const Ok(null));
    when(
      repository.loadCatalog,
    ).thenAnswer((_) async => const Ok(catalog));

    final result = await CompleteHouseModelGenerationUseCase(repository)(
      generation,
    );

    expect(result.valueOrNull, same(catalog));
    verifyInOrder([
      () => repository.waitForModelGeneration(generation),
      repository.loadCatalog,
    ]);
  });
}

HouseModelDraft _draft({
  String gender = 'female',
  int heightCm = 170,
  int photoCount = 1,
}) => HouseModelDraft(
  name: 'Taylor',
  gender: gender,
  heightCm: heightCm,
  heightEstimated: false,
  photos: [
    for (var index = 0; index < photoCount; index++)
      HouseModelUpload(bytes: Uint8List(1), fileName: 'model-$index.jpg'),
  ],
);
