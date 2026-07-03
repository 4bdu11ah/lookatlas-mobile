import 'package:flutter/foundation.dart';
import 'package:look_atlas/core/constants/app_assets.dart';

/// Calibration (wizard step 3) is built but switched off for the free trial,
/// mirroring the web app's `CALIBRATION_ENABLED_IN_TRIAL = false`.
const bool calibrationEnabledInTrial = false;

/// Shots x variations of the free shoot: 3 shots x 5 variations = 15 images.
const int freeShootShotCount = 3;
const int freeShootVariationsPerShot = 5;
const int freeShootImageCount = freeShootShotCount * freeShootVariationsPerShot;

/// The six wizard steps, in flow order. [WizardStep.calibrate] only appears
/// for calibratable categories and is currently feature-flagged off.
enum WizardStep { intro, product, calibrate, model, director, review }

/// Sub-state of the product step: pick a category first, then upload photos.
enum ProductPhase { category, upload }

/// Product categories offered on step 2 (11 total, "Other" spans two columns).
enum ProductCategory {
  tops('Tops'),
  dresses('Dresses'),
  outerwear('Outerwear'),
  bottoms('Bottoms'),
  bags('Bags'),
  shoes('Shoes'),
  jewelry('Jewelry'),
  eyewear('Eyewear'),
  watches('Watches'),
  accessories('Accessories'),
  other('Other');

  const ProductCategory(this.label);

  final String label;

  /// Categories that benefit from proportion calibration (step 3).
  bool get isCalibratable =>
      this == ProductCategory.jewelry ||
      this == ProductCategory.bags ||
      this == ProductCategory.accessories;

  /// Bundled image for the category picker tile (the category's front/hero
  /// angle example).
  String get imageUrl => switch (this) {
    ProductCategory.tops => AppAssets.anglesTopsFront,
    ProductCategory.dresses => AppAssets.anglesDressesFront,
    ProductCategory.outerwear => AppAssets.anglesOuterwearFront,
    ProductCategory.bottoms => AppAssets.anglesBottomsFront,
    ProductCategory.bags => AppAssets.anglesBagsFront,
    ProductCategory.shoes => AppAssets.anglesShoesFront,
    ProductCategory.jewelry => AppAssets.anglesJewelryCloseup1,
    ProductCategory.eyewear => AppAssets.anglesEyewearFront,
    ProductCategory.watches => AppAssets.anglesWatchesFace,
    ProductCategory.accessories => AppAssets.anglesAccessoriesFront,
    ProductCategory.other => AppAssets.angleExampleFront,
  };

  /// The sides worth capturing for this category, as (label, image) pairs
  /// shown by the upload step's angle guidance.
  List<(String, String)> get angleGuides => switch (this) {
    ProductCategory.tops => const [
      ('Front', AppAssets.anglesTopsFront),
      ('Back', AppAssets.anglesTopsBack),
    ],
    ProductCategory.dresses => const [
      ('Front', AppAssets.anglesDressesFront),
      ('Back', AppAssets.anglesDressesBack),
      ('Detail', AppAssets.anglesDressesDetail),
    ],
    ProductCategory.outerwear => const [
      ('Front', AppAssets.anglesOuterwearFront),
      ('Back', AppAssets.anglesOuterwearBack),
      ('Side', AppAssets.anglesOuterwearSide),
    ],
    ProductCategory.bottoms => const [
      ('Front', AppAssets.anglesBottomsFront),
      ('Back', AppAssets.anglesBottomsBack),
    ],
    ProductCategory.bags => const [
      ('Front', AppAssets.anglesBagsFront),
      ('Side', AppAssets.anglesBagsSide),
      ('Detail', AppAssets.anglesBagsDetail),
    ],
    ProductCategory.shoes => const [
      ('Front', AppAssets.anglesShoesFront),
      ('Side', AppAssets.anglesShoesSide),
      ('Top', AppAssets.anglesShoesTop),
    ],
    ProductCategory.jewelry => const [
      ('Close-up', AppAssets.anglesJewelryCloseup1),
      ('Detail', AppAssets.anglesJewelryCloseup2),
    ],
    ProductCategory.eyewear => const [
      ('Front', AppAssets.anglesEyewearFront),
      ('Side', AppAssets.anglesEyewearSide),
    ],
    ProductCategory.watches => const [
      ('Face', AppAssets.anglesWatchesFace),
      ('Side', AppAssets.anglesWatchesSide),
    ],
    ProductCategory.accessories => const [
      ('Front', AppAssets.anglesAccessoriesFront),
      ('Detail', AppAssets.anglesAccessoriesDetail),
    ],
    ProductCategory.other => const [
      ('Front', AppAssets.angleExampleFront),
      ('Back', AppAssets.angleExampleBack),
    ],
  };
}

