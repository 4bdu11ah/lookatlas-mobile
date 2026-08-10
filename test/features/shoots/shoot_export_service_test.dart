import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/features/shoots/domain/entities/shoot_job.dart';
import 'package:look_atlas/features/shoots/presentation/services/shoot_export_service.dart';

void main() {
  test('buildCsv_escapes_values_and_uses_export_columns', () {
    const job = ShootJob(
      id: 'job-1',
      name: 'Summer Bag',
      status: 'completed',
      renders: 1,
      date: null,
      productThumbnail: '',
      modelThumbnail: '',
      productSku: 'BAG-104',
      modelName: 'Mila',
      preset: 'Clean, Pro',
      aspectRatio: '4:5',
    );
    const image = ShootImage(
      id: 'image-1',
      url: 'https://example.com/image.jpg',
      shotIndex: 1,
      variationIndex: 2,
      approved: true,
    );

    final csv = const ShootExportService().buildCsv(job, [image]);

    expect(
      csv,
      contains(
        '"sku","model","preset","shot","aspect_ratio","variation","url"',
      ),
    );
    expect(csv, contains('"Clean, Pro"'));
    expect(csv, contains('"2","4:5","3"'));
  });
}
