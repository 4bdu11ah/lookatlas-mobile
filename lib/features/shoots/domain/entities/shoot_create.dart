import 'package:flutter/foundation.dart';

@immutable
class ShootCatalogItem {
  const ShootCatalogItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.subtitle = '',
    this.source,
  });

  final String id;
  final String name;
  final String imageUrl;
  final String subtitle;
  final String? source;
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
  });

  final List<ShootCatalogItem> products;
  final List<ShootCatalogItem> userModels;
  final List<ShootCatalogItem> libraryModels;
  final List<ShootLook> looks;
  final Map<String, List<String>> lookFilters;
  final List<ShootPreset> presets;
  final int availableCredits;
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
    this.background = 'studio',
    this.backgroundNotes = '',
    this.aspectRatio = '4:5',
    this.imageSize = '2K',
    this.numberOfShots = 5,
    this.variations = 3,
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
  );
}

@immutable
class ShootSelection {
  const ShootSelection({
    required this.product,
    required this.model,
    required this.settings,
  });

  final ShootCatalogItem product;
  final ShootCatalogItem model;
  final ShootSettings settings;

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
  });

  final ShootSelection selection;
  final List<PlannedShootShot> shots;
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
