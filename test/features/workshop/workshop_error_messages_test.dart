import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/features/workshop/domain/entities/workshop_models.dart';
import 'package:look_atlas/features/workshop/presentation/controllers/workshop_error_messages.dart';

void main() {
  group('workshopGenerationFailureMessage', () {
    const cases = <(String, String)>[
      (
        'content_moderation',
        'The image or prompt was rejected by content moderation. Please adjust and try again — your credit was refunded.',
      ),
      (
        'no_image',
        "The model didn't return an image. Please try again — your credit was refunded.",
      ),
      (
        'storage_upload_failed',
        'Failed to save the generated image. Your credit was refunded — please try again.',
      ),
      (
        'input_lost',
        'We lost track of your uploaded images. Please try again — your credit was refunded.',
      ),
      (
        'generation_timeout',
        'The generation took too long and was cancelled. Your credit was refunded.',
      ),
      (
        'quota_exceeded',
        'Not enough credits. Top up to keep generating.',
      ),
      (
        'unexpected',
        'Generation failed. Your credit was refunded — please try again.',
      ),
    ];

    for (final (code, expected) in cases) {
      test('network_${code}_returnsCanonicalCopy', () {
        final message = workshopGenerationFailureMessage(
          NetworkFailure('Request failed.', code: code),
        );

        expect(message, expected);
      });
    }
  });

  test('completedWithoutImage_returnsNoImageCopy', () {
    const generation = WorkshopGeneration(
      id: 'generation-1',
      status: WorkshopGenerationStatus.completed,
    );

    expect(
      workshopCompletedGenerationMessage(generation),
      "The model didn't return an image. Please try again — your credit was refunded.",
    );
  });

  test('completedWithImage_returnsNoError', () {
    const generation = WorkshopGeneration(
      id: 'generation-1',
      status: WorkshopGenerationStatus.completed,
      imageUrl: 'https://example.com/result.jpg',
    );

    expect(workshopCompletedGenerationMessage(generation), isNull);
  });

  test('lostUploadedImages_prefersInputsLostCopy', () {
    expect(
      workshopGenerationErrorMessage('Lost uploaded images'),
      'We lost track of your uploaded images. Please try again — your credit was refunded.',
    );
  });

  test('refundedCredit_doesNotLookLikeQuotaFailure', () {
    expect(
      workshopGenerationErrorMessage('Request failed, credit was refunded'),
      'Generation failed. Your credit was refunded — please try again.',
    );
  });
}
