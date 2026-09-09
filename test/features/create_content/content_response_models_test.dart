import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/features/create_content/data/models/content_response_models.dart';
import 'package:look_atlas/features/create_content/domain/entities/content_models.dart';

void main() {
  test('contentGenerationModel_validPayload_mapsDomainValues', () {
    final generation = ContentGenerationModel.fromJson({
      'id': 'generation-1',
      'format': 'single',
      'status': 'completed',
      'frames': <dynamic>[],
    }).toEntity();

    expect(generation.id, 'generation-1');
    expect(generation.format, ContentFormat.single);
    expect(generation.completed, isTrue);
  });

  test('contentGenerationModel_missingStatus_throwsFormatException', () {
    expect(
      () => ContentGenerationModel.fromJson({
        'id': 'generation-1',
        'format': 'single',
      }),
      throwsFormatException,
    );
  });

  test('contentExportTicketModel_sanitizesFileName_andRejectsBadUrl', () {
    final ticket = ContentExportTicketModel.fromJson({
      'url': 'https://assets.example/package.zip',
      'fileName': 'My package?.zip',
    }).toEntity();

    expect(ticket.fileName, 'My-package-.zip');
    expect(
      () => ContentExportTicketModel.fromJson({
        'url': 'file:///tmp/package.zip',
        'fileName': 'package.zip',
      }).toEntity(),
      throwsFormatException,
    );
  });
}
