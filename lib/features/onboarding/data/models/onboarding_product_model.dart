import 'package:look_atlas/features/onboarding/domain/entities/onboarding_product.dart';

class OnboardingProductModel {
  const OnboardingProductModel({required this.entity});

  factory OnboardingProductModel.fromJson(Map<String, dynamic> json) {
    return OnboardingProductModel(
      entity: OnboardingProduct(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        sku: json['sku'] as String? ?? '',
        category: json['category'] as String? ?? 'other',
        description: json['description'] as String?,
        subCategory: json['subCategory'] as String?,
        createdAt: _date(json['createdAt']),
        thumbnail: json['thumbnail'] as String?,
        photos: [
          for (final photo in json['photos'] as List? ?? const [])
            if (photo is Map<String, dynamic>)
              OnboardingProductPhoto(
                id: photo['id'] as String? ?? '',
                url: photo['url'] as String? ?? '',
                sortOrder: (photo['sortOrder'] as num?)?.toInt() ?? 0,
                viewAngle: photo['viewAngle'] as String?,
              ),
        ],
      ),
    );
  }

  final OnboardingProduct entity;

  OnboardingProduct toEntity() => entity;

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
