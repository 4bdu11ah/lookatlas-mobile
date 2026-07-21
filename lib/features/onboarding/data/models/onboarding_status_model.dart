import 'package:look_atlas/features/onboarding/domain/entities/onboarding_status.dart';

class OnboardingStatusModel {
  const OnboardingStatusModel({required this.entity});

  factory OnboardingStatusModel.fromJson(Map<String, dynamic> json) {
    final job = json['onboardingJob'];
    return OnboardingStatusModel(
      entity: OnboardingStatus(
        subscriptionStatus: json['subscriptionStatus'] as String?,
        subscriptionPlan: json['subscriptionPlan'] as String?,
        freeShootUsed: json['freeShootUsed'] as bool? ?? false,
        onboardingJobStatus: json['onboardingJobStatus'] as String?,
        onboardingJob: job is Map<String, dynamic> ? _jobFromJson(job) : null,
        onboardingImages: [
          for (final item in json['onboardingImages'] as List? ?? const [])
            if (item is Map<String, dynamic>) _imageFromJson(item),
        ],
        currentPeriodEnd: _date(json['currentPeriodEnd']),
        productCategory: json['productCategory'] as String?,
        hasCalibration: json['hasCalibration'] as bool? ?? false,
      ),
    );
  }

  final OnboardingStatus entity;

  OnboardingStatus toEntity() => entity;

  static OnboardingJob _jobFromJson(Map<String, dynamic> json) => OnboardingJob(
    id: json['id'] as String? ?? '',
    status: json['status'] as String? ?? 'pending',
    progress: (json['progress'] as num?)?.toInt() ?? 0,
    currentStep: json['current_step'] as String?,
    estimatedCompletion: _date(json['estimated_completion']),
    createdAt: _date(json['created_at']),
  );

  static OnboardingImage _imageFromJson(Map<String, dynamic> json) =>
      OnboardingImage(
        url: json['url'] as String? ?? '',
        shotIndex: (json['shot_index'] as num?)?.toInt() ?? 0,
        variation: (json['variation'] as num?)?.toInt() ?? 0,
      );

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
