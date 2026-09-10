import 'package:look_atlas/features/house_model/domain/entities/house_model_profile.dart';

const houseModelImagePath = 'assets/images/onboarding';

enum HouseModelGender {
  female('Female', 'F'),
  male('Male', 'M'),
  nonBinary('Non-binary', 'NB'),
  preferNotToSay('Prefer not to say', 'NA');

  const HouseModelGender(this.label, this.badge);

  final String label;
  final String badge;
}

enum HouseModelBody {
  average('Average'),
  petite('Petite'),
  slimAthletic('Slim/Athletic'),
  plusSizeCurvy('Plus-size/Curvy');

  const HouseModelBody(this.label);

  final String label;
}

enum HouseModelViewSource {
  lookAtlas('LookAtlas'),
  user('Your model');

  const HouseModelViewSource(this.label);

  final String label;
}

enum HouseModelAngle {
  front('F', 'Front'),
  left('L', 'Left'),
  right('R', 'Right'),
  back('B', 'Back');

  const HouseModelAngle(this.shortLabel, this.label);

  final String shortLabel;
  final String label;
}

class HouseModelViewModel {
  const HouseModelViewModel({
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
    this.photoIds = const [],
  });

  factory HouseModelViewModel.fromProfile(HouseModelProfile profile) {
    final asset = profile.imageUrl.isEmpty
        ? '$houseModelImagePath/angle-example-front.png'
        : profile.imageUrl;
    return HouseModelViewModel(
      id: profile.id,
      name: profile.name,
      gender: _genderFromWire(profile.gender),
      body: _bodyFromWire(profile.bodyType),
      ethnicity: profile.ethnicity ?? 'Not specified',
      ageRange: profile.ageRange ?? 'Not specified',
      heightCm: profile.heightCm ?? 170,
      asset: asset,
      source: profile.source == HouseModelSource.lookAtlas
          ? HouseModelViewSource.lookAtlas
          : HouseModelViewSource.user,
      photoCount: profile.photos.length,
      heightEstimated: profile.heightEstimated,
      photoUrls: profile.photos,
      photoIds: profile.photoIds,
    );
  }

  final String id;
  final String name;
  final HouseModelGender gender;
  final HouseModelBody body;
  final String ethnicity;
  final String ageRange;
  final int heightCm;
  final String asset;
  final HouseModelViewSource source;
  final int photoCount;
  final bool heightEstimated;
  final List<String> photoUrls;
  final List<String?> photoIds;

  String get subtitle => '${gender.label} · ${body.label}';

  String get heightLabel => '$heightCm cm${heightEstimated ? ' est.' : ''}';

  bool get isLibrary => source == HouseModelViewSource.lookAtlas;

  String assetForAngle(HouseModelAngle angle) {
    if (photoUrls.isNotEmpty) {
      final index = angle.index < photoUrls.length
          ? angle.index
          : photoUrls.length - 1;
      return photoUrls[index];
    }
    return switch (angle) {
      HouseModelAngle.front => asset,
      HouseModelAngle.left => '$houseModelImagePath/angle-example-side.png',
      HouseModelAngle.right => '$houseModelImagePath/angle-example-detail.png',
      HouseModelAngle.back => '$houseModelImagePath/angle-example-back.png',
    };
  }

  HouseModelViewModel copyWith({
    String? name,
    HouseModelGender? gender,
    HouseModelBody? body,
    String? ethnicity,
    String? ageRange,
    int? heightCm,
    String? asset,
    HouseModelViewSource? source,
    int? photoCount,
    bool? heightEstimated,
    List<String>? photoUrls,
    List<String?>? photoIds,
  }) {
    return HouseModelViewModel(
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
      photoIds: photoIds ?? this.photoIds,
    );
  }

  static HouseModelGender _genderFromWire(String raw) =>
      switch (raw.toLowerCase().replaceAll('-', '_')) {
        'female' || 'woman' || 'women' => HouseModelGender.female,
        'male' || 'man' || 'men' => HouseModelGender.male,
        'non_binary' || 'nonbinary' => HouseModelGender.nonBinary,
        _ => HouseModelGender.preferNotToSay,
      };

  static HouseModelBody _bodyFromWire(String? raw) => switch (raw
      ?.toLowerCase()
      .replaceAll(RegExp('[^a-z]'), '')) {
    'petite' => HouseModelBody.petite,
    'slimathletic' || 'athletic' || 'slim' => HouseModelBody.slimAthletic,
    'plussizecurvy' || 'plussize' || 'curvy' => HouseModelBody.plusSizeCurvy,
    _ => HouseModelBody.average,
  };
}

class HouseModelFormInput {
  const HouseModelFormInput({
    required this.name,
    required this.gender,
    required this.heightCm,
    required this.photos,
    this.heightEstimated = false,
  });

  final String name;
  final HouseModelGender gender;
  final int heightCm;
  final List<HouseModelUpload> photos;
  final bool heightEstimated;

  HouseModelDraft toDraft() => HouseModelDraft(
    name: name,
    gender: switch (gender) {
      HouseModelGender.nonBinary => 'non_binary',
      HouseModelGender.preferNotToSay => 'unspecified',
      _ => gender.name,
    },
    heightCm: heightCm,
    heightEstimated: heightEstimated,
    photos: photos,
  );
}
