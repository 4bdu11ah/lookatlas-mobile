part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _Product {
  const _Product({required this.item, required this.calibrated});

  factory _Product.fromCatalog(
    ProductCatalogItem item,
    Set<String> calibratedIds,
  ) => _Product(item: item, calibrated: calibratedIds.contains(item.id));

  final ProductCatalogItem item;
  final bool calibrated;

  String get id => item.id;
  String get name => item.name;
  String get sku => item.sku;
  String get description => item.description ?? '';
  String get category => item.category;
  String? get subtype => item.subCategory;
  int get photos => item.photos.length;
  List<ProductPhoto> get productPhotos => item.photos;
  String get asset => item.imageUrl;
  String get status => calibrated ? 'Calibrated' : 'Recommended';
  String get addedLabel => item.createdAt == null
      ? 'Recently added'
      : DateFormat('MMM d').format(item.createdAt!.toLocal());

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
