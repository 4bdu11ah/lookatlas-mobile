import 'package:flutter/foundation.dart';

@immutable
class ShootCatalogItem {
  const ShootCatalogItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.subtitle = '',
    this.source,
    this.category,
    this.subCategory,
    this.isCalibrated = false,
  });

  final String id;
  final String name;
  final String imageUrl;
  final String subtitle;
  final String? source;
  final String? category;
  final String? subCategory;
  final bool isCalibrated;

  ShootCatalogItem copyWith({bool? isCalibrated}) => ShootCatalogItem(
    id: id,
    name: name,
    imageUrl: imageUrl,
    subtitle: subtitle,
    source: source,
    category: category,
    subCategory: subCategory,
    isCalibrated: isCalibrated ?? this.isCalibrated,
  );
}

enum ProductMode { pairing, variant }

enum ShootLane { fast, relax }

@immutable
class DemoDirectorConfig {
  const DemoDirectorConfig({this.numberOfShots = 5, this.variations = 2});

  final int numberOfShots;
  final int variations;

  DemoDirectorConfig copyWith({int? numberOfShots, int? variations}) =>
      DemoDirectorConfig(
        numberOfShots: numberOfShots ?? this.numberOfShots,
        variations: variations ?? this.variations,
      );
}

@immutable
class ShootAppConfig {
  const ShootAppConfig({
    this.supportedAspectRatios = const [
      '4:5',
      '3:4',
      '1:1',
      '4:3',
      '16:9',
      '9:16',
    ],
    this.defaultAspectRatio = '4:5',
    this.relaxEnabled = false,
  });

  final List<String> supportedAspectRatios;
  final String defaultAspectRatio;
  final bool relaxEnabled;
}

@immutable
class ShootSubscription {
  const ShootSubscription({this.plan = '', this.status = ''});

  final String plan;
  final String status;

  bool isUnlimitedEligible({required bool relaxEnabled}) =>
      relaxEnabled &&
      const {'pro', 'enterprise'}.contains(plan) &&
      const {'active', 'trialing'}.contains(status);
}

@immutable
class ShootLook {
  const ShootLook({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.settings,
    this.subtitle = '',
    this.portfolioImages = const [],
  });

  final String id;
  final String name;
  final String imageUrl;
  final String subtitle;
  final Map<String, dynamic> settings;
  final List<String> portfolioImages;
}

const defaultShootDirectors = [
  ShootLook(
    id: 'clean-pro',
    name: 'Alex Chen',
    subtitle: 'Clean Professional',
    imageUrl: 'assets/directors/covers/alex.jpeg',
    settings: {},
    portfolioImages: [
      'assets/directors/clean-pro/1.jpg',
      'assets/directors/clean-pro/2.jpg',
      'assets/directors/clean-pro/3.jpg',
      'assets/directors/clean-pro/4.jpg',
    ],
  ),
  ShootLook(
    id: 'luxury-editorial',
    name: 'Isabella Romano',
    subtitle: 'Luxury Editorial',
    imageUrl: 'assets/directors/covers/isabella.jpeg',
    settings: {},
  ),
  ShootLook(
    id: 'bold-dramatic',
    name: 'Marcus Vega',
    subtitle: 'Bold & Dramatic',
    imageUrl: 'assets/directors/covers/marcus.jpeg',
    settings: {},
  ),
  ShootLook(
    id: 'street-energy',
    name: 'Jordan Kim',
    subtitle: 'Street Energy',
    imageUrl: 'assets/directors/covers/jordan.jpeg',
    settings: {},
  ),
  ShootLook(
    id: 'minimalist',
    name: 'Suki Tanaka',
    subtitle: 'Minimalist',
    imageUrl: 'assets/directors/covers/suki.jpeg',
    settings: {},
  ),
  ShootLook(
    id: 'lifestyle-natural',
    name: 'Emma Santos',
    subtitle: 'Lifestyle Natural',
    imageUrl: 'assets/directors/covers/emma.jpeg',
    settings: {},
  ),
  ShootLook(
    id: 'fine-jewelry',
    name: 'Natalie Laurent',
    subtitle: 'Fine Jewelry',
    imageUrl: 'assets/directors/covers/natalie.jpeg',
    settings: {},
  ),
  ShootLook(
    id: 'editorial-jewelry',
    name: 'Devon Cole',
    subtitle: 'Editorial Jewelry',
    imageUrl: 'assets/directors/covers/devon.jpeg',
    settings: {},
  ),
  ShootLook(
    id: 'heirloom-children',
    name: 'Beatrice Hartley',
    subtitle: 'Heirloom Childhood',
    imageUrl: 'assets/directors/covers/beatrice.jpeg',
    settings: {},
  ),
];

