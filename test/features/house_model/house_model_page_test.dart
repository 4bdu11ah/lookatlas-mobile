import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:look_atlas/features/house_model/di/house_model_providers.dart';
import 'package:look_atlas/features/house_model/domain/entities/house_model_profile.dart';
import 'package:look_atlas/features/house_model/domain/repositories/house_models_repository.dart';
import 'package:look_atlas/shared/image_picker/image_picker_providers.dart';
import 'package:look_atlas/shared/widgets/app_dialog.dart';
import 'package:look_atlas/shared/widgets/app_floating_action_button.dart';
import 'package:look_atlas/shared/widgets/app_outlined_button.dart';

import '../../helpers/fake_repositories.dart';

class _FakeImagePicker extends ImagePicker {
  _FakeImagePicker({this.imageCount = 1});

  final int imageCount;
  int? lastLimit;
  int singleImagePickCount = 0;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    singleImagePickCount++;
    return XFile.fromData(
      Uint8List.fromList(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        ),
      ),
      name: 'model.jpg',
    );
  }

  @override
  Future<List<XFile>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
    bool requestFullMetadata = true,
  }) async {
    lastLimit = limit;
    return [
      for (var index = 0; index < imageCount; index++)
        XFile.fromData(
          Uint8List.fromList(
            base64Decode(
              'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
            ),
          ),
          name: 'model-$index.jpg',
        ),
    ];
  }
}

class _FakeHouseModelsRepository implements HouseModelsRepository {
  _FakeHouseModelsRepository({
    List<HouseModelProfile> userModels = const [],
    this.loadFailure,
    this.refreshFailure,
    this.initialLoad,
    this.generationCompletion,
  }) : _userModels = [...userModels];

  final List<HouseModelProfile> _userModels;
  final Failure? loadFailure;
  final Failure? refreshFailure;
  final Future<Result<HouseModelCatalog>>? initialLoad;
  final Future<Result<void>>? generationCompletion;
  int _loadCount = 0;
  HouseModelDraft? lastCreatedDraft;
  String? lastDeletedPhotoId;

  @override
  Future<Result<HouseModelCatalog>> loadCatalog() async {
    _loadCount++;
    if (_loadCount == 1 && initialLoad != null) return initialLoad!;
    final failure = loadFailure;
    if (failure != null) return Result.err(failure);
    final refreshError = refreshFailure;
    if (_loadCount > 1 && refreshError != null) {
      return Result.err(refreshError);
    }
    return Result.ok(
      HouseModelCatalog(
        libraryModels: _libraryModels,
        userModels: List.unmodifiable(_userModels),
      ),
    );
  }

