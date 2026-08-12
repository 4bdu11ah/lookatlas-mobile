import 'package:look_atlas/core/config/app_config.dart';
import 'package:look_atlas/features/shoots/domain/entities/shoot_create.dart';
import 'package:look_atlas/features/shoots/domain/entities/shoot_job.dart';

abstract final class ShootsApiCodec {
  static ShootPage decodeJobPage(dynamic data) {
    final body = _map(data);
    final pagination = _map(body['pagination']);
    final jobs = [
      for (final item in _items(data, 'jobs'))
        if (item is Map<String, dynamic>) _decodeJob(item),
    ];
    return ShootPage(
      jobs: jobs,
      page: _integer(pagination['page'], fallback: 1),
      totalPages: _integer(pagination['totalPages'], fallback: 1),
      total: _integer(pagination['total'], fallback: jobs.length),
    );
  }

  static ShootJob decodeJobResponse(dynamic data) =>
      _decodeJob(_nestedMap(data, 'job'));

  static ShootJob _decodeJob(Map<String, dynamic> json) {
    final product = _map(json['product']);
    final model = _map(json['model']);
    final settings = _map(json['settings']);
    final flatImages = [
      for (final item in _imageItems(json))
        if (item is Map<String, dynamic>) _decodeImage(item),
    ];
    final shots = [
      for (final (index, item) in _items(json['shots'], 'shots').indexed)
        if (item is Map<String, dynamic>) _decodeShot(item, index),
    ];
    return ShootJob(
      id: _string(json['id'] ?? json['_id'] ?? json['jobId']),
      name: _string(
        json['name'] ?? json['title'],
        fallback: _string(product['name'], fallback: 'Untitled shoot'),
      ),
      status: _string(json['status'], fallback: 'pending').toLowerCase(),
      renders: _integer(
        json['renders'] ?? json['renderCount'] ?? json['imagesCount'],
        fallback: flatImages.length,
      ),
      date: _date(json['date'] ?? json['createdAt'] ?? json['created_at']),
      productThumbnail: _url(
        json['productThumbnail'] ??
            product['thumbnail'] ??
            product['imageUrl'] ??
            _firstPhoto(product),
      ),
      modelThumbnail: _url(
        json['modelThumbnail'] ??
            model['thumbnail'] ??
            model['coverThumbnail'] ??
            _firstPhoto(model),
      ),
      progress: _progress(
        json['progress'] ??
            json['progressPercentage'] ??
            json['progress_percent'],
        status: _string(json['status']),
      ),
      supportTicketId: _nullableString(
        json['supportTicketId'] ?? json['support_ticket_id'],
      ),
      productId: _nullableString(json['productId'] ?? product['id']),
      productSku: _nullableString(json['sku'] ?? product['sku']),
      modelId: _nullableString(json['modelId'] ?? model['id']),
      modelName: _nullableString(json['modelName'] ?? model['name']),
      preset: _nullableString(
        json['presetName'] ?? json['preset'] ?? settings['preset'],
      ),
      aspectRatio: _nullableString(
        json['aspectRatio'] ??
            settings['aspectRatio'] ??
            settings['aspect_ratio'],
      ),
      images: flatImages,
      shots: shots,
      hasActiveMediaWork: _hasActiveMediaWork(json, flatImages, shots),
    );
  }

  static ShootShot _decodeShot(Map<String, dynamic> json, int fallbackIndex) {
    final index = _integer(
      json['shotIndex'] ?? json['index'],
      fallback: fallbackIndex,
    );
    return ShootShot(
      index: index,
      title: _string(
        json['title'] ?? json['name'],
        fallback: 'Shot ${index + 1}',
      ),
      description: _string(
        json['shortDescription'] ?? json['description'] ?? json['prompt'],
      ),
      images: [
        for (final item in _imageItems(json))
          if (item is Map<String, dynamic>)
            _decodeImage(item, fallbackShotIndex: index),
      ],
    );
  }

  static ShootImage _decodeImage(
    Map<String, dynamic> json, {
    int fallbackShotIndex = 0,
  }) => ShootImage(
    id: _string(json['id'] ?? json['_id'] ?? json['imageId']),
    url: _url(
      json['url'] ??
          json['imageUrl'] ??
          json['image_url'] ??
          json['watermarkedUrl'],
    ),
    approved: json['approved'] as bool? ?? json['isApproved'] as bool? ?? false,
    shotIndex: _integer(
      json['shotIndex'] ?? json['shot_index'],
      fallback: fallbackShotIndex,
    ),
    variationIndex: _integer(
      json['variationIndex'] ?? json['variation_index'],
    ),
    status: _string(json['status'], fallback: 'completed'),
  );

