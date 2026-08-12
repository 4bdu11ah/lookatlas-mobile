import 'dart:async';
import 'dart:convert';

import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/core/storage/key_value_store.dart';
import 'package:look_atlas/features/studio_school/data/studio_school_api.dart';
import 'package:look_atlas/features/studio_school/data/welcome_dto.dart';
import 'package:look_atlas/features/studio_school/domain/welcome_lesson.dart';
import 'package:look_atlas/features/studio_school/domain/welcome_repository.dart';

class WelcomeRepositoryImpl implements WelcomeRepository {
  WelcomeRepositoryImpl({
    required StudioSchoolApi remote,
    required KeyValueStore store,
    DateTime Function()? now,
  }) : _remote = remote,
       _store = store,
       _now = now ?? DateTime.now;

  static const _staleAfter = Duration(seconds: 45);
  static const _cachePrefix = 'welcome_state:';

  final StudioSchoolApi _remote;
  final KeyValueStore _store;
  final DateTime Function() _now;
  final Map<String, Future<Result<WelcomeState>>> _inFlight = {};

  @override
  Future<Result<WelcomeState>> getState(
    String userId, {
    bool forceRefresh = false,
  }) {
    final cached = _readCache(userId);
    if (!forceRefresh && cached != null && !_isStale(cached.$2)) {
      return Future.value(Ok(cached.$1.copyWith(isCached: false)));
    }
    return _inFlight.putIfAbsent(userId, () => _fetch(userId, cached?.$1));
  }

  Future<Result<WelcomeState>> _fetch(
    String userId,
    WelcomeState? fallback,
  ) async {
    try {
      final result = await _remote.getState();
      if (result case Ok(:final value)) {
        await _writeCache(userId, value);
        return Ok(value);
      }
      if (fallback != null) return Ok(fallback.copyWith(isCached: true));
      return result;
    } finally {
      final _ = _inFlight.remove(userId);
    }
  }

  @override
  Future<Result<DateTime>> startLesson(
    String userId,
    WelcomeLessonId lessonId,
  ) => _remote.startLesson(lessonId);

  @override
  Future<Result<DateTime>> completeLesson(
    String userId,
    WelcomeLessonId lessonId,
  ) async {
    final result = await _remote.completeLesson(lessonId);
    if (result.isOk) await clearCache(userId);
    return result;
  }

  @override
  Future<Result<LessonClaimResult>> claimLessons(String userId) async {
    final result = await _remote.claimLessons();
    if (result.isOk) await clearCache(userId);
    return result;
  }

  @override
  Future<void> clearCache(String userId) => _store.remove(_key(userId));

  (WelcomeState, DateTime)? _readCache(String userId) {
    final raw = _store.getString(_key(userId));
    if (raw == null) return null;
    try {
      final wrapper = jsonDecode(raw);
      if (wrapper is! Map<String, dynamic>) return null;
      final rawSavedAt = wrapper['savedAt'];
      if (rawSavedAt is! String) return null;
      final savedAt = DateTime.tryParse(rawSavedAt);
      if (savedAt == null) return null;
      return (WelcomeDto.state(wrapper['state'], isCached: true), savedAt);
    } on FormatException {
      return null;
    }
  }

  Future<void> _writeCache(String userId, WelcomeState state) =>
      _store.setString(
        _key(userId),
        jsonEncode({
          'savedAt': _now().toUtc().toIso8601String(),
          'state': WelcomeDto.toJson(state),
        }),
      );

  bool _isStale(DateTime savedAt) => _now().difference(savedAt) > _staleAfter;

  String _key(String userId) => '$_cachePrefix$userId';
}
