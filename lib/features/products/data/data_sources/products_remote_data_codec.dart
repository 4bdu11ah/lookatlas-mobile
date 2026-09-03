part of 'products_remote_data_source.dart';

ProductCatalogPage _decodePage(dynamic data) {
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

ProductCatalogItem _decodeProduct(Map<String, dynamic> json) {
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

ProductPhoto? _decodePhoto(Object? raw, int index) {
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

ProductCalibration _decodeCalibration(dynamic data) {
  final body = _map(data);
  final nested = body['calibration'];
  final json = nested is Map<String, dynamic> ? nested : body;
  return ProductCalibration(
    id: _nullableValueString(
      json['id'] ?? json['calibrationId'] ?? json['calibration_id'],
    ),
    revision: _integerOrNull(json['revision']),
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
    status: ProductCalibrationStatus.fromWire(
      _nullableString(
        json['status'] ??
            json['calibrationStatus'] ??
            json['calibration_status'],
      ),
    ),
    activeRenderId: _nullableValueString(
      json['activeRenderId'] ?? json['active_render_id'],
    ),
    hasLegacyShapes: _shapeItems(json['shapes']).isNotEmpty,
    candidateState: CalibrationCandidateState.fromWire(
      _nullableString(json['candidateState'] ?? json['candidate_state']),
    ),
    renderStatus: CalibrationReferenceStatus.fromWire(
      _nullableString(json['renderStatus'] ?? json['render_status']),
    ),
  );
}

Map<String, ProductCalibrationStatus> _decodeCalibrationStatuses(
  dynamic data,
) {
  final root = _map(data);
  final nested = _map(root['data']);
  final raw = root['statuses'] ?? nested['statuses'];
  if (raw is Map) {
    return {
      for (final entry in raw.entries)
        entry.key.toString(): ProductCalibrationStatus.fromWire(
          entry.value is Map
              ? _nullableString(
                  (entry.value as Map)['status'] ??
                      (entry.value as Map)['calibrationStatus'],
                )
              : _nullableString(entry.value),
        ),
    };
  }
  return {
    for (final item in _items(data, const ['products']))
      if (item is Map<String, dynamic>)
        _string(
          item['id'] ?? item['_id'] ?? item['productId'],
        ): ProductCalibrationStatus.fromWire(
          _nullableString(
                item['status'] ??
                    item['calibrationStatus'] ??
                    item['calibration_status'],
              ) ??
              'calibrated',
        ),
  }..remove('');
}

CalibrationRender _decodeRender(dynamic data) {
  final root = _map(data);
  final nested = root['render'];
  final json = nested is Map<String, dynamic> ? nested : root;
  return CalibrationRender(
    id: _string(json['id'] ?? json['_id'] ?? json['renderId']),
    status: CalibrationRenderStatus.fromWire(
      _nullableString(json['status']),
    ),
    imageUrl: _absoluteUrl(
      _nullableString(
        json['imageUrl'] ?? json['image_url'] ?? json['outputUrl'],
      ),
    ),
    bodyPreset: _nullableString(json['bodyPreset'] ?? json['body_preset']),
    feedback: _nullableString(json['feedback']),
    previousRenderId: _nullableValueString(
      json['previousRenderId'] ?? json['previous_render_id'],
    ),
    createdAt: _date(json['createdAt'] ?? json['created_at']),
    isStale: json['isStale'] == true || json['is_stale'] == true,
    approvalAllowed:
        (json['approvalEligible'] ?? json['approval_eligible']) as bool?,
    refundStatus: _nullableString(
      json['refundStatus'] ?? json['refund_status'],
    ),
    version: _integerOrNull(json['version']),
  );
}

FormData _productFormData(
  CatalogProductDraft draft, {
  bool forUpdate = false,
}) {
  final data = FormData();
  bool includes(String field) =>
      !forUpdate || draft.changedFields.contains(field);
  if (includes('name')) data.fields.add(MapEntry('name', draft.name));
  if (includes('sku')) data.fields.add(MapEntry('sku', draft.sku));
  if (includes('description')) {
    data.fields.add(MapEntry('description', draft.description));
  }
  if (includes('category')) {
    data.fields.add(MapEntry('category', draft.category.trim().toLowerCase()));
  }
  if (includes('sub_category')) {
    data.fields.add(
      MapEntry(
        'sub_category',
        draft.subCategory.trim().toLowerCase().replaceAll(
          RegExp('[- ]+'),
          '_',
        ),
      ),
    );
  }
  if (forUpdate && draft.existingPhotoOrderChanged) {
    data.fields.add(
      MapEntry(
        'existingPhotosOrder',
        jsonEncode([
          for (final (sortOrder, id) in draft.existingPhotoOrder.indexed)
            {'id': id, 'sortOrder': sortOrder},
        ]),
      ),
    );
  }
  if (forUpdate && draft.existingPhotoAnglesChanged) {
    data.fields.add(
      MapEntry(
        'existing_photo_angles',
        jsonEncode([
          for (final entry in draft.existingPhotoAngles.entries)
            {'id': entry.key, 'viewAngle': entry.value},
        ]),
      ),
    );
  }
  for (final photo in draft.photos) {
    data.files.add(MapEntry('photos', _multipart(photo)));
  }
  if (draft.photos.isNotEmpty) {
    final photoKeys = [
      for (final (index, photo) in draft.photos.indexed)
        _photoKey(photo, index),
    ];
    data.fields
      ..add(MapEntry('photo_keys', jsonEncode(photoKeys)))
      ..add(
        MapEntry(
          'view_angles',
          jsonEncode([
            for (var index = 0; index < draft.photos.length; index++)
              draft.viewAngles[index],
          ]),
        ),
      );
  }
  return data;
}

String _photoKey(ProductUpload photo, int index) {
  var hash = 0;
  for (final byte in photo.bytes) {
    hash = (hash * 31 + byte) & 0x7fffffff;
  }
  return 'photo${index + 1}${hash.toRadixString(16)}';
}

String? _duplicateSkuProductId(Failure? failure) {
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

FormData _singleUpload(String field, ProductUpload upload) =>
    FormData()..files.add(MapEntry(field, _multipart(upload)));

MultipartFile _multipart(ProductUpload upload) => MultipartFile.fromBytes(
  upload.bytes,
  filename: upload.fileName,
  contentType: switch (upload.fileName.split('.').last.toLowerCase()) {
    'png' => DioMediaType('image', 'png'),
    'webp' => DioMediaType('image', 'webp'),
    _ => DioMediaType('image', 'jpeg'),
  },
);

Options _uploadOptions(CatalogProductDraft draft) {
  final totalBytes = draft.photos.fold<int>(
    0,
    (total, photo) => total + photo.bytes.lengthInBytes,
  );
  final transferSeconds = (totalBytes / (512 * 1024)).ceil();
  final seconds = (120 + transferSeconds).clamp(120, 600);
  return Options(
    sendTimeout: Duration(seconds: seconds),
    receiveTimeout: Duration(seconds: seconds),
  );
}

List<dynamic> _items(dynamic data, List<String> keys) {
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

List<dynamic> _shapeItems(Object? value) {
  if (value is List) return value;
  if (value is Map<String, dynamic> && value['shapes'] is List) {
    return value['shapes'] as List<dynamic>;
  }
  return const [];
}

String? _absoluteUrl(String? value) {
  if (value == null || value.isEmpty) return null;
  final uri = Uri.tryParse(value);
  if (uri?.hasScheme ?? false) return value;
  return Uri.parse(AppConfig.apiBaseUrl).resolve(value).toString();
}

Map<String, dynamic> _map(Object? data) =>
    data is Map<String, dynamic> ? data : const {};

String _string(Object? value, {String fallback = ''}) =>
    value is String && value.trim().isNotEmpty ? value.trim() : fallback;

String? _nullableString(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;

String? _nullableValueString(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

int _integer(Object? value, {int fallback = 0}) =>
    value is num ? value.round() : int.tryParse('$value') ?? fallback;

int? _integerOrNull(Object? value) => switch (value) {
  final num number => number.round(),
  final String text => int.tryParse(text),
  _ => null,
};

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
