part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _Product {
  const _Product({
    required this.name,
    required this.sku,
    required this.asset,
    required this.photos,
    required this.status,
    required this.category,
    required this.addedLabel,
    this.subtype,
  });

  final String name;
  final String sku;
  final String asset;
  final int photos;
  final String status;
  final String category;
  final String addedLabel;
  final String? subtype;

  List<String> get photoAssets {
    final assets = switch (category) {
      'Tops' => const [
        '$_img/angles/tops-front.png',
        '$_img/angles/tops-back.png',
      ],
      'Dresses' => const [
        '$_img/angles/dresses-front.png',
        '$_img/angles/dresses-back.png',
        '$_img/angles/dresses-detail.png',
      ],
      'Outerwear' => const [
        '$_img/angles/outerwear-front.png',
        '$_img/angles/outerwear-back.png',
        '$_img/angles/outerwear-side.png',
      ],
      'Bottoms' => const [
        '$_img/angles/bottoms-front.png',
        '$_img/angles/bottoms-back.png',
      ],
      'Bags' => const [
        '$_img/angles/bags-front.png',
        '$_img/angles/bags-side.png',
        '$_img/angles/bags-detail.png',
      ],
      'Shoes' => const [
        '$_img/angles/shoes-side.png',
        '$_img/angles/shoes-front.png',
        '$_img/angles/shoes-top.png',
      ],
      'Jewelry' => const [
        '$_img/angles/jewelry-closeup1.png',
        '$_img/angles/jewelry-closeup2.png',
      ],
      'Eyewear' => const [
        '$_img/angles/eyewear-front.png',
        '$_img/angles/eyewear-side.png',
      ],
      'Watches' => const [
        '$_img/angles/watches-face.png',
        '$_img/angles/watches-side.png',
      ],
      'Accessories' => const [
        '$_img/angles/accessories-front.png',
        '$_img/angles/accessories-detail.png',
      ],
      _ => <String>[],
    };
    return assets.isEmpty ? [asset] : assets;
  }

  bool matchesSearch(String query) {
    final searchable = [
      name,
      sku,
      status,
      category,
      ?subtype,
    ].join(' ').toLowerCase();
    return searchable.contains(query);
  }
}
