import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:look_atlas/core/config/app_config.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/network/api_endpoints.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/products/domain/entities/product_catalog.dart';

abstract interface class ProductsRemoteDataSource {
  Future<Result<ProductCatalogPage>> getProducts(ProductQuery query);
  Future<Result<void>> createProduct(CatalogProductDraft draft);
  Future<Result<void>> updateProduct(
    String productId,
    CatalogProductDraft draft,
  );
  Future<Result<void>> updatePhotoAngles(
    String productId,
    Map<int, String?> angles,
  );
  Future<Result<void>> deleteProduct(String productId);
  Future<Result<void>> deletePhoto(String productId, int photoIndex);
  Future<Result<void>> replacePhoto(
    String productId,
    String photoId,
    ProductUpload photo,
  );
  Future<Result<List<CalibrationOutline>>> getCalibrationOutlines();
  Future<Result<ProductCalibration>> getCalibration(String productId);
  Future<Result<List<ProductCatalogItem>>> getCalibratedProducts();
  Future<Result<void>> uploadWornPhoto(
    String productId,
    ProductUpload photo,
  );
  Future<Result<void>> uploadCutout(
    String productId,
    ProductUpload photo,
  );
  Future<Result<void>> saveCalibration(
    String productId,
    ProductCalibrationDraft calibration,
  );
  Future<Result<void>> copyCalibration(
    String targetProductId,
    String sourceProductId,
  );
}

class ProductsRemoteDataSourceImpl implements ProductsRemoteDataSource {
  const ProductsRemoteDataSourceImpl({
    required ApiService api,
    required ApiService publicApi,
  }) : _api = api,
       _publicApi = publicApi;

  final ApiService _api;
  final ApiService _publicApi;

  @override
  Future<Result<ProductCatalogPage>> getProducts(ProductQuery query) =>
      _api.get<ProductCatalogPage>(
        ApiEndpoints.products,
        queryParameters: query.toQueryParameters(),
        decoder: _decodePage,
      );

  @override
  Future<Result<void>> createProduct(CatalogProductDraft draft) async {
    final created = await _api.post<void>(
      ApiEndpoints.products,
      data: _productFormData(draft, includeAngles: true),
      decoder: (_) {},
    );
    final existingProductId = _duplicateSkuProductId(created.failureOrNull);
    if (existingProductId == null) return created;
    final retried = await updateProduct(existingProductId, draft);
    if (!retried.isOk || draft.viewAngles.isEmpty) return retried;
    return updatePhotoAngles(existingProductId, draft.viewAngles);
  }

  @override
  Future<Result<void>> updateProduct(
    String productId,
    CatalogProductDraft draft,
  ) => _api.put<void>(
    ApiEndpoints.product(productId),
    data: _productFormData(draft, includeAngles: false),
    decoder: (_) {},
  );

  @override
  Future<Result<void>> updatePhotoAngles(
    String productId,
    Map<int, String?> angles,
  ) => _api.patch<void>(
    ApiEndpoints.productPhotoAngles(productId),
    data: {
      'angles': {
        for (final entry in angles.entries) '${entry.key}': entry.value,
      },
    },
    decoder: (_) {},
  );

  @override
  Future<Result<void>> deleteProduct(String productId) => _api.delete<void>(
    ApiEndpoints.product(productId),
    decoder: (_) {},
  );

  @override
  Future<Result<void>> deletePhoto(String productId, int photoIndex) =>
      _api.delete<void>(
        ApiEndpoints.productPhoto(productId, photoIndex),
        decoder: (_) {},
      );

  @override
  Future<Result<void>> replacePhoto(
    String productId,
    String photoId,
    ProductUpload photo,
  ) => _api.post<void>(
    ApiEndpoints.replaceProductPhoto(productId, photoId),
    data: _singleUpload('photo', photo),
    decoder: (_) {},
  );

  @override
  Future<Result<List<CalibrationOutline>>>
  getCalibrationOutlines() => _publicApi.get<List<CalibrationOutline>>(
    ApiEndpoints.calibrationOutlines,
    decoder: (data) => [
      for (final item in _items(data, const ['outlines']))
        if (item is Map<String, dynamic>)
          CalibrationOutline(
            id: _string(
              item['bodyArea'] ??
                  item['body_area'] ??
                  item['id'] ??
                  item['value'],
            ),
            name: _string(
              item['name'] ?? item['label'],
              fallback: 'Body view',
            ),
            imageUrl:
                _absoluteUrl(
                  _nullableString(item['imageUrl'] ?? item['image_url']),
                ) ??
                _absoluteUrl(
                  '${ApiEndpoints.calibrationOutlines}/${_string(item['bodyArea'] ?? item['body_area'] ?? item['id'] ?? item['value'])}.png',
                ),
          ),
    ],
  );

