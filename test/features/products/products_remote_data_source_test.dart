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

class _BytesAdapter implements HttpClientAdapter {
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromBytes(
      const [137, 80, 78, 71],
      200,
      headers: {
        Headers.contentTypeHeader: ['image/png'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

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
      'limit': 24,
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
      () => api.post<String>(
        ApiEndpoints.products,
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder] as JsonDecoder<String>;
      return Result.ok(decoder({'id': 'product-created'}));
    });
    when(
      () => api.put<void>(
        ApiEndpoints.product('product-1'),
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
        options: any(named: 'options'),
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
              () => api.post<String>(
                ApiEndpoints.products,
                data: captureAny(named: 'data'),
                decoder: any(named: 'decoder'),
                options: any(named: 'options'),
              ),
            ).captured.single
            as FormData;
    final updateData =
        verify(
              () => api.put<void>(
                ApiEndpoints.product('product-1'),
                data: captureAny(named: 'data'),
                decoder: any(named: 'decoder'),
                options: any(named: 'options'),
              ),
            ).captured.single
            as FormData;

    expect(Map<String, String>.fromEntries(createData.fields), {
      'name': 'Canvas Bag',
      'sku': 'BAG-1',
      'description': 'Natural canvas',
      'category': 'bags',
      'sub_category': 'crossbody',
      'view_angles': '["front","side"]',
      'photo_keys': '["photo121","photo261"]',
    });
    expect(createData.files.map((part) => part.key), ['photos', 'photos']);
    expect(
      createData.files.map((part) => part.value.contentType.toString()),
      ['image/png', 'image/jpeg'],
    );
    expect(Map<String, String>.fromEntries(updateData.fields), {
      'photo_keys': '["photo121","photo261"]',
      'view_angles': '["front","side"]',
    });
  });

  test('create_retries_duplicate_sku_with_existing_product_id', () async {
    final requestOptions = RequestOptions(path: ApiEndpoints.products);
    when(
      () => api.post<String>(
        ApiEndpoints.products,
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
        options: any(named: 'options'),
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
        options: any(named: 'options'),
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
        options: any(named: 'options'),
      ),
    ).called(1);
  });

  test('update_sends_saved_photo_order_and_new_photo_fields', () async {
    when(
      () => api.put<void>(
        ApiEndpoints.product('product-1'),
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));
    final draft = CatalogProductDraft(
      name: 'Canvas Bag',
      sku: 'BAG-1',
      category: 'Bags',
      subCategory: 'Crossbody',
      existingPhotoOrder: const ['saved-front', 'saved-back'],
      existingPhotoOrderChanged: true,
      photos: [
        ProductUpload(
          bytes: Uint8List.fromList([1, 2]),
          fileName: 'detail.png',
          localKey: 'new-detail',
        ),
      ],
      viewAngles: const {0: 'Side'},
    );

    await dataSource.updateProduct('product-1', draft);

    final formData =
        verify(
              () => api.put<void>(
                ApiEndpoints.product('product-1'),
                data: captureAny(named: 'data'),
                decoder: any(named: 'decoder'),
                options: any(named: 'options'),
              ),
            ).captured.single
            as FormData;
    expect(
      Map<String, String>.fromEntries(formData.fields),
      containsPair(
        'existingPhotosOrder',
        '[{"id":"saved-front","sortOrder":0},{"id":"saved-back","sortOrder":1}]',
      ),
    );
    expect(
      Map<String, String>.fromEntries(formData.fields),
      containsPair('view_angles', '["Side"]'),
    );
    final photoKeys = (Map<String, String>.fromEntries(
      formData.fields,
    )['photo_keys']!).replaceAll(RegExp('[\\[\\]"]'), '').split(',');
    expect(photoKeys, everyElement(matches(RegExp(r'^[A-Za-z0-9]{1,32}$'))));
  });

