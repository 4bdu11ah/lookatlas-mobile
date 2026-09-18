import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/auth/presentation/controllers/sign_up_ui_controller.dart';
import 'package:look_atlas/features/auth/presentation/models/sign_up_models.dart';
import 'package:look_atlas/shared/widgets/app_image.dart';

/// Top hero banner displaying an interactive before/after split slider
/// and product thumbnail switcher.
class SignUpBeforeAfterHeader extends ConsumerWidget {
  const SignUpBeforeAfterHeader({
    super.key,
    this.showcases = defaultSignUpShowcases,
    this.height = 325,
    this.margin = const EdgeInsets.symmetric(horizontal: 6),
  });

  final List<SignUpShowcaseItem> showcases;
  final double? height;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeIndex = ref.watch(signUpShowcaseIndexProvider);
    final sliderPos = ref.watch(signUpSliderPositionProvider);
    final currentItem = showcases[activeIndex.clamp(0, showcases.length - 1)];
    return Container(
      margin: margin,
      height: height,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Left Before Image & Badge (Original)
          Positioned.fill(
            child: ClipRect(
              clipper: _LeftSideClipper(sliderPos),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AppImage(
                      currentItem.beforeImage,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const Positioned(
                    left: 20,
                    top: 20,
                    child: _BadgeTag(label: 'ORIGINAL'),
                  ),
                ],
              ),
            ),
          ),
          // Right After Image & Badge (LookAtlas)
          Positioned.fill(
            child: ClipRect(
              clipper: _RightSideClipper(sliderPos),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AppImage(
                      currentItem.afterImage,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const Positioned(
                    right: 20,
                    top: 20,
                    child: _BadgeTag(label: 'LOOKATLAS'),
                  ),
                ],
              ),
            ),
          ),
          // Interactive Drag Handle Line & Knob
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragUpdate: (details) {
                    final fraction =
                        details.localPosition.dx / constraints.maxWidth;
                    ref
                        .read(signUpSliderPositionProvider.notifier)
                        .updatePosition(fraction);
                  },
                  child: Stack(
                    children: [
                      Positioned(
                        left: constraints.maxWidth * sliderPos - 0.5,
                        top: 0,
                        bottom: 0,
                        width: 1,
                        child: Container(color: AppColors.white),
                      ),
                      Positioned(
                        left: constraints.maxWidth * sliderPos - 14,
                        top: (constraints.maxHeight / 2) - 14,
                        child: const _SliderKnob(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Bottom Thumbnails Strip
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: _ThumbnailBar(
              showcases: showcases,
              activeIndex: activeIndex,
              onSelect: (index) =>
                  ref.read(signUpShowcaseIndexProvider.notifier).select(index),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeftSideClipper extends CustomClipper<Rect> {
  const _LeftSideClipper(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width * fraction, size.height);
  }

  @override
  bool shouldReclip(_LeftSideClipper oldClipper) =>
      oldClipper.fraction != fraction;
}

class _RightSideClipper extends CustomClipper<Rect> {
  const _RightSideClipper(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(size.width * fraction, 0, size.width, size.height);
  }

  @override
  bool shouldReclip(_RightSideClipper oldClipper) =>
      oldClipper.fraction != fraction;
}

class _SliderKnob extends StatelessWidget {
  const _SliderKnob();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.surfaceOffWhite,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chevron_left, size: 12, color: AppColors.darkSurface),
          Icon(Icons.chevron_right, size: 12, color: AppColors.darkSurface),
        ],
      ),
    );
  }
}

class _BadgeTag extends StatelessWidget {
  const _BadgeTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.darkBadge,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style: AppTypography.sfPro(
          color: AppColors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ThumbnailBar extends StatelessWidget {
  const _ThumbnailBar({
    required this.showcases,
    required this.activeIndex,
    required this.onSelect,
  });

  final List<SignUpShowcaseItem> showcases;
  final int activeIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (int i = 0; i < showcases.length; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          GestureDetector(
            onTap: () => onSelect(i),
            child: _ThumbnailTile(
              image: showcases[i].thumbnailImage,
              isSelected: i == activeIndex,
            ),
          ),
        ],
      ],
    );
  }
}

class _ThumbnailTile extends StatelessWidget {
  const _ThumbnailTile({
    required this.image,
    required this.isSelected,
  });

  final String image;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final size = isSelected ? 52.0 : 40.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: isSelected
            ? Border.all(color: AppColors.white, width: 1.2)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: AppImage(
        image,
        fit: BoxFit.cover,
      ),
    );
  }
}
