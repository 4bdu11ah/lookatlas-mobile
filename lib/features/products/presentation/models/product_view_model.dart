import 'package:intl/intl.dart';
import 'package:look_atlas/features/products/domain/entities/product_catalog.dart';

class ProductViewModel {
  const ProductViewModel({required this.item, required this.calibrationStatus});

  factory ProductViewModel.fromCatalog(
    ProductCatalogItem item,
    Map<String, ProductCalibrationStatus> statuses,
  ) => ProductViewModel(
    item: item,
    calibrationStatus:
        statuses[item.id] ?? ProductCalibrationStatus.recommended,
  );

  final ProductCatalogItem item;
  final ProductCalibrationStatus calibrationStatus;

  bool get calibrated => calibrationStatus.isCalibrated;

  String get id => item.id;
  String get name => item.name;
  String get sku => item.sku;
  String get description => item.description ?? '';
  String get category => item.category;
  String? get subtype => item.subCategory;
  int get photos => item.photos.length;
  List<ProductPhoto> get productPhotos => item.photos;
  String get asset => item.imageUrl;
  String get status => calibrationStatus.label;
  String get addedLabel => item.createdAt == null
      ? 'Recently added'
      : DateFormat('MMM d, y').format(item.createdAt!.toLocal());

  List<String> get photoAssets {
    final photos = [
      for (final photo in productPhotos)
        if (photo.url.isNotEmpty) photo.url,
    ];
    if (photos.isNotEmpty) return photos;
    return asset.isEmpty ? const [] : [asset];
  }

  bool matchesSearch(String query) {
    final searchable = [
      name,
      sku,
      description,
      status,
      category,
      ?subtype,
    ].join(' ').toLowerCase();
    return searchable.contains(query);
  }
}
