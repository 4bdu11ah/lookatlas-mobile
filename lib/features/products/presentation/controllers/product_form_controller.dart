part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _ProductFormState {
  const _ProductFormState({
    this.productId,
    this.name = '',
    this.sku = '',
    this.description = '',
    this.category = 'Tops',
    this.subtype = 'Crossbody',
    this.existingPhotos = const [],
    this.newPhotos = const [],
    this.removedPhotoIndexes = const {},
    this.angles = const {},
    this.newAngles = const {},
    this.isSubmitting = false,
  });

  final String? productId;
  final String name;
  final String sku;
  final String description;
  final String category;
  final String subtype;
  final List<ProductPhoto> existingPhotos;
  final List<ProductUpload> newPhotos;
  final Set<int> removedPhotoIndexes;
  final Map<int, String?> angles;
  final Map<int, String?> newAngles;
  final bool isSubmitting;

  List<(int, ProductPhoto)> get visibleExistingPhotos => [
    for (final (index, photo) in existingPhotos.indexed)
      if (!removedPhotoIndexes.contains(index)) (index, photo),
  ];
  int get photoCount => visibleExistingPhotos.length + newPhotos.length;
  bool get isValid =>
      name.trim().isNotEmpty && sku.trim().isNotEmpty && photoCount > 0;

  _ProductFormState copyWith({
    String? name,
    String? sku,
    String? description,
    String? category,
    String? subtype,
    List<ProductPhoto>? existingPhotos,
    List<ProductUpload>? newPhotos,
    Set<int>? removedPhotoIndexes,
    Map<int, String?>? angles,
    Map<int, String?>? newAngles,
    bool? isSubmitting,
  }) => _ProductFormState(
    productId: productId,
    name: name ?? this.name,
    sku: sku ?? this.sku,
    description: description ?? this.description,
    category: category ?? this.category,
    subtype: subtype ?? this.subtype,
    existingPhotos: existingPhotos ?? this.existingPhotos,
    newPhotos: newPhotos ?? this.newPhotos,
    removedPhotoIndexes: removedPhotoIndexes ?? this.removedPhotoIndexes,
    angles: angles ?? this.angles,
    newAngles: newAngles ?? this.newAngles,
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
    subtype: product?.subtype ?? 'Crossbody',
    existingPhotos: product?.productPhotos ?? const [],
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
  void addPhotos(List<ProductUpload> photos) =>
      state = state.copyWith(newPhotos: [...state.newPhotos, ...photos]);
  void clearNewPhotos() => state = state.copyWith(newPhotos: const []);
  void removeExistingPhoto(int index) => state = state.copyWith(
    removedPhotoIndexes: {...state.removedPhotoIndexes, index},
  );
  void setAngle(int index, String? value) =>
      state = state.copyWith(angles: {...state.angles, index: value});
  void setNewAngle(int index, String? value) =>
      state = state.copyWith(newAngles: {...state.newAngles, index: value});

  Future<Result<void>?> submit(_Product? product) async {
    if (state.isSubmitting || !state.isValid) return null;
    state = state.copyWith(isSubmitting: true);
    final existing = state.visibleExistingPhotos;
    final viewAngles = product == null
        ? {
            for (final (displayIndex, photo) in existing.indexed)
              displayIndex: state.angles[photo.$1],
            for (final (index, _) in state.newPhotos.indexed)
              existing.length + index: state.newAngles[index],
          }
        : {
            for (final (displayIndex, photo) in existing.indexed)
              if (state.angles[photo.$1] != photo.$2.viewAngle)
                displayIndex: state.angles[photo.$1],
            for (final (index, _) in state.newPhotos.indexed)
              if (state.newAngles[index] != null)
                existing.length + index: state.newAngles[index],
          };
    final draft = CatalogProductDraft(
      name: state.name.trim(),
      sku: state.sku.trim(),
      description: state.description.trim(),
      category: state.category,
      subCategory: state.category == 'Bags' ? state.subtype : '',
      photos: state.newPhotos,
      viewAngles: viewAngles,
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
