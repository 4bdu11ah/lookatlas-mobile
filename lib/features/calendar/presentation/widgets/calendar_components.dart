import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Widget calendarBody(
  String text, {
  double size = 12,
  Color color = CALENDAR_MUTED,
}) => Text(
  text,
  style: TextStyle(
    fontSize: size,
    height: size == 14 ? 1.58 : 1.5,
    color: color,
  ),
);
Widget calendarDisplay(
  String text,
  double size, {
  Color color = CALENDAR_INK,
  bool italic = false,
}) => Text(
  text,
  style: TextStyle(
    fontFamily: size == 43 || size == 40 ? 'InstrumentSerif' : 'Georgia',
    fontFamilyFallback: const ['serif'],
    fontSize: size,
    height: size == 43 ? .93 : 1,
    letterSpacing: -size * (size == 43 ? .048 : .03),
    fontWeight: FontWeight.w400,
    color: color,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
  ),
);
Widget calendarKicker(String text) => Text(
  text.toUpperCase(),
  style: const TextStyle(
    color: CALENDAR_MUTED,
    fontSize: 11,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.21,
  ),
);
Widget calendarRule() =>
    const Divider(height: 1, thickness: 1, color: CALENDAR_LINE);
Widget calendarButton(
  String text,
  VoidCallback? action, {
  bool primary = false,
  bool compact = false,
  IconData? icon,
  String? label,
}) => Semantics(
  button: true,
  label: label,
  child: TextButton(
    onPressed: action,
    style: TextButton.styleFrom(
      foregroundColor: primary ? Colors.white : CALENDAR_INK,
      backgroundColor: primary ? CALENDAR_INK : Colors.white,
      disabledBackgroundColor: primary ? CALENDAR_LINE : null,
      disabledForegroundColor: const Color(0xff8c8c85),
      minimumSize: Size(0, compact ? 33 : 43),
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 16),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: const RoundedRectangleBorder(),
      side: BorderSide(color: primary ? CALENDAR_INK : CALENDAR_LINE),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null && icon != LucideIcons.arrowRight) ...[
          Icon(icon, size: 15),
          if (text.isNotEmpty) const SizedBox(width: 6),
        ],
        if (text.isNotEmpty)
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        if (icon == LucideIcons.arrowRight) ...[
          const SizedBox(width: 12),
          const Icon(LucideIcons.arrowRight, size: 15),
        ],
      ],
    ),
  ),
);
Widget calendarErrorBanner(String text, [VoidCallback? action]) => Semantics(
  liveRegion: true,
  child: Container(
    margin: const EdgeInsets.only(top: 14),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xfff8ece9),
      border: Border.all(color: const Color(0xffdcb9b2)),
    ),
    child: Row(
      children: [
        Expanded(child: calendarBody(text, color: const Color(0xff8c2f23))),
        if (action != null)
          IconButton(
            onPressed: action,
            tooltip: 'Dismiss or retry',
            icon: const Icon(LucideIcons.rotateCw, size: 16),
          ),
      ],
    ),
  ),
);
Widget calendarNote(String text) => Container(
  margin: const EdgeInsets.symmetric(vertical: 14),
  padding: const EdgeInsets.all(12),
  color: CALENDAR_FIELD,
  child: calendarBody(text),
);
Widget calendarPhoto(String? url, {double? width, double? height}) =>
    CalendarPhoto(url: url, width: width, height: height);

class CalendarPhoto extends StatelessWidget {
  const CalendarPhoto({required this.url, super.key, this.width, this.height});
  final String? url;
  final double? width;
  final double? height;
  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: const Color(0xffecece6),
    );
    if (url == null || url!.isEmpty) return placeholder;
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final pixels =
        ((width?.isFinite == true ? width! : MediaQuery.sizeOf(context).width) *
                ratio)
            .round();
    if (url!.startsWith('assets/')) {
      return Image.asset(
        url!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        cacheWidth: pixels,
      );
    }
    return CachedNetworkImage(
      imageUrl: url!,
      width: width,
      height: height,
      fit: BoxFit.cover,
      memCacheWidth: pixels,
      placeholder: (context, url) => placeholder,
      errorWidget: (context, url, error) => placeholder,
    );
  }
}

