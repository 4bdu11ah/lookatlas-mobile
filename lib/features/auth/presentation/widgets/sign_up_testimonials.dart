import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/auth/presentation/models/sign_up_models.dart';
import 'package:look_atlas/shared/widgets/app_image.dart';

/// Horizontal scrollable testimonial cards at the bottom of the sign up screen.
class SignUpTestimonials extends StatelessWidget {
  const SignUpTestimonials({
    super.key,
    this.testimonials = defaultSignUpTestimonials,
    this.padding = const EdgeInsets.all(6),
    this.isColumn = false,
  });

  final List<SignUpTestimonialItem> testimonials;
  final EdgeInsetsGeometry padding;
  final bool isColumn;

  @override
  Widget build(BuildContext context) {
    if (isColumn) {
      return Container(
        color: AppColors.darkSurface,
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < testimonials.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _TestimonialCard(
                item: testimonials[i],
                isExpanded: true,
              ),
            ],
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = padding.horizontal;
        final availableWidth = constraints.maxWidth - horizontalPadding;
        final cardWidth = availableWidth.isFinite && availableWidth > 0
            ? availableWidth
            : (MediaQuery.sizeOf(context).width - horizontalPadding);
        final cardHeight = (cardWidth * 0.50).clamp(180.0, 205.0);
        final photoWidth = (cardWidth * 0.40).clamp(130.0, 165.0);

        return Container(
          color: AppColors.darkSurface,
          padding: padding,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < testimonials.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  _TestimonialCard(
                    item: testimonials[i],
                    width: cardWidth,
                    height: cardHeight,
                    photoWidth: photoWidth,
                    isExpanded: true,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({
    required this.item,
    this.width,
    this.height = 185,
    this.photoWidth,
    this.isExpanded = false,
  });

  final SignUpTestimonialItem item;
  final double? width;
  final double height;
  final double? photoWidth;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final effectivePhotoWidth = photoWidth ?? 185.0;
    final feedbackContent = Container(
      width: isExpanded ? null : 245,
      height: height,
      color: AppColors.darkCard,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Star rating
          Row(
            children: List.generate(
              item.rating,
              (_) => const Padding(
                padding: EdgeInsets.only(right: 3),
                child: Icon(
                  Icons.star,
                  size: 11,
                  color: AppColors.starGold,
                ),
              ),
            ),
          ),
          // Quote text
          Text(
            item.quote,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.sfPro(
              fontSize: 12,
              height: 1.35,
              color: AppColors.textPlaceholder,
            ),
          ),
          // Author info
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: AppImage(
                  item.authorAvatar,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.sfPro(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.authorRole,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.sfPro(
                        fontSize: 10,
                        height: 1.25,
                        color: AppColors.textPlaceholder,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: width,
        height: height,
        child: Row(
          mainAxisSize: (width != null || isExpanded)
              ? MainAxisSize.max
              : MainAxisSize.min,
          children: [
            // Left photo
            SizedBox(
              width: effectivePhotoWidth,
              height: height,
              child: AppImage(
                item.showcaseImage,
                fit: BoxFit.cover,
              ),
            ),
            // Right feedback card
            if (isExpanded)
              Expanded(child: feedbackContent)
            else
              feedbackContent,
          ],
        ),
      ),
    );
  }
}
