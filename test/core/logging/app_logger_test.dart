import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/logging/app_logger.dart';

void main() {
  test('chunkMessage_longMessage_preservesEveryCharacter', () {
    final message = List.generate(5000, (index) => '$index|').join();

    final chunks = AppLogger.chunkMessage(message);

    expect(chunks, isNotEmpty);
    expect(chunks.every((chunk) => chunk.length <= 800), isTrue);
    expect(chunks.join(), message);
  });

  test('chunkMessage_unicode_doesNotSplitSurrogatePairs', () {
    const message = '1234567🚀remaining';

    final chunks = AppLogger.chunkMessage(message, chunkSize: 8);

    expect(chunks.join(), message);
    expect(chunks.first, '1234567');
    expect(chunks[1], startsWith('🚀'));
  });

  test('frameMessage_addsTimedStartAndEndSeparators', () {
    final output = AppLogger.frameMessage(
      '[DEBUG] response body',
      timestamp: DateTime(2026, 8, 12, 13, 5, 7),
    );

    expect(
      output.first,
      '<-------------------- START 01:05:07 PM -------------------->',
    );
    expect(output[1], '[DEBUG] response body');
    expect(
      output.last,
      '<-------------------- END 01:05:07 PM -------------------->',
    );
  });

  test('frameMessage_convertsHourFourteenToTwoPm', () {
    final output = AppLogger.frameMessage(
      'message',
      timestamp: DateTime(2026, 8, 12, 14, 6, 8),
    );

    expect(output.first, contains('START 02:06:08 PM'));
    expect(output.last, contains('END 02:06:08 PM'));
  });

  test('formatLogLines_usesColorForEachLogLevel', () {
    const expectedColors = {
      'DEBUG': '\x1B[36m',
      'INFO': '\x1B[32m',
      'WARNING': '\x1B[33m',
      'ERROR': '\x1B[31m',
    };

    for (final entry in expectedColors.entries) {
      final output = AppLogger.formatLogLines(entry.key, 'message');

      expect(output.every((line) => line.startsWith(entry.value)), isTrue);
      expect(output.every((line) => line.endsWith('\x1B[0m')), isTrue);
      expect(output[1], contains('[${entry.key}] message'));
    }
  });
}
