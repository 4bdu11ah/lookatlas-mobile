import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/shared/widgets/app_outlined_button.dart';
import 'package:look_atlas/shared/widgets/app_text_button.dart';
import 'package:look_atlas/shared/widgets/primary_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SquareSliderThumb extends SliderComponentShape {
  const SquareSliderThumb();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(16, 16);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final color = Color.lerp(
      sliderTheme.disabledThumbColor ?? AppColors.muted,
      sliderTheme.thumbColor ?? AppColors.ink,
      enableAnimation.value,
    )!;
    context.canvas.drawRect(
      Rect.fromCenter(center: center, width: 16, height: 16),
      Paint()..color = color,
    );
    context.canvas.drawRect(
      Rect.fromCenter(center: center, width: 14, height: 14),
      Paint()..color = AppColors.paper,
    );
    context.canvas.drawRect(
      Rect.fromCenter(center: center, width: 10, height: 10),
      Paint()..color = color,
    );
  }
}

Widget contentDisplay(String text, double size) => Builder(
  builder: (context) => Text(
    text,
    style: Theme.of(context).textTheme.displayLarge?.copyWith(
      fontFamily: 'InstrumentSerif',
      fontSize: size,
      height: .98,
      letterSpacing: -size * .035,
      fontWeight: AppTypography.regular,
    ),
  ),
);

Widget contentEyebrow(String text) => Builder(
  builder: (context) => Text(
    text.toUpperCase(),
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      fontSize: 11,
      height: 1.35,
      fontWeight: AppTypography.bold,
      letterSpacing: 1,
      color: const Color(0xff74746d),
    ),
  ),
);

Widget contentBody(String text) => Builder(
  builder: (context) => Text(
    text,
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontSize: 13,
      height: 1.5,
      color: AppColors.muted,
    ),
  ),
);

Widget contentRule() =>
    const Divider(height: 1, thickness: 1, color: AppColors.line);

Widget contentSmallTextButton(
  String text,
  VoidCallback? onTap, {
  Color? color,
  String? label,
}) => Builder(
  builder: (context) => Semantics(
    label: label,
    child: AppTextButton(
      label: text,
      onPressed: onTap,
      fitToContent: true,
      showBorder: false,
      textColor: color ?? AppColors.muted,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      textStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
        fontWeight: AppTypography.bold,
        color: color ?? AppColors.muted,
      ),
    ),
  ),
);

Widget contentAction(
  String text,
  VoidCallback? onTap, {
  bool dark = true,
  IconData? icon,
}) => Builder(
  builder: (context) {
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontSize: 11,
      fontWeight: AppTypography.bold,
      letterSpacing: 0.5,
      color: dark ? Colors.white : AppColors.ink,
    );
    return dark
        ? PrimaryButton(
            onPressed: onTap,
            label: text,
            icon: icon,
            iconAlignment: IconAlignment.end,
            iconSize: 16,
            height: 42,
            backgroundColor: AppColors.ink,
            foregroundColor: Colors.white,
            textStyle: textStyle,
          )
        : AppOutlinedButton(
            onPressed: onTap,
            label: text,
            icon: icon,
            iconAlignment: IconAlignment.end,
            iconSize: 16,
            height: 42,
            borderColor: AppColors.line,
            foregroundColor: AppColors.ink,
            backgroundColor: AppColors.transparent,
            textStyle: textStyle,
          );
  },
);

Widget contentHeaderAction(
  String text,
  IconData icon,
  VoidCallback? onTap,
) => ConstrainedBox(
  constraints: const BoxConstraints(maxWidth: 190),
  child: AppOutlinedButton(
    onPressed: onTap,
    label: text,
    icon: icon,
    iconAlignment: IconAlignment.end,
    iconSize: 16,
    height: 40,
    borderColor: AppColors.line,
    backgroundColor: AppColors.paper,
    foregroundColor: AppColors.ink,
    fitToContent: true,
    textStyle: const TextStyle(
      fontFamily: 'Satoshi',
      fontSize: 12,
      fontWeight: FontWeight.w700,
    ),
  ),
);

