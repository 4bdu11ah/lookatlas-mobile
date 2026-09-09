import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_caption.dart';

import '../create_content/content_test_backend.dart';

void main() {
  test('caption_unchanged_doesNotMutate', () async {
    final backend = ContentTestBackend();
    final caption = CalendarCaption(
      backend.repository,
      'generation-1',
      refresh: () async {},
    );
    addTearDown(caption.dispose);
    await caption.load();
    expect(await caption.save(), true);
    expect(backend.requests.where((r) => r.method == 'PATCH'), isEmpty);
    expect(caption.hashtags, isNotEmpty);
  });
  test('caption_failedSave_preservesTextAndRefreshes', () async {
    final backend = ContentTestBackend();
    var refreshes = 0;
    final caption = CalendarCaption(
      backend.repository,
      'generation-1',
      refresh: () async {
        refreshes++;
      },
    );
    addTearDown(caption.dispose);
    await caption.load();
    backend.handler = (r) {
      if (r.method == 'PATCH') throw DioException(requestOptions: r);
      return backend.respond(r);
    };
    caption.edit('Keep my edit');
    expect(await caption.save(), false);
    expect(caption.value, 'Keep my edit');
    expect(caption.error, isNotNull);
    expect(refreshes, 1);
    backend.handler = null;
    expect(await caption.save(), true);
    expect(caption.saved, true);
    expect(refreshes, 2);
  });
  test('caption_newTextDuringSave_isNotOverwrittenOrMarkedSaved', () async {
    final backend = ContentTestBackend();
    final caption = CalendarCaption(
      backend.repository,
      'generation-1',
      refresh: () async {},
    );
    addTearDown(caption.dispose);
    await caption.load();
    final gate = Completer<Map<String, dynamic>>();
    backend.handler = (r) =>
        r.method == 'PATCH' ? gate.future : backend.respond(r);
    caption.edit('First text');
    final saving = caption.save();
    expect(caption.saving, true);
    caption.edit('Newer text');
    expect(await caption.save(), false);
    gate.complete({
      'publishingKit': {'caption': 'First text'},
    });
    expect(await saving, false);
    expect(caption.value, 'Newer text');
    expect(caption.savedValue, 'First text');
    expect(caption.saved, false);
    backend.handler = null;
    expect(await caption.save(), true);
  });
  test('caption_limit_blocksOversizeAndAccepts2200', () async {
    final backend = ContentTestBackend();
    final caption = CalendarCaption(
      backend.repository,
      'generation-1',
      refresh: () async {},
    );
    addTearDown(caption.dispose);
    await caption.load();
    caption.edit('a' * 2201);
    expect(await caption.save(), false);
    expect(backend.requests.where((r) => r.method == 'PATCH'), isEmpty);
    caption.edit('a' * 2200);
    expect(await caption.save(), true);
  });
  test('caption_disposedLoad_doesNotNotifyOrAffectAnotherGeneration', () async {
    final backend = ContentTestBackend();
    final gate = Completer<Map<String, dynamic>>();
    backend.handler = (r) => gate.future;
    final first = CalendarCaption(
      backend.repository,
      'generation-1',
      refresh: () async {},
    );
    var notifications = 0;
    first.addListener(() => notifications++);
    final loading = first.load();
    first.dispose();
    final before = notifications;
    gate.complete(backend.generation);
    await loading;
    expect(notifications, before);
    expect(first.loaded, false);
  });
}
