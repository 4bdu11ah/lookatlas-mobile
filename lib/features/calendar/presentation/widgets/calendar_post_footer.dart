import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_drawer_controller.dart';
import 'package:look_atlas/features/calendar/presentation/models/calendar_drawer_state.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_components.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CalendarPostFooter extends ConsumerWidget {
  const CalendarPostFooter({required this.args, super.key});
  final CalendarDrawerArgs args;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calendarDrawerProvider(args));
    final controller = ref.read(calendarDrawerProvider(args).notifier);
    final s = args.view.session;
    final item = state.item;
    final saving = state.saving;
    final captionSaving = state.caption.saving;
    final commitTime = controller.commitTime;
    final saveCaption = controller.saveCaption;
    final action = controller.action;

    final i = item!;
    final reviewActions = [
      for (final value in i.actions)
        calendarButton(
          calendarActionLabel(value, drafts: s.overview!.drafts),
          saving || captionSaving || s.busy.contains(i.id)
              ? null
              : () => action(value),
          primary: value == 'looks-good' || value == 'build',
          compact: true,
        ),
    ];
    final creativeActions = [
      if (i.downloadable)
        calendarButton(
          s.busy.contains('download:${i.id}') ? 'Preparing…' : 'Download',
          saving || captionSaving || s.busy.contains('download:${i.id}')
              ? null
              : () async {
                  if (await commitTime() && await saveCaption()) {
                    await args.view.actions.download(i);
                  }
                },
          compact: true,
          icon: LucideIcons.download,
        ),
      if (i.generationId != null)
        calendarButton(
          'Open creative',
          saving || captionSaving
              ? null
              : () async {
                  if (!await commitTime() ||
                      !await saveCaption() ||
                      !context.mounted) {
                    return;
                  }
                  Navigator.of(context).pop();
                  await args.view.actions.editor(i);
                },
          primary: true,
          compact: true,
          icon: LucideIcons.arrowRight,
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (reviewActions.isNotEmpty) _CalendarPostButtonRow(reviewActions),
        if (reviewActions.isNotEmpty && creativeActions.isNotEmpty)
          const SizedBox(height: 6),
        if (creativeActions.isNotEmpty)
          _CalendarPostButtonRow(creativeActions)
        else if (i.generationId == null)
          calendarBody('This post hasn’t been created yet.'),
      ],
    );
  }
}

class _CalendarPostButtonRow extends StatelessWidget {
  const _CalendarPostButtonRow(this.buttons);

  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var index = 0; index < buttons.length; index++) ...[
        if (index > 0) const SizedBox(width: 6),
        Expanded(child: buttons[index]),
      ],
    ],
  );
}
