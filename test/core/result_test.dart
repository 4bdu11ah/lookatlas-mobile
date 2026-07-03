import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';

void main() {
  group('Result', () {
    test('Ok exposes value and folds to the ok branch', () {
      const result = Result<int>.ok(42);

      expect(result.isOk, isTrue);
      expect(result.isErr, isFalse);
      expect(result.valueOrNull, 42);
      expect(result.failureOrNull, isNull);
      expect(result.fold((v) => v * 2, (_) => -1), 84);
    });

    test('Err exposes failure and folds to the err branch', () {
      const failure = AuthFailure('nope');
      const result = Result<int>.err(failure);

      expect(result.isErr, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, same(failure));
      expect(result.fold((_) => 'ok', (f) => f.message), 'nope');
    });

    test('map transforms Ok and preserves Err', () {
      expect(const Result<int>.ok(2).map((v) => v + 1).valueOrNull, 3);

      const failure = NetworkFailure('boom');
      final mapped = const Result<int>.err(failure).map((v) => v + 1);
      expect(mapped.failureOrNull, same(failure));
    });
  });
}
