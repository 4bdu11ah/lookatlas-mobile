import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/house_model/data/data_sources/house_models_remote_data_source.dart';
import 'package:look_atlas/features/house_model/data/repositories/house_models_repository_impl.dart';
import 'package:look_atlas/features/house_model/domain/entities/house_model_profile.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemoteDataSource extends Mock
    implements HouseModelsRemoteDataSource {}

void main() {
  late _MockRemoteDataSource remote;

  setUpAll(() => registerFallbackValue(_draft()));

  setUp(() {
    remote = _MockRemoteDataSource();
  });

  test('generate_model_polls_until_completed', () async {
    const draft = AiHouseModelDraft(
      gender: 'female',
      age: 25,
      description: 'Silver hair editorial model',
    );
    when(() => remote.generateModel(draft)).thenAnswer(
      (_) async => const Result.ok(
        HouseModelGeneration(
          id: 'generation-1',
          status: HouseModelGenerationStatus.pending,
        ),
      ),
    );
    when(() => remote.getGeneration('generation-1')).thenAnswer(
      (_) async => const Result.ok(
        HouseModelGeneration(
          id: 'generation-1',
          status: HouseModelGenerationStatus.completed,
        ),
      ),
    );
    final delays = <Duration>[];
    final repository = HouseModelsRepositoryImpl(
      remote,
      delay: (duration) async => delays.add(duration),
    );

    final result = await repository.generateModel(draft);

    expect(result.isOk, isTrue);
    expect(delays, [const Duration(seconds: 4)]);
    verify(() => remote.getGeneration('generation-1')).called(1);
  });

  test('generate_model_retries_poll_after_network_failure', () async {
    const draft = AiHouseModelDraft(
      gender: 'male',
      age: 30,
      description: 'Athletic commercial model',
    );
    when(() => remote.generateModel(draft)).thenAnswer(
      (_) async => const Result.ok(
        HouseModelGeneration(
          id: 'generation-2',
          status: HouseModelGenerationStatus.processing,
        ),
      ),
    );
    var pollCount = 0;
    when(() => remote.getGeneration('generation-2')).thenAnswer((_) async {
      pollCount++;
      if (pollCount == 1) {
        return const Result.err(NetworkFailure('Connection lost.'));
      }
      return const Result.ok(
        HouseModelGeneration(
          id: 'generation-2',
          status: HouseModelGenerationStatus.completed,
        ),
      );
    });
    final delays = <Duration>[];
    final repository = HouseModelsRepositoryImpl(
      remote,
      delay: (duration) async => delays.add(duration),
    );

    final result = await repository.generateModel(draft);

    expect(result.isOk, isTrue);
    expect(delays, [
      const Duration(seconds: 4),
      const Duration(seconds: 6),
    ]);
    verify(() => remote.getGeneration('generation-2')).called(2);
  });

  test(
    'generate_model_returns_non_network_poll_failure_without_retry',
    () async {
      const draft = AiHouseModelDraft(
        gender: 'male',
        age: 30,
        description: 'Athletic commercial model',
      );
      when(() => remote.generateModel(draft)).thenAnswer(
        (_) async => const Result.ok(
          HouseModelGeneration(
            id: 'generation-3',
            status: HouseModelGenerationStatus.processing,
          ),
        ),
      );
      when(
        () => remote.getGeneration('generation-3'),
      ).thenAnswer(
        (_) async => const Result.err(
          ValidationFailure('Generation is unavailable.'),
        ),
      );
      final delays = <Duration>[];
      final repository = HouseModelsRepositoryImpl(
        remote,
        delay: (duration) async => delays.add(duration),
      );

      final result = await repository.generateModel(draft);

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(delays, [const Duration(seconds: 4)]);
      verify(() => remote.getGeneration('generation-3')).called(1);
    },
  );

  test('create_model_accepts_one_photo', () async {
    final draft = _draft();
    when(
      () => remote.createModel(draft),
    ).thenAnswer((_) async => const Result.ok(null));
    final repository = HouseModelsRepositoryImpl(remote);

    final result = await repository.createModel(draft);

    expect(result.isOk, isTrue);
    verify(() => remote.createModel(draft)).called(1);
  });

  test('create_model_rejects_missing_name', () async {
    final repository = HouseModelsRepositoryImpl(remote);

    final result = await repository.createModel(_draft(name: ' '));

    expect(result.failureOrNull, isA<ValidationFailure>());
    verifyNever(() => remote.createModel(any()));
  });

  test('create_model_rejects_missing_gender', () async {
    final repository = HouseModelsRepositoryImpl(remote);

    final result = await repository.createModel(_draft(gender: ''));

    expect(result.failureOrNull, isA<ValidationFailure>());
    verifyNever(() => remote.createModel(any()));
  });

  test('create_model_rejects_invalid_height', () async {
    final repository = HouseModelsRepositoryImpl(remote);

    final result = await repository.createModel(_draft(heightCm: 99));

    expect(result.failureOrNull, isA<ValidationFailure>());
    verifyNever(() => remote.createModel(any()));
  });

  test('create_model_rejects_missing_photo', () async {
    final repository = HouseModelsRepositoryImpl(remote);

    final result = await repository.createModel(_draft(photoCount: 0));

    expect(result.failureOrNull, isA<ValidationFailure>());
    verifyNever(() => remote.createModel(any()));
  });

  test('create_model_rejects_more_than_four_photos', () async {
    final repository = HouseModelsRepositoryImpl(remote);

    final result = await repository.createModel(_draft(photoCount: 5));

    expect(result.failureOrNull, isA<ValidationFailure>());
    verifyNever(() => remote.createModel(any()));
  });

  test('update_model_uses_patch_when_no_new_photos_exist', () async {
    const draft = HouseModelDraft(
      name: 'Taylor',
      gender: 'female',
      heightCm: 174,
      heightEstimated: false,
    );
    when(
      () => remote.patchModel('model-1', draft),
    ).thenAnswer((_) async => const Result.ok(null));
    final repository = HouseModelsRepositoryImpl(remote);

    await repository.updateModel('model-1', draft);

    verify(() => remote.patchModel('model-1', draft)).called(1);
    verifyNever(() => remote.updateModel('model-1', draft));
  });
}

HouseModelDraft _draft({
  String name = 'Taylor',
  String gender = 'female',
  int heightCm = 174,
  int photoCount = 1,
}) => HouseModelDraft(
  name: name,
  gender: gender,
  heightCm: heightCm,
  heightEstimated: false,
  photos: [
    for (var index = 0; index < photoCount; index++)
      HouseModelUpload(
        bytes: Uint8List.fromList([index]),
        fileName: 'model-$index.jpg',
      ),
  ],
);
