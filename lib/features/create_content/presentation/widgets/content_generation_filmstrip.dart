import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/create_content/domain/entities/content_models.dart';
import 'package:look_atlas/features/create_content/presentation/widgets/content_widgets.dart';
import 'package:look_atlas/shared/widgets/bar_spinner.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ContentGenerationFilmstrip extends StatelessWidget {
  const ContentGenerationFilmstrip({
    required this.format,
    required this.frames,
    required this.total,
    required this.generating,
    this.backgroundImageUrl,
    this.selectedFrame = 0,
    this.onSelected,
    super.key,
  });

  final ContentFormat format;
  final List<ContentFrame> frames;
  final int total;
  final bool generating;
  final String? backgroundImageUrl;
  final int selectedFrame;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final itemCount = math.max(total, frames.length);
    return Container(
      height: 116,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _heading,
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$itemCount total',
                  style: textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: AppColors.muted,
                  ),
                ),
                const Spacer(),
                Text(
                  generating ? 'Building sequence' : 'Select to review',
                  style: textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 17, color: AppColors.line),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: itemCount,
              separatorBuilder: (_, _) => const SizedBox(width: 7),
              itemBuilder: (context, index) {
                final frame = index < frames.length ? frames[index] : null;
                return _FrameSlot(
                  index: index,
                  frame: frame,
                  label: _label(index, frame, itemCount),
                  selected: !generating && index == selectedFrame,
                  generating: generating,
                  backgroundImageUrl: backgroundImageUrl,
                  onTap: !generating && frame != null && onSelected != null
                      ? () => onSelected!(index)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String get _heading => switch (format) {
    ContentFormat.slideshow => 'Frames',
    ContentFormat.single => 'Variants',
    ContentFormat.video => 'Cover frames',
  };

  String _label(int index, ContentFrame? frame, int count) {
    if (frame != null) return frame.label;
    if (format != ContentFormat.slideshow) return 'Frame';
    const labels = {
      3: ['Hook', 'Product', 'Finish'],
      4: ['Hook', 'Context', 'Detail', 'Finish'],
      5: ['Hook', 'Context', 'Product story', 'Detail', 'Finish'],
      6: ['Hook', 'Context', 'Product story', 'Use', 'Detail', 'Finish'],
      7: [
        'Hook',
        'Context',
        'Product story',
        'Use',
        'Material',
        'Proof',
        'Finish',
      ],
      8: [
        'Hook',
        'Context',
        'Product story',
        'Use',
        'Material',
        'Detail',
        'Proof',
        'Finish',
      ],
    };
    return labels[count]?[index] ?? 'Frame';
  }
}

class _FrameSlot extends StatelessWidget {
  const _FrameSlot({
    required this.index,
    required this.frame,
    required this.label,
    required this.selected,
    required this.generating,
    this.backgroundImageUrl,
    this.onTap,
  });

  final int index;
  final ContentFrame? frame;
  final String label;
  final bool selected;
  final bool generating;
  final String? backgroundImageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      selected: selected,
      button: onTap != null,
      label: 'Frame ${index + 1}: $label',
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 66,
          child: Column(
            children: [
              Container(
                width: 66,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xffe7e7e1),
                  border: Border.all(
                    color: selected ? AppColors.ink : AppColors.line,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (frame?.imageUrl != null)
                      _FrameImage(frame: frame!)
                    else if (backgroundImageUrl != null)
                      Stack(
                        key: ValueKey('content-frame-background-$index'),
                        fit: StackFit.expand,
                        children: [
                          contentImage(backgroundImageUrl),
                          ColoredBox(
                            color: AppColors.ink.withValues(alpha: .42),
                          ),
                          if (generating)
                            const Center(
                              child: BarSpinner(
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      )
                    else
                      ColoredBox(
                        key: ValueKey('content-frame-placeholder-$index'),
                        color: const Color(0xffe7e7e1),
                        child: Center(
                          child: generating
                              ? const BarSpinner(
                                  size: 18,
                                  color: AppColors.muted,
                                )
                              : const Icon(
                                  LucideIcons.image,
                                  size: 16,
                                  color: AppColors.muted,
                                ),
                        ),
                      ),
                    Positioned(
                      left: 4,
                      bottom: 4,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        height: 18,
                        alignment: Alignment.center,
                        color: AppColors.ink.withValues(alpha: .82),
                        child: Text(
                          (index + 1).toString().padLeft(2, '0'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FrameImage extends StatelessWidget {
  const _FrameImage({required this.frame});

  final ContentFrame frame;

  @override
  Widget build(BuildContext context) {
    final crop = frame.crop;
    final scale = (crop?['scale'] as num? ?? 1).toDouble();
    final x = (crop?['x'] as num? ?? 50).toDouble() / 100;
    final y = (crop?['y'] as num? ?? 50).toDouble() / 100;
    return ClipRect(
      child: Transform.scale(
        scale: scale,
        child: contentImage(
          frame.imageUrl,
          alignment: Alignment(x * 2 - 1, y * 2 - 1),
        ),
      ),
    );
  }
}
