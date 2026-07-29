import 'package:flutter/foundation.dart';

enum HouseModelSource { lookAtlas, user }

@immutable
class HouseModelProfile {
  const HouseModelProfile({
    required this.id,
    required this.name,
    required this.gender,
    required this.source,
    this.bodyType,
    this.ethnicity,
    this.ageRange,
    this.heightCm,
    this.heightEstimated = false,
    this.photos = const [],
    this.coverThumbnail,
  });

  final String id;
  final String name;
  final String gender;
  final HouseModelSource source;
  final String? bodyType;
  final String? ethnicity;
  final String? ageRange;
  final int? heightCm;
  final bool heightEstimated;
  final List<String> photos;
  final String? coverThumbnail;

  String get imageUrl =>
      coverThumbnail ?? (photos.isNotEmpty ? photos.first : '');
}

@immutable
class HouseModelUpload {
  const HouseModelUpload({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;
}

@immutable
class HouseModelDraft {
  const HouseModelDraft({
    required this.name,
    required this.gender,
    required this.heightCm,
    required this.heightEstimated,
    this.photos = const [],
  });

  final String name;
  final String gender;
  final int heightCm;
  final bool heightEstimated;
  final List<HouseModelUpload> photos;
}

@immutable
class AiHouseModelDraft {
  const AiHouseModelDraft({
    required this.gender,
    required this.age,
    required this.description,
    this.name,
  });

  final String gender;
  final int age;
  final String description;
  final String? name;
}

enum HouseModelGenerationStatus { pending, processing, completed, failed }

@immutable
class HouseModelGeneration {
  const HouseModelGeneration({
    required this.id,
    required this.status,
    this.creditCost,
    this.message,
    this.modelId,
  });

  final String id;
  final HouseModelGenerationStatus status;
  final int? creditCost;
  final String? message;
  final String? modelId;

  bool get isTerminal =>
      status == HouseModelGenerationStatus.completed ||
      status == HouseModelGenerationStatus.failed;
}

@immutable
class HouseModelCatalog {
  const HouseModelCatalog({
    required this.libraryModels,
    required this.userModels,
  });

  final List<HouseModelProfile> libraryModels;
  final List<HouseModelProfile> userModels;
}
