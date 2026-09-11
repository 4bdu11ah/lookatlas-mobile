import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/features/create_content/presentation/controllers/create_content_controller.dart';

void main() {
  test('canvas zoom controls step, clamp, and fit', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(
      createContentControllerProvider.notifier,
    )..zoomCanvasIn();
    expect(container.read(createContentControllerProvider).canvasZoom, 1);

    controller.zoomCanvasOut();
    expect(container.read(createContentControllerProvider).canvasZoom, 0.9);

    controller.setCanvasZoom(10);
    expect(container.read(createContentControllerProvider).canvasZoom, 1.5);

    controller.setCanvasZoom(-10);
    expect(container.read(createContentControllerProvider).canvasZoom, 0.5);

    controller.fitCanvas();
    expect(container.read(createContentControllerProvider).canvasZoom, 0.94);
  });
}
