import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_session.dart';
import 'package:look_atlas/features/calendar/presentation/models/calendar_actions.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_components.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_plan_revision.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_plan_row.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_plan_summary.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CalendarPlanReviewScreen extends ConsumerWidget {
  const CalendarPlanReviewScreen({required this.view, super.key});
  final CalendarViewData view;
  CalendarSession get s => view.session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
      calendarControllerProvider.select(
        (state) => (
          state.overview,
          state.busy.contains('plan'),
          state.picked.join(','),
        ),
      ),
    );
    final o = s.overview!;
    final p = o.plan!;
    final included = o.items.where((i) => i.status != 'skipped').toList();
    final selected = included.where((i) => s.picked.contains(i.id)).length;
    final count = included
        .map((i) => i.productId)
        .whereType<String>()
        .toSet()
        .length;
    final groups = p.batch || p.chapters.isEmpty
        ? [
            <String, dynamic>{
              'key': null,
              'title': 'The concept set',
              'description': 'Standalone posts, each angling its product differently. Pick the ones to create.',
            },
          ]
        : p.chapters;
    return calendarLazySections([
      calendarHeading(
        '${p.title ?? 'Your month'} / ${calendarWindow(p)}',
        p.batch
            ? 'Pick the concepts to create.'
            : 'Here’s the month we’d make.',
        p.batch
            ? '${p.strategy ?? 'Every concept takes its product from a different angle.'} Untick anything you don’t want, you only pay for what we create.'
            : '${p.strategy ?? 'Review the idea for each day.'} Change or skip anything, everything else is in.',
        actions: [
          _approvalControls(o, included.length, selected),
        ],
      ),
      const SizedBox(height: 18),
      CalendarPlanSummary(
        overview: o,
        items: included,
        productCount: count,
      ),
      if (p.settings['launchProductMissingPhotos'] == true)
        calendarErrorBanner(
          'The product you’re launching has no photos yet, so it can’t open and close the month. Add photos to it, then re-plan via Change setup.',
        ),
      if ((p.settings['downgradedForCredits'] as num? ?? 0) > 0)
        calendarNote(
          'To fit your credits, ${p.settings['downgradedForCredits']} posts were planned as single images instead of slideshows or video.',
        ),
      if (p.settings['skippedNoPhotos'] case final List<dynamic> skipped)
        if (skipped.isNotEmpty)
          calendarNote(
            'Products without photos: ${skipped.map((e) => (e as Map)['name']).join(', ')}.',
          ),
      if (o.credits != null &&
          (o.estimate['remainingTotal'] as num) > o.credits!)
        calendarErrorBanner(
          'This month needs about ${o.estimate['remainingTotal']} credits and you have ${o.credits}. We’ll create as much as your credits cover and pause the rest, or skip a few videos to fit.',
        ),
      const SizedBox(height: 18),
      CalendarPlanRevision(s: s),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(14),
        color: const Color(0xffedf2ee),
        child: Column(
          children: [
            for (final text in [
              'Balanced across $count products',
              'Mix of image, slideshow and video',
              'Ideas you change or lock won’t be touched',
            ])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.check,
                      size: 13,
                      color: Color(0xff4c725d),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: calendarBody(text)),
                  ],
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 34),
      for (var n = 0; n < groups.length; n++) ...[
        if (n > 0) const SizedBox(height: 38),
        _CalendarPlanChapter(
          number: n + 1,
          chapter: groups[n],
          fallbackCount: o.items.length,
        ),
        for (final item in o.items.where(
          (i) => groups[n]['key'] == null || i.chapterKey == groups[n]['key'],
        ))
          CalendarPlanRow(view: view, item: item, batch: p.batch),
      ],
      // Retain any server items without a matching chapter instead of dropping them.
      if (!p.batch && p.chapters.isNotEmpty)
        for (final item in o.items.where(
          (i) => !p.chapters.any((c) => c['key'] == i.chapterKey),
        ))
          CalendarPlanRow(view: view, item: item, batch: false),
    ]);
  }

  Widget _approvalControls(
    CalendarOverview overview,
    int included,
    int selected,
  ) {
    final plan = overview.plan!;
    final busy = s.busy.contains('plan') || s.revising;
    final change = calendarButton(
      'Change setup',
      busy ? null : s.changeSetup,
      icon: LucideIcons.settings2,
    );
    final approve = calendarButton(
      s.busy.contains('plan')
          ? 'Starting production…'
          : plan.batch
          ? 'Create $selected posts · ~${overview.selectedCost(s.picked)} credits'
          : 'Approve plan & start creating',
      busy || (plan.batch ? selected == 0 : included == 0) ? null : s.approve,
      primary: true,
      icon: LucideIcons.arrowRight,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              approve,
              const SizedBox(height: 8),
              change,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: approve),
            const SizedBox(width: 8),
            Expanded(child: change),
          ],
        );
      },
    );
  }
}

class _CalendarPlanChapter extends StatelessWidget {
  const _CalendarPlanChapter({
    required this.number,
    required this.chapter,
    required this.fallbackCount,
  });

  final int number;
  final Map<String, dynamic> chapter;
  final int fallbackCount;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 46,
          child: calendarDisplay(
            number.toString().padLeft(2, '0'),
            22,
            color: CALENDAR_MUTED,
            italic: true,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              calendarKicker(_range),
              const SizedBox(height: 7),
              calendarDisplay(chapter['title'] as String, 34),
              if (chapter['description'] case final String description)
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  calendarBody(description, size: 13),
                ],
            ],
          ),
        ),
      ],
    ),
  );

  String get _range {
    final start = DateTime.tryParse(chapter['startsOn'] as String? ?? '');
    final end = DateTime.tryParse(chapter['endsOn'] as String? ?? '');
    if (start == null || end == null) return '$fallbackCount concepts';
    return '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d').format(end)}';
  }
}
