import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/studio_school/domain/entities/welcome_profile_draft.dart';
import 'package:look_atlas/features/studio_school/domain/repositories/welcome_repository.dart';
import 'package:look_atlas/features/studio_school/domain/use_cases/complete_welcome_profile_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockWelcomeRepository extends Mock implements WelcomeRepository {}

void main() {
  test('call_completed_recordsEventBeforeSavingProfile', () async {
    final repository = _MockWelcomeRepository();
    const profile = WelcomeProfileDraft(
      brandUrl: 'example.com',
      vertical: 'Fashion',
      primaryUses: ['Campaigns'],
      dropCadence: 'Monthly',
      referral: 'Search',
      referralOther: '',
    );
    when(
      () => repository.recordEvent('user-1', 'welcome.intro_completed'),
    ).thenAnswer((_) async => const Ok(null));
    when(
      () => repository.saveProfile('user-1', profile),
    ).thenAnswer((_) async => const Ok(null));

    await CompleteWelcomeProfileUseCase(repository)(
      userId: 'user-1',
      profile: profile,
      skipped: false,
      step: 5,
    );

    verifyInOrder([
      () => repository.recordEvent('user-1', 'welcome.intro_completed'),
      () => repository.saveProfile('user-1', profile),
    ]);
  });
}
