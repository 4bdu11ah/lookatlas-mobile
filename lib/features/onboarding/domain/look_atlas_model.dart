import 'package:flutter/foundation.dart';
import 'package:look_atlas/features/onboarding/domain/onboarding_models.dart';

/// A model from the Look Atlas library (`GET /lookatlas-models`), mirroring
/// the web client's `LookAtlasModel` interface.
@immutable
class LookAtlasModel {
  const LookAtlasModel({
    required this.id,
    required this.name,
    this.gender,
    this.ethnicity,
    this.bodyType,
    this.ageRange,
    this.height,
    this.displayOrder = 0,
    this.photos = const [],
    this.coverThumbnail,
  });

  factory LookAtlasModel.fromJson(Map<String, dynamic> json) {
    return LookAtlasModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Model',
      gender: _parseGender(json['gender'] as String?),
      ethnicity: json['ethnicity'] as String?,
      bodyType: json['bodyType'] as String?,
      ageRange: json['ageRange'] as String?,
      height: json['height'] as String?,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      photos: [
        for (final photo in json['photos'] as List<dynamic>? ?? <dynamic>[])
          photo as String,
      ],
      coverThumbnail: json['coverThumbnail'] as String?,
    );
  }

  final String id;
  final String name;

  /// Null when the backend sends a gender the app doesn't know; such models
  /// only show under the "All" filter.
  final ModelGender? gender;
  final String? ethnicity;
  final String? bodyType;
  final String? ageRange;
  final String? height;
  final int displayOrder;
  final List<String> photos;
  final String? coverThumbnail;

  /// Card image: the cover thumbnail, else the first photo.
  String get imageUrl =>
      coverThumbnail ?? (photos.isNotEmpty ? photos.first : '');

  static ModelGender? _parseGender(String? raw) =>
      switch (raw?.toLowerCase()) {
        'female' || 'women' || 'woman' => ModelGender.women,
        'male' || 'men' || 'man' => ModelGender.men,
        _ => null,
      };
}

/// Built-in starter models, used while the backend is unreachable in dev
/// (the mobile counterpart of the web client's `DEV_PREVIEW` mocks).
final List<LookAtlasModel> fallbackLibraryModels = [
  for (final (i, (id, name, gender)) in const [
    ('amara', 'Amara', ModelGender.women),
    ('sofia', 'Sofia', ModelGender.women),
    ('elena', 'Elena', ModelGender.women),
    ('james', 'James', ModelGender.men),
    ('maya', 'Maya', ModelGender.women),
    ('lucas', 'Lucas', ModelGender.men),
  ].indexed)
    LookAtlasModel(
      id: id,
      name: name,
      gender: gender,
      displayOrder: i,
      photos: ['https://picsum.photos/seed/la-model-$id/600/800'],
    ),
];