  @override
  Future<Result<ProductCalibration>> getCalibration(String productId) =>
      _api.get<ProductCalibration>(
        ApiEndpoints.productCalibration(productId),
        decoder: _decodeCalibration,
      );

  @override
  Future<Result<List<ProductCatalogItem>>> getCalibratedProducts() =>
      _api.get<List<ProductCatalogItem>>(
        ApiEndpoints.calibratedProducts,
        decoder: (data) => [
          for (final item in _items(
            data,
            const ['products', 'calibratedProducts', 'ids'],
          ))
            if (item is Map<String, dynamic>)
              _decodeProduct(item)
            else if (item is String)
              ProductCatalogItem(
                id: item,
                name: 'Calibrated product',
                sku: '',
                category: '',
              ),
        ],
      );

  @override
  Future<Result<void>> uploadWornPhoto(
    String productId,
    ProductUpload photo,
  ) => _api.post<void>(
    ApiEndpoints.productCalibrationWornPhoto(productId),
    data: _singleUpload('file', photo),
    decoder: (_) {},
  );

  @override
  Future<Result<void>> uploadCutout(
    String productId,
    ProductUpload photo,
  ) => _api.post<void>(
    ApiEndpoints.productCalibrationCutout(productId),
    data: _singleUpload('file', photo),
    decoder: (_) {},
  );

  @override
  Future<Result<void>> saveCalibration(
    String productId,
    ProductCalibrationDraft calibration,
  ) => _api.put<void>(
    ApiEndpoints.productCalibration(productId),
    data: calibration.toJson(),
    decoder: (_) {},
  );

  @override
  Future<Result<void>> copyCalibration(
    String targetProductId,
    String sourceProductId,
  ) => _api.post<void>(
    ApiEndpoints.copyProductCalibration(targetProductId),
    data: {'sourceProductId': sourceProductId},
    decoder: (_) {},
  );

  static ProductCatalogPage _decodePage(dynamic data) {
    final root = _map(data);
    final nested = root['data'];
    final body = nested is Map<String, dynamic> ? nested : root;
    final pagination = _map(body['pagination']);
    final products = [
      for (final item in _items(body, const ['products']))
        if (item is Map<String, dynamic>) _decodeProduct(item),
    ];
    return ProductCatalogPage(
      products: products,
      page: _integer(pagination['page'], fallback: 1),
      limit: _integer(pagination['limit'], fallback: 20),
      total: _integer(pagination['total'], fallback: products.length),
      totalPages: _integer(pagination['totalPages'], fallback: 1),
    );
  }

  static ProductCatalogItem _decodeProduct(Map<String, dynamic> json) {
    final rawPhotos = json['photos'] as List? ?? const [];
    final photos = [
      for (final (index, raw) in rawPhotos.indexed) _decodePhoto(raw, index),
    ].nonNulls.toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return ProductCatalogItem(
      id: _string(json['id'] ?? json['_id'] ?? json['productId']),
      name: _string(json['name'], fallback: 'Untitled product'),
      sku: _string(json['sku']),
      description: _nullableString(json['description']),
      category: _string(json['category'], fallback: 'Other'),
      subCategory: _nullableString(
        json['subCategory'] ?? json['sub_category'],
      ),
      createdAt: _date(json['createdAt'] ?? json['created_at']),
      thumbnail: _absoluteUrl(
        _nullableString(json['thumbnail'] ?? json['thumbnailUrl']),
      ),
      photos: photos,
    );
  }

  static ProductPhoto? _decodePhoto(Object? raw, int index) {
    if (raw is String) {
      return ProductPhoto(
        id: '$index',
        url: _absoluteUrl(raw) ?? '',
        sortOrder: index,
      );
    }
    if (raw is! Map<String, dynamic>) return null;
    return ProductPhoto(
      id: _string(raw['id'] ?? raw['_id'], fallback: '$index'),
      url:
          _absoluteUrl(
            _nullableString(raw['url'] ?? raw['path'] ?? raw['thumbnail']),
          ) ??
          '',
      sortOrder: _integer(
        raw['sortOrder'] ?? raw['sort_order'],
        fallback: index,
      ),
      viewAngle: _nullableString(raw['viewAngle'] ?? raw['view_angle']),
    );
  }