  @override
  Future<Result<void>> createModel(HouseModelDraft draft) async {
    lastCreatedDraft = draft;
    _userModels.add(
      HouseModelProfile(
        id: 'user-${_userModels.length + 1}',
        name: draft.name,
        gender: draft.gender,
        source: HouseModelSource.user,
        heightCm: draft.heightCm,
        heightEstimated: draft.heightEstimated,
        photos: const ['assets/images/onboarding/step-model.jpg'],
      ),
    );
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> updateModel(
    String modelId,
    HouseModelDraft draft,
  ) async {
    final index = _userModels.indexWhere((model) => model.id == modelId);
    final current = _userModels[index];
    _userModels[index] = HouseModelProfile(
      id: current.id,
      name: draft.name,
      gender: draft.gender,
      source: current.source,
      heightCm: draft.heightCm,
      heightEstimated: draft.heightEstimated,
      photos: current.photos,
      photoIds: current.photoIds,
    );
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> deleteModel(String modelId) async {
    _userModels.removeWhere((model) => model.id == modelId);
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> deletePhoto(String modelId, String photoId) async {
    lastDeletedPhotoId = photoId;
    final index = _userModels.indexWhere((model) => model.id == modelId);
    final current = _userModels[index];
    final photoIndex = current.photoIds.indexOf(photoId);
    final photos = [...current.photos]..removeAt(photoIndex);
    final photoIds = [...current.photoIds]..removeAt(photoIndex);
    _userModels[index] = HouseModelProfile(
      id: current.id,
      name: current.name,
      gender: current.gender,
      source: current.source,
      heightCm: current.heightCm,
      heightEstimated: current.heightEstimated,
      photos: photos,
      photoIds: photoIds,
    );
    return const Result.ok(null);
  }

  @override
  Future<Result<HouseModelGeneration>> startModelGeneration(
    AiHouseModelDraft draft,
  ) async => const Result.ok(
    HouseModelGeneration(
      id: 'ai-generation-1',
      status: HouseModelGenerationStatus.processing,
    ),
  );

  @override
  Future<Result<void>> waitForModelGeneration(
    HouseModelGeneration generation,
  ) async {
    final result = await generationCompletion ?? const Result.ok(null);
    if (result.isErr) return result;
    _userModels.add(
      const HouseModelProfile(
        id: 'ai-1',
        name: 'Silver Hair',
        gender: 'female',
        source: HouseModelSource.user,
        heightCm: 170,
        photos: ['assets/images/onboarding/step-model.jpg'],
      ),
    );
    return result;
  }

  @override
  Future<Result<void>> generateModel(AiHouseModelDraft draft) async {
    final generation = await startModelGeneration(draft);
    return waitForModelGeneration(generation.valueOrNull!);
  }
}

const _libraryModels = [
  HouseModelProfile(
    id: 'sofia',
    name: 'Sofia',
    gender: 'female',
    source: HouseModelSource.lookAtlas,
    bodyType: 'slim_athletic',
    photos: ['assets/images/onboarding/step-model.jpg'],
  ),
  HouseModelProfile(
    id: 'kai',
    name: 'Kai',
    gender: 'male',
    source: HouseModelSource.lookAtlas,
    bodyType: 'slim_athletic',
    photos: ['assets/images/onboarding/showcase-tshirt-after.jpg'],
  ),
  HouseModelProfile(
    id: 'ava',
    name: 'Ava',
    gender: 'female',
    source: HouseModelSource.lookAtlas,
    bodyType: 'petite',
    photos: ['assets/images/onboarding/showcase-sunglasses-after.jpg'],
  ),
  HouseModelProfile(
    id: 'rose',
    name: 'Rose',
    gender: 'female',
    source: HouseModelSource.lookAtlas,
    bodyType: 'average',
    photos: ['assets/images/onboarding/showcase-dress-after.jpg'],
  ),
  HouseModelProfile(
    id: 'imani',
    name: 'Imani',
    gender: 'female',
    source: HouseModelSource.lookAtlas,
    bodyType: 'plus_size_curvy',
    photos: ['assets/images/onboarding/showcase-bag-after.jpg'],
  ),
  HouseModelProfile(
    id: 'noah',
    name: 'Noah',
    gender: 'male',
    source: HouseModelSource.lookAtlas,
    bodyType: 'average',
    photos: ['assets/images/onboarding/showcase-shoes-after.jpg'],
  ),
];

const _existingUserModel = HouseModelProfile(
  id: 'user-1',
  name: 'Taylor',
  gender: 'female',
  source: HouseModelSource.user,
  heightCm: 174,
  photos: ['assets/images/onboarding/step-model.jpg'],
  photoIds: ['photo-1'],
);

const _multiPhotoUserModel = HouseModelProfile(
  id: 'user-2',
  name: 'Morgan',
  gender: 'female',
  source: HouseModelSource.user,
  heightCm: 174,
  photos: [
    'assets/images/onboarding/step-model.jpg',
    'assets/images/onboarding/showcase-tshirt-after.jpg',
  ],
  photoIds: ['photo-2a', 'photo-2b'],
);

const _threePhotoUserModel = HouseModelProfile(
  id: 'user-3',
  name: 'Alex',
  gender: 'male',
  source: HouseModelSource.user,
  heightCm: 180,
  photos: [
    'assets/images/onboarding/step-model.jpg',
    'assets/images/onboarding/showcase-tshirt-after.jpg',
    'assets/images/onboarding/showcase-sunglasses-after.jpg',
  ],
  photoIds: ['photo-3a', 'photo-3b', 'photo-3c'],
);

const _fourPhotoUserModel = HouseModelProfile(
  id: 'user-4',
  name: 'Jordan',
  gender: 'female',
  source: HouseModelSource.user,
  heightCm: 170,
  photos: [
    'assets/images/onboarding/step-model.jpg',
    'assets/images/onboarding/showcase-tshirt-after.jpg',
    'assets/images/onboarding/showcase-sunglasses-after.jpg',
    'assets/images/onboarding/showcase-dress-after.jpg',
  ],
  photoIds: ['photo-4a', 'photo-4b', 'photo-4c', 'photo-4d'],
);

void main() {
  Future<void> pumpModels(
    WidgetTester tester, {
    _FakeHouseModelsRepository? repository,
    ImagePicker? imagePicker,
    bool settle = true,
  }) async {
    final modelsRepository = repository ?? _FakeHouseModelsRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(
              user: const AppUser(id: 'user-1', email: 'jane@example.com'),
            ),
          ),
          houseModelsRepositoryProvider.overrideWithValue(modelsRepository),
          imagePickerProvider.overrideWithValue(
            imagePicker ?? _FakeImagePicker(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const HouseModelsScreen(),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  testWidgets('house model first load shows both custom shimmer layouts', (
    tester,
  ) async {
    Finder shimmerCards(String prefix) => find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> && key.value.startsWith(prefix);
    });

    final load = Completer<Result<HouseModelCatalog>>();
    await pumpModels(
      tester,
      repository: _FakeHouseModelsRepository(initialLoad: load.future),
      settle: false,
    );

    expect(
      find.byKey(const ValueKey('house-model-library-shimmer-grid')),
      findsOneWidget,
    );
    expect(
      shimmerCards('house-model-library-shimmer-card-'),
      findsNWidgets(6),
    );
    expect(
      find.byKey(const ValueKey('house-model-user-shimmer-list')),
      findsOneWidget,
    );
    expect(
      shimmerCards('house-model-user-shimmer-card-'),
      findsNWidgets(4),
    );
    expect(find.text('LookAtlas Models'), findsOneWidget);
    expect(find.text('Your Models'), findsOneWidget);
    expect(find.text('Loading house models...'), findsNothing);
    expect(find.byType(AspectRatio), findsNWidgets(10));
    for (final portrait in tester.widgetList<AspectRatio>(
      find.byType(AspectRatio),
    )) {
      expect(portrait.aspectRatio, 9 / 16);
    }

    load.complete(
      const Result.ok(
        HouseModelCatalog(
          libraryModels: _libraryModels,
          userModels: [],
        ),
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('house model page expands the LookAtlas library', (tester) async {
    await pumpModels(tester);

    expect(find.text('House Models'), findsOneWidget);
    expect(find.text('Sofia'), findsOneWidget);
    expect(find.text('Imani'), findsNothing);

    await tester.ensureVisible(find.byKey(const ValueKey('show-more-models')));
    await tester.tap(find.byKey(const ValueKey('show-more-models')));
    await tester.pumpAndSettle();

    expect(find.text('Imani'), findsOneWidget);
    expect(find.text('Showing 6 of 6 models'), findsOneWidget);
  });

  testWidgets('house model page filters by gender', (tester) async {
    await pumpModels(tester);

    await tester.tap(find.byKey(const ValueKey('filter-models')));
    await tester.pumpAndSettle();
    expect(find.text('All genders'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
    expect(find.text('Non-binary'), findsOneWidget);
    expect(find.text('All body types'), findsOneWidget);
    expect(find.text('Average'), findsWidgets);
    expect(find.text('Petite'), findsWidgets);
    expect(find.text('Slim/Athletic'), findsWidgets);
    expect(find.text('Plus-size/Curvy'), findsWidgets);
    await tester.tap(find.text('Male'));
    await tester.ensureVisible(find.text('Show models'));
    await tester.tap(find.text('Show models'));
    await tester.pumpAndSettle();

    expect(find.text('Kai'), findsOneWidget);
    expect(find.text('Noah'), findsOneWidget);
    expect(find.text('Sofia'), findsNothing);
    expect(find.text('Showing 2 of 2 models'), findsOneWidget);
  });

  testWidgets('house model page clears filters and closes the sheet', (
    tester,
  ) async {
    await pumpModels(tester);

    await tester.tap(find.byKey(const ValueKey('filter-models')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Male'));
    await tester.ensureVisible(find.text('Show models'));
    await tester.tap(find.text('Show models'));
    await tester.pumpAndSettle();
    expect(find.text('Showing 2 of 2 models'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('filter-models')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(find.text('All genders'), findsNothing);
    expect(find.text('Sofia'), findsOneWidget);
    expect(find.text('Showing 4 of 6 models'), findsOneWidget);
  });

  testWidgets('house model page shows empty Your Models actions', (
    tester,
  ) async {
    await pumpModels(tester);

    await tester.ensureVisible(find.text('No models added yet'));

    expect(find.text('No models added yet'), findsOneWidget);
    expect(
      find.text(
        'Upload your first house model to get started with on-model image generation.',
      ),
      findsOneWidget,
    );
    expect(find.text('Add your first model'), findsOneWidget);
    expect(find.text('Create with AI (20 credits)'), findsOneWidget);
    // expect(find.text('3-5 clear photos work best'), findsOneWidget);
  });

  testWidgets('house model actions use shared app buttons', (tester) async {
    await pumpModels(tester);

    expect(find.byType(AppFloatingActionButton), findsOneWidget);
    expect(find.byType(AppOutlinedButton), findsWidgets);
  });

  testWidgets('house model empty state actions open their flows', (
    tester,
  ) async {
    await pumpModels(tester);

    await tester.ensureVisible(find.text('Add your first model'));
    await tester.tap(find.text('Add your first model'));
    await tester.pumpAndSettle();
    final appDialog = tester.widget<AppDialog>(find.byType(AppDialog));
    expect(appDialog.config.title, 'Add New Model');
    expect(find.text('Add New Model'), findsOneWidget);

    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Create with AI (20 credits)'));
    await tester.tap(find.text('Create with AI (20 credits)'));
    await tester.pumpAndSettle();
    expect(find.text('Create your own model (AI)'), findsOneWidget);
  });

  testWidgets('house model grid changes angle by tap and swipe', (
    tester,
  ) async {
    await pumpModels(tester);

    expect(find.byIcon(Icons.more_horiz), findsNothing);
    expect(find.text('FRONT'), findsWidgets);
    expect(
      find.byKey(const ValueKey('model-sofia-angle-front-active')),
      findsOneWidget,
    );

    await tester.tap(find.text('Sofia'));
    await tester.pumpAndSettle();
    expect(find.text('Model profile'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('model-sofia-angle-left')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('model-sofia-angle-left-active')),
      findsOneWidget,
    );
    expect(find.text('LEFT'), findsWidgets);

    await tester.drag(
      find.byKey(const ValueKey('model-sofia-angle-pager')),
      const Offset(-220, 0),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('model-sofia-angle-right-active')),
      findsOneWidget,
    );
    expect(find.text('RIGHT'), findsWidgets);
  });

  testWidgets('house model page adds an uploaded model', (tester) async {
    final repository = _FakeHouseModelsRepository();
    await pumpModels(tester, repository: repository);

    await tester.tap(find.byKey(const ValueKey('add-model-fab')));
    await tester.pumpAndSettle();
    expect(find.byType(AppDialog), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'Taylor Stone');
    await tester.enterText(find.byType(TextField).at(1), '174');
    await tester.ensureVisible(
      find.byKey(const ValueKey('model-photo-upload')),
    );
    await tester.tap(find.byKey(const ValueKey('model-photo-upload')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('submit-model-form')));
    await tester.tap(find.byKey(const ValueKey('submit-model-form')));
    await tester.pumpAndSettle();

    expect(find.text('Taylor Stone'), findsOneWidget);
    expect(find.text('Model added to Your Models'), findsOneWidget);
    expect(repository.lastCreatedDraft?.name, 'Taylor Stone');
    expect(repository.lastCreatedDraft?.gender, 'female');
    expect(repository.lastCreatedDraft?.heightCm, 174);
    expect(repository.lastCreatedDraft?.photos, hasLength(1));
  });

  testWidgets('add model requires name height and one photo', (tester) async {
    final repository = _FakeHouseModelsRepository();
    await pumpModels(tester, repository: repository);

    await tester.tap(find.byKey(const ValueKey('add-model-fab')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('submit-model-form')));
    await tester.tap(find.byKey(const ValueKey('submit-model-form')));
    await tester.pump();

    expect(find.text('Enter a model name.'), findsOneWidget);
    expect(find.text('Enter a height between 100 and 250 cm.'), findsOneWidget);
    expect(find.text('Add at least one clear model photo.'), findsOneWidget);
    expect(repository.lastCreatedDraft, isNull);
  });

  testWidgets('add model accepts at most four selected photos', (tester) async {
    final imagePicker = _FakeImagePicker(imageCount: 7);
    final repository = _FakeHouseModelsRepository();
    await pumpModels(
      tester,
      repository: repository,
      imagePicker: imagePicker,
    );

    await tester.tap(find.byKey(const ValueKey('add-model-fab')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Taylor Stone');
    await tester.enterText(find.byType(TextField).at(1), '174');
    await tester.ensureVisible(
      find.byKey(const ValueKey('model-photo-upload')),
    );
    await tester.tap(find.byKey(const ValueKey('model-photo-upload')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();

    expect(imagePicker.lastLimit, 4);
    expect(find.text('(4/4)'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('submit-model-form')));
    await tester.tap(find.byKey(const ValueKey('submit-model-form')));
    await tester.pumpAndSettle();
    expect(repository.lastCreatedDraft?.photos, hasLength(4));
  });

  testWidgets('reopening add model clears successfully uploaded photos', (
    tester,
  ) async {
    await pumpModels(tester, repository: _FakeHouseModelsRepository());

    await tester.tap(find.byKey(const ValueKey('add-model-fab')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Taylor Stone');
    await tester.enterText(find.byType(TextField).at(1), '174');
    await tester.ensureVisible(
      find.byKey(const ValueKey('model-photo-upload')),
    );
    await tester.tap(find.byKey(const ValueKey('model-photo-upload')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();
    expect(find.text('(1/4)'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('submit-model-form')));
    await tester.tap(find.byKey(const ValueKey('submit-model-form')));
    await tester.pumpAndSettle();
    expect(find.byType(AppDialog), findsNothing);

    await tester.tap(find.byKey(const ValueKey('add-model-fab')));
    await tester.pumpAndSettle();
    expect(find.text('(0/4)'), findsOneWidget);
  });

  testWidgets('successful create closes form when catalog refresh fails', (
    tester,
  ) async {
    await pumpModels(
      tester,
      repository: _FakeHouseModelsRepository(
        refreshFailure: const NetworkFailure('Refresh unavailable.'),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('add-model-fab')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Taylor Stone');
    await tester.enterText(find.byType(TextField).at(1), '174');
    await tester.ensureVisible(
      find.byKey(const ValueKey('model-photo-upload')),
    );
    await tester.tap(find.byKey(const ValueKey('model-photo-upload')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('submit-model-form')));
    await tester.tap(find.byKey(const ValueKey('submit-model-form')));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Model added to Your Models'), findsOneWidget);
    expect(find.textContaining('Refresh unavailable.'), findsOneWidget);
  });

  testWidgets('house model page tracks AI generation and refreshes models', (
    tester,
  ) async {
    final generationCompletion = Completer<Result<void>>();
    await pumpModels(
      tester,
      repository: _FakeHouseModelsRepository(
        generationCompletion: generationCompletion.future,
      ),
    );

    await tester.tap(find.text('Create with AI'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('ai-description')),
      'silver hair editorial model',
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('generate-ai-model')));
    await tester.tap(find.byKey(const ValueKey('generate-ai-model')));
    for (var frame = 0; frame < 5; frame++) {
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const ValueKey('ai-model-generation-progress')),
      findsOneWidget,
    );
    expect(find.byType(Dialog), findsNothing);

    generationCompletion.complete(const Result.ok(null));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('ai-model-generation-progress')),
      findsNothing,
    );
    expect(find.text('Silver Hair'), findsOneWidget);
    expect(find.text('AI model generation started'), findsOneWidget);
  });

  testWidgets('house model page edits a user model through the API layer', (
    tester,
  ) async {
    await pumpModels(
      tester,
      repository: _FakeHouseModelsRepository(
        userModels: const [_existingUserModel],
      ),
    );

    await tester.ensureVisible(find.byIcon(Icons.edit_outlined));
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(AppDialog), findsOneWidget);
    expect(find.text('Edit Model'), findsOneWidget);
    expect(
      find.text('Update photos and details for Taylor'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField).first, 'Taylor Updated');
    await tester.ensureVisible(find.byKey(const ValueKey('submit-model-form')));
    await tester.tap(find.byKey(const ValueKey('submit-model-form')));
    await tester.pumpAndSettle();

    expect(find.text('Taylor Updated'), findsOneWidget);
    expect(find.text('Model updated'), findsOneWidget);
  });

  testWidgets('gallery uses one-image picker when one model photo remains', (
    tester,
  ) async {
    final imagePicker = _FakeImagePicker();
    await pumpModels(
      tester,
      repository: _FakeHouseModelsRepository(
        userModels: const [_threePhotoUserModel],
      ),
      imagePicker: imagePicker,
    );

    await tester.ensureVisible(find.byTooltip('Edit model'));
    await tester.tap(find.byTooltip('Edit model'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('model-photo-upload')),
    );
    await tester.tap(find.byKey(const ValueKey('model-photo-upload')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();

    expect(imagePicker.singleImagePickCount, 1);
    expect(imagePicker.lastLimit, isNull);
    expect(find.byKey(const ValueKey('model-photo-upload')), findsNothing);
  });

  testWidgets('user model card shows profile details and header actions', (
    tester,
  ) async {
    await pumpModels(
      tester,
      repository: _FakeHouseModelsRepository(
        userModels: const [_existingUserModel],
      ),
    );

    await tester.ensureVisible(find.text('Taylor'));

    expect(find.text('Female'), findsOneWidget);
    expect(find.text('174 cm'), findsOneWidget);
    expect(find.byTooltip('Edit model'), findsOneWidget);
    expect(find.byTooltip('Delete model'), findsOneWidget);
    expect(find.text('YOUR MODEL'), findsNothing);
  });

  testWidgets('user model card swipes through multiple photos', (tester) async {
    await pumpModels(
      tester,
      repository: _FakeHouseModelsRepository(
        userModels: const [_multiPhotoUserModel],
      ),
    );

    final pager = find.byKey(
      const ValueKey('user-model-user-2-photo-pager'),
    );
    await tester.ensureVisible(pager);
    expect(
      find.byKey(const ValueKey('user-model-user-2-photo-0')),
      findsOneWidget,
    );
    expect(find.text('1 / 2'), findsOneWidget);

    await tester.drag(pager, const Offset(-220, 0));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('user-model-user-2-photo-1')),
      findsOneWidget,
    );
    expect(find.text('2 / 2'), findsOneWidget);
  });

  testWidgets('editing a current model photo confirms before deleting it', (
    tester,
  ) async {
    final repository = _FakeHouseModelsRepository(
      userModels: const [_fourPhotoUserModel],
    );
    await pumpModels(tester, repository: repository);

    await tester.ensureVisible(find.byTooltip('Edit model'));
    await tester.tap(find.byTooltip('Edit model'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('model-photo-upload')), findsNothing);
    await tester.ensureVisible(find.byTooltip('Delete photo').first);
    await tester.tap(find.byKey(const ValueKey('existing-model-photo-0')));
    await tester.pumpAndSettle();
    expect(find.text('Delete Photo'), findsNothing);

    await tester.tap(find.byTooltip('Delete photo').first);
    await tester.pumpAndSettle();

    expect(find.byType(AppDialog), findsNWidgets(2));
    expect(find.text('Delete Photo'), findsNWidgets(2));
    await tester.tap(find.text('Delete Photo').last);
    await tester.pumpAndSettle();

    expect(repository._userModels.single.photos, hasLength(3));
    expect(repository.lastDeletedPhotoId, 'photo-4a');
    expect(find.text('(3 existing)'), findsOneWidget);
    expect(find.byKey(const ValueKey('model-photo-upload')), findsOneWidget);
  });

  testWidgets('house model page deletes a user model after confirmation', (
    tester,
  ) async {
    await pumpModels(
      tester,
      repository: _FakeHouseModelsRepository(
        userModels: const [_existingUserModel],
      ),
    );

    await tester.ensureVisible(find.byTooltip('Delete model'));
    await tester.tap(find.byTooltip('Delete model'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Model').last);
    await tester.pumpAndSettle();

    expect(find.text('Taylor'), findsNothing);
    expect(find.text('Model deleted'), findsOneWidget);
  });

  testWidgets('editing a model closes through the dialog close action', (
    tester,
  ) async {
    await pumpModels(
      tester,
      repository: _FakeHouseModelsRepository(
        userModels: const [_existingUserModel],
      ),
    );

    await tester.ensureVisible(find.byIcon(Icons.edit_outlined));
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Edit model'), findsNothing);
    expect(find.text('Taylor'), findsOneWidget);
  });

  testWidgets('house model page shows API load errors', (tester) async {
    await pumpModels(
      tester,
      repository: _FakeHouseModelsRepository(
        loadFailure: const NetworkFailure('Connection lost.'),
      ),
    );

    expect(find.text('Could not load house models'), findsOneWidget);
    expect(find.text('Connection lost.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
