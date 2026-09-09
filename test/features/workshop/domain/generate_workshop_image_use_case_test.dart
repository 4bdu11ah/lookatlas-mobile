import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/features/workshop/domain/entities/workshop_models.dart';
import 'package:look_atlas/features/workshop/domain/repositories/workshop_repository.dart';
import 'package:look_atlas/features/workshop/domain/use_cases/generate_workshop_image_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockWorkshopRepository extends Mock implements WorkshopRepository {}

void main() {
  test('prepare_validInput_normalizesPromptAndBuildsUploads', () {
    final useCase = GenerateWorkshopImageUseCase(_MockWorkshopRepository());
    final bytes = Uint8List.fromList([1, 2, 3]);

    final result = useCase.prepare(
      base: WorkshopBaseImage(source: 'local', bytes: bytes),
      references: [
        WorkshopSample(
          id: 'reference-1',
          label: 'Reference',
          asset: 'local',
          bytes: bytes,
          fileName: 'reference.jpg',
        ),
      ],
      prompt: '  Change the background  ',
      mode: WorkshopEditMode.lock,
    );

    final request = result.valueOrNull!;
    expect(request.prompt, 'Change the background');
    expect(request.base.fileName, 'workshop-base.jpg');
    expect(request.references.single.fileName, 'reference.jpg');
  });
}