  test(
    'update_only_sends_changed_values_and_complete_saved_photo_data',
    () async {
      when(
        () => api.put<void>(
          ApiEndpoints.product('product-1'),
          data: any(named: 'data'),
          decoder: any(named: 'decoder'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => const Result.ok(null));
      const draft = CatalogProductDraft(
        name: 'Unchanged name',
        sku: 'NEW-SKU',
        description: '',
        category: 'Bags',
        subCategory: 'Other Bag',
        changedFields: {'sku', 'description', 'sub_category'},
        existingPhotoOrder: ['photo-2', 'photo-1'],
        existingPhotoAngles: {'photo-2': 'Side', 'photo-1': null},
        existingPhotoOrderChanged: true,
        existingPhotoAnglesChanged: true,
      );

      await dataSource.updateProduct('product-1', draft);

      final formData =
          verify(
                () => api.put<void>(
                  ApiEndpoints.product('product-1'),
                  data: captureAny(named: 'data'),
                  decoder: any(named: 'decoder'),
                  options: any(named: 'options'),
                ),
              ).captured.single
              as FormData;
      expect(Map<String, String>.fromEntries(formData.fields), {
        'sku': 'NEW-SKU',
        'description': '',
        'sub_category': 'other_bag',
        'existingPhotosOrder':
            '[{"id":"photo-2","sortOrder":0},{"id":"photo-1","sortOrder":1}]',
        'existing_photo_angles': '[{"id":"photo-2","viewAngle":"Side"},{"id":"photo-1","viewAngle":null}]',
      });
      expect(formData.files, isEmpty);
    },
  );

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
      'photo-1': 'Front',
      'photo-2': null,
    });
    await dataSource.deleteProduct('product-1');
    await dataSource.deletePhoto('product-1', 'photo-2');
    await dataSource.replacePhoto('product-1', 'photo-1', upload);

