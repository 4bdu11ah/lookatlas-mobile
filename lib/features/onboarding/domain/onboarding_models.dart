import 'package:flutter/foundation.dart';
import 'package:look_atlas/core/constants/app_assets.dart';

/// Calibration (wizard step 3) is built but switched off for the free trial,
/// mirroring the web app's `CALIBRATION_ENABLED_IN_TRIAL = false`.
const bool calibrationEnabledInTrial = false;

/// Current live free shoot: 5 shots x 3 variations = 15 images.
const int freeShootShotCount = 5;
const int freeShootVariationsPerShot = 3;
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
const wizardAngles = [
  'Front',
  'Back',
  'Side',
  'Top',
  'Bottom',
  'Detail',
  'Inside',
];

/// Max product photos on step 2.
const int maxWizardPhotos = 4;

/// Max user-model photos on step 4.
const int maxModelPhotos = 4;

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
    required this.description,
    required this.story,
    required this.philosophy,
    required this.styleCharacteristics,
    required this.bestFor,
    required this.signature,
    required this.coverImage,
    required this.portfolioImages,
    required this.portfolioDescriptions,
  });

  final String id;
  final String name;
  final String tagline;

  /// Reference brands, rendered as "Like `<brands>`".
  final String brands;
  final String description;
  final String story;
  final String philosophy;
  final List<String> styleCharacteristics;
  final List<String> bestFor;
  final String signature;
  final String coverImage;
  final List<String> portfolioImages;
  final List<String> portfolioDescriptions;

  String get apiId => switch (id) {
    'alex' => 'clean-pro',
    'isabella' => 'luxury-editorial',
    'marcus' => 'bold-dramatic',
    'jordan' => 'street-energy',
    'suki' => 'minimalist',
    'emma' => 'lifestyle-natural',
    'natalie' => 'fine-jewelry',
    'devon' => 'editorial-jewelry',
    'beatrice' => 'heirloom-children',
    _ => 'clean-pro',
  };

  String get imageUrl => coverImage;

  /// A few portfolio shots shown from the eye button.
  List<String> get portfolioUrls => portfolioImages;
}