  static ProductCalibration _decodeCalibration(dynamic data) {
    final body = _map(data);
    final nested = body['calibration'];
    final json = nested is Map<String, dynamic> ? nested : body;
    return ProductCalibration(
      bodyArea: _nullableString(json['bodyArea'] ?? json['body_area']),
      shapes: [
        for (final shape in _shapeItems(json['shapes']))
          if (shape is Map<String, dynamic>) shape,
      ],
      userNotes: _nullableString(json['userNotes'] ?? json['user_notes']),
      cutoutPlacement: _map(
        json['cutoutPlacement'] ?? json['cutout_placement'],
      ),
      wornPhotoUrl: _absoluteUrl(
        _nullableString(json['wornPhotoUrl'] ?? json['worn_photo_url']),
      ),
      cutoutUrl: _absoluteUrl(
        _nullableString(
          json['productCutoutUrl'] ??
              json['product_cutout_url'] ??
              json['cutoutUrl'] ??
              json['cutout_url'],
        ),
      ),
      hasLegacyShapes: _shapeItems(json['shapes']).isNotEmpty,
    );
  }

  static FormData _productFormData(
    CatalogProductDraft draft, {
    required bool includeAngles,
  }) {
    final data = FormData();
    data.fields
      ..add(MapEntry('name', draft.name))
      ..add(MapEntry('sku', draft.sku));
    if (draft.description.isNotEmpty) {
      data.fields.add(MapEntry('description', draft.description));
    }
    data.fields.add(MapEntry('category', draft.category.toLowerCase()));
    if (draft.subCategory.isNotEmpty) {
      data.fields.add(MapEntry('sub_category', draft.subCategory));
    }
    if (includeAngles && draft.viewAngles.isNotEmpty) {
      data.fields.add(
        MapEntry(
          'view_angles',
          jsonEncode([
            for (var index = 0; index < draft.viewAngles.length; index++)
              draft.viewAngles[index],
          ]),
        ),
      );
    }
    for (final photo in draft.photos) {
      data.files.add(MapEntry('photos', _multipart(photo)));
    }
    if (draft.photos.isNotEmpty) {
      data.fields.add(
        MapEntry(
          'photo_keys',
          jsonEncode([
            for (final (index, photo) in draft.photos.indexed)
              _photoKey(photo, index),
          ]),
        ),
      );
    }
    return data;
  }

  static String _photoKey(ProductUpload photo, int index) {
    var hash = 0;
    for (final byte in photo.bytes) {
      hash = (hash * 31 + byte) & 0x7fffffff;
    }
    return '${photo.fileName}-${photo.bytes.lengthInBytes}-$hash-$index';
  }

  static String? _duplicateSkuProductId(Failure? failure) {
    if (failure is! NetworkFailure ||
        failure.statusCode != 409 ||
        failure.code != 'DUPLICATE_SKU') {
      return null;
    }
    final response = (failure.cause as DioException?)?.response?.data;
    final error = _map(response)['error'];
    return error is Map<String, dynamic>
        ? _nullableString(error['existingProductId'])
        : null;
  }

  static FormData _singleUpload(String field, ProductUpload upload) =>
      FormData()..files.add(MapEntry(field, _multipart(upload)));

  static MultipartFile _multipart(ProductUpload upload) =>
      MultipartFile.fromBytes(
        upload.bytes,
        filename: upload.fileName,
        contentType: upload.fileName.toLowerCase().endsWith('.png')
            ? DioMediaType('image', 'png')
            : DioMediaType('image', 'jpeg'),
      );

  static List<dynamic> _items(dynamic data, List<String> keys) {
    if (data is List) return data;
    var body = _map(data);
    final nested = body['data'];
    if (nested is List) return nested;
    if (nested is Map<String, dynamic>) body = nested;
    for (final key in keys) {
      final value = body[key];
      if (value is List) return value;
    }
    return const [];
  }

  static List<dynamic> _shapeItems(Object? value) {
    if (value is List) return value;
    if (value is Map<String, dynamic> && value['shapes'] is List) {
      return value['shapes'] as List<dynamic>;
    }
    return const [];
  }

  static String? _absoluteUrl(String? value) {
    if (value == null || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri?.hasScheme ?? false) return value;
    return Uri.parse(AppConfig.apiBaseUrl).resolve(value).toString();
  }

  static Map<String, dynamic> _map(Object? data) =>
      data is Map<String, dynamic> ? data : const {};

  static String _string(Object? value, {String fallback = ''}) =>
      value is String && value.trim().isNotEmpty ? value.trim() : fallback;

  static String? _nullableString(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;

  static int _integer(Object? value, {int fallback = 0}) =>
      value is num ? value.round() : int.tryParse('$value') ?? fallback;

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
