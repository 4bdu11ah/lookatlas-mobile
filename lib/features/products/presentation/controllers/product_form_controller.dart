part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _ProductFormState {
  const _ProductFormState({
    this.productId,
    this.name = '',
    this.sku = '',
    this.description = '',
    this.category = 'Other',
    this.subtype = '',
    this.existingPhotos = const [],
    this.replacementPhotos = const {},
    this.replacingPhotoId,
    this.newPhotos = const [],
    this.removedPhotoIndexes = const {},
    this.angles = const {},
    this.newAngles = const {},
    this.photoOrder = const [],
    this.isSubmitting = false,
  });

  final String? productId;
  final String name;
  final String sku;
  final String description;
  final String category;
  final String subtype;
  final List<ProductPhoto> existingPhotos;
  final Map<String, ProductUpload> replacementPhotos;
  final String? replacingPhotoId;
  final List<ProductUpload> newPhotos;
  final Set<int> removedPhotoIndexes;
  final Map<int, String?> angles;
  final Map<int, String?> newAngles;
  final List<String> photoOrder;
  final bool isSubmitting;

  List<(int, ProductPhoto)> get visibleExistingPhotos => [
    for (final token in orderedPhotoTokens)
      if (token.startsWith('existing:'))
        for (final entry in existingPhotos.indexed)
          if (entry.$2.id == token.substring(9) &&
              !removedPhotoIndexes.contains(entry.$1))
            entry,
  ];
  List<String> get orderedPhotoTokens => photoOrder.isEmpty
      ? [
          for (final photo in existingPhotos) 'existing:${photo.id}',
          for (final photo in newPhotos) 'new:${photo.orderKey}',
        ]
      : photoOrder;
  int get photoCount => visibleExistingPhotos.length + newPhotos.length;
  bool get isValid =>
      name.trim().isNotEmpty &&
      sku.trim().isNotEmpty &&
      photoCount > 0 &&
      (!const {'Bags', 'Jewelry'}.contains(category) ||
          subtype.trim().isNotEmpty);

  _ProductFormState copyWith({
    String? name,
    String? sku,
    String? description,
    String? category,
    String? subtype,
    List<ProductPhoto>? existingPhotos,
    Map<String, ProductUpload>? replacementPhotos,
    String? replacingPhotoId,
    bool clearReplacingPhotoId = false,
    List<ProductUpload>? newPhotos,
    Set<int>? removedPhotoIndexes,
    Map<int, String?>? angles,
    Map<int, String?>? newAngles,
    List<String>? photoOrder,
    bool? isSubmitting,
  }) => _ProductFormState(
    productId: productId,
    name: name ?? this.name,
    sku: sku ?? this.sku,
    description: description ?? this.description,
    category: category ?? this.category,
    subtype: subtype ?? this.subtype,
    existingPhotos: existingPhotos ?? this.existingPhotos,
    replacementPhotos: replacementPhotos ?? this.replacementPhotos,
    replacingPhotoId: clearReplacingPhotoId
        ? null
        : replacingPhotoId ?? this.replacingPhotoId,
    newPhotos: newPhotos ?? this.newPhotos,
    removedPhotoIndexes: removedPhotoIndexes ?? this.removedPhotoIndexes,
    angles: angles ?? this.angles,
    newAngles: newAngles ?? this.newAngles,
    photoOrder: photoOrder ?? this.photoOrder,
    isSubmitting: isSubmitting ?? this.isSubmitting,
  );
}

class _ProductFormController extends Notifier<_ProductFormState> {
  _ProductFormController(this.product);

  final _Product? product;

  @override
  _ProductFormState build() => _ProductFormState(
    productId: product?.id,
    name: product?.name ?? '',
    sku: product?.sku ?? '',
    description: product?.description ?? '',
    category: product?.category ?? 'Other',
    subtype: product?.subtype ?? '',
    existingPhotos: product?.productPhotos ?? const [],
    photoOrder: [
      for (final photo in product?.productPhotos ?? const <ProductPhoto>[])
        'existing:${photo.id}',
    ],
    angles: {
      for (final (index, photo) in (product?.productPhotos ?? const []).indexed)
        index: photo.viewAngle,
    },
  );

  void setName(String value) => state = state.copyWith(name: value);
  void setSku(String value) => state = state.copyWith(sku: value);
  void setDescription(String value) =>
      state = state.copyWith(description: value);
  void setCategory(String value) => state = state.copyWith(
    category: value,
    subtype: value == state.category ? state.subtype : '',
  );
  void setSubtype(String value) => state = state.copyWith(subtype: value);
  void addPhotos(List<ProductUpload> photos) => state = state.copyWith(
    newPhotos: [...state.newPhotos, ...photos],
    photoOrder: [
      ...state.orderedPhotoTokens,
      for (final photo in photos) 'new:${photo.orderKey}',
    ],
  );
  void clearNewPhotos() => state = state.copyWith(
    newPhotos: const [],
    newAngles: const {},
    photoOrder: [
      for (final token in state.orderedPhotoTokens)
        if (token.startsWith('existing:')) token,
    ],
  );
  void removeNewPhoto(int index) {
    if (index < 0 || index >= state.newPhotos.length) return;
    final removed = state.newPhotos[index];
    final photos = [...state.newPhotos]..removeAt(index);
    final angles = <int, String?>{
      for (final (newIndex, _) in photos.indexed)
        newIndex: state.newAngles[newIndex >= index ? newIndex + 1 : newIndex],
    };
    state = state.copyWith(
      newPhotos: photos,
      newAngles: angles,
      photoOrder: [
        for (final token in state.orderedPhotoTokens)
          if (token != 'new:${removed.orderKey}') token,
      ],
    );
  }

