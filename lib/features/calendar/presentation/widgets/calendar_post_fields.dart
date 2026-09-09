import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_drawer_controller.dart';
import 'package:look_atlas/features/calendar/presentation/models/calendar_drawer_state.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_components.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_drawer_body.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_theme.dart';

class CalendarPostFields extends ConsumerWidget {
  const CalendarPostFields({required this.args, super.key});
  final CalendarDrawerArgs args;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calendarDrawerProvider(args));
    final controller = ref.read(calendarDrawerProvider(args).notifier);
    final s = args.view.session;
    final item = state.item;
    final time = controller.time;
    final caption = controller.caption;
    final captionLoaded = state.caption.loaded;
    final captionError = state.caption.error;
    final captionSaving = state.caption.saving;
    final captionSaved = state.caption.saved;
    final hashtags = state.caption.hashtags;
    final generation = state.caption.generation;
    final commitTime = controller.commitTime;
    final saveCaption = controller.saveCaption;
    final loadCaption = controller.loadCaption;
    final editCaption = controller.editCaption;

    final i = item!;
    final o = s.overview!;
    final prod = s.products.where((p) => p.id == i.productId).firstOrNull;
    return CalendarDrawerBody(
      args: args,
      children: [
        if ((i.previewUrl ?? prod?.thumbnail) != null)
          calendarPhoto(
            i.previewUrl ?? prod?.thumbnail,
            height: 290,
            width: double.infinity,
          ),
        const SizedBox(height: 14),
        calendarBody(prod?.name ?? 'From your library', size: 11),
        const SizedBox(height: 10),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            calendarBody(calendarFormats[i.format]!, size: 11),
            calendarPlatformIcons(i.platforms),
            calendarStatus(i, drafts: o.drafts),
          ],
        ),
        const SizedBox(height: 24),
        calendarRule(),
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
        _metadata('Channels', '${i.platforms.length} channel versions'),
        if (i.editable) ...[
          calendarFieldWidget(
            'Posting time',
            time,
            blur: () => unawaited(commitTime()),
          ),
          calendarBody('YYYY-MM-DDTHH:MM · device local time', size: 10),
          if (i.generationId != null) ...[
            if (!captionLoaded && captionError == null)
              calendarNote('Loading caption…'),
            if (captionError != null)
              calendarErrorBanner(
                captionError,
                captionLoaded ? () => unawaited(saveCaption()) : loadCaption,
              ),
            if (captionLoaded) ...[
              calendarFieldWidget(
                'Caption',
                caption,
                lines: 4,
                limit: 2200,
                blur: () => unawaited(saveCaption()),
                onChanged: editCaption,
              ),
              calendarButton(
                captionSaving
                    ? 'Saving…'
                    : captionSaved
                    ? 'Saved'
                    : 'Save caption',
                captionSaving || captionSaved
                    ? null
                    : () => unawaited(saveCaption()),
                compact: true,
              ),
              if (hashtags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: hashtags
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
                calendarBody(
                  'Edit hashtags in the editor (Open creative).',
                  size: 11,
                ),
              ],
            ],
          ],
        ],
        if (generation?.data['platform'] != null)
          _metadata('Generated for', '${generation!.data['platform']}'),
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

  Widget _metadata(String label, String value) => Container(
    constraints: const BoxConstraints(minHeight: 49),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: CALENDAR_LINE)),
    ),
    child: Row(
      children: [
        SizedBox(width: 84, child: calendarBody(label, size: 10)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
