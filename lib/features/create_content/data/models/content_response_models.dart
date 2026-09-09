import 'package:look_atlas/features/create_content/domain/entities/content_archive.dart';
import 'package:look_atlas/features/create_content/domain/entities/content_models.dart';
import 'package:look_atlas/features/products/domain/entities/product_catalog.dart';

class ContentDraftModel {
  ContentDraftModel.fromJson(Object? value) : json = contentObject(value) {
    contentId(json);
    ContentFormat.parse(json['format'] as String);
  }
  final ContentJson json;
  ContentDraft toEntity() => ContentDraft(json);
}

class ContentGenerationModel {
  ContentGenerationModel.fromJson(Object? value) : json = contentObject(value) {
    contentId(json);
    ContentFormat.parse(json['format'] as String);
    if (json['status'] is! String) {
      throw const FormatException('Missing status.');
    }
  }
  final ContentJson json;
  ContentGeneration toEntity() => ContentGeneration(json);
}

class ContentFrameModel {
  ContentFrameModel.fromJson(Object? value) : json = contentObject(value) {
    contentId(json, 'frameId');
    if (json['index'] is! num) throw const FormatException('Missing index.');
  }
  final ContentJson json;
  ContentFrame toEntity() => ContentFrame(json);
}

class ContentQuoteModel {
  ContentQuoteModel.fromJson(Object? value) : json = contentObject(value);
  final ContentJson json;
  ContentQuote toEntity() => ContentQuote(
    cost: (json['creditCost'] as num).toInt(),
    remaining: (json['remaining'] as num).toInt(),
    canAfford: json['canAfford'] as bool,
    unlimitedImages: json['unlimitedImages'] as bool,
  );
}

class ContentExportTicketModel {
  ContentExportTicketModel.fromJson(Object? value)
    : json = contentObject(value);
  final ContentJson json;
  ContentExportTicket toEntity() {
    final url = Uri.parse(json['url'] as String);
    if (!{'https', 'http'}.contains(url.scheme) || url.host.isEmpty) {
      throw const FormatException('Invalid archive URL');
    }
    return ContentExportTicket(
      url: url,
      fileName: (json['fileName'] as String).replaceAll(
        RegExp('[^a-zA-Z0-9._-]'),
        '-',
      ),
    );
  }
}

class ContentProductModel {
  ContentProductModel.fromJson(Object? value) : json = contentObject(value);
  final ContentJson json;
  ProductCatalogItem toEntity() {
    final photos = (json['photos'] as List? ?? []).map((value) {
      final photo = contentObject(value);
      return ProductPhoto(
        id: contentId(photo),
        url: photo['url'] as String? ?? '',
        sortOrder: (photo['sortOrder'] as num? ?? 0).toInt(),
      );
    }).toList();
    return ProductCatalogItem(
      id: contentId(json),
      name: json['name'] as String,
      sku: json['sku'] as String? ?? '',
      category: json['category'] as String? ?? '',
      thumbnail: json['thumbnail'] as String?,
      photos: photos,
    );
  }
}