  static ShootProgressStatus decodeProgress(dynamic data) {
    final body = _nestedMap(data, 'job');
    final status = _string(body['status'], fallback: 'pending').toLowerCase();
    return ShootProgressStatus(
      status: status,
      progress: _progress(
        body['progress'] ??
            body['progressPercentage'] ??
            body['progress_percent'],
        status: status,
      ),
      currentStep: _nullableString(body['currentStep'] ?? body['current_step']),
      estimatedCompletion: _date(
        body['estimatedCompletion'] ?? body['estimated_completion'],
      ),
    );
  }

  static ShootImageEditState decodeEditStatus(dynamic data) {
    final status = _string(_nestedMap(data, 'edit')['status']).toLowerCase();
    return switch (status) {
      'completed' || 'complete' || 'succeeded' => ShootImageEditState.completed,
      'failed' || 'error' => ShootImageEditState.failed,
      'processing' || 'running' => ShootImageEditState.processing,
      _ => ShootImageEditState.pending,
    };
  }

  static List<ShootImageVersion> decodeVersions(dynamic data) => [
    for (final (index, item) in _items(data, 'versions').indexed)
      if (item is Map<String, dynamic>)
        ShootImageVersion(
          id: _string(item['id'] ?? item['_id'] ?? item['versionId']),
          url: _url(item['url'] ?? item['imageUrl']),
          label: _string(
            item['label'] ?? item['name'],
            fallback: 'Version ${index + 1}',
          ),
          description: _string(
            item['description'] ?? item['prompt'],
            fallback: index == 0 ? 'Original image' : 'AI edit',
          ),
          isActive:
              item['isActive'] as bool? ?? item['active'] as bool? ?? false,
        ),
  ];

  static List<ShootCatalogItem> decodeCatalogItems(
    dynamic data,
    String key, {
    String? source,
  }) => [
    for (final item in _items(data, key))
      if (item is Map<String, dynamic>)
        ShootCatalogItem(
          id: _string(item['id'] ?? item['_id']),
          name: _string(item['name'], fallback: 'Untitled'),
          subtitle: _string(
            item['sku'] ?? item['gender'] ?? item['category'] ?? item['style'],
          ),
          imageUrl: _url(
            item['thumbnail'] ??
                item['coverThumbnail'] ??
                item['heroImageUrl'] ??
                _firstPhoto(item),
          ),
          source: source,
          category: _nullableString(item['category']),
          subCategory: _nullableString(
            item['subCategory'] ?? item['sub_category'],
          ),
        ),
  ];

  static int decodeAvailableCredits(dynamic data) =>
      _integer(_map(data)['credits']);

  static ShootAppConfig decodeAppConfig(dynamic data) {
    final body = _map(data);
    final ratios = [
      for (final value in body['supportedAspectRatios'] as List? ?? const [])
        if (value is String && value.isNotEmpty) value,
    ];
    return ShootAppConfig(
      supportedAspectRatios: ratios.isEmpty
          ? const ['4:5', '3:4', '1:1', '4:3', '16:9', '9:16']
          : ratios,
      defaultAspectRatio: _string(
        body['defaultAspectRatio'],
        fallback: '4:5',
      ),
      relaxEnabled: body['relaxEnabled'] as bool? ?? false,
    );
  }

  static ShootSubscription decodeSubscription(dynamic data) {
    final body = _map(data);
    return ShootSubscription(
      plan: _string(body['plan']).toLowerCase(),
      status: _string(body['status']).toLowerCase(),
    );
  }

  static Set<String> decodeCalibratedProductIds(dynamic data) => {
    for (final item in _items(data, 'products'))
      if (item is Map<String, dynamic>) _string(item['productId']),
  }..remove('');

  static List<ShootLook> decodeLooks(dynamic data) => [
    for (final item in _items(data, 'looks'))
      if (item is Map<String, dynamic>)
        ShootLook(
          id: _string(item['id'] ?? item['_id'] ?? item['slug']),
          name: _string(item['name'] ?? item['title'], fallback: 'Look'),
          subtitle: _string(item['subtitle'] ?? item['description']),
          imageUrl: _url(
            item['heroImageUrl'] ?? item['thumbnail'] ?? _firstPhoto(item),
          ),
          settings: _map(item['settings']),
          portfolioImages: _stringImages(
            item['portfolioImages'] ?? item['portfolio'] ?? item['images'],
          ),
        ),
  ];

