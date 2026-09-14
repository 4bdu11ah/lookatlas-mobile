import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_drawer_controller.dart';
import 'package:look_atlas/features/calendar/presentation/models/calendar_drawer_state.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_channels.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_components.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_date_time_field.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_drawer_body.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CalendarIdeaFields extends ConsumerWidget {
  const CalendarIdeaFields({required this.args, super.key});
  final CalendarDrawerArgs args;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calendarDrawerProvider(args));
    final controller = ref.read(calendarDrawerProvider(args).notifier);
    final s = args.view.session;
    final item = state.item;
    final productId = state.productId;
    final format = state.format;
    final platforms = state.platforms;
    final product = s.products.where((p) => p.id == productId).firstOrNull;
    final hook = controller.hook;
    final purpose = controller.purpose;
    final time = controller.time;
    final isEditing = args.type == 'idea';
    return CalendarDrawerBody(
      args: args,
      children: [
        if (isEditing && (item?.previewUrl ?? product?.thumbnail) != null)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              border: Border.all(color: CALENDAR_LINE),
            ),
            child: calendarPhoto(
              item?.previewUrl ?? product?.thumbnail,
              height: 220,
              width: double.infinity,
            ),
          ),
        if (isEditing)
          _CalendarEditSection(
            title: 'Creative direction',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                calendarFieldWidget('Post idea', hook),
                calendarFieldWidget('What this post should do', purpose),
              ],
            ),
          ),
        _CalendarEditSection(
          title: 'Post details',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              calendarSelect('Product', productId, {
                for (final product in s.products) product.id: product.name,
              }, controller.setProduct),
              if (s.productError != null)
                calendarErrorBanner(s.productError!, s.loadProducts),
              calendarSelect('Format', format, {
                for (final entry in calendarFormats.entries)
                  if (entry.key != 'video' ||
                      s.overview!.videoEligible ||
                      format == 'video')
                    entry.key: entry.value,
              }, controller.setFormat),
              CalendarDateTimeField(
                controller: time,
                plan: s.overview!.plan!,
                now: s.now(),
              ),
              const SizedBox(height: 6),
              calendarBody('YYYY-MM-DDTHH:MM · device local time', size: 10),
            ],
          ),
        ),
        if (!isEditing)
          _CalendarEditSection(
            title: 'Creative direction',
            child: calendarFieldWidget('Post idea (optional)', hook),
          ),
        _CalendarEditSection(
          title: 'Channels',
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: calendarChannelChoices(
              platforms,
              controller.togglePlatform,
            ),
          ),
        ),
        _CalendarEditNotice(
          editing: isEditing,
          unlimitedImages: s.overview!.unlimitedImages,
        ),
      ],
    );
  }
}

class _CalendarEditSection extends StatelessWidget {
  const _CalendarEditSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
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
          child: calendarKicker(title),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          child: child,
        ),
      ],
    ),
  );
}

class _CalendarEditNotice extends StatelessWidget {
  const _CalendarEditNotice({
    required this.editing,
    required this.unlimitedImages,
  });

  final bool editing;
  final bool unlimitedImages;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xffedf2ee),
      border: Border.all(color: const Color(0xffcfddd3)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          editing ? LucideIcons.lock : LucideIcons.info,
          size: 16,
          color: const Color(0xff4c725d),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: calendarBody(
            editing
                ? 'Saved changes stay locked when you update the rest of the plan.'
                : 'This joins the production line like every other post${unlimitedImages ? '' : ' and uses credits the same way'}.',
          ),
        ),
      ],
    ),
  );
}
