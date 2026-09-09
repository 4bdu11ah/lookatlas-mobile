import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      calendarFullBleed(
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: calendarSummaryCell(
                    '${included.length} post ideas',
                    bold: true,
                  ),
                ),
                Expanded(child: calendarSummaryCell('$count products')),
              ],
            ),
            Row(
              children: [
                for (final e in ['slideshow', 'video', 'single'])
                  Expanded(
                    child: calendarSummaryCell(
                      '${included.where((i) => i.format == e).length} ${e == 'single' ? 'single posts' : '${e}s'}',
                    ),
                  ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: calendarSummaryCell(
                    '${o.estimate['total'] == 0 ? 'Included in your plan' : '≈ ${o.estimate['total']} credits'}${o.credits == null ? '' : ' · you have ${o.credits}'}',
                    bold: true,
                  ),
                ),
                const Expanded(flex: 2, child: SizedBox()),
              ],
            ),
          ],
        ),
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
        calendarSection(
          '0${n + 1} / ${groups[n]['startsOn'] ?? '${o.items.length} concepts'}',
          groups[n]['title'] as String,
          groups[n]['description'] as String? ?? '',
        ),
        for (final item in o.items.where(
          (i) => groups[n]['key'] == null || i.chapterKey == groups[n]['key'],
        ))
          CalendarPlanRow(view: view, item: item, batch: p.batch),
        const SizedBox(height: 48),
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
    final change = Container(
      width: 86.16,
      height: 43,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CALENDAR_LINE)),
      ),
      child: TextButton(
        onPressed: busy ? null : s.changeSetup,
        style: TextButton.styleFrom(
          foregroundColor: CALENDAR_MUTED,
          padding: const EdgeInsets.symmetric(horizontal: 3),
          shape: const RoundedRectangleBorder(),
        ),
        child: const Text(
          'Change setup',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ),
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
        if (constraints.maxWidth < 330) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(alignment: Alignment.centerLeft, child: change),
              const SizedBox(height: 8),
              approve,
            ],
          );
        }
        return Row(
          children: [
            change,
            const SizedBox(width: 8),
            Expanded(child: approve),
          ],
        );
      },
    );
  }
}