/// Jewelry sub-types shown by the calibration step.
const jewelrySubtypes = ['Necklace', 'Ring', 'Earrings', 'Bracelet'];

/// Bag sub-types shown by the calibration step.
const bagSubtypes = ['Handbag', 'Crossbody', 'Tote', 'Backpack'];

/// Angles a product photo can be tagged with on step 2.
const wizardAngles = ['Front', 'Back', 'Side', 'Detail'];

/// Max product photos on step 2 and model photos on step 4.
const int maxWizardPhotos = 4;

/// One product photo added in the wizard, plus the angle the user tagged it
/// with (null until they pick one).
@immutable
class WizardPhoto {
  const WizardPhoto({required this.bytes, this.angle});

  final Uint8List bytes;
  final String? angle;

  WizardPhoto copyWith({String? angle}) =>
      WizardPhoto(bytes: bytes, angle: angle ?? this.angle);
}

/// Gender filter for the model library on step 4.
enum ModelGender { all, women, men }


/// A creative director / photo style (step 5).
@immutable
class Director {
  const Director({
    required this.id,
    required this.name,
    required this.tagline,
    required this.brands,
  });

  final String id;
  final String name;
  final String tagline;

  /// Reference brands, rendered as "Like `<brands>`".
  final String brands;

  String get imageUrl => 'https://picsum.photos/seed/la-dir-$id/600/800';

  /// A few portfolio shots shown from the eye button.
  List<String> get portfolioUrls => [
    for (var i = 1; i <= 4; i++)
      'https://picsum.photos/seed/la-dir-$id-p$i/600/800',
  ];
}

/// The nine directors from the mockup, in display order.
const directors = [
  Director(
    id: 'alex',
    name: 'Alex Chen',
    tagline: 'Clean Professional',
    brands: 'Uniqlo, Everlane',
  ),
  Director(
    id: 'isabella',
    name: 'Isabella Romano',
    tagline: 'Luxury Editorial',
    brands: 'Hermès, Loro Piana',
  ),
  Director(
    id: 'marcus',
    name: 'Marcus Vega',
    tagline: 'Bold & Dramatic',
    brands: 'Versace, Balmain',
  ),
  Director(
    id: 'jordan',
    name: 'Jordan Kim',
    tagline: 'Street Energy',
    brands: 'Zara, ASOS',
  ),
  Director(
    id: 'suki',
    name: 'Suki Tanaka',
    tagline: 'Minimalist',
    brands: 'COS, Arket',
  ),
  Director(
    id: 'emma',
    name: 'Emma Santos',
    tagline: 'Lifestyle Natural',
    brands: 'Reformation, Madewell',
  ),
  Director(
    id: 'natalie',
    name: 'Natalie Laurent',
    tagline: 'Fine Jewelry',
    brands: 'Tiffany & Co., Cartier',
  ),
  Director(
    id: 'devon',
    name: 'Devon Cole',
    tagline: 'Editorial Jewelry',
    brands: 'Mejuri, Net-a-Porter',
  ),
  Director(
    id: 'beatrice',
    name: 'Beatrice Hartley',
    tagline: 'Heirloom Childhood',
    brands: 'Bonpoint, Tartine et Chocolat',
  ),
];

/// One before/after pair in the intro showcase (rotates every 3 seconds).
/// [id] matches the bundled `showcase-<id>-{before,after}.jpg` file pair.
@immutable
class ShowcaseItem {
  const ShowcaseItem({required this.id, required this.name});

  final String id;
  final String name;

  String get beforeUrl => AppAssets.showcaseBefore(id);
  String get afterUrl => AppAssets.showcaseAfter(id);
}

/// The six showcase products from the mockup.
const showcaseItems = [
  ShowcaseItem(id: 'dress', name: 'Emerald Dress'),
  ShowcaseItem(id: 'tshirt', name: 'Black Tee'),
  ShowcaseItem(id: 'bag', name: 'Leather Bag'),
  ShowcaseItem(id: 'necklace', name: 'Gold Necklace'),
  ShowcaseItem(id: 'sunglasses', name: 'Sunglasses'),
  ShowcaseItem(id: 'shoes', name: 'White Sneakers'),
];
