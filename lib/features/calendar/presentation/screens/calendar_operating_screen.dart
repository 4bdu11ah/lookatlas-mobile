import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_session.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_view_controller.dart';
import 'package:look_atlas/features/calendar/presentation/models/calendar_actions.dart';
import 'package:look_atlas/features/calendar/presentation/screens/calendar_agenda_screen.dart';
import 'package:look_atlas/features/calendar/presentation/screens/calendar_month_screen.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_agenda_row.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_components.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_connection_strip.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_metrics.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_production_progress.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_review_card.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_theme.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_tray_schedule.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CalendarOperatingScreen extends ConsumerWidget {
  const CalendarOperatingScreen({required this.view, super.key});
  final CalendarViewData view;
  CalendarSession get s => view.session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
      calendarControllerProvider.select(
        (state) => (state.overview, state.busy.contains('plan')),
      ),
    );
    final month = ref.watch(
      calendarViewProvider.select((state) => state.month),
    );
    final reviewKey = ref.watch(calendarReviewKeyProvider);
    final scrollController = ref.watch(calendarScrollControllerProvider);
    Future<void> board() async {
      ref.read(calendarViewProvider.notifier).setMonth(value: false);
      await WidgetsBinding.instance.endOfFrame;
      for (var step = 0; step < 8; step++) {
        if (!context.mounted) return;
        if (reviewKey.currentContext case final target? when target.mounted) {
          await Scrollable.ensureVisible(
            target,
            duration: const Duration(milliseconds: 250),
          );
          return;
        }
        if (!scrollController.hasClients) return;
        final position = scrollController.position;
        final next = (position.pixels + position.viewportDimension * .75).clamp(
          0.0,
          position.maxScrollExtent,
        );
        if (next <= position.pixels + 1) return;
        await scrollController.animateTo(
          next,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
        await WidgetsBinding.instance.endOfFrame;
      }
    }

    final o = s.overview!;
    final p = o.plan!;
    final r = o.rollup;
    final items = o.items.where((i) => i.status != 'skipped').toList();
    final ready = o.items.where((i) => i.status == 'ready').toList();
    final needsReview = o.count('needsReview');
    final tray = o.items.where((i) => i.publishAt == null).toList();
    final building = o.count('producing') + o.count('queuedForProduction');
    final now = s.now();
    final end = DateTime.parse('${p.endsOn}T23:59:59');
    final wrapped =
        o.items.isNotEmpty &&
        (end.isBefore(now) ||
            (items.isNotEmpty &&
                o.count('published') > 0 &&
                items.every(
                  (i) => {'published', 'failed'}.contains(i.status),
                )));
    final first =
        needsReview > 0 && o.count('scheduled') + o.count('published') == 0;
    final next = r['nextPublishAt'] == null
        ? null
        : DateTime.parse(r['nextPublishAt'] as String).toLocal();
    final title = wrapped
        ? 'This month is wrapped.'
        : first
        ? 'Your first post is ready, take a look.'
        : needsReview > 0
        ? '$needsReview ${needsReview == 1 ? 'post needs' : 'posts need'} your approval.'
        : building > 0
        ? 'We’re building your month.'
        : 'Your runway is on track.';
    final copy = wrapped
        ? '${o.count('published')} posts published. Keep your runway going, plan the next 30 days.'
        : first
        ? o.drafts
              ? 'One click approves it and it’s yours to download and post. The rest of your month keeps building in the background.'
              : 'One click approves it onto your schedule. The rest of your month keeps building in the background.'
        : needsReview > 0
        ? 'Everything else is on track. A quick look and they’re ready ${o.drafts ? 'to download' : 'for the schedule'}.'
        : building > 0
        ? 'You can leave this page, we’ll email you when posts are ready for your approval.'
        : o.drafts
        ? 'Everything you approved is ready to download and post whenever you like.'
        : next == null
        ? 'Everything produced so far is approved and scheduled.'
        : 'Your next post is scheduled for ${DateFormat('MMM d, HH:mm').format(next)}.';
    return SliverMainAxisGroup(
      slivers: [
        calendarLazySections([
          calendarHeading(
            'Content calendar / ${wrapped
                ? 'Month complete'
                : first
                ? 'First post'
                : needsReview > 0
                ? 'Needs you'
                : building > 0
                ? 'In production'
                : 'On track'}',
            title,
            copy,
            actions: [
              if (wrapped)
                calendarButton(
                  s.busy.contains('plan')
                      ? 'Opening setup…'
                      : 'Plan your next month',
                  s.busy.contains('plan') ? null : s.rollover,
                  primary: true,
                  icon: LucideIcons.arrowRight,
                )
              else if (ready.isNotEmpty)
                calendarButton(
                  'Review $needsReview ${needsReview == 1 ? 'post' : 'posts'}',
                  board,
                  primary: true,
                  icon: LucideIcons.arrowRight,
                ),
              calendarButton(
                'Settings',
                () => view.actions.drawer('automation'),
                icon: LucideIcons.settings2,
              ),
            ],
          ),
          const SizedBox(height: 18),
          CalendarConnectionStrip(s: s),
          if (!wrapped && end.difference(now).inDays <= 7)
            calendarNoteWithAction(
              '${end.difference(now).inDays} runway days left. Stay 30 days ahead.',
              'Plan next 30 days',
              s.busy.contains('plan') ? null : s.rollover,
            ),
          const SizedBox(height: 18),
          calendarKicker('Runway snapshot'),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, c) => Wrap(
              children: [
                calendarMetric(
                  'Needs approval',
                  '${r['needsReview']}',
                  needsReview == 0
                      ? 'All caught up'
                      : 'About $needsReview ${needsReview == 1 ? 'minute' : 'minutes'}',
                  c.maxWidth / 2,
                  onTap: board,
                ),
                calendarMetric(
                  o.drafts ? 'Next planned' : 'Next post',
                  next == null ? 'None' : DateFormat('MMM d').format(next),
                  next == null
                      ? 'Nothing planned yet'
                      : 'planned for ${DateFormat('HH:mm').format(next)}',
                  c.maxWidth / 2,
                ),
                calendarMetric(
                  o.drafts ? 'Approved' : 'Scheduled',
                  '${r['scheduled']}',
                  o.drafts ? 'Ready to download' : 'Publish on their day',
                  c.maxWidth / 2,
                ),
                calendarMetric(
                  'Published',
                  '${r['published']}',
                  'This month',
                  c.maxWidth / 2,
                ),
              ],
            ),
          ),
          if (building > 0) CalendarProductionProgress(s: s),
          if (items.any((i) => i.status == 'failed' || i.status == 'blocked'))
            calendarErrorBanner(
              '${items.where((i) => i.status == 'failed' || i.status == 'blocked').length} posts need attention. ${calendarError(items.firstWhere((i) => i.status == 'failed' || i.status == 'blocked').errorCode)}',
              board,
            ),
          if (ready.isNotEmpty) ...[
            const SizedBox(height: 48),
            Container(
              key: reviewKey,
              child: calendarSection(
                'Needs review',
                '${ready.length} ${ready.length == 1 ? 'post is' : 'posts are'} ready to approve.',
                'Open one for a closer look, or approve it right here.',
              ),
            ),
            for (final i in ready.take(3))
              CalendarReviewCard(view: view, item: i),
          ],
          if (tray.isNotEmpty) ...[
            const SizedBox(height: 27),
            calendarSection(
              'Unscheduled',
              '${tray.length} posts waiting for a day.',
              'Build the concepts you like, then give each one a time.',
            ),
            for (final i in tray) ...[
              CalendarAgendaRow(view: view, item: i),
              if ({'idea', 'approved', 'ready', 'scheduled'}.contains(i.status))
                CalendarTraySchedule(
                  key: ValueKey('tray:${i.id}'),
                  item: i,
                  session: s,
                ),
            ],
          ],
          const SizedBox(height: 48),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: CALENDAR_LINE),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      calendarKicker('Your month'),
                      const SizedBox(height: 7),
                      calendarDisplay(p.title ?? 'The calendar', 34),
                      const SizedBox(height: 7),
                      calendarBody(calendarWindow(p), size: 11),
                    ],
                  ),
                ),
                calendarRule(),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Expanded(
                        child: calendarButton(
                          'Add post',
                          () => view.actions.drawer('add'),
                          compact: true,
                          icon: LucideIcons.plus,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: calendarButton(
                          'Agenda',
                          () => ref
                              .read(calendarViewProvider.notifier)
                              .setMonth(value: false),
                          primary: !month,
                          compact: true,
                          icon: LucideIcons.list,
                        ),
                      ),
                      if (MediaQuery.sizeOf(context).width > 520) ...[
                        const SizedBox(width: 7),
                        Expanded(
                          child: calendarButton(
                            'Month',
                            () => ref
                                .read(calendarViewProvider.notifier)
                                .setMonth(value: true),
                            primary: month,
                            compact: true,
                            icon: LucideIcons.grid3x3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ]),
        if (month)
          CalendarMonthScreen(view: view)
        else
          CalendarAgendaScreen(view: view),
      ],
    );
  }
}
