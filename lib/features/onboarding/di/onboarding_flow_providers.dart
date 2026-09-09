import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/onboarding/presentation/controllers/generation_controller.dart';

final onboardingGenerationStartProvider = Provider<void Function()>(
  (ref) => () => ref.read(generationControllerProvider.notifier).start(),
);
