import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/features/calendar/di/calendar_providers.dart';
import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';

import 'calendar_test_backend.dart';

void main() {
  test(
    'resume reloads products when the initial request was cancelled',
    () async {
      final backend = CalendarTestBackend();
      final pending = Completer<Object?>();
      backend.handler = (request) => request.path == '/products'
          ? pending.future
          : backend.respond(request);
      final session = backend.session();
      addTearDown(session.dispose);
      final initial = session.initialize();
      await Future<void>.delayed(Duration.zero);
      session.setPaused(value: true);
      await initial;
      expect(session.products, isEmpty);
      backend.handler = null;
      final reloaded = Completer<void>();
      session.addListener(() {
        if (session.products.isNotEmpty && !reloaded.isCompleted) {
          reloaded.complete();
        }
      });
      session.setPaused(value: false);
      await reloaded.future;
      expect(session.products, hasLength(10));
      expect(session.productError, isNull);
      pending.complete({'products': <dynamic>[]});
      await Future<void>.delayed(Duration.zero);
      expect(session.products, hasLength(10));
    },
  );

  testWidgets('active polling pauses in background and stops when static', (
    tester,
  ) async {
    final backend = CalendarTestBackend()
      ..stage = 'active'
      ..statuses = ['producing'];
    final session = backend.session();
    unawaited(session.initialize());
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
    final initial = backend.requests.length;
    await tester.pump(const Duration(seconds: 4));
    expect(backend.requests.length, initial);
    await tester.pump(const Duration(seconds: 1));
    expect(backend.requests.length, greaterThan(initial));
    session.setPaused(value: true);
    final paused = backend.requests.length;
    await tester.pump(const Duration(seconds: 20));
    expect(backend.requests.length, paused);
    backend.statuses = ['ready'];
    session.setPaused(value: false);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
    final resumed = backend.requests.length;
    await tester.pump(const Duration(seconds: 20));
    expect(backend.requests.length, resumed);
    session.dispose();
  });

  test(
    'scheduled and batch payloads, launch validation and credit fitting',
    () async {
      final b = CalendarTestBackend()..stage = 'setup';
      final s = b.session();
      addTearDown(s.dispose);
      await s.initialize();
      await s.requote();
      s.setup.objective = 'Launch a product';
      expect(await s.createPlan(), false);
      expect(s.setup.validation, isNotNull);
      s.setup.productModes = {'product-10': 'spotlight'};
      s.setup.horizonDays = 14;
      expect(await s.createPlan(), true);
      final r = b.requests.firstWhere((r) => r.path == '/runway/plans');
      expect(r.data, containsPair('timeZone', 'Asia/Karachi'));
      expect(r.data, containsPair('horizonDays', 14));
      expect(r.data, containsPair('fitToCredits', true));
      expect(r.headers['Authorization'], 'Bearer test-token');
      b.stage = 'setup';
      await s.refresh();
      s.setup.mode = 'batch';
      s.setup.batchCount = 5;
      await s.requote();
      expect(b.requests.last.queryParameters, containsPair('batchCount', 5));
      expect(b.requests.last.queryParameters, isNot(contains('horizonDays')));
      await s.createPlan();
      final body =
          b.requests.lastWhere((r) => r.path == '/runway/plans').data as Map;
      expect(body['mode'], 'batch');
      expect(body['batchCount'], 5);
      expect(body.containsKey('horizonDays'), false);
    },
  );
  test('one channel is required and planning guards resubmission', () async {
    final b = CalendarTestBackend()..stage = 'setup';
    final s = b.session();
    addTearDown(s.dispose);
    await s.initialize();
    s.setup.platforms = [];
    expect(await s.createPlan(), false);
    s.setup.platforms = ['instagram'];
    await s.createPlan();
    expect(await s.createPlan(), false);
    expect(b.requests.where((r) => r.path == '/runway/plans'), hasLength(1));
  });
  test(
    'selected batch charges use costs, unlimited images, skip exclusion',
    () {
      final b = CalendarTestBackend()
        ..batch = true
        ..statuses = ['idea', 'idea', 'idea', 'skipped'];
      final o = CalendarOverview(b.overview);
      expect(o.selectedCost({'item-0', 'item-2', 'item-3'}), 14);
      expect(
        CalendarOverview({...b.overview, 'unlimitedImages': true})
            .selectedCost({'item-0', 'item-1', 'item-2'}),
        12,
      );
      final legacy = {...b.overview}..remove('unitCosts');
      expect(CalendarOverview(legacy).selectedCost({'item-2'}), 10);
    },
  );
  test('approve selected batch excludes skipped IDs', () async {
    final b = CalendarTestBackend()
      ..batch = true
      ..statuses = ['idea', 'idea', 'skipped'];
    final s = b.session();
    addTearDown(s.dispose);
    await s.initialize();
    s.picked.remove('item-1');
    await s.approve();
    expect(b.requests.firstWhere((r) => r.path.endsWith('/approve')).data, {
      'itemIds': ['item-0'],
    });
  });
  test('every item action uses item IDs and no JSON body', () async {
    for (final entry in {
      'skip': 'idea',
      'unskip': 'skipped',
      'looks-good': 'ready',
      'back-to-review': 'scheduled',
      'retry': 'failed',
      'swap': 'idea',
      'build': 'approved',
    }.entries) {
      final b = CalendarTestBackend()
        ..stage = 'active'
        ..batch = true
        ..statuses = [entry.value];
      final s = b.session();
      await s.initialize();
      expect(await s.itemAction(s.overview!.items.first, entry.key), true);
      final r = b.requests.firstWhere((r) => r.path.endsWith('/${entry.key}'));
      expect(r.path, '/runway/items/item-0/${entry.key}');
      expect(r.method, 'POST');
      expect(r.data, null);
      s.dispose();
    }
  });
  test(
    'failed mutation refreshes truth, preserves setup and item errors',
    () async {
      final b = CalendarTestBackend();
      final s = b.session();
      addTearDown(s.dispose);
      await s.initialize();
      s.setup.objective = 'Grow followers';
      b.handler = (r) {
        if (r.method == 'POST') {
          throw DioException(
            requestOptions: r,
            response: Response<dynamic>(requestOptions: r, statusCode: 402),
          );
        }
        return b.respond(r);
      };
      expect(await s.itemAction(s.overview!.items.first, 'skip'), false);
      expect(s.actionError, contains('credits'));
      expect(s.setup.objective, 'Grow followers');
      expect(b.requests.last.path, '/runway/overview');
      expect(s.mutationErrors['item-0'], isNotNull);
    },
  );
  test('busy set guards same item, permits independent items', () async {
    final b = CalendarTestBackend()..statuses = ['idea', 'idea'];
    final s = b.session();
    addTearDown(s.dispose);
    await s.initialize();
    final gate = Completer<Object?>();
    b.handler = (r) => r.method == 'POST' ? gate.future : b.respond(r);
    final a = s.itemAction(s.overview!.items[0], 'skip');
    final c = s.itemAction(s.overview!.items[1], 'skip');
    expect(s.busy, containsAll(['item-0', 'item-1']));
    expect(await s.itemAction(s.overview!.items[0], 'skip'), false);
    gate.complete({'item': b.makeItem(0, 'skipped')});
    expect(await a, true);
    expect(await c, true);
    expect(s.busy, isEmpty);
  });
  test(
    'overlapping refreshes coalesce into exactly one trailing read',
    () async {
      final b = CalendarTestBackend();
      final s = b.session();
      addTearDown(s.dispose);
      await s.initialize();
      final gate = Completer<Object?>();
      final started = Completer<void>();
      var reads = 0;
      b.handler = (r) {
        if (r.path == '/runway/overview' && ++reads == 1) {
          started.complete();
          return gate.future;
        }
        return b.respond(r);
      };
      final a = s.refresh();
      final c = s.refresh();
      final d = s.refresh();
      await started.future;
      expect(reads, 1);
      gate.complete(b.overview);
      await Future.wait([a, c, d]);
      expect(reads, 2);
    },
  );
  test(
    'revision failure preserves instruction; success uses plan ID',
    () async {
      final b = CalendarTestBackend();
      final s = b.session();
      addTearDown(s.dispose);
      await s.initialize();
      expect(await s.revise('More editorial'), true);
      expect(b.requests.firstWhere((r) => r.path.endsWith('/revise')).data, {
        'instruction': 'More editorial',
      });
      expect(s.revising, true);
      expect(await s.revise('Again'), false);
      b.revision = 'failed';
      await s.refresh();
      expect(s.revising, false);
      expect(s.overview!.plan!.revision, 'failed');
    },
  );
  test('archive must succeed before prefilled next-month setup', () async {
    final b = CalendarTestBackend()..stage = 'active';
    final s = b.session();
    addTearDown(s.dispose);
    await s.initialize();
    b.handler = (r) {
      if (r.path.endsWith('/archive')) throw DioException(requestOptions: r);
      return b.respond(r);
    };
    expect(await s.rollover(), false);
    expect(s.setupOverride, false);
    b.handler = null;
    expect(await s.rollover(), true);
    expect(s.setupOverride, true);
    expect(s.setup.productModes, {'product-1': 'spotlight'});
    expect(s.setup.horizonDays, 30);
    expect(
      b.requests.firstWhere((r) => r.path.endsWith('/archive')).data,
      isNull,
    );
  });
  test('malformed overview never becomes an empty Calendar', () async {
    final b = CalendarTestBackend();
    b.handler = (r) =>
        r.path == '/runway/overview' ? <String, dynamic>{} : b.respond(r);
    final s = b.session();
    addTearDown(s.dispose);
    await s.initialize();
    expect(s.overview, isNull);
    expect(s.error, contains('invalid'));
  });
  test('poll rules honor revisions, availability and paused production', () {
    final b = CalendarTestBackend()..stage = 'planning';
    expect(
      CalendarOverview(b.overview).pollDelay,
      const Duration(milliseconds: 1500),
    );
    b
      ..stage = 'plan_ready'
      ..revision = 'applying';
    expect(
      CalendarOverview(b.overview).pollDelay,
      const Duration(milliseconds: 1500),
    );
    b
      ..revision = null
      ..stage = 'active'
      ..statuses = ['scheduled'];
    expect(CalendarOverview(b.overview).pollDelay, isNull);
    b.unavailable = false;
    expect(CalendarOverview(b.overview).pollDelay, const Duration(seconds: 5));
    b
      ..statuses = ['approved']
      ..paused = true;
    expect(CalendarOverview(b.overview).pollDelay, isNull);
    b.statuses = ['producing'];
    expect(CalendarOverview(b.overview).pollDelay, const Duration(seconds: 5));
  });
  testWidgets('planning polls at 1.5s and disposal cancels timers', (
    tester,
  ) async {
    final b = CalendarTestBackend()..stage = 'planning';
    final s = b.session();
    unawaited(s.initialize());
    for (var n = 0; n < 20; n++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
    final n = b.requests.length;
    await tester.pump(const Duration(milliseconds: 1400));
    expect(b.requests.length, n);
    await tester.pump(const Duration(milliseconds: 100));
    for (var n = 0; n < 10; n++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
    expect(b.requests.length, greaterThan(n));
    s.dispose();
    final end = b.requests.length;
    await tester.pump(const Duration(seconds: 15));
    expect(b.requests.length, end);
  });
  test('date input rejects partial or normalized invalid values and future defaults', () {
    expect(calendarParseInput('2026-09-'), isNull);
    expect(calendarParseInput('2026-02-30T11:00'), isNull);
    final now = DateTime(2026, 9, 8, 15);
    expect(calendarDefaultTime(now, now).isAfter(now), true);
    expect(calendarDefaultTime(DateTime(2026, 9, 9), now).hour, 11);
    final p = CalendarPlan(CalendarTestBackend().plan);
    expect(calendarTimeError('2026-09-08T11:00', p, now), contains('future'));
    expect(calendarTimeError('2026-10-10T11:00', p, now), contains('within'));
  });
  test('42 local Monday-first cells retain multiple same-day posts', () {
    final b = CalendarTestBackend()..statuses = ['ready', 'ready'];
    final json = b.overview;
    final items = json['items'] as List;
    items[1] = {
      ...(items[1] as Map<String, dynamic>),
      'publishAt': (items[0] as Map)['publishAt'],
    };
    final o = CalendarOverview(json);
    final cells = calendarDays(o, DateTime(2026, 9, 8));
    expect(cells, hasLength(42));
    expect(cells.first.date.weekday, DateTime.monday);
    expect(cells.expand((c) => c.items), hasLength(2));
    expect(cells.firstWhere((c) => c.items.isNotEmpty).items, hasLength(2));
    expect(
      cells.where((c) => c.items.isNotEmpty).every((c) => !c.addable),
      true,
    );
  });
  test('all documented statuses and badge label', () {
    final b = CalendarTestBackend();
    for (final status in [
      'idea',
      'approved',
      'producing',
      'ready',
      'scheduled',
      'publishing',
      'published',
      'failed',
      'blocked',
      'skipped',
    ]) {
      final i = CalendarItem(b.makeItem(0, status));
      expect(i.label(drafts: true), isNotEmpty);
      if ({'producing', 'publishing', 'published'}.contains(status)) {
        expect(i.actions, isEmpty);
      }
    }
    expect(calendarBadge(9), '9');
    expect(calendarBadge(10), '9+');
  });
  test('old availability fallback uses available, not connected', () {
    final b = CalendarTestBackend();
    final json = b.overview..remove('publishingAvailable');
    json['connections'] = [
      {'platform': 'instagram', 'available': false, 'status': 'connected'},
    ];
    expect(CalendarOverview(json).drafts, true);
  });
  test('item patch leaves publishAt absent for unrelated edits', () async {
    final b = CalendarTestBackend();
    await b.repo.changeItem(
      'item-1',
      patch: {'hook': 'New hook', 'locked': true},
    );
    expect(b.requests.single.data, {'hook': 'New hook', 'locked': true});
    expect(
      () => b.repo.changeItem('item-1', action: 'publish'),
      throwsArgumentError,
    );
  });
}
