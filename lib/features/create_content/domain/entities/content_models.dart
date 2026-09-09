typedef ContentJson = Map<String, dynamic>;

ContentJson contentObject(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Expected a content JSON object.');
  }
  return value;
}

String contentId(ContentJson value, [String key = 'id']) {
  final id = value[key];
  if (id is! String || id.isEmpty) {
    throw FormatException('Missing $key.');
  }
  return id;
}

enum ContentFormat {
  single,
  slideshow,
  video;

  String get label => switch (this) {
    single => 'Single post',
    slideshow => 'Slideshow',
    video => 'Video post',
  };
  static ContentFormat parse(String value) => values.byName(value);
}

bool contentIsActive(String? status) =>
    const {'pending', 'queued', 'processing'}.contains(status);

class ContentDraft {
  ContentDraft(ContentJson json)
    : id = contentId(json),
      data = Map.unmodifiable(json);
  final String id;
  final ContentJson data;
  ContentFormat get format => ContentFormat.parse(data['format'] as String);
}

class ContentFrame {
  ContentFrame(ContentJson json)
    : id = contentId(json, 'frameId'),
      data = Map.unmodifiable(json);
  final String id;
  final ContentJson data;
  int get index => (data['index'] as num).toInt();
  String get label => data['label'] as String? ?? 'Frame ${index + 1}';
  List<ContentJson> get variants =>
      (data['variants'] as List? ?? []).map(contentObject).toList();
  String? get imageUrl {
    for (final variant in variants) {
      if (variant['variantId'] == data['selectedVariantId']) {
        return variant['imageUrl'] as String?;
      }
    }
    return data['imageUrl'] as String?;
  }

  ContentJson? get crop =>
      data['crop'] == null ? null : contentObject(data['crop']);
  ContentFrame patch(ContentJson patch) => ContentFrame({...data, ...patch});
}

class ContentGeneration {
  ContentGeneration(ContentJson json)
    : id = contentId(json),
      data = Map.unmodifiable(json);
  final String id;
  final ContentJson data;
  ContentFormat get format => ContentFormat.parse(data['format'] as String);
  String get status => data['status'] as String;
  bool get active => contentIsActive(status);
  bool get completed => status == 'completed';
  bool get failed => status == 'failed';
  bool get retryable => data['retryable'] == true;
  String get title => data['title'] as String? ?? format.label;
  List<ContentFrame> get frames => (data['frames'] as List? ?? [])
      .map((e) => ContentFrame(contentObject(e)))
      .toList();
  ContentJson? get kit => data['publishingKit'] == null
      ? null
      : contentObject(data['publishingKit']);
  ContentJson? get video =>
      data['video'] == null ? null : contentObject(data['video']);
  ContentGeneration patch(ContentJson patch) =>
      ContentGeneration({...data, ...patch});
}

class ContentQuote {
  const ContentQuote({
    required this.cost,
    required this.remaining,
    required this.canAfford,
    required this.unlimitedImages,
  });
  final int cost;
  final int remaining;
  final bool canAfford;
  final bool unlimitedImages;
}

List<String> normalizeContentHashtags(Iterable<String> tags) => tags
    .expand((tag) => tag.split(RegExp(r'[\s,]+')))
    .map(
      (tag) => tag
          .toLowerCase()
          .replaceAll(RegExp('^#+'), '')
          .replaceAll(RegExp('[^a-z0-9_]'), ''),
    )
    .where((tag) => tag.isNotEmpty)
    .toSet()
    .take(30)
    .toList();

ContentJson defaultContentBrief(ContentFormat format) => {
  'title': null,
  'productId': null,
  'sourceUploadPath': null,
  'modelId': null,
  'modelSource': null,
  'directionMode': 'auto',
  'directionNotes': null,
  'platform': 'both',
  'notes': null,
  'settings': <String, dynamic>{
    'lastStep': 1,
    'visualDirection': 'Editorial',
    if (format == ContentFormat.slideshow) ...{
      'frameCount': 5,
      'story': 'Best story',
    },
    if (format == ContentFormat.single) 'purpose': 'Spotlight a product',
    if (format == ContentFormat.video) ...{
      'durationSeconds': 6,
      'videoDirection': 'Campaign teaser',
    },
  },
};
