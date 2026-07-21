import 'package:flutter/foundation.dart';

@immutable
class ShootSettings {
  const ShootSettings({
    required this.aspectRatio,
    this.useCase = 'pdp',
    this.directorId = 'clean-pro',
    this.background = 'ai_decide',
  });

  final String useCase;
  final String directorId;
  final String background;
  final String aspectRatio;
}

enum ShootModelSource { lookatlas, user }

@immutable
class StartShootRequest {
  const StartShootRequest({
    required this.productId,
    required this.modelId,
    required this.modelSource,
    required this.settings,
    this.deviceFingerprint,
    this.deviceToken,
    this.uaFamily,
    this.screenHash,
    this.tzOffset,
  });

  final String productId;
  final String modelId;
  final ShootModelSource modelSource;
  final ShootSettings settings;
  final String? deviceFingerprint;
  final String? deviceToken;
  final String? uaFamily;
  final String? screenHash;
  final int? tzOffset;
}

@immutable
class StartShootResponse {
  const StartShootResponse({
    required this.id,
    required this.status,
    required this.message,
    required this.shotCount,
    required this.variations,
    required this.totalImages,
    this.estimatedCompletion,
  });

  final String id;
  final String status;
  final String message;
  final DateTime? estimatedCompletion;
  final int shotCount;
  final int variations;
  final int totalImages;
}
