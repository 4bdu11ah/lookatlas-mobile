import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/services/image_save_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/image_save');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('save_sends_sanitized_filename_bytes_and_mime_type', () async {
    MethodCall? captured;
    messenger.setMockMethodCallHandler(channel, (call) async {
      captured = call;
      return null;
    });
    const service = ImageSaveService(channel: channel);
    final bytes = Uint8List.fromList([1, 2, 3]);

    await service.save(bytes, fileName: 'Look Atlas / result.png');

    expect(captured?.method, 'save');
    final arguments = captured?.arguments as Map<Object?, Object?>;
    expect(arguments['bytes'], bytes);
    expect(arguments['fileName'], 'Look-Atlas-result.png');
    expect(arguments['mimeType'], 'image/png');
  });

  test('save_rejects_empty_images_without_calling_platform', () async {
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (_) async {
      calls++;
      return null;
    });
    const service = ImageSaveService(channel: channel);

    await expectLater(
      service.save(Uint8List(0), fileName: 'empty.jpg'),
      throwsArgumentError,
    );

    expect(calls, 0);
  });
}
