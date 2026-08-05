import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/features/workshop/domain/entities/workshop_models.dart';

String? workshopCompletedGenerationMessage(WorkshopGeneration generation) {
  if (generation.status == WorkshopGenerationStatus.completed) {
    return generation.hasImage
        ? null
        : "The model didn't return an image. Please try again — "
              'your credit was refunded.';
  }
  if (generation.status == WorkshopGenerationStatus.failed) {
    return workshopGenerationErrorMessage(generation.errorMessage);
  }
  if (generation.status == WorkshopGenerationStatus.cancelled) {
    return 'The generation took too long and was cancelled. '
        'Your credit was refunded.';
  }
  return 'Generation failed. Your credit was refunded — please try again.';
}

String workshopGenerationFailureMessage(Failure failure) {
  final code = failure is NetworkFailure ? failure.code : null;
  return workshopGenerationErrorMessage('$code ${failure.message}');
}

String workshopGenerationErrorMessage(String? raw) {
  final value = raw?.toLowerCase() ?? '';
  if (value.contains('content') || value.contains('moderat')) {
    return 'The image or prompt was rejected by content moderation. '
        'Please adjust and try again — your credit was refunded.';
  }
  if (value.contains('no_image') || value.contains('no image')) {
    return "The model didn't return an image. Please try again — "
        'your credit was refunded.';
  }
  if (value.contains('input') || value.contains('lost')) {
    return 'We lost track of your uploaded images. Please try again — '
        'your credit was refunded.';
  }
  if (value.contains('storage') || value.contains('upload')) {
    return 'Failed to save the generated image. Your credit was refunded — '
        'please try again.';
  }
  if (value.contains('timeout') || value.contains('too long')) {
    return 'The generation took too long and was cancelled. '
        'Your credit was refunded.';
  }
  if (value.contains('quota') ||
      value.contains('insufficient') ||
      value.contains('not enough credit') ||
      value.contains('credit balance')) {
    return 'Not enough credits. Top up to keep generating.';
  }
  return 'Generation failed. Your credit was refunded — please try again.';
}
