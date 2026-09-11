import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/features/create_content/domain/entities/content_models.dart';
import 'package:look_atlas/features/create_content/domain/errors/content_api_exception.dart';
import 'package:look_atlas/features/create_content/domain/use_cases/save_content_draft_use_case.dart';
import 'package:look_atlas/features/create_content/presentation/controllers/content_session.dart';

import 'content_test_backend.dart';

void main() {
  late ContentTestBackend backend;
  late ContentSession session;
  var creditRefreshes = 0;
  setUp(() {
    backend = ContentTestBackend();
    creditRefreshes = 0;
    session = ContentSession(
      backend.repository,
      ContentFormat.slideshow,
      saveDraft: SaveContentDraftUseCase(backend.repository),
      refreshCredits: () => creditRefreshes++,
    )..loading = false;
  });
  tearDown(() => session.dispose());
  test(
    'serializes create and patch; late create never loses newer notes',
    () async {
      final gate = Completer<ContentJson>();
      backend.handler = (request) => request.path == '/content/drafts'
          ? gate.future
          : backend.respond(request);
      session.updateBrief({'productId': 'product-1', 'notes': 'first'});
      final flush = session.flushDraft();
      await Future<void>.delayed(Duration.zero);
      session.updateBrief({'notes': 'newest'});
      gate.complete({
        'draft': {'id': 'draft-1', 'format': 'slideshow'},
      });
      expect(await flush, isTrue);
      final saves = backend.requests
          .where((r) => r.path.startsWith('/content/drafts'))
          .toList();
      expect(saves.map((r) => r.method), ['POST', 'PATCH']);
      expect((saves.last.data as ContentJson)['notes'], 'newest');
      expect(session.brief['notes'], 'newest');
      expect(session.saveState, ContentSaveState.saved);
    },
  );
  test(
    'save failure preserves edits and prevents generation; retry recovers',
    () async {
      backend.handler = (request) {
        if (request.path == '/content/drafts') {
          throw DioException(
            requestOptions: request,
            type: DioExceptionType.connectionError,
          );
        }
        return backend.respond(request);
      };
      session.updateBrief({'productId': 'product-1'});
      await session.generate();
      expect(session.saveState, ContentSaveState.offline);
      expect(
        backend.requests.any((r) => r.path == '/content/generations'),
        isFalse,
      );
      backend.handler = null;
      expect(await session.flushDraft(), isTrue);
      expect(session.draftId, 'draft-1');
    },
  );
  test('404 PATCH recreates draft and keeps all brief fields', () async {
    session.draftId = 'deleted';
    backend.handler = (request) {
      if (request.method == 'PATCH') {
        throw DioException(
          requestOptions: request,
          response: Response<dynamic>(requestOptions: request, statusCode: 404),
          type: DioExceptionType.badResponse,
        );
      }
      return backend.respond(request);
    };
    session.updateBrief({'productId': 'product-1'});
    expect(await session.flushDraft(), isTrue);
    expect(session.draftId, 'draft-1');
    expect((backend.requests.last.data as ContentJson)['platform'], 'both');
  });
  test('duplicate generate is locked before awaiting draft save', () async {
    session.updateBrief({'productId': 'product-1'});
    await Future.wait([
      session.generate(),
      session.generate(),
      session.generate(),
    ]);
    expect(
      backend.requests.where((r) => r.path == '/content/generations').length,
      1,
    );
    expect(session.reviewing, isTrue);
    expect(creditRefreshes, 2);
  });
  test('completed generation removes its source draft', () async {
    backend.emptyDeleteResponse = true;
    session.updateBrief({'productId': 'product-1'});

    await session.generate();

    expect(session.reviewing, isTrue);
    expect(session.draftId, isNull);
    expect(backend.draft, isNull);
    final deleteRequest = backend.requests.singleWhere(
      (request) =>
          request.method == 'DELETE' &&
          request.path == '/content/drafts/draft-1',
    );
    expect(deleteRequest.data, isNull);
    expect(deleteRequest.contentType, isNull);
  });
  test('failed generation keeps its source draft', () async {
    backend.status = 'failed';
    session.updateBrief({'productId': 'product-1'});

    await session.generate();

    expect(session.draftId, 'draft-1');
    expect(backend.draft, isNotNull);
    expect(
      backend.requests.any((request) => request.method == 'DELETE'),
      isFalse,
    );
  });
  test(
    'initialization removes draft already used by completed content',
    () async {
      backend
        ..generationDraftId = 'draft-1'
        ..draft = {
          'id': 'draft-1',
          'format': 'slideshow',
          'productId': 'product-1',
          'settings': {'lastStep': 3},
        };

      await session.initialize();

      expect(session.draftId, isNull);
      expect(session.step, 1);
      expect(backend.draft, isNull);
    },
  );
  test('402 and 403 retain brief and expose paywall', () async {
    for (final status in [402, 403]) {
      backend.handler = (request) {
        if (request.path == '/content/generations') {
          throw DioException(
            requestOptions: request,
            response: Response<dynamic>(
              requestOptions: request,
              statusCode: status,
            ),
            type: DioExceptionType.badResponse,
          );
        }
        return backend.respond(request);
      };
      session.updateBrief({'productId': 'product-1'});
      await session.generate();
      expect(session.paywall, status);
      expect(session.hasSource, isTrue);
    }
  });
  test(
    '409 generation and edit IDs attach to their respective endpoints',
    () async {
      backend.handler = (request) {
        if (request.path == '/content/generations' ||
            request.path.endsWith('/retouch')) {
          throw DioException(
            requestOptions: request,
            type: DioExceptionType.badResponse,
            response: Response<dynamic>(
              requestOptions: request,
              statusCode: 409,
              data: {
                'error': {
                  'activeJobId': request.path.endsWith('/retouch')
                      ? 'edit-1'
                      : 'generation-1',
                },
              },
            ),
          );
        }
        return backend.respond(request);
      };
      session.updateBrief({'productId': 'product-1'});
      await session.generate();
      expect(session.generation?.id, 'generation-1');
      await session.editFrame(prompt: 'Clean the edge');
      expect(
        backend.requests.any((r) => r.path == '/content/frame-edits/edit-1'),
        isTrue,
      );
      expect(session.editBusy, isFalse);
    },
  );
  test(
    'caption responses and crop reset cannot overwrite newer optimistic edits',
    () async {
      session.generation = ContentGeneration(backend.generation);
      final gate = Completer<ContentJson>();
      backend.handler = (request) =>
          request.path.contains('/frames/') &&
              backend.requests
                      .where((r) => r.path.contains('/frames/'))
                      .length ==
                  1
          ? gate.future
          : backend.respond(request);
      session.updateCrop({'scale': 1.4, 'x': 20, 'y': 80});
      final flush = session.flushEdits();
      await Future<void>.delayed(Duration.zero);
      session.updateCrop(null);
      gate.complete({
        'frame': {
          ...session.frame!.data,
          'crop': {'scale': 1.4, 'x': 20, 'y': 80},
        },
      });
      expect(await flush, isTrue);
      expect(session.frame!.crop, isNull);
      expect((backend.requests.last.data as ContentJson)['crop'], isNull);
    },
  );
  test('restores local unsaved changes over remote draft', () async {
    session.dispose();
    final recovery = jsonEncode({
      'draftId': 'draft-1',
      'brief': {
        ...defaultContentBrief(ContentFormat.slideshow),
        'notes': 'local',
      },
      'pendingDraft': {'notes': 'local'},
      'generationId': null,
      'pendingFrames': <String, dynamic>{},
      'pendingKit': <String, dynamic>{},
    });
    session = ContentSession(
      backend.repository,
      ContentFormat.slideshow,
      saveDraft: SaveContentDraftUseCase(backend.repository),
      refreshCredits: () {},
      restoreRecovery: () => recovery,
    );
    await session.initialize();
    expect(session.brief['notes'], 'local');
    expect(session.saveState, ContentSaveState.unsaved);
    expect(await session.flush(), isTrue);
  });
  test('deep link loads generation before draft/active requests', () async {
    await session.initialize(generationId: 'generation-1');
    expect(backend.requests.first.path, '/content/generations/generation-1');
    expect(
      backend.requests.any((r) => r.path == '/content/drafts/latest'),
      isFalse,
    );
    expect(
      backend.requests.any(
        (request) =>
            request.path == '/content/drafts/completed-draft-1' &&
            request.method == 'DELETE',
      ),
      isTrue,
    );
    expect(session.generation?.data['source'], 'runway');
  });
  testWidgets('300ms search and 800ms draft debounce use latest input', (
    tester,
  ) async {
    session.search('first');
    await tester.pump(const Duration(milliseconds: 200));
    session.search('second');
    await tester.pump(const Duration(milliseconds: 299));
    expect(backend.requests, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(backend.requests.single.queryParameters['search'], 'second');
    session.updateBrief({'notes': 'a'});
    await tester.pump(const Duration(milliseconds: 799));
    expect(backend.requests.length, 1);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(backend.requests.last.path, '/content/drafts');
  });
  testWidgets('polling is 3 seconds, never overlaps, and cancels on pause', (
    tester,
  ) async {
    expect(session.disposed, isFalse);
    backend.status = 'processing';
    session.generation = ContentGeneration(backend.generation);
    unawaited(session.pollGeneration());
    await tester.pump();
    await tester.pump();
    expect(session.error, isNull);
    await tester.pump(const Duration(milliseconds: 1));
    expect(backend.requests.length, 1);
    await tester.pump(const Duration(milliseconds: 2998));
    expect(backend.requests.length, 1);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(backend.requests.length, 2);
    session.setPaused(value: true);
    await tester.pump(const Duration(seconds: 10));
    expect(backend.requests.length, 2);
    session.setPaused(value: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(backend.requests.length, 3);
    session.setPaused(value: true);
    await tester.pump();
  });
  test('normalizes, deduplicates, and caps hashtags', () {
    expect(
      normalizeContentHashtags(['##Hello', 'hello', 'a-b', 'two words', '!!!']),
      ['hello', 'ab', 'two', 'words'],
    );
    expect(
      normalizeContentHashtags(List.generate(40, (i) => '#tag$i')).length,
      30,
    );
  });
  test(
    'all API paths preserve draft, generation, frame, and edit IDs',
    () async {
      final repo = backend.repository;
      await repo.drafts();
      await repo.history();
      await repo.latest(ContentFormat.video);
      await repo.active();
      await repo.products(search: '  coat  ');
      for (final format in ContentFormat.values) {
        await repo.quote(
          format,
          contentObject(defaultContentBrief(format)['settings']),
        );
      }
      await repo.save(ContentFormat.single, null, {'productId': 'product-1'});
      await repo.save(ContentFormat.single, 'draft/one', {'notes': 'note'});
      await repo.start('draft/one');
      await repo.generation('generation/one');
      await repo.retry('generation/one');
      await repo.frame('generation/one', 'frame/two', {
        'selectedVariantId': 'variant-three',
      });
      await repo.edit(
        'generation/one',
        'frame/two',
        prompt: 'Smooth the fabric',
      );
      await repo.edit('generation/one', 'frame/two');
      await repo.editStatus('edit/four');
      await repo.publishing('generation/one', {'coverFrameIndex': 2});
      await repo.export('generation/one');
      expect(backend.requests.map((r) => '${r.method} ${r.path}'), [
        'GET /content/drafts',
        'GET /content',
        'GET /content/drafts/latest',
        'GET /content/generations/active',
        'GET /products',
        'GET /content/quote',
        'GET /content/quote',
        'GET /content/quote',
        'POST /content/drafts',
        'PATCH /content/drafts/draft%2Fone',
        'POST /content/generations',
        'GET /content/generations/generation%2Fone',
        'POST /content/generations/generation%2Fone/retry',
        'PATCH /content/generation%2Fone/frames/frame%2Ftwo',
        'POST /content/generation%2Fone/frames/frame%2Ftwo/retouch',
        'POST /content/generation%2Fone/frames/frame%2Ftwo/regenerate',
        'GET /content/frame-edits/edit%2Ffour',
        'PATCH /content/generation%2Fone/publishing-kit',
        'POST /content/generation%2Fone/export',
      ]);
      expect(backend.requests[4].queryParameters, {
        'includePhotos': true,
        'page': 1,
        'limit': 12,
        'search': 'coat',
      });
      expect(backend.requests[5].queryParameters, {'format': 'single'});
      expect(backend.requests[6].queryParameters, {
        'format': 'slideshow',
        'frameCount': 5,
      });
      expect(backend.requests[7].queryParameters, {
        'format': 'video',
        'durationSeconds': 6,
      });
      expect(backend.requests[10].data, {'draftId': 'draft/one'});
      expect(backend.requests[14].data, {'prompt': 'Smooth the fabric'});
    },
  );
  test(
    'stale search and quote responses cannot replace newer results',
    () async {
      final oldSearch = Completer<ContentJson>();
      final oldQuote = Completer<ContentJson>();
      backend.handler = (request) {
        if (request.queryParameters['search'] == 'old') return oldSearch.future;
        if (request.queryParameters['frameCount'] == 5) return oldQuote.future;
        return backend.respond(request);
      };
      final search = session.loadProducts('old');
      await Future<void>.delayed(Duration.zero);
      await session.loadProducts('new');
      oldSearch.complete({'products': <dynamic>[]});
      await search;
      expect(session.products.single.id, 'product-1');
      final quote = session.requote();
      await Future<void>.delayed(Duration.zero);
      session.brief = {
        ...session.brief,
        'settings': {...session.settings, 'frameCount': 8},
      };
      await session.requote();
      oldQuote.complete({
        'creditCost': 999,
        'remaining': 0,
        'canAfford': false,
        'unlimitedImages': false,
      });
      await quote;
      expect(session.quote?.cost, 10);
      expect(session.quoteError, isNull);
    },
  );
  test('caption writes serialize and retain newest text while older request finishes', () async {
    session.generation = ContentGeneration(backend.generation);
    final gate = Completer<ContentJson>();
    var writes = 0;
    backend.handler = (request) {
      if (request.path.endsWith('/publishing-kit') && ++writes == 1) {
        return gate.future;
      }
      return backend.respond(request);
    };
    session.updatePublishing({'caption': 'first'}, debounce: true);
    final flush = session.flushEdits();
    await Future<void>.delayed(Duration.zero);
    session.updatePublishing({'caption': 'latest'}, debounce: true);
    gate.complete({
      'publishingKit': {'caption': 'first', 'hashtags': <String>[]},
      'coverFrameIndex': 0,
    });
    expect(await flush, isTrue);
    expect(session.generation?.kit?['caption'], 'latest');
    expect(
      backend.requests.where((r) => r.path.endsWith('/publishing-kit')).length,
      2,
    );
  });
  test(
    'no overlapping generation polls and in-flight reads cancel on pause',
    () async {
      backend.status = 'processing';
      session.generation = ContentGeneration(backend.generation);
      final gate = Completer<ContentJson>();
      final started = Completer<void>();
      backend.handler = (_) {
        started.complete();
        return gate.future;
      };
      final first = session.pollGeneration();
      final second = session.pollGeneration();
      await started.future;
      expect(backend.requests.length, 1);
      session.setPaused(value: true);
      gate.complete(backend.generation);
      await Future.wait([first, second]);
      expect(backend.requests.single.cancelToken?.isCancelled, isTrue);
      expect(session.error, isNull);
    },
  );
  test(
    'unknown generation restoration failure blocks new production work',
    () async {
      backend.handler = (_) => throw const FormatException('bad response');
      await session.initialize(generationId: 'missing');
      session.updateBrief({'productId': 'product-1'});
      await session.generate();
      expect(session.restorationFailed, isTrue);
      expect(backend.requests.length, 1);
    },
  );
  test('non-JSON success is rejected', () async {
    final dio = Dio()..httpClientAdapter = _EmptyAdapter();
    // Exercise through the configured service, with no network.
    backend.api.raw.httpClientAdapter = dio.httpClientAdapter;
    expect(backend.repository.history(), throwsA(isA<ContentApiException>()));
  });
}

class _EmptyAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString('', 204);
  @override
  void close({bool force = false}) {}
}
