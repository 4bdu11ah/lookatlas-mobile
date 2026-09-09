import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/features/create_content/domain/entities/content_models.dart';
import 'package:look_atlas/features/create_content/domain/errors/content_api_exception.dart';
import 'package:look_atlas/features/create_content/domain/repositories/content_repository.dart';
import 'package:look_atlas/features/create_content/domain/use_cases/save_content_draft_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockContentRepository extends Mock implements ContentRepository {}

void main() {
  test('call_existingDraft_savesPatchOnce', () async {
    final repository = _MockContentRepository();
    final draft = ContentDraft(const {
      'id': 'draft-1',
      'format': 'slideshow',
    });
    when(
      () =>
          repository.save(ContentFormat.slideshow, 'draft-1', {'notes': 'new'}),
    ).thenAnswer((_) async => draft);

    final saved = await SaveContentDraftUseCase(repository)(
      format: ContentFormat.slideshow,
      draftId: 'draft-1',
      brief: const {'title': 'Brief'},
      patch: const {'notes': 'new'},
      onRemoteDraftMissing: () {},
    );

    expect(saved, same(draft));
    verify(
      () =>
          repository.save(ContentFormat.slideshow, 'draft-1', {'notes': 'new'}),
    ).called(1);
  });

  test('call_missingRemoteDraft_recreatesFromBriefAndPatch', () async {
    final repository = _MockContentRepository();
    when(
      () =>
          repository.save(ContentFormat.slideshow, 'draft-1', {'notes': 'new'}),
    ).thenThrow(const ContentApiException('Missing', status: 404));
    when(
      () => repository.save(ContentFormat.slideshow, null, {
        'title': 'Brief',
        'notes': 'new',
      }),
    ).thenAnswer(
      (_) async => ContentDraft(const {
        'id': 'draft-2',
        'format': 'slideshow',
      }),
    );

    var remoteDraftMissing = false;
    final saved = await SaveContentDraftUseCase(repository)(
      format: ContentFormat.slideshow,
      draftId: 'draft-1',
      brief: const {'title': 'Brief'},
      patch: const {'notes': 'new'},
      onRemoteDraftMissing: () => remoteDraftMissing = true,
    );

    expect(saved.id, 'draft-2');
    expect(remoteDraftMissing, isTrue);
    verify(
      () => repository.save(ContentFormat.slideshow, null, {
        'title': 'Brief',
        'notes': 'new',
      }),
    ).called(1);
  });
}