  static Map<String, List<String>> decodeFilters(dynamic data) {
    final body = _nestedMap(data, 'filters');
    return {
      for (final entry in body.entries)
        entry.key: [
          for (final value
              in entry.value is List ? entry.value as List : const [])
            if (value is String) value,
        ],
    };
  }

  static List<ShootPreset> decodePresets(dynamic data) => [
    for (final item in _items(data, 'presets'))
      if (item is Map<String, dynamic>)
        ShootPreset(
          id: _string(item['id'] ?? item['_id']),
          name: _string(item['name'], fallback: 'Preset'),
          settings: _map(item['settings']),
          heroImageUrl: _nullableUrl(item['heroImageUrl']),
          isDefault: item['isDefault'] as bool? ?? false,
        ),
  ];

  static List<PlannedShootShot> decodePlannedShots(dynamic data) => [
    for (final item in _items(data, 'shots'))
      if (item is Map<String, dynamic>) _decodePlannedShot(item),
  ];

  static PlannedShootShot decodeCustomShot(dynamic data) =>
      _decodePlannedShot(_nestedMap(data, 'shot'));

  static PlannedShootShot _decodePlannedShot(Map<String, dynamic> item) =>
      PlannedShootShot(
        title: _string(item['title'] ?? item['name'], fallback: 'Custom shot'),
        description: _string(
          item['shortDescription'] ?? item['description'] ?? item['prompt'],
        ),
        payload: item,
      );

  static String decodeCreatedJobId(dynamic data) {
    final body = _nestedMap(data, 'job');
    final id = _string(body['id'] ?? body['jobId'] ?? _map(data)['jobId']);
    if (id.isEmpty) {
      throw const FormatException('Create shoot response has no job id.');
    }
    return id;
  }

  static Map<String, dynamic> videoPayload(ShootVideoRequest request) {
    final payload = <String, dynamic>{
      'variationIndex': request.variationIndex,
      'aspectRatio': request.aspectRatio,
      'videoTier': request.videoTier,
    };
    final startingImageId = request.startingImageId;
    if (startingImageId != null) {
      payload['startingImageId'] = startingImageId;
    }
    return payload;
  }

  static Map<String, dynamic> planPayload(ShootSelection selection) {
    final settings = selection.settings;
    return {
      ..._selectionPayload(selection),
      'useCase': settings.useCase,
      'directorId': settings.directorId,
      if (settings.directorFeedback.trim().isNotEmpty)
        'directorFeedback': settings.directorFeedback.trim(),
      'background': settings.background,
      'numberOfShots': settings.numberOfShots,
      'aspectRatio': settings.aspectRatio,
      if (settings.background == 'custom' &&
          settings.backgroundNotes.trim().isNotEmpty)
        'backgroundNotes': settings.backgroundNotes.trim(),
      if (settings.directorId == 'heirloom-children' &&
          _trimmedEntries(settings.stylingNotes).isNotEmpty)
        'stylingNotes': _trimmedEntries(settings.stylingNotes),
    };
  }

  static Map<String, dynamic> customShotPayload(
    CustomShootShotRequest request,
  ) {
    final settings = request.selection.settings;
    return {
      'shotIdea': request.shotIdea,
      if (request.poseDirection.trim().isNotEmpty)
        'poseDirection': request.poseDirection.trim(),
      if (request.focusArea.trim().isNotEmpty)
        'focusArea': request.focusArea.trim(),
      'useCase': settings.useCase,
      'directorId': settings.directorId,
      'background': settings.background,
      'aspectRatio': settings.aspectRatio,
      if (settings.background == 'custom' &&
          settings.backgroundNotes.trim().isNotEmpty)
        'backgroundNotes': settings.backgroundNotes.trim(),
      'existingShots': [
        for (final shot in request.existingShots) shot.toJson(),
      ],
    };
  }

  static Map<String, dynamic> createPayload(CreateShootRequest request) {
    final settings = request.selection.settings;
    return {
      ..._selectionPayload(request.selection),
      'demoGroupId': ?request.demoGroupId,
      'variations': settings.variations,
      'shots': [for (final shot in request.shots) shot.toJson()],
      'settings': {
        'useCase': settings.useCase,
        'shootType': settings.useCase,
        'directorId': settings.directorId,
        'background': settings.background,
        'aspectRatio': settings.aspectRatio,
        'imageSize': settings.imageSize,
        'variations': settings.variations,
        if (settings.lane == ShootLane.relax) 'lane': 'relax',
        if (settings.background == 'custom' &&
            settings.backgroundNotes.trim().isNotEmpty)
          'backgroundNotes': settings.backgroundNotes.trim(),
      },
    };
  }

