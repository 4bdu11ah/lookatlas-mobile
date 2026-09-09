import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_drawer_controller.dart';
import 'package:look_atlas/features/calendar/presentation/models/calendar_drawer_state.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_channels.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_components.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_drawer_body.dart';

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
    return CalendarDrawerBody(
      args: args,
      children: [
        if (args.type == 'idea' &&
            (item?.previewUrl ?? product?.thumbnail) != null)
          calendarPhoto(
            item?.previewUrl ?? product?.thumbnail,
            height: 290,
            width: double.infinity,
          ),
        if (args.type == 'idea') calendarFieldWidget('Post idea', hook),
        calendarSelect('Product', productId, {
          for (final p in s.products) p.id: p.name,
        }, controller.setProduct),
        if (s.productError != null)
          calendarErrorBanner(s.productError!, s.loadProducts),
        calendarSelect('Format', format, {
          for (final e in calendarFormats.entries)
            if (e.key != 'video' ||
                s.overview!.videoEligible ||
                format == 'video')
              e.key: e.value,
        }, controller.setFormat),
        if (args.type == 'idea')
          calendarFieldWidget('What this post should do', purpose),
        calendarFieldWidget('When it posts', time),
        calendarBody('YYYY-MM-DDTHH:MM · device local time', size: 10),
        if (args.type == 'add')
          calendarFieldWidget('Post idea (optional)', hook),
        const SizedBox(height: 21),
        calendarKicker('Channels'),
        const SizedBox(height: 8),
        calendarChannelChoices(
          platforms,
          controller.togglePlatform,
        ),
        calendarNote(
          args.type == 'idea'
              ? 'Your changes are locked in, “Update my plan” won’t touch this idea.'
              : 'It joins the production line like every other post${s.overview!.unlimitedImages ? '' : ' and uses credits the same way'}.',
        ),
      ],
    );
  }
}
