import 'package:look_atlas/features/onboarding/domain/entities/onboarding_config.dart';

class OnboardingAppConfigModel {
  const OnboardingAppConfigModel({
    required this.imageProvider,
    required this.supportedAspectRatios,
    required this.defaultAspectRatio,
  });

  factory OnboardingAppConfigModel.fromJson(Map<String, dynamic> json) {
    final ratios = [
      for (final value in json['supportedAspectRatios'] as List? ?? const [])
        if (value is String) value,
    ];
    const fallback = OnboardingAppConfig.fallback;
    return OnboardingAppConfigModel(
      imageProvider: json['imageProvider'] as String? ?? fallback.imageProvider,
      supportedAspectRatios: ratios.isEmpty
          ? fallback.supportedAspectRatios
          : ratios,
      defaultAspectRatio:
          json['defaultAspectRatio'] as String? ?? fallback.defaultAspectRatio,
    );
  }

  final String imageProvider;
  final List<String> supportedAspectRatios;
  final String defaultAspectRatio;

  OnboardingAppConfig toEntity() => OnboardingAppConfig(
    imageProvider: imageProvider,
    supportedAspectRatios: supportedAspectRatios,
    defaultAspectRatio: defaultAspectRatio,
  );
}
