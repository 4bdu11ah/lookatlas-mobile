import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/features/calendar/di/calendar_providers.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_drawer_controller.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_tray_controller.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_view_controller.dart';
import 'package:look_atlas/features/calendar/presentation/models/calendar_actions.dart';
import 'package:look_atlas/features/calendar/presentation/models/calendar_drawer_state.dart';
import 'package:look_atlas/features/create_content/di/content_providers.dart';

import '../create_content/content_test_backend.dart';
import 'calendar_test_backend.dart';

void main() {
  Future<ProviderContainer> mount(CalendarTestBackend backend) async {
    final container = ProviderContainer(
      overrides: [
        calendarSessionFactoryProvider.overrideWithValue(backend.session),
        contentRepositoryProvider.overrideWithValue(
          ContentTestBackend().repository,
        ),
      ],
    );
    addTearDown(container.dispose);
    final ready = Completer<void>();
    container.listen(calendarControllerProvider, (_, next) {
      if (next.overview != null &&
          !next.productsLoading &&
          !ready.isCompleted) {
        ready.complete();
      }
    }, fireImmediately: true);
    await ready.future;
    return container;
  }

  CalendarDrawerArgs drawerArgs(
    ProviderContainer container,
    String type, {
    int index = 0,
  }) {
    final session = container.read(calendarControllerProvider.notifier).session;
    final actions = CalendarActions(
      drawer: (_, {item, day}) async {},
      editor: (_) async {},
      download: (_) async {},
    );
    return CalendarDrawerArgs(
      type: type,
      view: CalendarViewData(session, actions),
      item: type == 'add' ? null : session.overview!.items[index],
    );
  }

  test('calendarProvider_setupChanges_preserveEarlierSnapshots', () async {
    final container = await mount(CalendarTestBackend()..stage = 'setup');
    final previous = container.read(calendarControllerProvider);
    final controller = container.read(calendarControllerProvider.notifier);
    controller.changeSetup(() {
      controller.session.setup.mode = 'batch';
      controller.session.setup.platforms.remove('facebook');
    });
    expect(container.read(calendarControllerProvider).setup.mode, 'batch');
    expect(container.read(calendarControllerProvider).setup.platforms, [
      'instagram',
    ]);
    expect(previous.setup.mode, 'scheduled');
    expect(previous.setup.platforms, ['instagram', 'facebook']);
  });

  test(
    'calendarViewProvider_independentControls_preserveRevisionText',
    () async {
      final container = await mount(CalendarTestBackend())
        ..listen(calendarViewProvider, (_, next) {});
      container.read(calendarViewProvider.notifier)
        ..setInstruction('More detail shots')
        ..setRevisionOpen(value: true)
        ..setProductsOpen(value: true)
        ..setMonth(value: true)
        ..setRevisionOpen(value: false);
      final state = container.read(calendarViewProvider);
      expect(state.instruction, 'More detail shots');
      expect(state.productsOpen, isTrue);
      expect(state.month, isTrue);
      expect(state.revisionOpen, isFalse);
    },
  );

  test(
    'drawerProvider_separateIdeas_isolateDraftsAndResetAfterDisposal',
    () async {
      final backend = CalendarTestBackend()..statuses = ['idea', 'idea'];
      final container = await mount(backend);
      final first = drawerArgs(container, 'idea');
      final second = drawerArgs(container, 'idea', index: 1);
      final subscription = container.listen(
        calendarDrawerProvider(first),
        (_, next) {},
      );
      container.listen(calendarDrawerProvider(second), (_, next) {});
      final edit = container.read(calendarDrawerProvider(first).notifier);
      edit.hook.text = 'Only the first draft changes';
      edit.setProduct('product-2');
      expect(
        container.read(calendarDrawerProvider(first)).productId,
        'product-2',
      );
      expect(
        container.read(calendarDrawerProvider(second)).productId,
        'product-1',
      );
      expect(
        container.read(calendarDrawerProvider(second).notifier).hook.text,
        'A fresh perspective 2',
      );
      subscription.close();
      await container.pump();
      container.listen(calendarDrawerProvider(first), (_, next) {});
      expect(
        container.read(calendarDrawerProvider(first).notifier).hook.text,
        'A fresh perspective 1',
      );
      expect(
        container.read(calendarDrawerProvider(first)).productId,
        'product-1',
      );
    },
  );

  test(
    'drawerProvider_failedSave_preservesDraftAndChangedOnlyPayload',
    () async {
      final backend = CalendarTestBackend();
      final container = await mount(backend);
      final args = drawerArgs(container, 'idea');
      container.listen(calendarDrawerProvider(args), (_, next) {});
      final controller = container.read(calendarDrawerProvider(args).notifier);
      controller.hook.text = 'A retained edit';
      backend.handler = (request) {
        if (request.method == 'PATCH') {
          throw DioException(requestOptions: request);
        }
        return backend.respond(request);
      };
      expect(await controller.save(), isFalse);
      expect(controller.hook.text, 'A retained edit');
      expect(container.read(calendarDrawerProvider(args)).error, isNotNull);
      expect(container.read(calendarDrawerProvider(args)).saving, isFalse);
      final patch =
          backend.requests.lastWhere((r) => r.method == 'PATCH').data as Map;
      expect(patch['locked'], isTrue);
      expect(patch.containsKey('publishAt'), isFalse);
      backend.handler = null;
      expect(await controller.save(), isTrue);
      expect(container.read(calendarDrawerProvider(args)).error, isNull);
    },
  );

  test('trayProvider_typingStaysLocal_untilValidatedSchedule', () async {
    final backend = CalendarTestBackend()..batch = true;
    final container = await mount(backend);
    container.listen(calendarTrayProvider('item-0'), (_, next) {});
    final controller = container.read(calendarTrayProvider('item-0').notifier)
      ..setInput('2026-09-');
    final before = backend.requests.where((r) => r.method == 'PATCH').length;
    await controller.schedule();
    expect(backend.requests.where((r) => r.method == 'PATCH').length, before);
    expect(container.read(calendarTrayProvider('item-0')).error, isNotNull);
    controller.setInput('2026-09-12T11:00');
    await controller.schedule();
    final patch =
        backend.requests.lastWhere((r) => r.method == 'PATCH').data as Map;
    expect(
      patch['publishAt'],
      DateTime(2026, 9, 12, 11).toUtc().toIso8601String(),
    );
    expect(container.read(calendarTrayProvider('item-0')).error, isNull);
  });

  testWidgets('calendarProvider_lastConsumerDisposes_cancelsPollingAndReads', (
    tester,
  ) async {
    final backend = CalendarTestBackend()..stage = 'planning';
    final container = ProviderContainer(
      overrides: [
        calendarSessionFactoryProvider.overrideWithValue(backend.session),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      calendarControllerProvider,
      (_, next) {},
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
    expect(backend.requests, isNotEmpty);
    subscription.close();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    final requests = backend.requests.length;
    await tester.pump(const Duration(seconds: 20));
    expect(backend.requests.length, requests);
    expect(
      backend.requests
          .where((r) => r.path == '/runway/overview')
          .last
          .cancelToken!
          .isCancelled,
      isTrue,
    );
  });
}
