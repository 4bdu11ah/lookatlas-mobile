import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_drawer_controller.dart';
import 'package:look_atlas/features/calendar/presentation/models/calendar_drawer_state.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_components.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_date_time_field.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_drawer_body.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_theme.dart';
import 'package:look_atlas/shared/widgets/app_text_field.dart';

class CalendarPostFields extends ConsumerWidget {
  const CalendarPostFields({required this.args, super.key});
  final CalendarDrawerArgs args;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawer = ref.watch(
      calendarDrawerProvider(args).select(
        (state) => (item: state.item, generation: state.caption.generation),
      ),
    );
    final controller = ref.read(calendarDrawerProvider(args).notifier);
    final s = args.view.session;

    final i = drawer.item!;
    final o = s.overview!;
    final prod = s.products.where((p) => p.id == i.productId).firstOrNull;
    return CalendarDrawerBody(
      args: args,
      children: [
        if ((i.previewUrl ?? prod?.thumbnail) != null)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              border: Border.all(color: CALENDAR_LINE),
            ),
            child: calendarPhoto(
              i.previewUrl ?? prod?.thumbnail,
              height: 260,
              width: double.infinity,
            ),
          ),
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: CALENDAR_LINE),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              calendarKicker('Post overview'),
              const SizedBox(height: 9),
              Text(
                prod?.name ?? 'From your library',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    color: CALENDAR_FIELD,
                    child: calendarBody(calendarFormats[i.format]!, size: 9),
                  ),
                  calendarPlatformIcons(i.platforms),
                  calendarStatus(i, drafts: o.drafts),
                ],
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: CALENDAR_LINE),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                color: CALENDAR_FIELD,
                child: calendarKicker('Post details'),
              ),
              _metadata(o.drafts ? 'Planned for' : 'Publish', calendarWhen(i)),
              if (i.angle != null) _metadata('Angle', i.angle!),
              _metadata(
                'Review',
                i.status == 'ready'
                    ? 'Waiting for you'
                    : i.status == 'published'
                    ? 'Published'
                    : {'scheduled', 'publishing'}.contains(i.status)
                    ? o.drafts
                          ? 'Approved · download to post'
                          : 'Approved'
                    : i.label(drafts: o.drafts),
              ),
              _metadata(
                'Channels',
                '${i.platforms.length} channel versions',
                last: true,
              ),
            ],
          ),
        ),
        if (i.editable) _PostContentCard(args: args),
        if (drawer.generation?.data['platform'] != null)
          _metadata(
            'Generated for',
            '${drawer.generation!.data['platform']}',
          ),
        for (final result in i.publishedResults)
          if (result['permalink'] is String &&
              (result['permalink'] as String).isNotEmpty)
            calendarButton(
              'View on ${calendarPlatforms[result['platform']]}',
              () => controller.openPublished(result['permalink'] as String),
            )
          else
            calendarErrorBanner(
              'Didn’t reach ${calendarPlatforms[result['platform']]}',
            ),
      ],
    );
  }

  Widget _metadata(String label, String value, {bool last = false}) =>
      Container(
        constraints: const BoxConstraints(minHeight: 49),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: CALENDAR_LINE)),
        ),
        child: Row(
          children: [
            SizedBox(width: 84, child: calendarBody(label, size: 10)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
}

class _PostContentCard extends ConsumerWidget {
  const _PostContentCard({required this.args});

  final CalendarDrawerArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calendarDrawerProvider(args));
    final controller = ref.read(calendarDrawerProvider(args).notifier);
    final captionState = state.caption;
    final session = args.view.session;
    return Container(
      margin: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: CALENDAR_LINE),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: CALENDAR_FIELD,
              border: Border(bottom: BorderSide(color: CALENDAR_LINE)),
            ),
            child: calendarKicker('Edit post'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CalendarDateTimeField(
                  controller: controller.time,
                  plan: session.overview!.plan!,
                  now: session.now(),
                  label: 'Posting time',
                  onBlur: () => unawaited(controller.commitTime()),
                  onPicked: () => unawaited(controller.commitTime()),
                ),
                const SizedBox(height: 6),
                calendarBody('YYYY-MM-DDTHH:MM · device local time', size: 10),
                if (state.item!.generationId != null) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Divider(height: 1, color: CALENDAR_LINE),
                  ),
                  if (!captionState.loaded && captionState.error == null)
                    calendarNote('Loading caption…'),
                  if (captionState.error != null)
                    calendarErrorBanner(
                      captionState.error!,
                      captionState.loaded
                          ? () => unawaited(controller.saveCaption())
                          : controller.loadCaption,
                    ),
                  if (captionState.loaded) ...[
                    calendarKicker('Caption'),
                    const SizedBox(height: 8),
                    Focus(
                      onFocusChange: (hasFocus) {
                        if (!hasFocus) unawaited(controller.saveCaption());
                      },
                      child: AppTextField(
                        controller: controller.caption,
                        minLines: 5,
                        maxLines: 8,
                        maxLength: 2200,
                        onChanged: controller.editCaption,
                        textStyle: const TextStyle(fontSize: 15, height: 1.5),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: calendarButton(
                        captionState.saving
                            ? 'Saving…'
                            : captionState.saved
                            ? 'Saved'
                            : 'Save caption',
                        captionState.saving || captionState.saved
                            ? null
                            : () => unawaited(controller.saveCaption()),
                        compact: true,
                      ),
                    ),
                    if (captionState.hashtags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: captionState.hashtags
                            .map(
                              (tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 4,
                                ),
                                color: CALENDAR_FIELD,
                                child: calendarBody(
                                  '#${tag.replaceFirst(RegExp('^#'), '')}',
                                  size: 11,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      calendarBody(
                        'Edit hashtags in Open creative.',
                        size: 11,
                      ),
                    ],
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
