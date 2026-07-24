import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/onboarding/di/onboarding_providers.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_product.dart';
import 'package:look_atlas/features/onboarding/domain/look_atlas_model.dart';
import 'package:look_atlas/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:look_atlas/features/onboarding/presentation/controllers/onboarding_submission_controller.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/steps/model_step.dart';
import 'package:look_atlas/shared/image_picker/image_picker_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockOnboardingRepository extends Mock implements OnboardingRepository {}

class _FakeUserModelDraft extends Fake implements UserModelDraft {}

class _FakeImagePicker extends ImagePicker {
  @override
  Future<List<XFile>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
    bool requestFullMetadata = true,
  }) async => [
    XFile.fromData(Uint8List(2), name: 'model-1.jpg'),
    XFile.fromData(Uint8List(3), name: 'model-2.jpg'),
  ];
}

void main() {
  setUpAll(() => registerFallbackValue(_FakeUserModelDraft()));

  testWidgets('pre_auth_custom_upload_posts_refreshes_and_shows_model', (
    tester,
  ) async {
    final repository = _MockOnboardingRepository();
    var fetchCount = 0;
    when(
      () => repository.createUserModel(any()),
    ).thenAnswer((_) async => const Result.ok('model-1'));
    when(repository.fetchUserModels).thenAnswer((_) async {
      fetchCount++;
      return Result.ok(
        fetchCount == 1
            ? const []
            : const [
                OnboardingUserModel(
                  id: 'model-1',
                  name: 'Custom model',
                  photos: ['https://cdn.example/model-1.jpg'],
                ),
              ],
      );
    });
    final container = ProviderContainer(
      overrides: [
        onboardingRepositoryProvider.overrideWithValue(repository),
        imagePickerProvider.overrideWithValue(_FakeImagePicker()),
        lookAtlasModelsProvider.overrideWith(
          (ref) async => const <LookAtlasModel>[],
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: ModelStep())),
      ),
    );

    await tester.tap(find.text('Upload Your Own'));
    await tester.pump();
    await tester.tap(find.text('Tap to add model photos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();

    verify(() => repository.createUserModel(any())).called(1);
    verify(repository.fetchUserModels).called(2);
    expect(find.text('Custom model'), findsOneWidget);
    expect(
      container.read(onboardingSubmissionControllerProvider).modelId,
      'model-1',
    );
  });
}
