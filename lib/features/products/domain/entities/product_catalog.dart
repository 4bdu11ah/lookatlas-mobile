import 'package:flutter/foundation.dart';

@immutable
class ProductPhoto {
  const ProductPhoto({
    required this.id,
    required this.url,
    required this.sortOrder,
    this.viewAngle,
  });

  final String id;
  final String url;
  final int sortOrder;
  final String? viewAngle;
}

@immutable
class ProductCatalogItem {
  const ProductCatalogItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    this.description,
    this.subCategory,
    this.createdAt,
    this.thumbnail,
    this.photos = const [],
  });

  final String id;
  final String name;
  final String sku;
  final String category;
  final String? description;
  final String? subCategory;
  final DateTime? createdAt;
  final String? thumbnail;
  final List<ProductPhoto> photos;

  String get imageUrl => thumbnail ?? (photos.isEmpty ? '' : photos.first.url);
}

@immutable
class ProductCatalogPage {
  const ProductCatalogPage({
    required this.products,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<ProductCatalogItem> products;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
}

@immutable
class ProductQuery {
  const ProductQuery({
    this.page = 1,
    this.limit = 24,
    this.search = '',
    this.category = '',
    this.sort = 'newest',
    this.calibration = '',
    this.calibratedIds = const {},
    this.productId,
  });

  final int page;
  final int limit;
  final String search;
  final String category;
  final String sort;
  final String calibration;
  final Set<String> calibratedIds;
  final String? productId;

  Map<String, dynamic> toQueryParameters() => {
    'includePhotos': true,
    'page': page,
    'limit': limit,
    'search': search,
    'category': category,
    'sort': sort,
    'calibration': calibration,
    'calibratedIds': calibratedIds.join(','),
    'productId': ?productId,
  };
}

// API spec names this shared limit in SCREAMING_SNAKE_CASE.
// ignore: constant_identifier_names
const int PRODUCT_PHOTO_UPLOAD_MAX_BYTES = 20 * 1024 * 1024;
// API spec names this shared limit in SCREAMING_SNAKE_CASE.
// ignore: constant_identifier_names
const int PRODUCT_PHOTO_UPLOAD_MAX_COUNT = 8;

enum ProductCalibrationStatus {
  calibrated,
  changesPending,
  fitRendering,
  fitReady,
  fitFailed,
  fitPending,
  saveReady,
  recommended,
  optional;

  static ProductCalibrationStatus fromWire(String? value) => switch (value) {
    'calibrated' => calibrated,
    'changes_pending' => changesPending,
    'fit_rendering' => fitRendering,
    'fit_ready' => fitReady,
    'fit_failed' => fitFailed,
    'fit_pending' => fitPending,
    'save_ready' => saveReady,
    'optional' => optional,
    _ => recommended,
  };

  String get label => switch (this) {
    calibrated => 'Size calibrated',
    changesPending => 'Size calibrated · changes pending',
    fitRendering => 'Fit rendering',
    fitReady => 'Review Fit',
    fitFailed => 'Retry Fit',
    fitPending => 'Finish Fit',
    saveReady => 'Review changes',
    recommended => 'Calibrate size',
    optional => 'Calibrate size',
  };

  bool get needsPolling => this == fitRendering || this == fitPending;
  bool get isCalibrated => this == calibrated || this == changesPending;
}

@immutable
class ProductCalibrationStatusSummary {
  const ProductCalibrationStatusSummary({
    required this.productId,
    required this.status,
  });

  final String productId;
  final ProductCalibrationStatus status;
}

enum CalibrationRenderStatus {
  queued,
  processing,
  completed,
  failed;

  static CalibrationRenderStatus fromWire(String? value) => switch (value) {
    'completed' => completed,
    'failed' => failed,
    'processing' || 'rendering' => processing,
    _ => queued,
  };

  bool get isPending => this == queued || this == processing;
}

@immutable
class CalibrationRender {
  const CalibrationRender({
    required this.id,
    required this.status,
    this.imageUrl,
    this.bodyPreset,
    this.feedback,
    this.previousRenderId,
    this.createdAt,
  });

  final String id;
  final CalibrationRenderStatus status;
  final String? imageUrl;
  final String? bodyPreset;
  final String? feedback;
  final String? previousRenderId;
  final DateTime? createdAt;

  bool get isApprovalEligible =>
      status == CalibrationRenderStatus.completed && imageUrl != null;
}

@immutable
class CalibrationMutationFence {
  const CalibrationMutationFence({
    required this.calibrationId,
    required this.revision,
    required this.mutationId,
  });

  final String? calibrationId;
  final String? revision;
  final String mutationId;

  Map<String, dynamic> toJson() => {
    'expectedCalibrationId': calibrationId,
    'expectedRevision': revision,
    'mutationId': mutationId,
  };
}

@immutable
class ProductUpload {
  const ProductUpload({
    required this.bytes,
    required this.fileName,
    this.path,
    this.localKey,
  });

  final Uint8List bytes;
  final String fileName;
  final String? path;
  final String? localKey;

  String get orderKey {
    if (localKey != null) return localKey!;
    var hash = 0;
    for (final byte in bytes) {
      hash = (hash * 31 + byte) & 0x7fffffff;
    }
    return '$fileName-${bytes.lengthInBytes}-$hash';
  }
}

@immutable
class CatalogProductDraft {
  const CatalogProductDraft({
    required this.name,
    required this.sku,
    required this.category,
    this.description = '',
    this.subCategory = '',
    this.photos = const [],
    this.viewAngles = const {},
    this.existingPhotoOrder = const [],
    this.existingPhotoAngles = const {},
    this.photoOrder = const [],
  });

  final String name;
  final String sku;
  final String description;
  final String category;
  final String subCategory;
  final List<ProductUpload> photos;
  final Map<int, String?> viewAngles;
  final List<String> existingPhotoOrder;
  final Map<String, String?> existingPhotoAngles;
  final List<String> photoOrder;
}

@immutable
class CalibrationOutline {
  const CalibrationOutline({
    required this.id,
    required this.name,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String? imageUrl;
}

@immutable
class ProductCalibration {
  const ProductCalibration({
    this.id,
    this.revision,
    this.bodyArea,
    this.shapes = const [],
    this.userNotes,
    this.cutoutPlacement = const {},
    this.wornPhotoUrl,
    this.cutoutUrl,
    this.status = ProductCalibrationStatus.recommended,
    this.activeRenderId,
    this.hasLegacyShapes = false,
  });

  final String? id;
  final String? revision;
  final String? bodyArea;
  final List<Map<String, dynamic>> shapes;
  final String? userNotes;
  final Map<String, dynamic> cutoutPlacement;
  final String? wornPhotoUrl;
  final String? cutoutUrl;
  final ProductCalibrationStatus status;
  final String? activeRenderId;
  final bool hasLegacyShapes;

  bool get hasPlacement => cutoutPlacement.isNotEmpty && cutoutUrl != null;
  bool get isLegacyOnly =>
      hasLegacyShapes && !hasPlacement && wornPhotoUrl == null;
}

@immutable
class ProductCalibrationDraft {
  const ProductCalibrationDraft({
    required this.bodyArea,
    required this.shapes,
    this.userNotes,
    this.cutoutPlacement,
    this.fence,
  });

  final String bodyArea;
  final List<Map<String, dynamic>> shapes;
  final String? userNotes;
  final Map<String, dynamic>? cutoutPlacement;
  final CalibrationMutationFence? fence;

  Map<String, dynamic> toJson() => {
    'bodyArea': bodyArea,
    'shapes': shapes,
    if (userNotes != null) 'userNotes': userNotes,
    if (cutoutPlacement != null) 'cutoutPlacement': cutoutPlacement,
    if (fence != null) ...fence!.toJson(),
  };
}

@immutable
class ProductCalibrationWorkspace {
  const ProductCalibrationWorkspace({
    required this.outlines,
    required this.calibration,
    required this.calibratedProducts,
  });

  final List<CalibrationOutline> outlines;
  final ProductCalibration calibration;
  final List<ProductCatalogItem> calibratedProducts;
}