Widget calendarHeading(
  String eyebrow,
  String title,
  String copy, {
  List<Widget> actions = const [],
}) => Container(
  margin: const EdgeInsets.only(top: 14),
  padding: const EdgeInsets.fromLTRB(0, 25, 0, 24),
  decoration: const BoxDecoration(
    border: Border(
      top: BorderSide(color: CALENDAR_INK),
      bottom: BorderSide(color: CALENDAR_LINE),
    ),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      calendarKicker(eyebrow),
      const SizedBox(height: 11),
      calendarDisplay(title, 43),
      const SizedBox(height: 17),
      calendarBody(copy, size: 14),
      if (actions.isNotEmpty) ...[
        const SizedBox(height: 24),
        ...actions.map(
          (w) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(width: double.infinity, child: w),
          ),
        ),
      ],
    ],
  ),
);
Widget calendarSection(String kicker, String title, String copy) => Padding(
  padding: const EdgeInsets.only(bottom: 20),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      calendarKicker(kicker),
      const SizedBox(height: 7),
      calendarDisplay(title, 29),
      if (copy.isNotEmpty) ...[const SizedBox(height: 8), calendarBody(copy)],
    ],
  ),
);
Widget calendarStatus(CalendarItem item, {required bool drafts}) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
  decoration: BoxDecoration(
    color: switch (item.status) {
      'ready' => const Color(0xfff5edef),
      'failed' || 'blocked' => const Color(0xfff8ece9),
      'published' || 'scheduled' => const Color(0xffedf1ed),
      _ => CALENDAR_FIELD,
    },
    border: Border.all(color: CALENDAR_LINE),
  ),
  child: Text(
    item.label(drafts: drafts),
    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
  ),
);
Widget calendarPlatformIcons(List<String> values) => Wrap(
  spacing: 4,
  runSpacing: 4,
  children: values
      .map(
        (p) => Tooltip(
          message: calendarPlatforms[p] ?? p,
          child: SvgPicture.asset(
            'assets/images/calendar/$p.svg',
            width: 18,
            height: 18,
            semanticsLabel: calendarPlatforms[p],
          ),
        ),
      )
      .toList(),
);
Widget calendarFieldWidget(
  String label,
  TextEditingController controller, {
  int lines = 1,
  int? limit,
  VoidCallback? blur,
  ValueChanged<String>? onChanged,
  bool enabled = true,
}) => Padding(
  padding: const EdgeInsets.only(top: 21),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      calendarKicker(label),
      const SizedBox(height: 8),
      Focus(
        onFocusChange: (hasFocus) {
          if (!hasFocus) blur?.call();
        },
        child: TextField(
          controller: controller,
          enabled: enabled,
          maxLines: lines,
          maxLength: limit,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
          decoration: const InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 11, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: CALENDAR_LINE),
            ),
          ),
        ),
      ),
    ],
  ),
);
Widget calendarSelect(
  String label,
  String? value,
  Map<String, String> choices,
  ValueChanged<String> change,
) => Padding(
  padding: const EdgeInsets.only(top: 21),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      calendarKicker(label),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        icon: const Icon(LucideIcons.chevronDown, size: 16),
        key: ValueKey('$label:$value'),
        initialValue: choices.containsKey(value) ? value : null,
        isExpanded: true,
        style: const TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: CALENDAR_INK,
        ),
        decoration: const InputDecoration(
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 11, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.zero),
        ),
        items: choices.entries
            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
            .toList(),
        onChanged: (v) {
          if (v != null) change(v);
        },
      ),
    ],
  ),
);
String calendarWhen(CalendarItem i) => i.localTime == null
    ? 'Unscheduled'
    : DateFormat('MMM d, HH:mm').format(i.localTime!);
String calendarWindow(CalendarPlan p) =>
    '${DateFormat('MMM d').format(DateTime.parse(p.startsOn))} – ${DateFormat('MMM d').format(DateTime.parse(p.endsOn))}'
        .toUpperCase();

Widget calendarLazySections(List<Widget> sections) => SliverList.builder(
  itemCount: sections.length,
  itemBuilder: (context, index) => sections[index],
);
String calendarActionLabel(String action, {required bool drafts}) =>
    switch (action) {
      'looks-good' => drafts ? 'Approve' : 'Looks good',
      'back-to-review' => drafts ? 'Un-approve' : 'Take another look',
      'unskip' => 'Bring back',
      'swap' => 'Try another idea',
      'build' => 'Build',
      'retry' => 'Retry',
      'skip' => 'Skip',
      _ => action,
    };
