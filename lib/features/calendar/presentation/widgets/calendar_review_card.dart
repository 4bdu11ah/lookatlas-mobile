import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_session.dart';
import 'package:look_atlas/features/calendar/presentation/models/calendar_actions.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_components.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CalendarReviewCard extends ConsumerWidget {
  const CalendarReviewCard({required this.view, required this.item, super.key});
  final CalendarViewData view;
  final CalendarItem item;
  CalendarSession get s => view.session;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i = item;
    ref.watch(
      calendarControllerProvider.select(
        (state) => (
          state.busy.contains(i.id),
          state.busy.contains('download:${i.id}'),
        ),
      ),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: CALENDAR_LINE),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              calendarPhoto(
                view.imageFor(i),
                width: double.infinity,
                height: 250,
              ),
              Positioned(
                top: 12,
                left: 12,
                child: calendarStatus(i, drafts: s.overview!.drafts),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                calendarBody(
                  '${calendarWhen(i)} · ${view.productName(i)}'.toUpperCase(),
                  size: 10,
                ),
                const SizedBox(height: 6),
                calendarDisplay(i.hook, 24),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    calendarButton(
                      s.overview!.drafts ? 'Approve' : 'Looks good',
                      s.busy.contains(i.id)
                          ? null
                          : () => s.itemAction(i, 'looks-good'),
                      primary: true,
                      compact: true,
                      icon: LucideIcons.check,
                    ),
                    calendarButton(
                      'Preview',
                      () => view.actions.drawer('post', item: i),
                      compact: true,
                      icon: LucideIcons.arrowRight,
                    ),
                    if (i.generationId != null)
                      calendarButton(
                        'Edit',
                        () => view.actions.editor(i),
                        compact: true,
                      ),
                    if (i.downloadable)
                      calendarButton(
                        '',
                        s.busy.contains('download:${i.id}')
                            ? null
                            : () => view.actions.download(i),
                        compact: true,
                        icon: LucideIcons.download,
                        label: 'Download this post',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