/// The nine directors from the mockup, in display order.
const directors = [
  Director(
    id: 'alex',
    name: 'Alex Chen',
    tagline: 'Clean Professional',
    brands: 'Uniqlo, Everlane',
    description:
        'Crystal-clear product presentation with neutral backgrounds, even lighting, and conversion-focused framing.',
    story:
        'Alex spent a decade shooting for Uniqlo and Everlane. His data-driven approach makes product photography clear, consistent, and easy to trust.',
    philosophy:
        'The best product photo is one you do not notice. You just see the product clearly, trust it immediately, and click Add to Cart.',
    styleCharacteristics: [
      'Pure white or light grey backgrounds',
      'Even, diffuse studio lighting',
      'Natural, approachable poses',
      'Product-first composition',
      'Perfect color accuracy',
      'Clean, sharp edges',
      'Conversion-optimized framing',
      'Consistent shadows',
    ],
    bestFor: [
      'E-commerce PDP',
      'Marketplace listings',
      'Product catalogs',
      'Size guides',
    ],
    signature: 'The invisible shot',
    coverImage: 'assets/directors/covers/alex.jpeg',
    portfolioImages: [
      'assets/directors/clean-pro/1.jpg',
      'assets/directors/clean-pro/2.jpg',
      'assets/directors/clean-pro/3.jpg',
      'assets/directors/clean-pro/4.jpg',
    ],
    portfolioDescriptions: [
      'Navy Merino Wool Sweater',
      'White Oxford Button-Down',
      'Camel Wool Coat',
      'Black Technical Jacket',
    ],
  ),
  Director(
    id: 'isabella',
    name: 'Isabella Romano',
    tagline: 'Luxury Editorial',
    brands: 'Hermès, Loro Piana',
    description:
        'Quiet luxury meets timeless elegance through soft light, muted tones, and refined atmosphere.',
    story:
        'Isabella grew up between Como and Milan and learned to photograph the light, texture, and heritage behind luxury.',
    philosophy:
        'Luxury whispers. The finest things reveal themselves slowly, in the right light.',
    styleCharacteristics: [
      'Soft, diffused natural light',
      'Muted, sophisticated palette',
      'European architectural settings',
      'Emphasis on material quality',
      'Understated poses',
      'Painterly, film-like quality',
      'Heritage atmosphere',
      'Calm, confident energy',
    ],
    bestFor: [
      'Luxury brands',
      'Heritage fashion',
      'Premium positioning',
      'Seasonal campaigns',
    ],
    signature: 'The inherited memory',
    coverImage: 'assets/directors/covers/isabella.jpeg',
    portfolioImages: [
      'assets/directors/luxury-editorial/1.jpg',
      'assets/directors/luxury-editorial/2.jpg',
      'assets/directors/luxury-editorial/3.jpg',
      'assets/directors/luxury-editorial/4.jpg',
    ],
    portfolioDescriptions: [
      'Cashmere Throw Cardigan',
      'Silk Scarf and Leather Handbag',
      'Navy Cashmere Blazer',
      'Camel Hair Wrap Coat',
    ],
  ),
  Director(
    id: 'marcus',
    name: 'Marcus Vega',
    tagline: 'Bold & Dramatic',
    brands: 'Versace, Balmain',
    description:
        'High-octane fashion with sharp contrast, powerful poses, and cinematic lighting.',
    story:
        'Marcus brings nightclub energy, film noir, and baroque drama to every frame.',
    philosophy:
        'Fashion should make you feel something. Play it safe on your own time.',
    styleCharacteristics: [
      'High contrast chiaroscuro lighting',
      'Powerful, commanding poses',
      'Dynamic angles and geometry',
      'Rich, saturated colors',
      'Deep, dramatic shadows',
      'Cinematic storytelling',
      'Bold architectural elements',
      'Unapologetic glamour',
    ],
    bestFor: [
      'Campaign imagery',
      'Social media heroes',
      'Fashion-forward brands',
      'Statement pieces',
    ],
    signature: 'The power moment',
    coverImage: 'assets/directors/covers/marcus.jpeg',
    portfolioImages: [
      'assets/directors/bold-dramatic/1.jpg',
      'assets/directors/bold-dramatic/2.jpg',
      'assets/directors/bold-dramatic/3.jpg',
      'assets/directors/bold-dramatic/4.jpg',
    ],
    portfolioDescriptions: [
      'Gold Baroque Silk Shirt',
      'Structured Power Blazer',
      'Sequined Evening Gown',
      'Leather Biker Jacket',
    ],
  ),
  Director(
    id: 'jordan',
    name: 'Jordan Kim',
    tagline: 'Street Energy',
    brands: 'Zara, ASOS',
    description:
        'Urban authenticity, candid movement, and effortless cool for social-first brands.',
    story:
        'Jordan documents global youth culture with an instinct for genuine moments in motion.',
    philosophy:
        'Cool cannot be manufactured. My job is to be there when it happens.',
    styleCharacteristics: [
      'Candid, in-motion moments',
      'Urban environments',
      'Natural daylight',
      'Youthful, authentic energy',
      'Social-media-native framing',
      'Effortless cool',
      'Diverse representation',
      'Environmental storytelling',
    ],
    bestFor: [
      'Social media content',
      'Youth-targeted brands',
      'Fast fashion',
      'Streetwear',
    ],
    signature: 'The stolen moment',
    coverImage: 'assets/directors/covers/jordan.jpeg',
    portfolioImages: [
      'assets/directors/street-energy/1.jpg',
      'assets/directors/street-energy/2.jpg',
      'assets/directors/street-energy/3.jpg',
      'assets/directors/street-energy/4.jpg',
    ],
    portfolioDescriptions: [
      'Oversized Graphic Hoodie',
      'Puffer Vest and Fleece',
      'Wide-Leg Cargo Pants',
      'Denim Jacket and Midi Skirt',
    ],
  ),
  Director(
    id: 'suki',
    name: 'Suki Tanaka',
    tagline: 'Minimalist',
    brands: 'COS, Arket',
    description:
        'Architectural precision, abundant negative space, and thoughtful restraint.',
    story:
        'Suki trained in Japanese calligraphy and brings ma, the active presence of negative space, to fashion.',
    philosophy: 'Remove the unnecessary until only truth remains.',
    styleCharacteristics: [
      'Abundant negative space',
      'Geometric compositions',
      'Muted tonal palette',
      'Clean, structured poses',
      'Soft, even lighting',
      'Focus on silhouette',
      'Gallery-worthy framing',
      'Contemplative energy',
    ],
    bestFor: [
      'Minimalist brands',
      'Design-focused products',
      'Premium basics',
      'Art direction',
    ],
    signature: 'The breathing room',
    coverImage: 'assets/directors/covers/suki.jpeg',
    portfolioImages: [
      'assets/directors/minimalist/1.jpg',
      'assets/directors/minimalist/2.jpg',
      'assets/directors/minimalist/3.jpg',
      'assets/directors/minimalist/4.jpg',
    ],
    portfolioDescriptions: [
      'Architectural Wool Coat',
      'Cream Cashmere Turtleneck',
      'Black Structured Dress',
      'Grey Wool Trousers',
    ],
  ),
  Director(
    id: 'emma',
    name: 'Emma Santos',
    tagline: 'Lifestyle Natural',
    brands: 'Reformation, Madewell',
    description:
        'Sun-drenched authenticity and genuine moments that celebrate real life.',
    story:
        'Emma built a visual language around sustainable fashion, golden light, and clothes moving with real bodies.',
    philosophy: 'The best moments are not planned, they are caught.',
    styleCharacteristics: [
      'Golden hour lighting',
      'Warm, earthy tones',
      'Candid, genuine moments',
      'Outdoor natural settings',
      'Relaxed, authentic poses',
      'Lifestyle storytelling',
      'Movement and texture',
      'Aspirational warmth',
    ],
    bestFor: [
      'Lifestyle brands',
      'Sustainable fashion',
      'Casual wear',
      'Social content',
    ],
    signature: 'The golden moment',
    coverImage: 'assets/directors/covers/emma.jpeg',
    portfolioImages: [
      'assets/directors/lifestyle-natural/1.jpg',
      'assets/directors/lifestyle-natural/2.jpg',
      'assets/directors/lifestyle-natural/3.jpg',
      'assets/directors/lifestyle-natural/4.jpg',
    ],
    portfolioDescriptions: [
      'Linen Wrap Dress',
      'Vintage Wash Denim',
      'Floral Maxi Skirt',
      'Chunky Knit Cardigan',
    ],
  ),
  Director(
    id: 'natalie',
    name: 'Natalie Laurent',
    tagline: 'Fine Jewelry',
    brands: 'Tiffany & Co., Cartier',
    description:
        'Precision-crafted jewelry photography with diamond brilliance, macro detail, and on-hand moments.',
    story:
        'Natalie spent fifteen years photographing haute joaillerie and perfected a two-light method that reveals authentic fire.',
    philosophy: 'You do not create sparkle, you reveal it.',
    styleCharacteristics: [
      'Natural diamond brilliance',
      'True macro craftsmanship details',
      'Realistic diamond sparkle',
      'Natural on-hand lifestyle poses',
      'Medium-format tonality',
      'Bright, clean, premium palette',
      'Conversion-optimized framing',
      'Surface and environment realism',
    ],
    bestFor: [
      'Jewelry ecommerce',
      'Engagement rings',
      'Luxury accessories',
      'Product detail pages',
    ],
    signature: 'The revealed brilliance',
    coverImage: 'assets/directors/covers/natalie.jpeg',
    portfolioImages: [
      'assets/directors/fine-jewelry/1.jpg',
      'assets/directors/fine-jewelry/2.jpg',
      'assets/directors/fine-jewelry/3.jpg',
      'assets/directors/fine-jewelry/4.jpg',
    ],
    portfolioDescriptions: [
      'Platinum Solitaire',
      'Oval Halo on Hand',
      'Setting Loupe View',
      'Emerald-Cut Three-Stone',
    ],
  ),
  Director(
    id: 'devon',
    name: 'Devon Cole',
    tagline: 'Editorial Jewelry',
    brands: 'Mejuri, Net-a-Porter',
    description:
        'Modern editorial jewelry with crisp facets, controlled metal shine, and approachable luxury.',
    story:
        'Devon bridges fashion editorial and real-world jewelry through textured stone, available light, and intimate gestures.',
    philosophy:
        'A diamond does not need to dazzle to be desired. It needs to read as real.',
    styleCharacteristics: [
      'Hard architectural sunlight on textured stone',
      'Crisp diamond facet geometry, no glitter',
      'Intimate hand-to-face gestures',
      'Cream and sand textured surfaces',
      'Warm yellow gold',
      'Editorial restraint',
      'Off-camera gaze',
      'Modern editorial polish',
    ],
    bestFor: [
      'Modern fine jewelry brands',
      'DTC engagement and bridal',
      'Editorial jewelry campaigns',
      'Approachable luxury accessories',
    ],
    signature: 'The honest stone',
    coverImage: 'assets/directors/covers/devon.jpeg',
    portfolioImages: [
      'assets/directors/editorial-jewelry/1.jpg',
      'assets/directors/editorial-jewelry/2.jpg',
      'assets/directors/editorial-jewelry/3.jpg',
      'assets/directors/editorial-jewelry/4.jpg',
      'assets/directors/editorial-jewelry/5.jpg',
      'assets/directors/editorial-jewelry/6.jpg',
      'assets/directors/editorial-jewelry/7.jpg',
      'assets/directors/editorial-jewelry/8.jpg',
      'assets/directors/editorial-jewelry/9.jpg',
      'assets/directors/editorial-jewelry/10.jpg',
      'assets/directors/editorial-jewelry/11.jpg',
      'assets/directors/editorial-jewelry/12.jpg',
    ],
    portfolioDescriptions: [
      'Engagement Ring on Cream Concrete',
      'Solitaire on Hand',
      'Eternity Band at the Café',
      'Diamond Drop Earring',
      'Gold Huggie Hoops in Courtyard',
      'Diamond Stud',
      'Solitaire Pendant',
      'Tennis Necklace on Craft Paper',
      'Layered Gold Chains',
      'Diamond Tennis Bracelet at the Café',
      'Gold Bangle Stack on Travertine',
      'Tennis Bracelet on Wrist',
    ],
  ),
  Director(
    id: 'beatrice',
    name: 'Beatrice Hartley',
    tagline: 'Heirloom Childhood',
    brands: 'Bonpoint, Tartine et Chocolat',
    description:
        'Elegant, modest children’s footwear photography with warm light and tender little moments.',
    story:
        'Beatrice photographs children as they really move, composing around legs and feet while preserving the feeling of a family album.',
    philosophy: 'You do not pose a childhood, you wait for it.',
    styleCharacteristics: [
      'Real photography, never an AI render',
      'Modest, age-appropriate styling',
      'Shoes and legs as the hero',
      'Warm natural daylight',
      'Storybook elegance',
      'Faithful leather grain and stitching',
      'Cohesive seasonal world',
      'Tender candid moments',
    ],
    bestFor: [
      'Modest children’s footwear',
      'Family and kidswear catalogs',
      'Children’s apparel',
      'Family lifestyle campaigns',
    ],
    signature: 'The heirloom moment',
    coverImage: 'assets/directors/covers/beatrice.jpeg',
    portfolioImages: [
      'assets/directors/heirloom-children/1.jpg',
      'assets/directors/heirloom-children/2.jpg',
      'assets/directors/heirloom-children/3.jpg',
      'assets/directors/heirloom-children/4.jpg',
    ],
    portfolioDescriptions: [
      'On-Foot Story',
      'Two-Model Moment',
      'Product-Only Print',
      'Detail Close-Up',
    ],
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
