part of 'director_portfolio_modal.dart';

class _DirectorPortfolioContent {
  const _DirectorPortfolioContent({
    required this.story,
    required this.quote,
    required this.styleCharacteristics,
    required this.bestFor,
    required this.signatureApproach,
    required this.similarBrands,
    required this.captions,
  });

  factory _DirectorPortfolioContent.from(Director director) {
    if (director.id == 'alex') {
      return const _DirectorPortfolioContent(
        story: [
          'Alex spent a decade shooting for efficient e-commerce operations, from Uniqlo studios to Everlane campaigns. What he learned: the best product photography is invisible. It does not distract; it converts.',
          'His philosophy came from studying thousands of A/B tests. The images that sold were not the cleverest, they were the clearest. A perfectly exposed garment on a relaxed model against pure white outsold every creative alternative.',
          'Now Alex brings that data driven precision to every shoot. He is obsessed with perfect color accuracy, consistent shadows, and poses that feel natural while showing every detail.',
        ],
        quote:
            'The best product photo is one you do not notice. You just see the product clearly, trust it immediately, and click Add to Cart.',
        styleCharacteristics: [
          'Pure white backgrounds',
          'Even studio lighting',
          'Natural poses',
          'Product-first composition',
          'Perfect color accuracy',
          'Clean sharp edges',
          'Conversion framing',
          'Consistent shadows',
        ],
        bestFor: [
          'E-commerce PDP',
          'Marketplace listings',
          'Product catalogs',
          'Size guides',
        ],
        signatureApproach:
            'The invisible shot, photography so clean you only see the product',
        similarBrands: 'Uniqlo / Everlane / Gap / COS',
        captions: [
          'Navy Merino Wool Sweater, clean studio lighting',
          'White Oxford Button-Down, conversion-focused presentation',
          'Camel Wool Coat, structure and drape highlighted',
          'Black Technical Jacket, modern essentials with accurate color',
        ],
      );
    }

    final style = director.tagline.toLowerCase();
    final brands = director.brands.split(',').map((brand) => brand.trim());
    return _DirectorPortfolioContent(
      story: [
        '${director.name} builds $style campaigns around the product first. Every shot is planned to make shape, material, scale, and customer intent clear in the first glance.',
        'The direction pulls from ${director.brands}: polished enough for a brand campaign, practical enough for a product page, and consistent enough to run across a full catalog.',
        'Each shoot balances model pose, lighting, and composition so the final images feel intentional without hiding the product details buyers need.',
      ],
      quote:
          'A strong product image should tell the customer what it feels like to own the piece before they read a single word.',
      styleCharacteristics: _styleCharacteristicsFor(director.id),
      bestFor: _bestFor(director.id),
      signatureApproach:
          '${director.tagline} direction with brand-grade polish and product clarity',
      similarBrands: brands.join(' / '),
      captions: [
        '${director.tagline} hero frame with controlled light',
        '${director.tagline} catalog angle focused on fit and material',
        '${director.tagline} detail shot with clear product hierarchy',
        '${director.tagline} campaign variation for social and ads',
      ],
    );
  }

  final List<String> story;
  final String quote;
  final List<String> styleCharacteristics;
  final List<String> bestFor;
  final String signatureApproach;
  final String similarBrands;
  final List<String> captions;

  static List<String> _styleCharacteristicsFor(String id) => switch (id) {
    'isabella' => const [
      'Soft luxury light',
      'Elegant poses',
      'Premium neutrals',
      'Editorial crop',
      'Refined texture',
      'Quiet movement',
    ],
    'marcus' => const [
      'High contrast',
      'Bold shadows',
      'Strong poses',
      'Dramatic angles',
      'Statement framing',
      'Campaign energy',
    ],
    'jordan' => const [
      'Street movement',
      'Outdoor texture',
      'Youthful framing',
      'Relaxed poses',
      'Graphic contrast',
      'Social-first crops',
    ],
    'suki' => const [
      'Minimal sets',
      'Precise spacing',
      'Muted palettes',
      'Quiet poses',
      'Clean geometry',
      'Texture focus',
    ],
    'emma' => const [
      'Natural light',
      'Lifestyle context',
      'Warm skin tones',
      'Soft motion',
      'Everyday styling',
      'Editorial ease',
    ],
    'natalie' => const [
      'Macro detail',
      'Soft sparkle',
      'Precise scale',
      'Elegant hands',
      'Clean reflections',
      'Luxury finish',
    ],
    'devon' => const [
      'Editorial crops',
      'Layered styling',
      'Rich contrast',
      'Close details',
      'Modern styling',
      'Magazine polish',
    ],
    'beatrice' => const [
      'Soft heirloom light',
      'Gentle poses',
      'Textile detail',
      'Warm neutrals',
      'Tender composition',
      'Boutique finish',
    ],
    _ => const [
      'Balanced light',
      'Natural poses',
      'Product clarity',
      'Brand consistency',
      'Campaign polish',
      'Detail focus',
    ],
  };

  static List<String> _bestFor(String id) => switch (id) {
    'natalie' || 'devon' => const [
      'Jewelry drops',
      'Detail pages',
      'Luxury ads',
      'Gift guides',
    ],
    'beatrice' => const [
      'Kidswear',
      'Boutique catalogs',
      'Campaign sets',
      'Lookbooks',
    ],
    'jordan' || 'marcus' => const [
      'Launch campaigns',
      'Social ads',
      'Lookbooks',
      'Streetwear drops',
    ],
    _ => const [
      'E-commerce PDP',
      'Campaign images',
      'Catalog pages',
      'Paid ads',
    ],
  };
}
