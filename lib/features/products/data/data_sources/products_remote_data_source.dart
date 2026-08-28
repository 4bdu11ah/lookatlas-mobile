import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:look_atlas/core/config/app_config.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/network/api_endpoints.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/products/domain/entities/product_catalog.dart';

part 'products_remote_data_codec.dart';

abstract interface class ProductsRemoteDataSource {
  Future<Result<ProductCatalogPage>> getProducts(ProductQuery query);
  Future<Result<String>> createProduct(CatalogProductDraft draft);
  Future<Result<void>> updateProduct(
    String productId,
    CatalogProductDraft draft,
  );
  Future<Result<void>> updatePhotoAngles(
    String productId,
    Map<Object, String?> angles,
  );
  Future<Result<void>> deleteProduct(String productId);
  Future<Result<void>> deletePhoto(String productId, String photoId);
  Future<Result<void>> replacePhoto(
    String productId,
    String photoId,
    ProductUpload photo,
  );
  Future<Result<List<CalibrationOutline>>> getCalibrationOutlines();
  Future<Result<ProductCalibration>> getCalibration(String productId);
  Future<Result<List<ProductCatalogItem>>> getCalibratedProducts();
  Future<Result<Map<String, ProductCalibrationStatus>>>
  getCalibrationStatuses();
  Future<Result<void>> uploadWornPhoto(
    String productId,
    ProductUpload photo, {
    required String? calibrationId,
    required String? revision,
    required String mutationId,
  });
  Future<Result<void>> deleteWornPhoto(
    String productId,
    CalibrationMutationFence fence,
  );
  Future<Result<void>> uploadPlacement(
    String productId,
    ProductUpload cutout,
    Map<String, dynamic> placement,
    CalibrationMutationFence fence,
  );
  Future<Result<CalibrationRender>> startCalibrationRender(
    String productId, {
    required String bodyPreset,
    required String mutationId,
    String? feedback,
    String? previousRenderId,
  });
  Future<Result<CalibrationRender?>> getLatestCalibrationRender(
    String productId,
  );
  Future<Result<List<CalibrationRender>>> getCalibrationRenders(
    String productId,
  );
  Future<Result<void>> approveCalibrationRender(
    String productId,
    String renderId,
    CalibrationMutationFence fence,
  );
  Future<Result<void>> promoteCalibrationCandidate(
    String productId,
    CalibrationMutationFence fence,
  );
  Future<Result<void>> discardCalibrationCandidate(
    String productId,
    CalibrationMutationFence fence,
  );
  Future<Result<void>> saveCalibration(
    String productId,
    ProductCalibrationDraft calibration,
  );
  Future<Result<void>> copyCalibration(
    String targetProductId,
    String sourceProductId,
    CalibrationMutationFence fence,
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
  Future<Result<String>> createProduct(CatalogProductDraft draft) async {
    final created = await _api.post<String>(
      ApiEndpoints.products,
      data: _productFormData(draft, includeAngles: true),
      options: _uploadOptions(draft),
      decoder: (data) {
        final root = _map(data);
        final nested = _map(root['data']);
        return _string(root['id'] ?? nested['id'] ?? root['productId']);
      },
    );
    if (created case Ok(:final value) when value.isEmpty) {
      return const Err(
        ValidationFailure('Product was saved, but its id was missing.'),
      );
    }
    final existingProductId = _duplicateSkuProductId(created.failureOrNull);
    if (existingProductId == null) return created;
    final retried = await updateProduct(existingProductId, draft);
    if (retried case Err(:final failure)) return Err(failure);
    if (draft.viewAngles.isNotEmpty) {
      final angles = await updatePhotoAngles(
        existingProductId,
        draft.viewAngles,
      );
      if (angles case Err(:final failure)) return Err(failure);
    }
    return Ok(existingProductId);
  }

  @override
  Future<Result<void>> updateProduct(
    String productId,
    CatalogProductDraft draft,
  ) => _api.put<void>(
    ApiEndpoints.product(productId),
    data: _productFormData(draft, includeAngles: false),
    options: _uploadOptions(draft),
    decoder: (_) {},
  );

  @override
  Future<Result<void>> updatePhotoAngles(
    String productId,
    Map<Object, String?> angles,
  ) => _api.patch<void>(
    ApiEndpoints.productPhotoAngles(productId),
    data: {
      'angles': {
        for (final entry in angles.entries) '${entry.key}': entry.value,
      },
      'photos': [
        for (final entry in angles.entries)
          if (entry.key is String) {'id': entry.key, 'viewAngle': entry.value},
      ],
    },
    decoder: (_) {},
  );

  @override
  Future<Result<void>> deleteProduct(String productId) => _api.delete<void>(
    ApiEndpoints.product(productId),
    decoder: (_) {},
  );

  @override
  Future<Result<void>> deletePhoto(String productId, String photoId) =>
      _api.delete<void>(
        ApiEndpoints.productPhoto(productId, photoId),
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
  Future<Result<Map<String, ProductCalibrationStatus>>>
  getCalibrationStatuses() => _api.get<Map<String, ProductCalibrationStatus>>(
    ApiEndpoints.calibratedProducts,
    decoder: _decodeCalibrationStatuses,
  );

  @override
  Future<Result<void>> uploadWornPhoto(
    String productId,
    ProductUpload photo, {
    required String? calibrationId,
    required String? revision,
    required String mutationId,
  }) => _api.post<void>(
    ApiEndpoints.productCalibrationWornPhoto(productId),
    data: _singleUpload('file', photo),
    queryParameters: {
      'expectedCalibrationId': calibrationId,
      'expectedRevision': revision,
      'mutationId': mutationId,
    },
    decoder: (_) {},
  );

  @override
  Future<Result<void>> deleteWornPhoto(
    String productId,
    CalibrationMutationFence fence,
  ) => _api.delete<void>(
    ApiEndpoints.productCalibrationWornPhoto(productId),
    data: fence.toJson(),
    decoder: (_) {},
  );

  @override
  Future<Result<void>> uploadPlacement(
    String productId,
    ProductUpload cutout,
    Map<String, dynamic> placement,
    CalibrationMutationFence fence,
  ) {
    final data = FormData()
      ..fields.add(
        MapEntry('payload', jsonEncode({...placement, ...fence.toJson()})),
      )
      ..files.add(MapEntry('file', _multipart(cutout)));
    return _api.post<void>(
      ApiEndpoints.productCalibrationPlacement(productId),
      data: data,
      decoder: (_) {},
    );
  }

  @override
  Future<Result<CalibrationRender>> startCalibrationRender(
    String productId, {
    required String bodyPreset,
    required String mutationId,
    String? feedback,
    String? previousRenderId,
  }) => _api.post<CalibrationRender>(
    ApiEndpoints.productCalibrationRender(productId),
    data: {
      'bodyPreset': bodyPreset,
      'feedback': ?feedback,
      'previousRenderId': ?previousRenderId,
      'mutationId': mutationId,
    },
    decoder: _decodeRender,
  );

  @override
  Future<Result<CalibrationRender?>> getLatestCalibrationRender(
    String productId,
  ) => _api.get<CalibrationRender?>(
    ApiEndpoints.productCalibrationLatestRender(productId),
    decoder: (data) {
      final root = _map(data);
      final render = root['render'] ?? _map(root['data'])['render'];
      return render is Map<String, dynamic> ? _decodeRender(render) : null;
    },
  );

  @override
  Future<Result<List<CalibrationRender>>> getCalibrationRenders(
    String productId,
  ) => _api.get<List<CalibrationRender>>(
    ApiEndpoints.productCalibrationRenders(productId),
    decoder: (data) => [
      for (final item in _items(data, const ['renders']))
        if (item is Map<String, dynamic>) _decodeRender(item),
    ],
  );

  @override
  Future<Result<void>> approveCalibrationRender(
    String productId,
    String renderId,
    CalibrationMutationFence fence,
  ) => _api.post<void>(
    ApiEndpoints.approveProductCalibrationRender(productId),
    data: {'renderId': renderId, ...fence.toJson()},
    decoder: (_) {},
  );

  @override
  Future<Result<void>> promoteCalibrationCandidate(
    String productId,
    CalibrationMutationFence fence,
  ) => _api.post<void>(
    ApiEndpoints.promoteProductCalibrationCandidate(productId),
    data: fence.toJson(),
    decoder: (_) {},
  );

  @override
  Future<Result<void>> discardCalibrationCandidate(
    String productId,
    CalibrationMutationFence fence,
  ) => _api.post<void>(
    ApiEndpoints.discardProductCalibrationCandidate(productId),
    data: fence.toJson(),
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
    CalibrationMutationFence fence,
  ) => _api.post<void>(
    ApiEndpoints.copyProductCalibration(targetProductId),
    data: {'sourceProductId': sourceProductId, ...fence.toJson()},
    decoder: (_) {},
  );
}