  void removeExistingPhoto(int index) {
    if (index < 0 || index >= state.existingPhotos.length) return;
    final removed = state.existingPhotos[index];
    final photos = [...state.existingPhotos]..removeAt(index);
    state = state.copyWith(
      existingPhotos: photos,
      removedPhotoIndexes: const {},
      angles: {
        for (final (newIndex, photo) in photos.indexed)
          newIndex:
              state.angles[state.existingPhotos.indexWhere(
                (existing) => existing.id == photo.id,
              )],
      },
      replacementPhotos: {
        for (final entry in state.replacementPhotos.entries)
          if (entry.key != removed.id) entry.key: entry.value,
      },
      photoOrder: [
        for (final token in state.orderedPhotoTokens)
          if (token != 'existing:${removed.id}') token,
      ],
    );
  }

  void movePhoto(String token, int delta) {
    final order = [...state.orderedPhotoTokens];
    final index = order.indexOf(token);
    final target = index + delta;
    if (index < 0 || target < 0 || target >= order.length) return;
    order.insert(target, order.removeAt(index));
    state = state.copyWith(photoOrder: order);
  }

  void replaceNewPhoto(int index, ProductUpload cropped) {
    if (index < 0 || index >= state.newPhotos.length) return;
    final original = state.newPhotos[index];
    final photos = [...state.newPhotos]
      ..[index] = ProductUpload(
        bytes: cropped.bytes,
        fileName: cropped.fileName,
        path: cropped.path,
        localKey: original.orderKey,
      );
    state = state.copyWith(newPhotos: photos);
  }

  void replaceExistingPhoto(ProductPhoto photo, ProductUpload replacement) =>
      state = state.copyWith(
        replacementPhotos: {...state.replacementPhotos, photo.id: replacement},
      );
  void setReplacingPhoto(String photoId) =>
      state = state.copyWith(replacingPhotoId: photoId);
  void clearReplacingPhoto() =>
      state = state.copyWith(clearReplacingPhotoId: true);
  void setAngle(int index, String? value) =>
      state = state.copyWith(angles: {...state.angles, index: value});
  void setNewAngle(int index, String? value) =>
      state = state.copyWith(newAngles: {...state.newAngles, index: value});

  String? _normalizedAngle(String? value) {
    if (value == null) return null;
    final cleaned = value.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
    if (cleaned.isEmpty) return null;
    return cleaned.substring(0, min(cleaned.length, 40));
  }

  Future<Result<void>?> submit(_Product? product) async {
    if (state.isSubmitting || !state.isValid) return null;
    state = state.copyWith(isSubmitting: true);
    final existing = state.visibleExistingPhotos;
    final orderedTokens = state.orderedPhotoTokens;
    final orderedNewPhotos = [
      for (final token in orderedTokens)
        if (token.startsWith('new:'))
          for (final photo in state.newPhotos)
            if (photo.orderKey == token.substring(4)) photo,
    ];
    final viewAngles = {
      for (final (uploadIndex, photo) in orderedNewPhotos.indexed)
        uploadIndex: _normalizedAngle(
          state.newAngles[state.newPhotos.indexWhere(
            (candidate) => candidate.orderKey == photo.orderKey,
          )],
        ),
    };
    final existingPhotoOrder = [for (final photo in existing) photo.$2.id];
    final originalPhotoOrder = [
      for (final photo in product?.productPhotos ?? const <ProductPhoto>[])
        photo.id,
    ];
    final existingPhotoAngles = {
      for (final photo in existing)
        photo.$2.id: _normalizedAngle(state.angles[photo.$1]),
    };
    final existingPhotoAnglesChanged =
        product != null &&
        existingPhotoAngles.entries.any(
          (entry) =>
              product.productPhotos
                  .firstWhere((photo) => photo.id == entry.key)
                  .viewAngle !=
              entry.value,
        );
    final subCategory = switch (state.category) {
      'Bags' || 'Jewelry' => state.subtype,
      _ => '',
    };
    final draft = CatalogProductDraft(
      name: state.name.trim(),
      sku: state.sku.trim(),
      description: state.description.trim(),
      category: state.category,
      subCategory: subCategory,
      photos: orderedNewPhotos,
      viewAngles: viewAngles,
      existingPhotoOrder: existingPhotoOrder,
      existingPhotoAngles: existingPhotoAngles,
      photoOrder: [
        for (final token in orderedTokens)
          if (token.startsWith('existing:'))
            token.substring(9)
          else
            token.substring(4),
      ],
      changedFields: product == null
          ? const {}
          : {
              if (state.name.trim() != product.name) 'name',
              if (state.sku.trim() != product.sku) 'sku',
              if (state.description.trim() != product.description)
                'description',
              if (state.category != product.category) 'category',
              if (subCategory != (product.subtype ?? '')) 'sub_category',
            },
      existingPhotoOrderChanged:
          product != null &&
          !listEquals(existingPhotoOrder, originalPhotoOrder),
      existingPhotoAnglesChanged: existingPhotoAnglesChanged,
    );
    final products = ref.read(_productsControllerProvider.notifier);
    final result = product == null
        ? await products.createProduct(draft)
        : await products.updateProduct(product, draft);
    if (!result.isOk) state = state.copyWith(isSubmitting: false);
    return result;
  }
}

// Riverpod's family provider type is inferred from the factory.
// ignore: specify_nonobvious_property_types
final _productFormProvider = NotifierProvider.autoDispose
    .family<_ProductFormController, _ProductFormState, _Product?>(
      _ProductFormController.new,
    );
