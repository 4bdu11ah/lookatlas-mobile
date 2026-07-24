import 'package:flutter/foundation.dart';

@immutable
class OnboardingUpload {
  const OnboardingUpload({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;
}

@immutable
class ProductDraft {
  const ProductDraft({
    required this.name,
    required this.sku,
    required this.category,
    required this.photos,
    this.viewAngles = const [],
  });

  final String name;
  final String sku;
  final String category;
  final List<OnboardingUpload> photos;
  final List<String?> viewAngles;
}

@immutable
class OnboardingProduct {
  const OnboardingProduct({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.photos,
    this.description,
    this.subCategory,
    this.createdAt,
    this.thumbnail,
  });

  final String id;
  final String name;
  final String sku;
  final String category;
  final String? description;
  final String? subCategory;
  final DateTime? createdAt;
  final String? thumbnail;
  final List<OnboardingProductPhoto> photos;
}

@immutable
class OnboardingProductPhoto {
  const OnboardingProductPhoto({
    required this.id,
    required this.url,
    required this.sortOrder,
    this.viewAngle,
  });

  final String id;
  final String url;
  final int sortOrder;
  final String? viewAngle;
}

@immutable
class OnboardingUserModel {
  const OnboardingUserModel({
    required this.id,
    required this.name,
    this.photos = const [],
    this.thumbnail,
  });

  final String id;
  final String name;
  final List<String> photos;
  final String? thumbnail;

  String get imageUrl => thumbnail ?? (photos.isNotEmpty ? photos.first : '');
}

@immutable
class UserModelDraft {
  const UserModelDraft({
    required this.name,
    required this.gender,
    required this.photos,
    this.height = '',
    this.heightEstimated = true,
  });

  final String name;
  final UserModelGender gender;
  final List<OnboardingUpload> photos;
  final String height;
  final bool heightEstimated;
}

enum UserModelGender { male, female, nonBinary, unspecified }

extension UserModelGenderWireValue on UserModelGender {
  String get wireValue => switch (this) {
    UserModelGender.nonBinary => 'non_binary',
    _ => name,
  };
}
