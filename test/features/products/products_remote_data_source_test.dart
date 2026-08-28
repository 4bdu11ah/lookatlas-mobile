import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/network/api_endpoints.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/products/data/data_sources/products_remote_data_source.dart';
import 'package:look_atlas/features/products/domain/entities/product_catalog.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiService extends Mock implements ApiService {}

void main() {
  late _MockApiService api;
  late _MockApiService publicApi;
  late ProductsRemoteDataSource dataSource;

  setUp(() {
    api = _MockApiService();
    publicApi = _MockApiService();
    dataSource = ProductsRemoteDataSourceImpl(
      api: api,
      publicApi: publicApi,
    );
  });

  test('get_products_sends_grid_query_and_decodes_catalog_page', () async {
    when(
      () => api.get<ProductCatalogPage>(
        ApiEndpoints.products,
        queryParameters: any(named: 'queryParameters'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder]
              as JsonDecoder<ProductCatalogPage>;
      return Result.ok(
        decoder({
          'products': [
            {
              'id': 'product-1',
              'name': 'Canvas Bag',
              'sku': 'BAG-1',
              'category': 'Bags',
              'sub_category': 'Crossbody',
              'thumbnail': '/thumb.jpg',
              'photos': [
                {
                  'id': 'photo-1',
                  'url': '/front.jpg',
                  'sort_order': 0,
                  'view_angle': 'front',
                },
              ],
            },
          ],
          'pagination': {
            'page': 2,
            'limit': 20,
            'total': 21,
            'totalPages': 2,
          },
        }),
      );
    });

    final page = (await dataSource.getProducts(
      const ProductQuery(
        page: 2,
        search: 'bag',
        category: 'Bags',
        sort: 'name_asc',
        calibration: 'calibrated',
        calibratedIds: {'product-1'},
      ),
    )).valueOrNull!;
    final query =
        verify(
              () => api.get<ProductCatalogPage>(
                ApiEndpoints.products,
                queryParameters: captureAny(named: 'queryParameters'),
                decoder: any(named: 'decoder'),
              ),
            ).captured.single
            as Map<String, dynamic>;

    expect(query, {
      'includePhotos': true,
      'page': 2,
      'limit': 20,
      'search': 'bag',
      'category': 'Bags',
      'sort': 'name_asc',
      'calibration': 'calibrated',
      'calibratedIds': 'product-1',
    });
    expect(page.total, 21);
    expect(page.products.single.subCategory, 'Crossbody');
    expect(page.products.single.photos.single.viewAngle, 'front');
    expect(page.products.single.imageUrl, endsWith('/thumb.jpg'));
  });

  test('create_and_update_send_documented_multipart_fields', () async {
    when(
      () => api.post<void>(
        ApiEndpoints.products,
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));
    when(
      () => api.put<void>(
        ApiEndpoints.product('product-1'),
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));
    final draft = CatalogProductDraft(
      name: 'Canvas Bag',
      sku: 'BAG-1',
      description: 'Natural canvas',
      category: 'Bags',
      subCategory: 'Crossbody',
      photos: [
        ProductUpload(
          bytes: Uint8List.fromList([1, 2]),
          fileName: 'front.png',
        ),
        ProductUpload(
          bytes: Uint8List.fromList([3, 4]),
          fileName: 'side.jpg',
        ),
      ],
      viewAngles: const {0: 'front', 1: 'side'},
    );

    await dataSource.createProduct(draft);
    await dataSource.updateProduct('product-1', draft);
    final createData =
        verify(
              () => api.post<void>(
                ApiEndpoints.products,
                data: captureAny(named: 'data'),
                decoder: any(named: 'decoder'),
              ),
            ).captured.single
            as FormData;
    final updateData =
        verify(
              () => api.put<void>(
                ApiEndpoints.product('product-1'),
                data: captureAny(named: 'data'),
                decoder: any(named: 'decoder'),
              ),
            ).captured.single
            as FormData;

    expect(Map<String, String>.fromEntries(createData.fields), {
      'name': 'Canvas Bag',
      'sku': 'BAG-1',
      'description': 'Natural canvas',
      'category': 'bags',
      'sub_category': 'Crossbody',
      'view_angles': '["front","side"]',
      'photo_keys': '["front.png-2-33-0","side.jpg-2-97-1"]',
    });
    expect(createData.files.map((part) => part.key), ['photos', 'photos']);
    expect(
      createData.files.map((part) => part.value.contentType.toString()),
      ['image/png', 'image/jpeg'],
    );
    expect(
      Map<String, String>.fromEntries(updateData.fields),
      isNot(contains('view_angles')),
    );
  });

  test('create_retries_duplicate_sku_with_existing_product_id', () async {
    final requestOptions = RequestOptions(path: ApiEndpoints.products);
    when(
      () => api.post<void>(
        ApiEndpoints.products,
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer(
      (_) async => Result.err(
        NetworkFailure(
          'Duplicate SKU',
          statusCode: 409,
          code: 'DUPLICATE_SKU',
          cause: DioException(
            requestOptions: requestOptions,
            response: Response<dynamic>(
              requestOptions: requestOptions,
              statusCode: 409,
              data: {
                'error': {
                  'code': 'DUPLICATE_SKU',
                  'existingProductId': 'existing-product',
                },
              },
            ),
          ),
        ),
      ),
    );
    when(
      () => api.put<void>(
        ApiEndpoints.product('existing-product'),
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));

    final result = await dataSource.createProduct(
      const CatalogProductDraft(
        name: 'Canvas Bag',
        sku: 'BAG-1',
        category: 'Bags',
      ),
    );

    expect(result.isOk, isTrue);
    verify(
      () => api.put<void>(
        ApiEndpoints.product('existing-product'),
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
  });

  test('product_photo_actions_use_documented_paths_and_payloads', () async {
    when(
      () => api.patch<void>(
        ApiEndpoints.productPhotoAngles('product-1'),
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));
    when(
      () => api.delete<void>(
        ApiEndpoints.product('product-1'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));
    when(
      () => api.delete<void>(
        ApiEndpoints.productPhoto('product-1', 'photo-2'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));
    when(
      () => api.post<void>(
        ApiEndpoints.replaceProductPhoto('product-1', 'photo-1'),
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));
    final upload = ProductUpload(
      bytes: Uint8List.fromList([1]),
      fileName: 'replacement.jpg',
    );

    await dataSource.updatePhotoAngles('product-1', const {
      0: 'front',
      1: null,
    });
    await dataSource.deleteProduct('product-1');
    await dataSource.deletePhoto('product-1', 'photo-2');
    await dataSource.replacePhoto('product-1', 'photo-1', upload);

    verify(
      () => api.patch<void>(
        ApiEndpoints.productPhotoAngles('product-1'),
        data: {
          'angles': {'0': 'front', '1': null},
        },
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
    verify(
      () => api.delete<void>(
        ApiEndpoints.product('product-1'),
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
    verify(
      () => api.delete<void>(
        ApiEndpoints.productPhoto('product-1', 'photo-2'),
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
    final replacement =
        verify(
              () => api.post<void>(
                ApiEndpoints.replaceProductPhoto('product-1', 'photo-1'),
                data: captureAny(named: 'data'),
                decoder: any(named: 'decoder'),
              ),
            ).captured.single
            as FormData;
    expect(replacement.files.single.key, 'photo');
  });

  test('calibration_load_calls_public_and_authenticated_endpoints', () async {
    when(
      () => publicApi.get<List<CalibrationOutline>>(
        ApiEndpoints.calibrationOutlines,
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder]
              as JsonDecoder<List<CalibrationOutline>>;
      return Result.ok(
        decoder({
          'outlines': [
            {'id': 'full_body_front', 'name': 'Full Body Front'},
          ],
        }),
      );
    });
    when(
      () => api.get<ProductCalibration>(
        ApiEndpoints.productCalibration('product-1'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder]
              as JsonDecoder<ProductCalibration>;
      return Result.ok(
        decoder({
          'calibration': {
            'id': 'calibration-1',
            'revision': 3,
            'bodyArea': 'full_body_front',
            'userNotes': 'Medium size',
            'productCutoutUrl': '/cutouts/product-1.png',
            'cutoutPlacement': {'x': 500, 'y': 750, 'w': 220, 'h': 260},
          },
        }),
      );
    });
    when(
      () => api.get<List<ProductCatalogItem>>(
        ApiEndpoints.calibratedProducts,
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder]
              as JsonDecoder<List<ProductCatalogItem>>;
      return Result.ok(
        decoder({
          'calibratedProducts': [
            {'id': 'product-2', 'name': 'Tote', 'sku': 'BAG-2'},
          ],
        }),
      );
    });

    final outlines = (await dataSource.getCalibrationOutlines()).valueOrNull!;
    final calibration = (await dataSource.getCalibration(
      'product-1',
    )).valueOrNull!;
    final products = (await dataSource.getCalibratedProducts()).valueOrNull!;

    expect(outlines.single.id, 'full_body_front');
    expect(calibration.userNotes, 'Medium size');
    expect(calibration.id, 'calibration-1');
    expect(calibration.revision, '3');
    expect(calibration.cutoutPlacement['w'], 220);
    expect(calibration.cutoutUrl, contains('/cutouts/product-1.png'));
    expect(calibration.hasPlacement, isTrue);
    expect(products.single.id, 'product-2');
  });

  test('calibration_mutations_send_upload_save_and_copy_requests', () async {
    when(
      () => api.post<void>(
        any(),
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));
    when(
      () => api.post<void>(
        ApiEndpoints.productCalibrationWornPhoto('product-1'),
        data: any(named: 'data'),
        queryParameters: any(named: 'queryParameters'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));
    when(
      () => api.put<void>(
        ApiEndpoints.productCalibration('product-1'),
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));
    final upload = ProductUpload(
      bytes: Uint8List.fromList([1]),
      fileName: 'reference.png',
    );

    await dataSource.uploadWornPhoto(
      'product-1',
      upload,
      calibrationId: 'calibration-1',
      revision: '3',
      mutationId: 'mutation-1',
    );
    await dataSource.uploadCutout('product-1', upload);
    await dataSource.saveCalibration(
      'product-1',
      const ProductCalibrationDraft(
        bodyArea: 'full_body_front',
        shapes: [],
        userNotes: 'Medium size',
        cutoutPlacement: {'x': 0.5, 'y': 0.5, 'scale': 1.0},
      ),
    );
    await dataSource.copyCalibration('product-1', 'product-2');

    final worn = verify(
      () => api.post<void>(
        ApiEndpoints.productCalibrationWornPhoto('product-1'),
        data: captureAny(named: 'data'),
        queryParameters: captureAny(named: 'queryParameters'),
        decoder: any(named: 'decoder'),
      ),
    ).captured;
    final wornData = worn[0] as FormData;
    final wornQuery = worn[1] as Map<String, dynamic>;
    final cutoutData =
        verify(
              () => api.post<void>(
                ApiEndpoints.productCalibrationCutout('product-1'),
                data: captureAny(named: 'data'),
                decoder: any(named: 'decoder'),
              ),
            ).captured.single
            as FormData;
    expect(wornData.files.single.key, 'file');
    expect(wornQuery, {
      'expectedCalibrationId': 'calibration-1',
      'expectedRevision': '3',
      'mutationId': 'mutation-1',
    });
    expect(cutoutData.files.single.key, 'file');
    verify(
      () => api.put<void>(
        ApiEndpoints.productCalibration('product-1'),
        data: {
          'bodyArea': 'full_body_front',
          'shapes': <Map<String, dynamic>>[],
          'userNotes': 'Medium size',
          'cutoutPlacement': {'x': 0.5, 'y': 0.5, 'scale': 1.0},
        },
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
    verify(
      () => api.post<void>(
        ApiEndpoints.copyProductCalibration('product-1'),
        data: {'sourceProductId': 'product-2'},
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
  });

  test('calibration_draft_omits_optional_values_for_notes_only_save', () {
    const draft = ProductCalibrationDraft(
      bodyArea: 'full_body_front',
      shapes: [],
    );

    expect(draft.toJson(), {
      'bodyArea': 'full_body_front',
      'shapes': <Map<String, dynamic>>[],
    });
  });
}
