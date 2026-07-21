import 'package:flutter/foundation.dart';

@immutable
class OnboardingAppConfig {
  const OnboardingAppConfig({
    required this.imageProvider,
    required this.supportedAspectRatios,
    required this.defaultAspectRatio,
  });

  static const fallback = OnboardingAppConfig(
    imageProvider: 'gemini',
    supportedAspectRatios: ['4:5', '3:4', '1:1', '4:3', '16:9', '9:16'],
    defaultAspectRatio: '4:5',
  );

  final String imageProvider;
  final List<String> supportedAspectRatios;
  final String defaultAspectRatio;
}

enum OnboardingTrackingStatus {
  pending,
  onboarding,
  generating,
  completed,
}
