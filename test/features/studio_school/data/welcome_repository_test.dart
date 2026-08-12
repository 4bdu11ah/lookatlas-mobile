import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/core/storage/key_value_store.dart';
import 'package:look_atlas/features/studio_school/data/studio_school_api.dart';
import 'package:look_atlas/features/studio_school/data/welcome_repository_impl.dart';
import 'package:look_atlas/features/studio_school/domain/welcome_lesson.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_welcome_repository.dart';

class _FakeStudioSchoolApi implements StudioSchoolApi {
  Result<WelcomeState> stateResult = Ok(fakeEligibleWelcomeState());
  Completer<Result<WelcomeState>>? pending;
  int stateCalls = 0;

  @override
  Future<Result<WelcomeState>> getState() {
    stateCalls++;
    return pending?.future ?? Future.value(stateResult);
  }

  @override
  Future<Result<LessonClaimResult>> claimLessons() async => const Ok(
    LessonClaimResult(granted: 20, alreadyClaimed: false),
  );

  @override
  Future<Result<DateTime>> completeLesson(WelcomeLessonId lessonId) async =>
      Ok(DateTime(2026, 8, 11));

  @override
  Future<Result<DateTime>> startLesson(WelcomeLessonId lessonId) async =>
      Ok(DateTime(2026, 8, 11));
}

void main() {
  late _FakeStudioSchoolApi api;
  late DateTime now;
  late WelcomeRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    api = _FakeStudioSchoolApi();
    now = DateTime(2026, 8, 11, 10);
    repository = WelcomeRepositoryImpl(
      remote: api,
      store: KeyValueStore(await SharedPreferences.getInstance()),
      now: () => now,
    );
  });

  test('getState_concurrentRequests_deduplicatesPerUser', () async {
    api.pending = Completer<Result<WelcomeState>>();

    final first = repository.getState('user-1');
    final second = repository.getState('user-1');
    api.pending!.complete(Ok(fakeEligibleWelcomeState()));

    await Future.wait([first, second]);
    expect(api.stateCalls, 1);
  });

  test('getState_accountSwitch_usesSeparateCacheKeys', () async {
    await repository.getState('user-1');
    await repository.getState('user-2');

    expect(api.stateCalls, 2);
  });

  test('getState_networkFailure_returnsStaleOfflineSnapshot', () async {
    await repository.getState('user-1');
    now = now.add(const Duration(minutes: 1));
    api.stateResult = const Err(NetworkFailure('Offline'));

    final result = await repository.getState('user-1');

    expect(result.valueOrNull?.isCached, isTrue);
    expect(result.valueOrNull?.eligible, isTrue);
  });
}
