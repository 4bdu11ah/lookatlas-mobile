import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/features/calendar/di/calendar_providers.dart';
import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';
import 'package:look_atlas/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_agenda_row.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_components.dart';
import 'package:look_atlas/features/create_content/di/content_providers.dart';
import 'package:look_atlas/shared/widgets/app_dropdown.dart';

import '../create_content/content_test_backend.dart';
import 'calendar_test_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await materialIcons.load();
    for (final family in ['Satoshi', 'InstrumentSerif']) {
      final font = FontLoader(family);
      for (final weight
          in family == 'Satoshi'
              ? ['Regular', 'Medium', 'Bold', 'Black']
              : ['Regular', 'Italic']) {
        font.addFont(rootBundle.load('assets/fonts/$family-$weight.ttf'));
      }
      await font.load();
    }
    final georgiaFile = File('/System/Library/Fonts/Supplemental/Georgia.ttf');
    if (georgiaFile.existsSync()) {
      final georgia = FontLoader('Georgia')
        ..addFont(
          Future.value(ByteData.sublistView(georgiaFile.readAsBytesSync())),
        );
      await georgia.load();
    }
    final icons = FontLoader('packages/lucide_icons_flutter/Lucide')
      ..addFont(
        rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'),
      );
    await icons.load();
  });
  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 12; i++) {
      await t.pump(const Duration(milliseconds: 25));
    }
  }

  testWidgets('approved calendar status uses subtle green text', (t) async {
    final item = CalendarItem(CalendarTestBackend().makeItem(0, 'scheduled'));
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: calendarStatus(
            item,
            drafts: true,
            emphasizeApproved: true,
          ),
        ),
      ),
    );

    final label = t.widget<Text>(find.text('Approved'));
    expect(label.style?.color, const Color(0xff4c725d));
  });

  for (final width in [320, 375, 390, 430]) {
    testWidgets('Calendar states and nested drawers at $width', (t) async {
      t.view.physicalSize = Size(width.toDouble(), 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final b = CalendarTestBackend()..stage = 'setup';
      final content = ContentTestBackend();
      // late CalendarSession session;
      Future<void> mount({bool month = false}) async {
        await t.pumpWidget(const SizedBox());
        await t.pump();
        await t.pumpWidget(
          ProviderScope(
            overrides: [
              calendarSessionFactoryProvider.overrideWithValue(b.session),
              contentRepositoryProvider.overrideWithValue(content.repository),
            ],
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              home: CalendarScreen(initialMonth: month),
            ),
          ),
        );
        await settle(t);
      }

      Future<void> shot(String name) async {
        await settle(t);
        expect(t.takeException(), isNull);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/$name-$width.png'),
        );
      }

      Future<void> tap(String label) async {
        final matches = find.text(label);
        if (matches.evaluate().isEmpty) {
          await t.scrollUntilVisible(
            matches,
            300,
            scrollable: find
                .byWidgetPredicate(
                  (w) =>
                      w is Scrollable && w.axisDirection == AxisDirection.down,
                )
                .last,
          );
        }
        final f = matches.first;
        if (f.hitTestable().evaluate().isEmpty) await t.ensureVisible(f);
        await settle(t);
        await t.tap(f);
        await settle(t);
      }

      await mount();
      await shot('setup');
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.right,
        ),
        findsNothing,
      );
      await tap('A batch of posts');
      await shot('batch');
      await tap('Launch a product');
      await t.ensureVisible(find.text('Which product are you launching?'));
      await settle(t);
      await shot('priority');
      b
        ..stage = 'plan_ready'
        ..statuses = ['idea', 'skipped'];
      await mount();
      await shot('plan');
      await t.scrollUntilVisible(
        find.text('The reveal'),
        300,
        scrollable: find
            .byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.down,
            )
            .last,
      );
      await shot('plan-items');
      await t.scrollUntilVisible(
        find.text('Want different ideas?'),
        -300,
        scrollable: find
            .byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.down,
            )
            .last,
      );
      await tap('Want different ideas?');
      await shot('revision');
      await tap('Change');
      expect(find.byType(AppDropdown<String>), findsNWidgets(2));
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
      await shot('idea');
      await t.ensureVisible(find.byTooltip('Choose posting date and time'));
      await settle(t);
      await t.tap(find.byTooltip('Choose posting date and time'));
      await t.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await t.tap(find.text('Cancel'));
      await settle(t);
      await t.ensureVisible(find.byType(AppDropdown<String>).first);
      await settle(t);
      await t.tap(find.byType(AppDropdown<String>).first);
      await settle(t);
      await t.tap(find.text('Product 2').last);
      await settle(t);
      await t.enterText(find.byType(TextField).first, 'An edited hook');
      b.handler = (r) {
        if (r.method == 'PATCH') throw DioException(requestOptions: r);
        return b.respond(r);
      };
      await tap('Save changes');
      expect(find.text('An edited hook'), findsOneWidget);
      await shot('idea-failed');
      b.handler = null;
      await tap('Save changes');
      expect(find.text('Save changes'), findsNothing);
      final patch =
          b.requests.lastWhere((r) => r.method == 'PATCH').data as Map;
      expect(patch.containsKey('publishAt'), false);
      expect(patch['locked'], true);
      expect(patch['productId'], 'product-2');
      b
        ..stage = 'active'
        ..statuses = [
          'ready',
          'scheduled',
          'producing',
          'approved',
          'published',
          'failed',
          'blocked',
          'skipped',
          'idea',
        ];
      await mount();
      final operatingScroll = find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .last;
      t.state<ScrollableState>(operatingScroll).position.jumpTo(0);
      await settle(t);
      await shot('operating');
      expect(find.text('Un-approve'), findsNothing);
      expect(find.text('Take another look'), findsNothing);
      await t.scrollUntilVisible(
        find.text('A fresh perspective 2'),
        300,
        scrollable: operatingScroll,
      );
      final scheduledRow = find.byWidgetPredicate(
        (widget) =>
            widget is CalendarAgendaRow && widget.item.status == 'scheduled',
      );
      await t.ensureVisible(scheduledRow);
      await settle(t);
      final scheduledPreview = find.descendant(
        of: scheduledRow,
        matching: find.text('Preview'),
      );
      await t.ensureVisible(scheduledPreview);
      await settle(t);
      await t.tap(scheduledPreview);
      await settle(t);
      expect(find.text('Un-approve'), findsOneWidget);
      await t.tap(find.bySemanticsLabel('Close').first);
      await settle(t);
      t.state<ScrollableState>(operatingScroll).position.jumpTo(0);
      await settle(t);
      await t.tap(find.text('Review 1 post'));
      for (var frame = 0; frame < 48; frame++) {
        await t.pump(const Duration(milliseconds: 25));
      }
      expect(find.text('NEEDS REVIEW').hitTestable(), findsOneWidget);
      await t.scrollUntilVisible(
        find.text('YOUR MONTH'),
        300,
        scrollable: operatingScroll,
      );
      await shot('operating-month');
      t.state<ScrollableState>(operatingScroll).position.jumpTo(0);
      await settle(t);
      await tap('Settings');
      await shot('automation');
      await tap('Save settings');
      await tap('Preview');
      await shot('post');
      await t.tap(find.byTooltip('Choose posting date and time'));
      await settle(t);
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await t.tap(find.text('Cancel'));
      await settle(t);
      final fields = find.byType(TextField);
      await t.ensureVisible(fields.last);
      await t.enterText(fields.last, 'A new calendar caption');
      await tap('Save caption');
      await shot('caption');
      expect(
        content.requests.where((r) => r.path.endsWith('/publishing-kit')),
        hasLength(1),
      );
      await t.tap(find.bySemanticsLabel('Close').first);
      await settle(t);
      await tap('Add post');
      await shot('add');
      final beforeAdd = b.requests
          .where((r) => r.path.endsWith('/items'))
          .length;
      await t.enterText(
        find.byKey(const ValueKey('calendar-post-time-field')),
        '2026-09-',
      );
      await tap('Add to the month');
      expect(find.text('2026-09-'), findsOneWidget);
      expect(
        b.requests.where((r) => r.path.endsWith('/items')).length,
        beforeAdd,
      );
      await t.enterText(
        find.byKey(const ValueKey('calendar-post-time-field')),
        '2026-09-12T11:00',
      );
      b.handler = (r) {
        if (r.path.endsWith('/items')) throw DioException(requestOptions: r);
        return b.respond(r);
      };
      await tap('Add to the month');
      expect(find.text('2026-09-12T11:00'), findsOneWidget);
      expect(find.text('Add to the month'), findsOneWidget);
      await shot('add-failed');
      b.handler = null;
      await tap('Add to the month');
      expect(find.text('Add to the month'), findsNothing);
      final added =
          b.requests.lastWhere((r) => r.path.endsWith('/items')).data as Map;
      expect(
        added['publishAt'],
        DateTime(2026, 9, 12, 11).toUtc().toIso8601String(),
      );
      await tap('Add post');
      await t.tap(find.bySemanticsLabel('Close').first);
      await settle(t);
      await mount(month: true);
      await tap('Add post');
      await t.tap(find.bySemanticsLabel('Close').first);
      await settle(t);
      await shot('month');
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.right,
        ),
        findsNothing,
      );
      expect(find.text('Month'), findsNothing);
      b
        ..batch = true
        ..statuses = ['idea', 'ready', 'failed', 'skipped'];
      await mount();
      await tap('4 posts waiting for a day.');
      await shot('tray');
      b
        ..stage = 'setup'
        ..noProducts = true;
      await mount();
      await shot('empty');
      b.handler = (r) {
        if (r.path == '/runway/overview') throw DioException(requestOptions: r);
        return b.respond(r);
      };
      await mount();
      await shot('error');
      b
        ..handler = null
        ..noProducts = false
        ..stage = 'planning';
      await mount();
      await shot('planning');
      b.stage = 'plan_failed';
      await mount();
      expect(
        find.textContaining('We couldn’t write your month'),
        findsOneWidget,
      );
      await shot('planning-failed');
      b
        ..stage = 'plan_ready'
        ..batch = true
        ..revision = 'failed';
      await mount();
      await tap('Want different ideas?');
      expect(
        find.textContaining('We couldn’t update the ideas'),
        findsOneWidget,
      );
      await shot('revision-failed');
      b
        ..stage = 'active'
        ..batch = false
        ..revision = null
        ..statuses = ['published'];
      await mount();
      expect(find.text('This month is wrapped.'), findsOneWidget);
      await shot('wrapped');
      final pending = Completer<Object?>();
      b.handler = (request) => request.path == '/runway/overview'
          ? pending.future
          : b.respond(request);
      await mount();
      expect(
        find.byKey(const ValueKey('calendar-loading-skeleton')),
        findsOneWidget,
      );
      expect(find.text('Loading your calendar…'), findsNothing);
      await shot('loading');
      await t.pumpWidget(const SizedBox());
      await t.pump();
      pending.complete(b.overview);
    });
  }
}
