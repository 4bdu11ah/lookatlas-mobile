part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

enum _ModelGender {
  female('Female', 'F'),
  male('Male', 'M'),
  nonBinary('Non-binary', 'NB'),
  preferNotToSay('Prefer not to say', 'NA');

  const _ModelGender(this.label, this.badge);

  final String label;
  final String badge;
}

enum _ModelBody {
  average('Average'),
  petite('Petite'),
  slimAthletic('Slim/Athletic'),
  plusSizeCurvy('Plus-size/Curvy');

  const _ModelBody(this.label);

  final String label;
}

enum _ModelSource {
  lookAtlas('LookAtlas'),
  user('Your model');

  const _ModelSource(this.label);

  final String label;
}

enum _ModelAngle {
  front('F', 'Front'),
  left('L', 'Left'),
  right('R', 'Right'),
  back('B', 'Back');

  const _ModelAngle(this.shortLabel, this.label);

  final String shortLabel;
  final String label;
}

class _HouseModel {
  const _HouseModel({
    required this.id,
    required this.name,
    required this.gender,
    required this.body,
    required this.ethnicity,
    required this.ageRange,
    required this.heightCm,
    required this.asset,
    required this.source,
    this.photoCount = 4,
    this.heightEstimated = false,
    this.photoUrls = const [],
  });

  factory _HouseModel.fromProfile(HouseModelProfile profile) {
    final asset = profile.imageUrl.isEmpty
        ? '$_img/angle-example-front.png'
        : profile.imageUrl;
    return _HouseModel(
      id: profile.id,
      name: profile.name,
      gender: _genderFromWire(profile.gender),
      body: _bodyFromWire(profile.bodyType),
      ethnicity: profile.ethnicity ?? 'Not specified',
      ageRange: profile.ageRange ?? 'Not specified',
      heightCm: profile.heightCm ?? 170,
      asset: asset,
      source: profile.source == HouseModelSource.lookAtlas
          ? _ModelSource.lookAtlas
          : _ModelSource.user,
      photoCount: profile.photos.length,
      heightEstimated: profile.heightEstimated,
      photoUrls: profile.photos,
    );
  }

  final String id;
  final String name;
  final _ModelGender gender;
  final _ModelBody body;
  final String ethnicity;
  final String ageRange;
  final int heightCm;
  final String asset;
  final _ModelSource source;
  final int photoCount;
  final bool heightEstimated;
  final List<String> photoUrls;

  String get subtitle => '${gender.label} · ${body.label}';

  String get heightLabel => '$heightCm cm${heightEstimated ? ' est.' : ''}';

  bool get isLibrary => source == _ModelSource.lookAtlas;

  String assetForAngle(_ModelAngle angle) {
    if (photoUrls.isNotEmpty) {
      final index = angle.index < photoUrls.length
          ? angle.index
          : photoUrls.length - 1;
      return photoUrls[index];
    }
    return switch (angle) {
      _ModelAngle.front => asset,
      _ModelAngle.left => '$_img/angle-example-side.png',
      _ModelAngle.right => '$_img/angle-example-detail.png',
      _ModelAngle.back => '$_img/angle-example-back.png',
    };
  }

  _HouseModel copyWith({
    String? name,
    _ModelGender? gender,
    _ModelBody? body,
    String? ethnicity,
    String? ageRange,
    int? heightCm,
    String? asset,
    _ModelSource? source,
    int? photoCount,
    bool? heightEstimated,
    List<String>? photoUrls,
  }) {
    return _HouseModel(
      id: id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      body: body ?? this.body,
      ethnicity: ethnicity ?? this.ethnicity,
      ageRange: ageRange ?? this.ageRange,
      heightCm: heightCm ?? this.heightCm,
      asset: asset ?? this.asset,
      source: source ?? this.source,
      photoCount: photoCount ?? this.photoCount,
      heightEstimated: heightEstimated ?? this.heightEstimated,
      photoUrls: photoUrls ?? this.photoUrls,
    );
  }

  static _ModelGender _genderFromWire(String raw) =>
      switch (raw.toLowerCase().replaceAll('-', '_')) {
        'female' || 'woman' || 'women' => _ModelGender.female,
        'male' || 'man' || 'men' => _ModelGender.male,
        'non_binary' || 'nonbinary' => _ModelGender.nonBinary,
        _ => _ModelGender.preferNotToSay,
      };

  static _ModelBody _bodyFromWire(String? raw) =>
      switch (raw?.toLowerCase().replaceAll(RegExp('[^a-z]'), '')) {
        'petite' => _ModelBody.petite,
        'slimathletic' || 'athletic' || 'slim' => _ModelBody.slimAthletic,
        'plussizecurvy' || 'plussize' || 'curvy' => _ModelBody.plusSizeCurvy,
        _ => _ModelBody.average,
      };
}

class _ModelFormInput {
  const _ModelFormInput({
    required this.name,
    required this.gender,
    required this.heightCm,
    required this.photos,
    this.removedPhotoIndexes = const [],
    this.heightEstimated = false,
  });

  final String name;
  final _ModelGender gender;
  final int heightCm;
  final List<HouseModelUpload> photos;
  final List<int> removedPhotoIndexes;
  final bool heightEstimated;

  HouseModelDraft toDraft() => HouseModelDraft(
    name: name,
    gender: switch (gender) {
      _ModelGender.nonBinary => 'non_binary',
      _ModelGender.preferNotToSay => 'unspecified',
      _ => gender.name,
    },
    heightCm: heightCm,
    heightEstimated: heightEstimated,
    photos: photos,
  );
}
