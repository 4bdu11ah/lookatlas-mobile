import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/features/create_content/data/repositories/content_repository_impl.dart';
import 'package:look_atlas/features/create_content/domain/entities/content_models.dart';
import 'package:look_atlas/features/create_content/domain/repositories/content_repository.dart';

/// Fixtures exist only in tests. Requests still exercise the real repository.
class ContentTestBackend implements HttpClientAdapter {
  ContentTestBackend() {
    final dio = Dio(BaseOptions(baseUrl: 'https://content.test'))
      ..httpClientAdapter = this;
    api = ApiService(baseUrl: 'https://content.test', dio: dio);
    repository = ContentRepositoryImpl(api);
  }
  late final ApiService api;
  late final ContentRepository repository;
  final List<RequestOptions> requests = [];
  FutureOr<ContentJson> Function(RequestOptions)? handler;
  ContentFormat format = ContentFormat.slideshow;
  String status = 'completed';
  ContentJson? draft;
  ContentJson get product => {
    'id': 'product-1',
    'name': 'Utility Bomber',
    'sku': 'JKT-014',
    'thumbnail': 'https://images.test/product.jpg',
    'photos': [
      for (var i = 0; i < 3; i++)
        {
          'id': 'photo-$i',
          'url': 'https://images.test/product.jpg',
          'sortOrder': i,
        },
    ],
  };
  ContentJson get generation => {
    'id': 'generation-1',
    'draftId': 'draft-1',
    'format': format.name,
    'status': status,
    'title': 'Emerald launch story',
    'platform': 'both',
    'source': 'runway',
    'progress': 54,
    'phase': 'building_visuals',
    'retryable': true,
    'creditCost': 10,
    'createdAt': '2026-09-07T10:00:00Z',
    'frames': [
      for (var i = 0; i < (format == ContentFormat.single ? 1 : 5); i++)
        {
          'frameId': 'frame-$i',
          'index': i,
          'label': [
            'The hook',
            'The hero',
            'The detail',
            'In use',
            'The finish',
          ][i],
          'imageUrl': 'https://images.test/frame-$i.jpg',
          'crop': null,
          'selectedVariantId': 'variant-$i',
          'variants': [
            {
              'variantId': 'variant-$i',
              'imageUrl': 'https://images.test/frame-$i.jpg',
              'source': 'generation',
            },
            {
              'variantId': 'alternate-$i',
              'imageUrl': 'https://images.test/frame-4.jpg',
              'source': 'generation',
            },
          ],
        },
    ],
    'video': format == ContentFormat.video
        ? {'url': null, 'coverFrameIndex': 0, 'durationSeconds': 6}
        : null,
    'publishingKit': {
      'caption': 'Texture changes everything. Our emerald faux-fur jacket pairs sculptural volume with a clean cropped line, made for nights that deserve a little more presence.',
      'hashtags': [
        'emeraldedit',
        'fauxfur',
        'winterstyle',
        'newseason',
        'lookatlas',
      ],
      'musicDirection': format == ContentFormat.single
          ? null
          : 'Warm electronic, confident pulse, 105-115 BPM',
    },
  };
  ContentJson respond(RequestOptions options) {
    final path = options.path;
    if (path == '/billing/subscription') return {'plan': 'pro'};
    final body = options.data is Map<String, dynamic>
        ? options.data as ContentJson
        : <String, dynamic>{};
    if (path == '/content/drafts' && options.method == 'GET') {
      return {
        'drafts': [if (draft != null) draft],
      };
    }
    if (path == '/content') {
      return {
        'items': [generation],
      };
    }
    if (path == '/content/drafts/latest') return {'draft': draft};
    if (path == '/content/generations/active') return {'active': null};
    if (path.startsWith('/content/drafts/') && options.method == 'DELETE') {
      draft = null;
      return {'ok': true};
    }
    if (path == '/content/drafts' || path.startsWith('/content/drafts/')) {
      draft = {'id': 'draft-1', 'format': format.name, ...?draft, ...body};
      return {'draft': draft};
    }
    if (path == '/products') {
      return {
        'products': [product],
        'pagination': {'page': 1, 'limit': 12, 'total': 1, 'totalPages': 1},
      };
    }
    if (path == '/content/quote') {
      return {
        'creditCost': 10,
        'remaining': 278,
        'canAfford': true,
        'unlimitedImages': false,
      };
    }
    if (path == '/content/generations' || path.endsWith('/retry')) {
      return {
        'id': 'generation-1',
        'status': 'pending',
        'creditCost': 10,
        'retryOf': null,
      };
    }
    if (path.startsWith('/content/generations/')) return generation;
    if (path.endsWith('/retouch') || path.endsWith('/regenerate')) {
      return {'id': 'edit-1', 'status': 'pending', 'creditCost': 1};
    }
    if (path.startsWith('/content/frame-edits/')) {
      return {
        'id': 'edit-1',
        'generationId': 'generation-1',
        'frameId': 'frame-0',
        'status': status,
      };
    }
    if (path.contains('/frames/')) {
      return {
        'frame': {
          ...contentObject((generation['frames'] as List).first),
          ...body,
        },
      };
    }
    if (path.endsWith('/publishing-kit')) {
      return {
        'publishingKit': {
          ...contentObject(generation['publishingKit']),
          ...body,
        },
        'coverFrameIndex': body['coverFrameIndex'] ?? 0,
      };
    }
    if (path.endsWith('/export')) {
      return {
        'url': 'https://assets.test/package.zip',
        'expiresAt': '2026-09-07T15:00:00Z',
        'fileName': 'package.zip',
      };
    }
    if (path == '/content/sources') {
      return {
        'sourcePath': 'uploads/source.jpg',
        'url': 'https://images.test/upload.jpg',
      };
    }
    throw StateError('Unexpected request: ${options.method} $path');
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final body = await (handler?.call(options) ?? respond(options));
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
