part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _ProductFormState {
  const _ProductFormState({
    this.productId,
    this.name = '',
    this.sku = '',
    this.description = '',
    this.category = 'Tops',
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
      (category != 'Bags' || subtype.trim().isNotEmpty);

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
    category: product?.category ?? 'Tops',
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
  void setCategory(String value) => state = state.copyWith(category: value);
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
  void removeExistingPhoto(int index) {
    final photos = [...state.existingPhotos]..removeAt(index);
    state = state.copyWith(
      existingPhotos: photos,
      removedPhotoIndexes: const {},
      angles: {
        for (final (newIndex, photo) in photos.indexed)
          newIndex: photo.viewAngle,
      },
      photoOrder: [
        for (final token in state.orderedPhotoTokens)
          if (token != 'existing:${state.existingPhotos[index].id}') token,
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

  Future<void> cropNewPhoto(int index) async {
    if (index < 0 || index >= state.newPhotos.length) return;
    final cropped = await _cropProductUploadToSquare(state.newPhotos[index]);
    final photos = [...state.newPhotos]..[index] = cropped;
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
    final viewAngles = product == null
        ? {
            for (final (displayIndex, token) in orderedTokens.indexed)
              displayIndex: token.startsWith('existing:')
                  ? state.angles[state.existingPhotos.indexWhere(
                      (photo) => photo.id == token.substring(9),
                    )]
                  : state.newAngles[state.newPhotos.indexWhere(
                      (photo) => photo.orderKey == token.substring(4),
                    )],
          }
        : {
            for (final (displayIndex, token) in orderedTokens.indexed)
              if (token.startsWith('new:'))
                displayIndex:
                    state.newAngles[state.newPhotos.indexWhere(
                      (photo) => photo.orderKey == token.substring(4),
                    )]
              else if (state.angles[state.existingPhotos.indexWhere(
                    (photo) => photo.id == token.substring(9),
                  )] !=
                  state.existingPhotos
                      .firstWhere((photo) => photo.id == token.substring(9))
                      .viewAngle)
                displayIndex:
                    state.angles[state.existingPhotos.indexWhere(
                      (photo) => photo.id == token.substring(9),
                    )],
          };
    final draft = CatalogProductDraft(
      name: state.name.trim(),
      sku: state.sku.trim(),
      description: state.description.trim(),
      category: state.category,
      subCategory: state.category == 'Bags' ? state.subtype : '',
      photos: orderedNewPhotos,
      viewAngles: viewAngles,
      existingPhotoOrder: [for (final photo in existing) photo.$2.id],
      existingPhotoAngles: {
        for (final photo in existing) photo.$2.id: state.angles[photo.$1],
      },
      photoOrder: [
        for (final token in orderedTokens)
          if (token.startsWith('existing:'))
            token.substring(9)
          else
            token.substring(4),
      ],
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
