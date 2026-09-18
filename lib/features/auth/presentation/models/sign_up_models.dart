import 'package:look_atlas/core/constants/app_assets.dart';

/// One showcase item for the before/after comparison slider.
/// Images can be swapped with custom assets or URLs.
class SignUpShowcaseItem {
  const SignUpShowcaseItem({
    required this.id,
    required this.title,
    required this.beforeImage,
    required this.afterImage,
    required this.thumbnailImage,
  });

  final String id;
  final String title;
  final String beforeImage;
  final String afterImage;
  final String thumbnailImage;
}

/// One customer testimonial card for the bottom carousel.
class SignUpTestimonialItem {
  const SignUpTestimonialItem({
    required this.id,
    required this.quote,
    required this.authorName,
    required this.authorRole,
    required this.authorAvatar,
    required this.showcaseImage,
    this.rating = 5,
  });

  final String id;
  final String quote;
  final String authorName;
  final String authorRole;
  final String authorAvatar;
  final String showcaseImage;
  final int rating;
}

/// Default showcase items matching the design.
/// The user can replace these image paths with final images anytime.
const defaultSignUpShowcases = <SignUpShowcaseItem>[
  SignUpShowcaseItem(
    id: 'bag',
    title: 'Leather Bag',
    beforeImage: AppAssets.showcaseBagBefore,
    afterImage: AppAssets.showcaseBagAfter,
    thumbnailImage: AppAssets.showcaseBagAfter,
  ),
  SignUpShowcaseItem(
    id: 'dress',
    title: 'Editorial Model',
    beforeImage: AppAssets.showcaseDressBefore,
    afterImage: AppAssets.showcaseDressAfter,
    thumbnailImage: AppAssets.showcaseDressAfter,
  ),
  SignUpShowcaseItem(
    id: 'sunglasses',
    title: 'Eyewear / Portrait',
    beforeImage: AppAssets.showcaseTshirtBefore,
    afterImage: AppAssets.showcaseSunglassesAfter,
    thumbnailImage: AppAssets.showcaseSunglassesAfter,
  ),
];

/// Default testimonials matching the design.
const defaultSignUpTestimonials = <SignUpTestimonialItem>[
  SignUpTestimonialItem(
    id: 'alex',
    quote:
        '“We’ve seen a 70% increase in engagement since switching to '
        'AI-generated product photos with LookAtlas”',
    authorName: 'Alex Richard',
    authorRole: 'E-commerce Lead, Velour Clothing',
    authorAvatar: 'assets/directors/covers/alex.jpeg',
    showcaseImage: 'assets/directors/street-energy/1.jpg',
  ),
  SignUpTestimonialItem(
    id: 'marcus',
    quote:
        '“Producing studio-grade campaigns used to take weeks. '
        'With LookAtlas, it takes under 10 minutes.”',
    authorName: 'Marcus Vance',
    authorRole: 'Creative Director, Nookla',
    authorAvatar: 'assets/directors/covers/marcus.jpeg',
    showcaseImage: 'assets/directors/clean-pro/1.jpg',
  ),
];
