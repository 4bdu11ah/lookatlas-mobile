import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/network/dio_client.dart';
import 'package:look_atlas/features/onboarding/data/models/look_atlas_model_dto.dart';
import 'package:look_atlas/features/onboarding/data/models/onboarding_config_model.dart';
import 'package:look_atlas/features/onboarding/data/models/onboarding_status_model.dart';
import 'package:look_atlas/features/onboarding/data/models/start_shoot_response_model.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_status.dart';

void main() {
  test('app_config_missing_values_uses_mobile_fallbacks', () {
    final config = OnboardingAppConfigModel.fromJson(const {}).toEntity();

    expect(config.imageProvider, 'gemini');
    expect(config.defaultAspectRatio, '4:5');
    expect(config.supportedAspectRatios, contains('9:16'));
  });

  test('status_snake_case_job_and_images_are_parsed', () {
    final status = OnboardingStatusModel.fromJson(const {
      'freeShootUsed': true,
      'onboardingJobStatus': 'generating',
      'hasCalibration': false,
      'onboardingJob': {
        'id': 'job-1',
        'status': 'enqueued',
        'progress': 10,
        'current_step': 'Planning shots',
        'estimated_completion': '2026-07-21T12:00:00Z',
        'created_at': '2026-07-21T11:00:00Z',
      },
      'onboardingImages': [
        {'url': 'https://cdn/image.jpg', 'shot_index': 0, 'variation': 1},
      ],
    }).toEntity();

    expect(status.onboardingJob?.currentStep, 'Planning shots');
    expect(status.onboardingJob?.progress, 10);
    expect(status.onboardingImages.single.identity, '0:1');
  });

  test('active_subscription_marks_onboarding_complete', () {
    const active = OnboardingStatus(
      subscriptionStatus: 'active',
      freeShootUsed: false,
      onboardingImages: [],
      hasCalibration: false,
    );
    const canceled = OnboardingStatus(
      subscriptionStatus: 'canceled',
      freeShootUsed: true,
      onboardingImages: [],
      hasCalibration: false,
    );

    expect(active.hasActiveSubscription, isTrue);
    expect(canceled.hasActiveSubscription, isFalse);
  });

  test('start_shoot_live_five_by_three_response_is_parsed', () {
    final response = StartShootResponseModel.fromJson(const {
      'id': 'job-1',
      'status': 'pending',
      'message': 'Free shoot started successfully',
      'shotCount': 5,
      'variations': 3,
      'totalImages': 15,
    }).toEntity();

    expect(response.shotCount, 5);
    expect(response.variations, 3);
    expect(response.totalImages, 15);
  });

  test('lookatlas_relative_thumbnail_is_resolved_against_api_origin', () {
    final model = LookAtlasModelDto.fromJson(const {
      'id': 'model-1',
      'coverThumbnail': '/lookatlas-models/thumbnail/a.jpg?w=800',
    }, baseUrl: 'https://api.lookatlas.test/v1/').toEntity();

    expect(
      model.coverThumbnail,
      'https://api.lookatlas.test/lookatlas-models/thumbnail/a.jpg?w=800',
    );
  });

  test('api_error_envelope_preserves_code_and_safe_message', () {
    final request = RequestOptions(path: '/onboarding/start-shoot');
    final failure = mapDioError(
      DioException.badResponse(
        statusCode: 403,
        requestOptions: request,
        response: Response<dynamic>(
          requestOptions: request,
          statusCode: 403,
          data: const {
            'error': {
              'code': 'FREE_SHOOT_UNAVAILABLE',
              'message': 'Free shoot is unavailable.',
            },
          },
        ),
      ),
    );

    expect(
      failure,
      isA<NetworkFailure>()
          .having(
            (value) => value.code,
            'code',
            'FREE_SHOOT_UNAVAILABLE',
          )
          .having(
            (value) => value.message,
            'message',
            'Free shoot is unavailable.',
          ),
    );
  });
}
