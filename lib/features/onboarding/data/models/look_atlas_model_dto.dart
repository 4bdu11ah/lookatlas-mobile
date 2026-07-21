import 'package:look_atlas/features/onboarding/domain/look_atlas_model.dart';
import 'package:look_atlas/features/onboarding/domain/onboarding_models.dart';

class LookAtlasModelDto {
  const LookAtlasModelDto({required this.entity});

  factory LookAtlasModelDto.fromJson(
    Map<String, dynamic> json, {
    required String baseUrl,
  }) {
    final cover = json['coverThumbnail'] as String?;
    return LookAtlasModelDto(
      entity: LookAtlasModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Model',
        gender: _gender(json['gender'] as String?),
        ethnicity: json['ethnicity'] as String?,
        bodyType: json['bodyType'] as String?,
        ageRange: json['ageRange'] as String?,
        height: json['height'] as String?,
        displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
        photos: [
          for (final photo in json['photos'] as List? ?? const [])
            if (photo is String) photo,
        ],
        coverThumbnail: _absoluteUrl(cover, baseUrl),
      ),
    );
  }

  final LookAtlasModel entity;

  LookAtlasModel toEntity() => entity;

  static String? _absoluteUrl(String? value, String baseUrl) {
    if (value == null || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri?.hasScheme ?? false) return value;
    return Uri.parse(baseUrl).resolve(value).toString();
  }

  static ModelGender? _gender(String? raw) => switch (raw?.toLowerCase()) {
    'female' || 'women' || 'woman' => ModelGender.women,
    'male' || 'men' || 'man' => ModelGender.men,
    _ => null,
  };
}
