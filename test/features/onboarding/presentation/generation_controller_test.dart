import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/onboarding/di/onboarding_providers.dart';
import 'package:look_atlas/features/onboarding/domain/entities/free_shoot.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_status.dart';
import 'package:look_atlas/features/onboarding/domain/use_cases/get_onboarding_status_use_case.dart';
import 'package:look_atlas/features/onboarding/presentation/providers/generation_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetStatusUseCase extends Mock
    implements GetOnboardingStatusUseCase {}

void main() {
  testWidgets('polls_every_five_seconds_and_keeps_live_five_by_three_layout', (
    tester,
  ) async {
    final getStatus = _MockGetStatusUseCase();
    var calls = 0;
    when(getStatus.call).thenAnswer((_) async {
      calls++;
      return Result.ok(calls == 1 ? _generating : _completed);
    });
    final container = ProviderContainer(
      overrides: [
        getOnboardingStatusUseCaseProvider.overrideWithValue(getStatus),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SizedBox()),
      ),
    );

    container
        .read(generationControllerProvider.notifier)
        .start(
          shoot: const StartShootResponse(
            id: 'job-1',
            status: 'pending',
            message: 'Started',
            shotCount: 5,
            variations: 3,
            totalImages: 15,
          ),
        );
    await tester.pump();

    expect(calls, 1);
    expect(container.read(generationControllerProvider).images, hasLength(15));
    await tester.pump(const Duration(milliseconds: 4999));
    expect(calls, 1);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();

    final state = container.read(generationControllerProvider);
    expect(calls, 2);
    expect(state.isComplete, isTrue);
    expect(state.readyCount, 15);
    expect(state.images.map((image) => image.shot).toSet(), {1, 2, 3, 4, 5});
    expect(state.images.map((image) => image.variation).toSet(), {1, 2, 3});
  });
}

const _generating = OnboardingStatus(
  freeShootUsed: true,
  onboardingImages: [],
  hasCalibration: false,
  onboardingJobStatus: 'generating',
  onboardingJob: OnboardingJob(
    id: 'job-1',
    status: 'processing',
    progress: 5,
  ),
);

final _completed = OnboardingStatus(
  freeShootUsed: true,
  hasCalibration: false,
  onboardingJobStatus: 'completed',
  onboardingJob: const OnboardingJob(
    id: 'job-1',
    status: 'completed',
    progress: 100,
  ),
  onboardingImages: [
    for (var variation = 1; variation <= 3; variation++)
      for (var shotIndex = 0; shotIndex < 5; shotIndex++)
        OnboardingImage(
          url: 'https://cdn.example/v$variation-shot$shotIndex.jpg',
          shotIndex: shotIndex,
          variation: variation,
        ),
  ],
);