    verify(
      () => api.patch<void>(
        ApiEndpoints.productPhotoAngles('product-1'),
        data: {
          'photos': [
            {'id': 'photo-1', 'viewAngle': 'Front'},
            {'id': 'photo-2', 'viewAngle': null},
          ],
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
    expect(calibration.revision, 3);
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
    when(
      () => api.delete<void>(
        ApiEndpoints.productCalibrationWornPhoto('product-1'),
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
      revision: 3,
      mutationId: 'mutation-1',
    );
    await dataSource.deleteWornPhoto(
      'product-1',
      const CalibrationMutationFence(
        calibrationId: 'calibration-1',
        revision: 3,
        mutationId: 'mutation-delete',
      ),
    );
    await dataSource.saveCalibration(
      'product-1',
      const ProductCalibrationDraft(
        bodyArea: 'full_body_front',
        shapes: [],
        userNotes: 'Medium size',
        cutoutPlacement: {'x': 0.5, 'y': 0.5, 'scale': 1.0},
      ),
    );
    await dataSource.copyCalibration(
      'product-1',
      'product-2',
      const CalibrationMutationFence(
        calibrationId: 'calibration-1',
        revision: 3,
        mutationId: 'mutation-2',
      ),
    );

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
    expect(wornData.files.single.key, 'file');
    expect(wornQuery, {
      'expectedCalibrationId': 'calibration-1',
      'expectedRevision': 3,
      'mutationId': 'mutation-1',
    });
    verify(
      () => api.delete<void>(
        ApiEndpoints.productCalibrationWornPhoto('product-1'),
        data: {
          'expectedCalibrationId': 'calibration-1',
          'expectedRevision': 3,
          'mutationId': 'mutation-delete',
        },
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
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
        data: {
          'sourceProductId': 'product-2',
          'expectedCalibrationId': 'calibration-1',
          'expectedRevision': 3,
          'mutationId': 'mutation-2',
        },
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

  test('first calibration mutation fence preserves absent baseline', () {
    const fence = CalibrationMutationFence(
      calibrationId: null,
      revision: null,
      mutationId: 'mutation-first',
    );

    expect(fence.toJson(), {
      'expectedCalibrationId': null,
      'expectedRevision': null,
      'mutationId': 'mutation-first',
    });
  });

  test('calibration_statuses_decode_every_library_state', () async {
    when(
      () => api.get<Map<String, ProductCalibrationStatus>>(
        ApiEndpoints.calibratedProducts,
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder]
              as JsonDecoder<Map<String, ProductCalibrationStatus>>;
      return Result.ok(
        decoder({
          'statuses': {
            'product-1': 'fit_rendering',
            'product-2': {'status': 'changes_pending'},
          },
        }),
      );
    });

    final statuses = (await dataSource.getCalibrationStatuses()).valueOrNull!;

    expect(statuses['product-1'], ProductCalibrationStatus.fitRendering);
    expect(statuses['product-2'], ProductCalibrationStatus.changesPending);
  });

  test('placement_upload_is_atomic_and_fenced', () async {
    when(
      () => api.post<void>(
        ApiEndpoints.productCalibrationPlacement('product-1'),
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));
    final upload = ProductUpload(
      bytes: Uint8List.fromList([1, 2]),
      fileName: 'cutout.png',
    );

    await dataSource.uploadPlacement(
      'product-1',
      upload,
      const {
        'bodyArea': 'full_body_front',
        'placement': {'x': 500, 'y': 750},
      },
      const CalibrationMutationFence(
        calibrationId: 'calibration-1',
        revision: 3,
        mutationId: 'mutation-placement',
      ),
    );

    final formData =
        verify(
              () => api.post<void>(
                ApiEndpoints.productCalibrationPlacement('product-1'),
                data: captureAny(named: 'data'),
                decoder: any(named: 'decoder'),
              ),
            ).captured.single
            as FormData;
    expect(formData.files.single.key, 'file');
    expect(formData.fields.single.key, 'payload');
    expect(formData.fields.single.value, contains('mutation-placement'));
    expect(formData.fields.single.value, contains('full_body_front'));
  });

  test('background_removal_fallback_posts_image_and_returns_png', () async {
    final adapter = _BytesAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter;
    when(() => api.raw).thenReturn(dio);
    final source = ProductUpload(
      bytes: Uint8List.fromList([1, 2, 3]),
      fileName: 'source.jpg',
      localKey: 'photo-1',
    );

    final result = await dataSource.removeBackgroundFallback(
      'product-1',
      source,
    );

    expect(result.valueOrNull?.bytes, const [137, 80, 78, 71]);
    expect(result.valueOrNull?.fileName, 'product-1-cutout.png');
    expect(result.valueOrNull?.localKey, 'photo-1');
    expect(
      adapter.request?.path,
      ApiEndpoints.productCalibrationBackgroundRemoval('product-1'),
    );
    final form = adapter.request?.data as FormData;
    expect(form.files.single.key, 'file');
    dio.close(force: true);
  });

  test('fit_render_contract_decodes_and_fences_mutations', () async {
    when(
      () => api.post<CalibrationRender>(
        ApiEndpoints.productCalibrationRender('product-1'),
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder] as JsonDecoder<CalibrationRender>;
      return Result.ok(
        decoder({
          'render': {
            'id': 'render-1',
            'status': 'completed',
            'imageUrl': '/fit.png',
            'bodyPreset': 'Female',
          },
        }),
      );
    });
    when(
      () => api.post<void>(
        ApiEndpoints.approveProductCalibrationRender('product-1'),
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));

    final render = (await dataSource.startCalibrationRender(
      'product-1',
      bodyPreset: 'Female',
      feedback: 'Longer hem',
      previousRenderId: 'render-0',
      mutationId: 'mutation-render',
    )).valueOrNull!;
    const fence = CalibrationMutationFence(
      calibrationId: 'calibration-1',
      revision: 3,
      mutationId: 'mutation-approve',
    );
    await dataSource.approveCalibrationRender(
      'product-1',
      render.id,
      fence,
    );

    expect(render.isApprovalEligible, isTrue);
    verify(
      () => api.post<CalibrationRender>(
        ApiEndpoints.productCalibrationRender('product-1'),
        data: {
          'bodyPreset': 'female',
          'feedback': 'Longer hem',
          'previousRenderId': 'render-0',
          'mutationId': 'mutation-render',
        },
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
    verify(
      () => api.post<void>(
        ApiEndpoints.approveProductCalibrationRender('product-1'),
        data: {
          'renderId': 'render-1',
          'expectedCalibrationId': 'calibration-1',
          'expectedRevision': 3,
          'mutationId': 'mutation-approve',
        },
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
  });
}
