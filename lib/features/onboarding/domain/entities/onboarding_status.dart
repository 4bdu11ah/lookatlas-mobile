import 'package:flutter/foundation.dart';

@immutable
class OnboardingStatus {
  const OnboardingStatus({
    required this.freeShootUsed,
    required this.onboardingImages,
    required this.hasCalibration,
    this.subscriptionStatus,
    this.subscriptionPlan,
    this.onboardingJobStatus,
    this.onboardingJob,
    this.currentPeriodEnd,
    this.productCategory,
  });

  final String? subscriptionStatus;
  final String? subscriptionPlan;
  final bool freeShootUsed;
  final String? onboardingJobStatus;
  final OnboardingJob? onboardingJob;
  final List<OnboardingImage> onboardingImages;
  final DateTime? currentPeriodEnd;
  final String? productCategory;
  final bool hasCalibration;

  bool get hasActiveSubscription {
    final status = subscriptionStatus?.toLowerCase();
    return status != null &&
        status.isNotEmpty &&
        status != 'inactive' &&
        status != 'canceled' &&
        status != 'cancelled';
  }
}

@immutable
class OnboardingJob {
  const OnboardingJob({
    required this.id,
    required this.status,
    required this.progress,
    this.currentStep,
    this.estimatedCompletion,
    this.createdAt,
  });

  final String id;
  final String status;
  final int progress;
  final String? currentStep;
  final DateTime? estimatedCompletion;
  final DateTime? createdAt;
}

@immutable
class OnboardingImage {
  const OnboardingImage({
    required this.url,
    required this.shotIndex,
    required this.variation,
  });

  final String url;
  final int shotIndex;
  final int variation;

  String get identity => '$shotIndex:$variation';
}