Widget contentField(
  String value,
  ValueChanged<String> onChanged, {
  int minLines = 1,
  int maxLines = 1,
  int? lines,
  String? hint,
}) => TextFormField(
  initialValue: value,
  onChanged: onChanged,
  minLines: lines ?? minLines,
  maxLines: lines ?? maxLines,
  style: const TextStyle(
    fontFamily: AppTypography.bodyFontFamily,
    fontSize: 13,
    height: 1.5,
  ),
  decoration: InputDecoration(
    hintText: hint,
    fillColor: Colors.white,
    filled: true,
  ),
);

Widget contentImage(
  String? url, {
  BoxFit fit = BoxFit.cover,
  Alignment alignment = Alignment.center,
}) {
  if (url == null || url.isEmpty) {
    return const ColoredBox(
      color: Color(0xffe3e3dc),
      child: Center(
        child: Icon(LucideIcons.image, size: 20, color: AppColors.muted),
      ),
    );
  }
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    final assetPath = url.startsWith('assets/')
        ? url
        : 'assets/images/create_content/$url';
    return Image.asset(
      assetPath,
      fit: fit,
      alignment: alignment,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: Color(0xffe3e3dc),
        child: Center(
          child: Icon(
            LucideIcons.imageOff,
            color: AppColors.muted,
            size: 20,
          ),
        ),
      ),
    );
  }
  if (debugNetworkImageHttpClientProvider != null) {
    return Image.network(
      url,
      fit: fit,
      alignment: alignment,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: Color(0xffe3e3dc),
        child: Center(
          child: Icon(
            LucideIcons.imageOff,
            color: AppColors.muted,
            size: 20,
          ),
        ),
      ),
    );
  }
  return CachedNetworkImage(
    imageUrl: url,
    fit: fit,
    alignment: alignment,
    width: double.infinity,
    height: double.infinity,
    errorWidget: (_, _, _) => const ColoredBox(
      color: Color(0xffe3e3dc),
      child: Center(
        child: Icon(
          LucideIcons.imageOff,
          color: AppColors.muted,
          size: 20,
        ),
      ),
    ),
  );
}

Widget contentPanelTitle(String label, String title, VoidCallback close) =>
    Builder(
      builder: (context) {
        final textTheme = Theme.of(context).textTheme;
        return Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.only(left: 16, right: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.line)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    contentEyebrow(label),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                  ],
                ),
              ),
              contentSmallTextButton('Done', close, label: 'Close panel'),
            ],
          ),
        );
      },
    );

Widget contentIntro(String label, String title, String body) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    contentEyebrow(label),
    const SizedBox(height: 7),
    contentDisplay(title, 30),
    const SizedBox(height: 10),
    contentBody(body),
  ],
);

Widget contentErrorBox(String message, VoidCallback retry) => Builder(
  builder: (context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xfff7e9e7),
        border: Border.all(color: const Color(0xffd7a49e)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: textTheme.bodySmall?.copyWith(
              color: const Color(0xff7d2720),
            ),
          ),
          const SizedBox(height: 10),
          contentSmallTextButton(
            'Retry',
            retry,
            color: const Color(0xff7d2720),
          ),
        ],
      ),
    );
  },
);

Widget contentChoice(
  String text, {
  required bool selected,
  VoidCallback? onTap,
  String? description,
}) => Builder(
  builder: (context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(11),
          constraints: const BoxConstraints(minHeight: 48),
          decoration: BoxDecoration(
            color: selected ? Colors.white : AppColors.soft,
            border: Border.all(
              color: selected ? AppColors.ink : AppColors.line,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 20,
                height: 20,
                color: AppColors.ink,
                child: selected
                    ? const Icon(
                        LucideIcons.check,
                        color: Colors.white,
                        size: 13,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        description,
                        style: textTheme.bodySmall?.copyWith(
                          height: 1.4,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  },
);

class StudioDots extends CustomPainter {
  const StudioDots();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xffcbc9c2);
    for (var x = 10.0; x < size.width; x += 20) {
      for (var y = 10.0; y < size.height; y += 20) {
        canvas.drawCircle(Offset(x, y), .65, paint);
      }
    }
  }

  @override
  bool shouldRepaint(StudioDots oldDelegate) => false;
}
