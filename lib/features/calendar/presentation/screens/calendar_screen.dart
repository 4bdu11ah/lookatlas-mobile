import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/network/request_cancellation.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_session.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_view_controller.dart';
import 'package:look_atlas/features/calendar/presentation/models/calendar_actions.dart';
import 'package:look_atlas/features/calendar/presentation/models/calendar_drawer_state.dart';
import 'package:look_atlas/features/calendar/presentation/screens/calendar_add_post_screen.dart';
import 'package:look_atlas/features/calendar/presentation/screens/calendar_automation_screen.dart';
import 'package:look_atlas/features/calendar/presentation/screens/calendar_edit_idea_screen.dart';
import 'package:look_atlas/features/calendar/presentation/screens/calendar_post_preview_screen.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_body.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_theme.dart';
import 'package:look_atlas/features/create_content/di/content_providers.dart';
import 'package:look_atlas/shared/widgets/custom_app_bar.dart';
import 'package:share_plus/share_plus.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key, this.initialMonth = false});
  final bool initialMonth;
  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [calendarInitialMonthProvider.overrideWithValue(initialMonth)],
    child: const CalendarRouteScreen(),
  );
}

class CalendarRouteScreen extends ConsumerStatefulWidget {
  const CalendarRouteScreen({super.key});
  @override
  ConsumerState<CalendarRouteScreen> createState() =>
      _CalendarRouteScreenState();
}

class _CalendarRouteScreenState extends ConsumerState<CalendarRouteScreen>
    with WidgetsBindingObserver {
  late final CalendarSession s;
  final Map<String, RequestCancellation> _downloads = {};
  late final CalendarActions _actions = CalendarActions(
    drawer: drawer,
    editor: editor,
    download: download,
  );
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    s = ref.read(calendarControllerProvider.notifier).session;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      s.setPaused(value: state != AppLifecycleState.resumed);
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final token in _downloads.values) {
      token.cancel();
    }
    super.dispose();
  }

  Future<void> editor(CalendarItem item) async {
    if (item.generationId == null) return;
    s.setPaused(value: true);
    await context.push<void>(
      '${AppRoutes.createContent}/item/${Uri.encodeComponent(item.generationId!)}',
    );
    if (mounted) s.setPaused(value: false);
  }

  Future<void> download(CalendarItem item) async {
    if (!item.downloadable || s.busy.contains('download:${item.id}')) return;
    final key = 'download:${item.id}';
    final token = RequestCancellation();
    _downloads[key] = token;
    s.busy.add(key);
    s.emit();
    try {
      final archive = await ref.read(contentArchiveDownloadProvider)(
        item.generationId!,
        cancellation: token,
      );
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              archive.bytes,
              mimeType: 'application/zip',
              name: archive.name,
            ),
          ],
          fileNameOverrides: [archive.name],
          sharePositionOrigin: Rect.fromLTWH(
            MediaQuery.sizeOf(context).width / 2,
            56,
            1,
            1,
          ),
        ),
      );
    } on Object {
      s.actionError = 'That download didn’t work. Try again, or open the post and export from the editor.';
    } finally {
      await s.refresh();
      _downloads.remove(key);
      s.busy.remove(key);
      s.emit();
    }
  }

  Future<void> drawer(String type, {CalendarItem? item, DateTime? day}) async {
    await showGeneralDialog<void>(
      context: context,
      barrierColor: const Color(0x55000000),
      barrierLabel: 'Calendar drawer',
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (context, a, _, child) => SlideTransition(
        position: Tween(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        child: child,
      ),
      pageBuilder: (context, _, _) {
        final args = CalendarDrawerArgs(
          type: type,
          view: CalendarViewData(s, _actions),
          item: item,
          day: day,
        );
        return switch (type) {
          'idea' => CalendarEditIdeaScreen(args: args),
          'add' => CalendarAddPostScreen(args: args),
          'automation' => CalendarAutomationScreen(args: args),
          'post' => CalendarPostPreviewScreen(args: args),
          _ => throw ArgumentError.value(type, 'type'),
        };
      },
    );
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..watch(calendarControllerProvider.notifier)
      ..watch(calendarViewProvider.notifier);
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: CALENDAR_PAPER,
        textTheme: Theme.of(context).textTheme.apply(
          fontFamily: 'Satoshi',
          bodyColor: CALENDAR_INK,
          displayColor: CALENDAR_INK,
        ),
        colorScheme: const ColorScheme.light(
          primary: CALENDAR_INK,
          surface: CALENDAR_PAPER,
        ),
      ),
      child: Scaffold(
        backgroundColor: CALENDAR_PAPER,
        appBar: CustomAppBar(
          title: 'Calendar',
          showBackButton: true,
          onBack: _leave,
        ),
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: () => Future.wait([s.refresh(), s.loadProducts()]),
            child: CalendarBody(view: CalendarViewData(s, _actions)),
          ),
        ),
      ),
    );
  }
}
