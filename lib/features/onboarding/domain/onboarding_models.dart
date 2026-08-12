// Director biographies preserve supplied copy without leading whitespace.
// ignore_for_file: leading_newlines_in_multiline_strings

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

  String get apiId => id;

  String get imageUrl => coverImage;

  /// A few portfolio shots shown from the eye button.
  List<String> get portfolioUrls => portfolioImages;
}

/// The nine directors from the mockup, in display order.
const directors = [
  Director(
    id: 'clean-pro',
    name: 'Alex Chen',
    tagline: 'Clean Professional',
    brands: 'Uniqlo, Everlane, Gap, COS',
    description:
        'The industry standard for e-commerce. Crystal-clear product presentation with neutral backgrounds, even lighting, and poses that let the product speak for itself. Perfect for brands prioritizing clarity and conversion.',
    story:
        '''Alex spent a decade shooting for the world's most efficient e-commerce operations, from Uniqlo's Tokyo headquarters to Everlane's San Francisco studio. What he learned: the best product photography is invisible. It doesn't distract; it converts.

His philosophy emerged from studying thousands of A/B tests. The images that sold weren't the cleverest, they were the clearest. A perfectly exposed sweater on a relaxed model against pure white outsold every "creative" alternative.

Now Alex brings that data-driven precision to every shoot. He's obsessed with the details that matter: perfect color accuracy, consistent shadows, poses that feel natural but show every seam. His images don't win photography awards, they win customers.''',
    philosophy:
        '''"The best product photo is one you don't notice. You just see the product clearly, trust it immediately, and click 'Add to Cart.'"''',
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
    signature:
        'The "invisible" shot, photography so clean you only see the product',
    coverImage: 'assets/directors/covers/alex.jpeg',
    portfolioImages: [
      'assets/directors/clean-pro/1.jpg',
      'assets/directors/clean-pro/2.jpg',
      'assets/directors/clean-pro/3.jpg',
      'assets/directors/clean-pro/4.jpg',
    ],
    portfolioDescriptions: [
      'Navy Merino Wool Sweater, classic layering piece showcased with clean studio lighting',
      'White Oxford Button-Down, crisp, conversion-focused product presentation',
      'Camel Wool Coat, investment piece shot to highlight drape and structure',
      'Black Technical Jacket, modern essentials with perfect color accuracy',
    ],
  ),
  Director(
    id: 'luxury-editorial',
    name: 'Isabella Romano',
    tagline: 'Luxury Editorial',
    brands: 'Hermès, Loro Piana, Brunello Cucinelli, The Row',
    description:
        'Quiet luxury meets timeless elegance. Soft, diffused lighting with muted tones creates an atmosphere of refined sophistication. For brands that whisper rather than shout.',
    story:
        '''Isabella grew up between her family's textile workshop in Como and the grand palazzos of Milan. She learned that true luxury isn't about logos, it's about light falling on cashmere, the weight of silk, the patina of leather.

After assisting at Hermès and Loro Piana's in-house studios, she developed her signature approach: images that feel like inherited memories. Her work evokes the quiet confidence of generational wealth, summer afternoons in Tuscan villas, morning light in Parisian apartments, the easy elegance of people who've never had to prove anything.

Isabella's clients come to her when they want images that transcend seasons and trends. She creates photographs that could hang in a gallery or illustrate a family's heritage, timeless, understated, unforgettable.''',
    philosophy:
        '''"Luxury whispers. If you have to explain it, if it has to announce itself, it isn't luxury. The finest things in life reveal themselves slowly, in the right light."''',
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
    signature:
        'The "inherited memory", images that feel like they belong in a family album from generations past',
    coverImage: 'assets/directors/covers/isabella.jpeg',
    portfolioImages: [
      'assets/directors/luxury-editorial/1.jpg',
      'assets/directors/luxury-editorial/2.jpg',
      'assets/directors/luxury-editorial/3.jpg',
      'assets/directors/luxury-editorial/4.jpg',
    ],
    portfolioDescriptions: [
      'Cashmere Throw Cardigan, quiet luxury captured in Tuscan afternoon light',
      'Silk Scarf & Leather Handbag, heritage accessories with painterly quality',
      'Navy Cashmere Blazer, Italian elegance in an Umbrian countryside setting',
      'Camel Hair Wrap Coat, timeless sophistication at dawn in a historic piazza',
    ],
  ),
  Director(
    id: 'bold-dramatic',
    name: 'Marcus Vega',
    tagline: 'Bold & Dramatic',
    brands: 'Versace, Balmain, Saint Laurent, Tom Ford',
    description:
        'High-octane fashion that demands attention. Sharp contrasts, powerful poses, and cinematic lighting create images that stop the scroll. For brands that want to make a statement.',
    story:
        '''Marcus cut his teeth on the nightclub photography circuit in São Paulo before catching the eye of a Balmain creative director at a fashion week afterparty. His raw, unpolished energy was exactly what high fashion needed, someone who wasn't afraid to break the rules.

His work is theatrical, confrontational, and impossible to ignore. He draws inspiration from film noir, baroque painting, and the glamour of Old Hollywood. Every image tells a story of power, seduction, and unapologetic confidence.

Marcus doesn't photograph clothes, he creates moments of high drama. His subjects don't just wear fashion; they wield it like armor. When brands want images that stop thumbs mid-scroll and make hearts race, Marcus is the only call.''',
    philosophy:
        '''"Fashion should make you feel something. If your image doesn't stop someone in their tracks, make them gasp, make them want, what's the point? Play it safe on your own time."''',
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
    signature:
        'The "power moment", images that command attention and demand respect',
    coverImage: 'assets/directors/covers/marcus.jpeg',
    portfolioImages: [
      'assets/directors/bold-dramatic/1.jpg',
      'assets/directors/bold-dramatic/2.jpg',
      'assets/directors/bold-dramatic/3.jpg',
      'assets/directors/bold-dramatic/4.jpg',
    ],
    portfolioDescriptions: [
      'Gold Baroque Silk Shirt, opulent glamour with dramatic chiaroscuro lighting',
      'Structured Power Blazer, high contrast editorial with architectural shadows',
      'Sequined Evening Gown, red carpet drama meets starlight',
      'Leather Biker Jacket, rock & roll rebellion with neon-lit edge',
    ],
  ),
  Director(
    id: 'street-energy',
    name: 'Jordan Kim',
    tagline: 'Street Energy',
    brands: 'Zara, ASOS, Urban Outfitters, H&M',
    description:
        'Urban authenticity meets youthful energy. Candid moments, city backdrops, and an effortless cool that resonates with the social-first generation. Fast fashion meets street culture.',
    story:
        '''Jordan started documenting Seoul's underground fashion scene on a cracked iPhone, posting to a small but devoted following. Their raw, unfiltered approach caught fire, soon Zara and ASOS were sliding into DMs, desperate to capture that authentic street energy.

Growing up between Seoul, New York, and London gave Jordan an intuitive understanding of global youth culture. They don't stage moments; they anticipate them. Their subjects are always in motion, walking, laughing, living. The images feel stolen from someone's best day ever.

Jordan's secret weapon? They still shoot like no one's watching. No artifice, no pretension, just the electric energy of young people who know they look good and couldn't care less about proving it.''',
    philosophy:
        '''"Cool can't be manufactured. It happens when you're not trying, when the light hits right, when someone laughs for real. My job is to be there when it happens."''',
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
    signature:
        '''The "stolen moment", images that feel like the best frame from someone's real life''',
    coverImage: 'assets/directors/covers/jordan.jpeg',
    portfolioImages: [
      'assets/directors/street-energy/1.jpg',
      'assets/directors/street-energy/2.jpg',
      'assets/directors/street-energy/3.jpg',
      'assets/directors/street-energy/4.jpg',
    ],
    portfolioDescriptions: [
      'Oversized Graphic Hoodie, morning coffee run with main character energy',
      'Puffer Vest & Fleece, golden hour city crossing with urban magic',
      'Wide-Leg Cargo Pants, arts district vibes with authentic street style',
      'Denim Jacket & Midi Skirt, weekend brunch energy with genuine joy',
    ],
  ),
  Director(
    id: 'minimalist',
    name: 'Suki Tanaka',
    tagline: 'Minimalist',
    brands: 'COS, Arket, Jil Sander, Lemaire',
    description:
        'Less is more. Architectural precision, abundant negative space, and a monastic attention to form. For brands that believe in the power of restraint and thoughtful design.',
    story:
        '''Suki trained in traditional Japanese calligraphy before pivoting to fashion photography. The discipline stuck: every image is an exercise in ma, the Japanese concept of negative space as active presence, silence as communication.

Her studio in Tokyo is bare except for light. She spends hours arranging nothing, adjusting the emptiness until a single garment becomes the only thing that matters. Clients say working with Suki is meditative; she'll reject twenty "perfect" shots waiting for the one that truly breathes.

Fashion houses from COS to Jil Sander trust Suki when they want images that transcend trends. Her work hangs in galleries alongside contemporary art. She doesn't capture fashion, she distills it to essence.''',
    philosophy:
        '''"In emptiness, everything speaks. Remove the unnecessary until only truth remains. A garment needs nothing but itself and the right light."''',
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
    signature:
        'The "breathing room", images where emptiness becomes the message',
    coverImage: 'assets/directors/covers/suki.jpeg',
    portfolioImages: [
      'assets/directors/minimalist/1.jpg',
      'assets/directors/minimalist/2.jpg',
      'assets/directors/minimalist/3.jpg',
      'assets/directors/minimalist/4.jpg',
    ],
    portfolioDescriptions: [
      'Architectural Wool Coat, masterful use of negative space with gallery-worthy composition',
      'Cream Cashmere Turtleneck, tonal study in restraint and texture',
      'Black Structured Dress, stark elegance with geometric precision',
      'Grey Wool Trousers, the beauty of perfect tailoring in quiet simplicity',
    ],
  ),
  Director(
    id: 'lifestyle-natural',
    name: 'Emma Santos',
    tagline: 'Lifestyle Natural',
    brands: 'Reformation, Madewell, Free People, Sézane',
    description:
        'Sun-drenched authenticity and genuine moments. Warm, inviting imagery that feels like a perfect day with friends. For brands that celebrate real life and sustainable values.',
    story:
        '''Emma's photography career began on a sustainable fashion blog she started in college. What was supposed to document ethical brands became a visual language for an entire generation, golden hour everything, laughter over posed perfection, clothes that move with real bodies.

She spent years living nomadically, shooting in Tulum, Big Sur, the Portuguese coast, chasing perfect light and the moments it illuminates. Her work feels like a perfect weekend that never ends: beach picnics, farmers markets, dancing barefoot at golden hour.

Brands like Reformation and Free People built their visual identity on Emma's influence. She doesn't just photograph clothes, she photographs the life those clothes are made for. Every image is an invitation to live more beautifully.''',
    philosophy:
        '''"The best moments aren't planned, they're caught. When the light is golden, the laugh is real, and the dress is dancing in the wind, that's when magic happens. My job is to be ready."''',
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
    signature: 'The "golden moment", images drenched in warmth and genuine joy',
    coverImage: 'assets/directors/covers/emma.jpeg',
    portfolioImages: [
      'assets/directors/lifestyle-natural/1.jpg',
      'assets/directors/lifestyle-natural/2.jpg',
      'assets/directors/lifestyle-natural/3.jpg',
      'assets/directors/lifestyle-natural/4.jpg',
    ],
    portfolioDescriptions: [
      'Linen Wrap Dress, golden hour at the beach with sun-kissed warmth',
      'Vintage Wash Denim, morning light on a country escape',
      'Floral Maxi Skirt, garden twirl with pure, genuine joy',
      'Chunky Knit Cardigan, coastal sunset with cozy, hygge energy',
    ],
  ),
  Director(
    id: 'fine-jewelry',
    name: 'Natalie Laurent',
    tagline: 'Fine Jewelry',
    brands: 'Tiffany & Co., Cartier, Harry Winston, De Beers',
    description:
        'Precision-crafted luxury jewelry photography. Two-light setups for diamond brilliance, macro craftsmanship details, and on-hand lifestyle moments that sell engagement rings. Built for high-end jewelry ecommerce.',
    story:
        '''Natalie spent fifteen years as head photographer for a Parisian haute joaillerie house before going independent. She learned that photographing jewelry is nothing like photographing fashion, a ring is three grams of metal and stone that must look like a dream worth thousands.

Her breakthrough was the two-light method: one soft light for the scene, one precise accent to wake up the diamonds. That tiny second light is the difference between a dead stone and one that dances with fire. She's obsessive about it, she'll spend an hour adjusting a single specular highlight on a pavé setting.

What sets Natalie apart is her insistence on craftsmanship shots. While other jewelers photograph the diamond face, she gets in close, macro close, to show prong work, setting precision, and metal finishing. "Customers aren't just buying a diamond," she says. "They're buying the ring that holds it."''',
    philosophy:
        '''"A diamond has its own light, you don't create sparkle, you reveal it. One perfect accent light, the right angle, and suddenly a stone worth thousands looks like it's worth millions."''',
    styleCharacteristics: [
      'Natural diamond brilliance',
      'True macro craftsmanship details',
      'Realistic diamond sparkle',
      'Natural on-hand lifestyle poses',
      'Hasselblad medium-format tonality',
      'Bright, clean, premium palette',
      'Conversion-optimized jewelry framing',
      'Surface and environment realism',
    ],
    bestFor: [
      'Jewelry ecommerce',
      'Engagement rings',
      'Luxury accessories',
      'Product detail pages',
    ],
    signature:
        'The "revealed brilliance", natural light that makes diamonds come alive with authentic fire',
    coverImage: 'assets/directors/covers/natalie.jpeg',
    portfolioImages: [
      'assets/directors/fine-jewelry/1.jpg',
      'assets/directors/fine-jewelry/2.jpg',
      'assets/directors/fine-jewelry/3.jpg',
      'assets/directors/fine-jewelry/4.jpg',
    ],
    portfolioDescriptions: [
      'Platinum Solitaire, clean studio product shot with dual-light diamond brilliance',
      'Oval Halo on Hand, aspirational lifestyle moment with natural sparkle and soft gesture',
      'Setting Loupe View, extreme macro showing prong tips, metal grain, and craftsmanship detail',
      'Emerald-Cut Three-Stone, premium presentation with luminous tonality and accent highlights',
    ],
  ),
  Director(
    id: 'editorial-jewelry',
    name: 'Devon Cole',
    tagline: 'Editorial Jewelry',
    brands: 'Mejuri, Net-a-Porter, Aurate, Spinelli Kilcollin',
    description:
        '''Modern editorial jewelry photography in the bridge between Net-a-Porter editorial styling and Mejuri's approachable everyday luxury. Crisp diamond facets and controlled metal shine over exaggerated sparkle. Cream and sand textured stone surfaces, warm yellow gold, intimate gesture-driven moments. Editorial without being unattainable.''',
    story:
        '''Devon Cole came to jewelry photography sideways. After a decade shooting fashion editorial for The Edit and assisting at Net-a-Porter's in-house studio, the move into jewelry came when a creative director hired Devon to reshoot a launch collection that "kept looking like mall jewelry on Pinterest." The solution was simple: stop trying to make diamonds dazzle.

The first reshoot pulled rings out of velvet boxes and onto a piece of cream concrete left over from a construction site, lit by direct afternoon sunlight through a window. The shadow did half the work. Mejuri kept Devon on retainer; Aurate followed; then Spinelli Kilcollin. The signature became visible, hard architectural sun on textured stone, intimate gestures incorporating jewelry as moments not products, an obsession with crisp facet geometry over sparkle effect.

Today Devon shoots between New York and Lisbon, refusing both the heritage-luxury register and the fast-fashion sparkle aesthetic. The work sits in the middle: luxury that feels real, jewelry that reads as something a real person could actually own and wear.''',
    philosophy:
        '''"A diamond doesn't need to dazzle to be desired. It needs to read as real. The eye trusts what looks honest under available light, sparkle is what you fall back on when the photography fails."''',
    styleCharacteristics: [
      'Hard architectural sunlight on textured stone',
      'Crisp diamond facet geometry, no glitter',
      'Intimate hand-to-face and hand-to-hair gestures',
      'Cream and sand textured concrete surfaces',
      'Warm yellow gold metal dominant',
      'Editorial restraint, quiet confidence',
      'Off-camera gaze, slightly serious composure',
      'Modern editorial bridge between Net-a-Porter and Mejuri',
    ],
    bestFor: [
      'Modern fine jewelry brands',
      'DTC engagement and bridal',
      'Editorial jewelry campaigns',
      'Approachable luxury accessories',
    ],
    signature:
        'The "honest stone", diamonds and metals rendered with the optical authenticity of real photography, where brilliance is contrast between bright and dark facets, never added glow',
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
      'Engagement Ring on Cream Concrete, still-life with hard afternoon sunlight casting a long defined shadow',
      'Solitaire on Hand, hand-to-cheek gesture in soft directional daylight',
      'Eternity Band at the Café, mid-range editorial moment with available daylight',
      'Diamond Drop Earring, tight beauty crop on ear and collarbone, profile against oat seamless',
      'Gold Huggie Hoops in Courtyard, editorial environmental wide in Parisian limestone light',
      'Diamond Stud, profile against deep navy, single hard side key, moody portrait',
      'Solitaire Pendant, hand at collarbone in soft directional daylight, intimate gesture',
      'Tennis Necklace on Craft Paper, editorial flat-lay with single dried daisy accent',
      'Layered Gold Chains, profile beauty crop in cream-oat seamless light',
      'Diamond Tennis Bracelet at the Café, captured mid-range moment in hard afternoon sun',
      'Gold Bangle Stack on Travertine, still-life with hard architectural sunlight',
      'Tennis Bracelet on Wrist, beauty studio crop on cream textured concrete',
    ],
  ),
  Director(
    id: 'heirloom-children',
    name: 'Beatrice Hartley',
    tagline: 'Heirloom Childhood',
    brands: 'Bonpoint, Tartine et Chocolat, La Coqueta, Jacadi',
    description:
        '''Elegant, modest children's & family footwear photography in the register of Bonpoint and Tartine et Chocolat, with a British-royal-children sensibility. Warm natural light, real-photography texture, and shoes and legs framed as tender little moments, never stiff catalog product shots. Built for modest kidswear and family brands.''',
    story:
        '''Beatrice Hartley photographed children for the great European children's houses for two decades before going independent, the kind of houses where a christening shoe is an heirloom and a catalog is expected to look like a family's own albums, not a storefront.

She learned early that children's footwear is its own discipline. You cannot direct a six-year-old like a model, and you should not try, the magic is in the moment just before or just after the pose, when a child forgets the camera and simply steps, twirls, or swings their legs off a chair. Beatrice composes for the legs and the feet, lets faces fall away from the frame, and waits for the real gesture. "The shoe is the subject," she says, "but the childhood is the photograph."

Her other obsession is restraint and modesty. Working closely with families who dress their children modestly, she built a way of shooting that is elegant and covered by design, knee-length, soft tights, nothing styled older than the child, and made it look like the most natural thing in the world. The result is warm, storybook, and unmistakably real: a little world you'd want to live inside, photographed as if it already exists.''',
    philosophy:
        '''"You don't pose a childhood, you wait for it. The shoe is the subject, but the moment is the photograph, and it should look like a memory, never a render."''',
    styleCharacteristics: [
      'Real photography, never an AI render',
      'Modest, age-appropriate styling by design',
      'Shoes and legs as the hero; faces minimized',
      'Warm natural daylight, soft real shadows',
      'Storybook British-royal-children elegance',
      'Faithful leather grain, color, and stitching',
      'One cohesive seasonal world, a different corner each shot',
      'Tender candid moments over stiff catalog poses',
    ],
    bestFor: [
      "Modest children's footwear",
      'Family & kidswear catalogs',
      "Children's & family apparel",
      'Family lifestyle campaigns',
    ],
    signature:
        '''The "heirloom moment", children's footwear shot like a warm family memory, modest and real, never AI-perfect''',
    coverImage: 'assets/directors/covers/beatrice.jpeg',
    portfolioImages: [
      'assets/directors/heirloom-children/1.jpg',
      'assets/directors/heirloom-children/2.jpg',
      'assets/directors/heirloom-children/3.jpg',
      'assets/directors/heirloom-children/4.jpg',
    ],
    portfolioDescriptions: [
      'On-Foot Story, a child mid-step in a sunlit autumn home, framed on legs and shoes, face out of frame',
      'Two-Model Moment, two children together, each in a different color of the same style, natural interaction',
      'Product-Only Print, the shoe large in frame on a warm rug, de-branded and print-ready',
      'Detail Close-Up, tight macro on leather grain and stitching, true to the reference',
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