@immutable
class ShootPreset {
  const ShootPreset({
    required this.id,
    required this.name,
    required this.settings,
    this.heroImageUrl,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final Map<String, dynamic> settings;
  final String? heroImageUrl;
  final bool isDefault;
}

@immutable
class ShootCreateCatalog {
  const ShootCreateCatalog({
    required this.products,
    required this.userModels,
    required this.libraryModels,
    required this.looks,
    required this.lookFilters,
    required this.presets,
    required this.availableCredits,
    this.supportedAspectRatios = const ['4:5', '3:4', '1:1', '4:3'],
    this.defaultAspectRatio = '4:5',
    this.relaxEnabled = false,
    this.plan = '',
    this.isUnlimitedEligible = false,
  });

  final List<ShootCatalogItem> products;
  final List<ShootCatalogItem> userModels;
  final List<ShootCatalogItem> libraryModels;
  final List<ShootLook> looks;
  final Map<String, List<String>> lookFilters;
  final List<ShootPreset> presets;
  final int availableCredits;
  final List<String> supportedAspectRatios;
  final String defaultAspectRatio;
  final bool relaxEnabled;
  final String plan;
  final bool isUnlimitedEligible;
}

@immutable
class PlannedShootShot {
  const PlannedShootShot({
    required this.title,
    required this.description,
    this.payload = const {},
  });

  final String title;
  final String description;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => {
    ...payload,
    'title': title,
    'shortDescription': description,
  };
}

@immutable
class ShootSettings {
  const ShootSettings({
    this.useCase = 'pdp',
    this.directorId = 'clean-pro',
    this.directorFeedback = '',
    this.background = 'ai_decide',
    this.backgroundNotes = '',
    this.aspectRatio = '4:5',
    this.imageSize = '2K',
    this.numberOfShots = 5,
    this.variations = 3,
    this.lane = ShootLane.fast,
    this.stylingNotes = const {},
  });

  final String useCase;
  final String directorId;
  final String directorFeedback;
  final String background;
  final String backgroundNotes;
  final String aspectRatio;
  final String imageSize;
  final int numberOfShots;
  final int variations;
  final ShootLane lane;
  final Map<String, String> stylingNotes;

  ShootSettings copyWith({
    String? useCase,
    String? directorId,
    String? directorFeedback,
    String? background,
    String? backgroundNotes,
    String? aspectRatio,
    String? imageSize,
    int? numberOfShots,
    int? variations,
    ShootLane? lane,
    Map<String, String>? stylingNotes,
  }) => ShootSettings(
    useCase: useCase ?? this.useCase,
    directorId: directorId ?? this.directorId,
    directorFeedback: directorFeedback ?? this.directorFeedback,
    background: background ?? this.background,
    backgroundNotes: backgroundNotes ?? this.backgroundNotes,
    aspectRatio: aspectRatio ?? this.aspectRatio,
    imageSize: imageSize ?? this.imageSize,
    numberOfShots: numberOfShots ?? this.numberOfShots,
    variations: variations ?? this.variations,
    lane: lane ?? this.lane,
    stylingNotes: stylingNotes ?? this.stylingNotes,
  );
}

@immutable
class ShootSelection {
  const ShootSelection({
    required this.products,
    required this.models,
    required this.settings,
    this.productMode = ProductMode.pairing,
  });

  final List<ShootCatalogItem> products;
  final List<ShootCatalogItem> models;
  final ShootSettings settings;
  final ProductMode productMode;

  ShootCatalogItem get product => products.first;
  ShootCatalogItem get model => models.first;
  String get modelSource => model.source ?? 'user';
}

@immutable
class CustomShootShotRequest {
  const CustomShootShotRequest({
    required this.selection,
    required this.shotIdea,
    required this.existingShots,
    this.poseDirection = '',
    this.focusArea = '',
  });

  final ShootSelection selection;
  final String shotIdea;
  final String poseDirection;
  final String focusArea;
  final List<PlannedShootShot> existingShots;
}

@immutable
class CreateShootRequest {
  const CreateShootRequest({
    required this.selection,
    required this.shots,
    this.demoGroupId,
  });

  final ShootSelection selection;
  final List<PlannedShootShot> shots;
  final String? demoGroupId;
}

@immutable
class ShootVideoRequest {
  const ShootVideoRequest({
    this.variationIndex = 0,
    this.aspectRatio = '9:16',
    this.videoTier = 'standard',
    this.startingImageId,
  });

  final int variationIndex;
  final String aspectRatio;
  final String videoTier;
  final String? startingImageId;
}
