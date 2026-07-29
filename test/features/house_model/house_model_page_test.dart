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

import '../../helpers/fake_repositories.dart';

class _FakeImagePicker extends ImagePicker {
  @override
  Future<List<XFile>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
    bool requestFullMetadata = true,
  }) async => [
    XFile.fromData(
      Uint8List.fromList(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        ),
      ),
      name: 'model.jpg',
    ),
  ];
}

class _FakeHouseModelsRepository implements HouseModelsRepository {
  _FakeHouseModelsRepository({
    List<HouseModelProfile> userModels = const [],
    this.loadFailure,
    this.refreshFailure,
  }) : _userModels = [...userModels];

  final List<HouseModelProfile> _userModels;
  final Failure? loadFailure;
  final Failure? refreshFailure;
  int _loadCount = 0;

  @override
  Future<Result<HouseModelCatalog>> loadCatalog() async {
    _loadCount++;
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
    );
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> deleteModel(String modelId) async {
    _userModels.removeWhere((model) => model.id == modelId);
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> deletePhoto(String modelId, int photoIndex) async {
    final index = _userModels.indexWhere((model) => model.id == modelId);
    final current = _userModels[index];
    final photos = [...current.photos]..removeAt(photoIndex);
    _userModels[index] = HouseModelProfile(
      id: current.id,
      name: current.name,
      gender: current.gender,
      source: current.source,
      heightCm: current.heightCm,
      heightEstimated: current.heightEstimated,
      photos: photos,
    );
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> generateModel(AiHouseModelDraft draft) async {
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
    return const Result.ok(null);
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
);

void main() {
  Future<void> pumpModels(
    WidgetTester tester, {
    _FakeHouseModelsRepository? repository,
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
          imagePickerProvider.overrideWithValue(_FakeImagePicker()),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const DashboardFeatureScreen.models(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

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

  testWidgets('house model empty state actions open their flows', (
    tester,
  ) async {
    await pumpModels(tester);

    await tester.ensureVisible(find.text('Add your first model'));
    await tester.tap(find.text('Add your first model'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
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
    await pumpModels(tester);

    await tester.tap(find.byKey(const ValueKey('add-model-fab')));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
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

  testWidgets('house model page creates an AI model', (tester) async {
    await pumpModels(tester);

    await tester.tap(find.text('Create with AI'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('ai-description')),
      'silver hair editorial model',
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('generate-ai-model')));
    await tester.tap(find.byKey(const ValueKey('generate-ai-model')));
    await tester.pumpAndSettle();

    expect(find.text('Model generated'), findsOneWidget);
    expect(find.text('Silver Hair'), findsOneWidget);
    expect(find.text('AI model is ready'), findsOneWidget);
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
    await tester.enterText(find.byType(TextField).first, 'Taylor Updated');
    await tester.ensureVisible(find.byKey(const ValueKey('submit-model-form')));
    await tester.tap(find.byKey(const ValueKey('submit-model-form')));
    await tester.pumpAndSettle();

    expect(find.text('Taylor Updated'), findsOneWidget);
    expect(find.text('Model updated'), findsOneWidget);
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
    await tester.tap(find.text('Delete model'));
    await tester.pumpAndSettle();

    expect(find.text('Taylor'), findsNothing);
    expect(find.text('Model deleted'), findsOneWidget);
  });

  testWidgets('deleting from edit closes both nested sheets', (tester) async {
    await pumpModels(
      tester,
      repository: _FakeHouseModelsRepository(
        userModels: const [_existingUserModel],
      ),
    );

    await tester.ensureVisible(find.byIcon(Icons.edit_outlined));
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete model').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete model'));
    await tester.pumpAndSettle();

    expect(find.text('Edit model'), findsNothing);
    expect(find.text('No models added yet'), findsOneWidget);
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
