import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:look_atlas/core/constants/app_assets.dart';
import 'package:look_atlas/core/logging/app_logger.dart';
import 'package:look_atlas/features/workshop/data/workshop_mock_data.dart';
import 'package:look_atlas/features/workshop/domain/entities/workshop_models.dart';
import 'package:look_atlas/shared/image_picker/image_picker_providers.dart';

class WorkshopController extends Notifier<WorkshopState> {
  static const double _pickMaxWidth = 1600;
  static const int _pickQuality = 85;

  int _nextReferenceId = 0;

  @override
  WorkshopState build() {
    return WorkshopState.initial().copyWith(history: initialWorkshopHistory);
  }

  void unlock() {
    state = state.copyWith(isUnlocked: true, validationMessage: null);
  }

  Future<void> pickBaseImageFrom(ImageSource source) async {
    try {
      final image = await ref
          .read(imagePickerProvider)
          .pickImage(
            source: source,
            maxWidth: _pickMaxWidth,
            imageQuality: _pickQuality,
          );
      if (image == null) return;
      final orientation = await _readOrientation(image);
      state = state.copyWith(
        baseImage: WorkshopBaseImage(
          source: image.path,
          orientation: orientation,
        ),
        editMode: WorkshopEditMode.lock,
        resultImage: null,
        validationMessage: null,
      );
    } on Exception catch (error) {
      AppLogger.warning('Workshop base image pick failed: $error');
      state = state.copyWith(
        validationMessage: 'Could not open your camera or photo library.',
      );
    }
  }

  void useResultAsBase() {
    final result = state.resultImage;
    if (result == null) return;
    state = state.copyWith(
      baseImage: WorkshopBaseImage(source: result),
      editMode: WorkshopEditMode.lock,
      resultImage: null,
      validationMessage: null,
    );
  }

  void removeBaseImage() {
    state = state.copyWith(
      baseImage: null,
      resultImage: null,
      validationMessage: null,
    );
  }

  void setMode(WorkshopEditMode mode) {
    state = state.copyWith(editMode: mode);
  }

  void updatePrompt(String prompt) {
    state = state.copyWith(prompt: prompt, validationMessage: null);
  }

  Future<void> addReferenceFrom(ImageSource source) async {
    if (state.referenceLimitReached) return;
    try {
      final image = await ref
          .read(imagePickerProvider)
          .pickImage(
            source: source,
            maxWidth: _pickMaxWidth,
            imageQuality: _pickQuality,
          );
      if (image == null || state.referenceLimitReached) return;
      _nextReferenceId++;
      final reference = WorkshopSample(
        id: 'picked-reference-$_nextReferenceId',
        label: 'Reference ${state.references.length + 1}',
        asset: image.path,
      );
      state = state.copyWith(
        references: [...state.references, reference],
        validationMessage: null,
      );
    } on Exception catch (error) {
      AppLogger.warning('Workshop reference pick failed: $error');
      state = state.copyWith(
        validationMessage: 'Could not open your camera or photo library.',
      );
    }
  }

  void removeReference(String id) {
    state = state.copyWith(
      references: [
        for (final reference in state.references)
          if (reference.id != id) reference,
      ],
    );
  }

  Future<bool> generate() async {
    if (!state.hasBaseImage) {
      state = state.copyWith(
        validationMessage: 'Upload a base image before generating.',
      );
      return false;
    }
    if (!state.hasPrompt) {
      state = state.copyWith(
        validationMessage: 'Write a prompt so Workshop knows what to change.',
      );
      return false;
    }
    if (!state.isUnlocked || state.isGenerating) return false;

    state = state.copyWith(isGenerating: true, validationMessage: null);
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    final result = _pickResultImage(state.history.length);
    final item = WorkshopHistoryItem(
      id: 'generated-${state.history.length + 1}',
      image: result,
      prompt: state.prompt.trim(),
      createdAtLabel: 'Just now',
    );
    state = state.copyWith(
      isGenerating: false,
      resultImage: result,
      history: [item, ...state.history],
      selectedHistoryIndex: 0,
    );
    return true;
  }

  void selectHistory(int index) {
    if (index < 0 || index >= state.history.length) return;
    state = state.copyWith(
      selectedHistoryIndex: index,
      resultImage: state.history[index].image,
    );
  }

  String _pickResultImage(int offset) {
    const images = [
      AppAssets.showcaseDressAfter,
      AppAssets.showcaseTshirtAfter,
      AppAssets.showcaseShoesAfter,
      AppAssets.showcaseBagAfter,
    ];
    return images[offset % images.length];
  }

  Future<WorkshopImageOrientation> _readOrientation(XFile image) async {
    final bytes = await image.readAsBytes();
    final dimensions = _readPngDimensions(bytes) ?? _readJpegDimensions(bytes);
    if (dimensions == null) throw const FormatException('Unknown image format');
    return WorkshopImageOrientation.fromDimensions(
      dimensions.width,
      dimensions.height,
    );
  }

  ({int width, int height})? _readPngDimensions(Uint8List bytes) {
    if (bytes.length < 24 ||
        bytes[0] != 0x89 ||
        bytes[1] != 0x50 ||
        bytes[2] != 0x4E ||
        bytes[3] != 0x47 ||
        bytes[4] != 0x0D ||
        bytes[5] != 0x0A ||
        bytes[6] != 0x1A ||
        bytes[7] != 0x0A) {
      return null;
    }
    final data = ByteData.sublistView(bytes);
    final width = data.getUint32(16);
    final height = data.getUint32(20);
    return width == 0 || height == 0 ? null : (width: width, height: height);
  }

  ({int width, int height})? _readJpegDimensions(Uint8List bytes) {
    if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) return null;
    var offset = 2;
    while (offset + 8 < bytes.length) {
      while (offset < bytes.length && bytes[offset] == 0xFF) {
        offset++;
      }
      if (offset >= bytes.length) return null;
      final marker = bytes[offset++];
      if (marker == 0xD9 || marker == 0xDA || offset + 1 >= bytes.length) {
        return null;
      }
      final segmentLength = (bytes[offset] << 8) | bytes[offset + 1];
      if (segmentLength < 2 || offset + segmentLength > bytes.length) {
        return null;
      }
      if (_isJpegStartOfFrame(marker)) {
        if (segmentLength < 7) return null;
        final height = (bytes[offset + 3] << 8) | bytes[offset + 4];
        final width = (bytes[offset + 5] << 8) | bytes[offset + 6];
        return width == 0 || height == 0
            ? null
            : (width: width, height: height);
      }
      offset += segmentLength;
    }
    return null;
  }

  bool _isJpegStartOfFrame(int marker) {
    return switch (marker) {
      0xC0 ||
      0xC1 ||
      0xC2 ||
      0xC3 ||
      0xC5 ||
      0xC6 ||
      0xC7 ||
      0xC9 ||
      0xCA ||
      0xCB ||
      0xCD ||
      0xCE ||
      0xCF => true,
      _ => false,
    };
  }
}

final workshopControllerProvider =
    NotifierProvider<WorkshopController, WorkshopState>(
      WorkshopController.new,
    );
