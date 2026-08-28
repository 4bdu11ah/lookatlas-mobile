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
    this.limit = 20,
    this.search = '',
    this.category = '',
    this.sort = 'newest',
    this.calibration = '',
    this.calibratedIds = const {},
  });

  final int page;
  final int limit;
  final String search;
  final String category;
  final String sort;
  final String calibration;
  final Set<String> calibratedIds;

  Map<String, dynamic> toQueryParameters() => {
    'includePhotos': true,
    'page': page,
    'limit': limit,
    'search': search,
    'category': category,
    'sort': sort,
    'calibration': calibration,
    'calibratedIds': calibratedIds.join(','),
  };
}

@immutable
class ProductUpload {
  const ProductUpload({required this.bytes, required this.fileName, this.path});

  final Uint8List bytes;
  final String fileName;
  final String? path;
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
  });

  final String name;
  final String sku;
  final String description;
  final String category;
  final String subCategory;
  final List<ProductUpload> photos;
  final Map<int, String?> viewAngles;
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
  });

  final String bodyArea;
  final List<Map<String, dynamic>> shapes;
  final String? userNotes;
  final Map<String, dynamic>? cutoutPlacement;

  Map<String, dynamic> toJson() => {
    'bodyArea': bodyArea,
    'shapes': shapes,
    if (userNotes != null) 'userNotes': userNotes,
    if (cutoutPlacement != null) 'cutoutPlacement': cutoutPlacement,
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