  static Map<String, dynamic> _selectionPayload(ShootSelection selection) => {
    'productId': selection.product.id,
    'modelId': selection.model.id,
    'modelSource': selection.modelSource,
    'models': [
      for (final (index, model) in selection.models.indexed)
        {
          'modelId': model.id,
          'source': model.source ?? 'user',
          'role': switch (index) {
            0 => 'primary',
            1 => 'secondary-1',
            _ => 'secondary-2',
          },
        },
    ],
    'products': [
      for (final product in selection.products) {'productId': product.id},
    ],
    if (selection.products.length > 1)
      'productMode': selection.productMode.name,
  };

  static Map<String, String> _trimmedEntries(Map<String, String> values) => {
    for (final entry in values.entries)
      if (entry.value.trim().isNotEmpty) entry.key: entry.value.trim(),
  };

  static List<dynamic> _imageItems(Map<String, dynamic> data) {
    for (final key in const ['images', 'generatedImages', 'results']) {
      final value = data[key];
      if (value is List) return value;
    }
    return const [];
  }

  static bool _hasActiveMediaWork(
    Map<String, dynamic> json,
    List<ShootImage> images,
    List<ShootShot> shots,
  ) {
    final video = _map(json['video']);
    final statuses = <String>[
      _string(video['status']),
      _string(json['videoStatus']),
      _string(json['redoHandShotsStatus']),
      for (final image in images) image.status,
      for (final shot in shots)
        for (final image in shot.images) image.status,
    ];
    return statuses.any(
      (status) => const {
        'pending',
        'queued',
        'enqueued',
        'processing',
        'generating',
        'running',
      }.contains(status.toLowerCase()),
    );
  }

  static List<dynamic> _items(dynamic data, String key) {
    if (data is List) return data;
    final body = _map(data);
    final direct = body[key];
    if (direct is List) return direct;
    final nested = body['data'];
    if (nested is List) return nested;
    if (nested is Map<String, dynamic> && nested[key] is List) {
      return nested[key] as List;
    }
    return const [];
  }

  static Map<String, dynamic> _nestedMap(dynamic data, String key) {
    final body = _map(data);
    final direct = body[key];
    if (direct is Map<String, dynamic>) return direct;
    final nested = body['data'];
    if (nested is Map<String, dynamic>) {
      final value = nested[key];
      if (value is Map<String, dynamic>) return value;
      return nested;
    }
    return body;
  }

  static Object? _firstPhoto(Map<String, dynamic> item) {
    final photos = item['photos'];
    if (photos is! List || photos.isEmpty) return null;
    final first = photos.first;
    if (first is String) return first;
    if (first is Map<String, dynamic>) {
      return first['url'] ?? first['thumbnailUrl'] ?? first['path'];
    }
    return null;
  }

  static List<String> _stringImages(Object? value) {
    if (value is! List) return const [];
    final images = <String>[];
    for (final item in value) {
      final raw = item is Map<String, dynamic>
          ? item['url'] ?? item['imageUrl'] ?? item['thumbnail']
          : item;
      final url = _nullableUrl(raw);
      if (url != null) images.add(url);
    }
    return images;
  }

  static double _progress(Object? raw, {required String status}) {
    final parsed = raw is num ? raw.toDouble() : double.tryParse('$raw');
    if (parsed == null) return status.toLowerCase() == 'completed' ? 1 : 0;
    return (parsed > 1 ? parsed / 100 : parsed).clamp(0, 1);
  }

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static String _url(Object? value) => _nullableUrl(value) ?? '';

  static String? _nullableUrl(Object? value) {
    final path = _nullableString(value);
    if (path == null) return null;
    final uri = Uri.tryParse(path);
    if (uri?.hasScheme ?? false) return path;
    return Uri.parse(AppConfig.apiBaseUrl).resolve(path).toString();
  }

  static int _integer(Object? value, {int fallback = 0}) {
    if (value is num) return value.round();
    return int.tryParse('$value') ?? fallback;
  }

  static String _string(Object? value, {String fallback = ''}) =>
      value is String && value.trim().isNotEmpty ? value.trim() : fallback;

  static String? _nullableString(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;

  static Map<String, dynamic> _map(dynamic data) =>
      data is Map<String, dynamic> ? data : const {};
}
