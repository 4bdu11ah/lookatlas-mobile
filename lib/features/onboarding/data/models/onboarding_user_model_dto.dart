import 'package:look_atlas/features/onboarding/domain/entities/onboarding_product.dart';

class OnboardingUserModelDto {
  const OnboardingUserModelDto({required this.entity});

  factory OnboardingUserModelDto.fromJson(
    Map<String, dynamic> json, {
    required String baseUrl,
  }) {
    return OnboardingUserModelDto(
      entity: OnboardingUserModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Custom model',
        thumbnail: _absoluteUrl(
          json['coverThumbnail'] as String? ?? json['thumbnail'] as String?,
          baseUrl,
        ),
        photos: [
          for (final photo in json['photos'] as List? ?? const [])
            if (_photoUrl(photo, baseUrl) case final String url) url,
        ],
      ),
    );
  }

  final OnboardingUserModel entity;

  OnboardingUserModel toEntity() => entity;

  static String? _photoUrl(Object? photo, String baseUrl) {
    if (photo is String) return _absoluteUrl(photo, baseUrl);
    if (photo is! Map<String, dynamic>) return null;
    final value = photo['url'] ?? photo['thumbnailUrl'] ?? photo['thumbnail'];
    return value is String ? _absoluteUrl(value, baseUrl) : null;
  }

  static String? _absoluteUrl(String? value, String baseUrl) {
    if (value == null || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri?.hasScheme ?? false) return value;
    return Uri.parse(baseUrl).resolve(value).toString();
  }
}
