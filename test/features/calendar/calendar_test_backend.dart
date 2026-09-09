import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/features/calendar/data/repositories/calendar_repository_impl.dart';
import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';
import 'package:look_atlas/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:look_atlas/features/calendar/domain/use_cases/calendar_plan_use_cases.dart';
import 'package:look_atlas/features/calendar/domain/use_cases/validate_calendar_mutation_use_case.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_session.dart';

class CalendarTestBackend implements HttpClientAdapter {
  CalendarTestBackend() {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://calendar.test',
        headers: {'Authorization': 'Bearer test-token'},
      ),
    )..httpClientAdapter = this;
    repo = CalendarRepositoryImpl(
      ApiService(baseUrl: 'https://calendar.test', dio: dio),
    );
  }
  late final CalendarRepository repo;
  List<RequestOptions> requests = [];
  FutureOr<Object?> Function(RequestOptions)? handler;
  int responseStatus = 200;
  String stage = 'plan_ready';
  bool batch = false;
  bool unavailable = true;
  bool paused = false;
  bool noProducts = false;
  String? revision;
  List<String> statuses = ['idea', 'skipped'];
  CalendarJson get plan => {
    'id': 'plan-1',
    'status': stage,
    'objective': 'Post consistently',
    'cadence': '5_per_week',
    'platforms': ['instagram', 'facebook'],
    'productModes': {'product-1': 'spotlight'},
    'startsOn': '2026-09-08',
    'endsOn': '2026-10-07',
    'title': 'The everyday edit',
    'strategy': 'A connected story from your real products.',
    'chapters': batch
        ? <dynamic>[]
        : [
            {
              'key': 'chapter-1',
              'title': 'The reveal',
              'startsOn': '2026-09-08',
              'endsOn': '2026-10-07',
              'description': 'Meet the collection.',
            },
          ],
    'automationMode': 'review',
    'productionPaused': paused,
    'settings': {
      'mode': batch ? 'batch' : 'scheduled',
      'horizonDays': 30,
      'batchCount': 10,
      if (revision != null)
        'revision': {'status': revision, 'instruction': 'More editorial'},
    },
    'errorCode': stage == 'plan_failed' ? 'PLANNING_FAILED' : null,
  };
  CalendarJson makeItem(int index, String status) => {
    'id': 'item-$index',
    'planId': 'plan-1',
    'status': status,
    'position': index,
    'chapterKey': 'chapter-1',
    'publishAt': batch
        ? null
        : '2026-09-${(9 + index).toString().padLeft(2, '0')}T11:00:00Z',
    'productId': 'product-1',
    'format': index % 3 == 0
        ? 'single'
        : index % 3 == 1
        ? 'slideshow'
        : 'video',
    'hook': 'A fresh perspective ${index + 1}',
    'purpose': 'Introduce the collection',
    'platforms': ['instagram', 'facebook'],
    'locked': false,
    'angle': 'Editorial detail',
    'generationId':
        {'ready', 'scheduled', 'publishing', 'published'}.contains(status)
        ? 'generation-$index'
        : null,
    'errorCode': status == 'blocked' ? 'NEEDS_CREDITS' : null,
    'publishedResults': status == 'published'
        ? [
            {
              'platform': 'instagram',
              'permalink': 'https://www.instagram.com/p/example',
            },
          ]
        : <dynamic>[],
    'previewUrl': null,
  };
  CalendarJson get overview => {
    'plan': stage == 'setup' ? null : plan,
    'items': stage == 'setup'
        ? <dynamic>[]
        : [for (var i = 0; i < statuses.length; i++) makeItem(i, statuses[i])],
    'rollup': {
      'needsReview': statuses.where((s) => s == 'ready').length,
      'producing': statuses.where((s) => s == 'producing').length,
      'queuedForProduction': statuses.where((s) => s == 'approved').length,
      'scheduled': statuses.where((s) => s == 'scheduled').length,
      'published': statuses.where((s) => s == 'published').length,
      'failed': statuses.where((s) => s == 'failed').length,
      'blocked': statuses.where((s) => s == 'blocked').length,
      'nextPublishAt': null,
    },
    'estimate': {
      'total': 24,
      'remainingTotal': 24,
      'perFormat': {
        'single': {'count': 1, 'credits': 2},
        'slideshow': {'count': 1, 'credits': 10},
        'video': {'count': 1, 'credits': 12},
      },
    },
    'creditsRemaining': 278,
    'unlimitedImages': false,
    'videoEligible': true,
    'productCount': noProducts ? 0 : 10,
    'publishingMode': 'live',
    'publishingAvailable': !unavailable,
    'unitCosts': {'single': 2, 'slideshow': 10, 'video': 12},
    'connections': [
      for (final p in calendarPlatforms.keys)
        {
          'platform': p,
          'status': 'disconnected',
          'available': !unavailable,
          'handle': null,
        },
    ],
  };
  CalendarSession session() => CalendarSession(
    repo,
    planUseCases: CalendarPlanUseCases(
      repo,
      timeZone: () async => 'Asia/Karachi',
    ),
    validateMutation: const ValidateCalendarMutationUseCase(),
    now: () => DateTime(2026, 9, 8, 9),
  );
  Object? respond(RequestOptions r) {
    if (r.path == '/runway/overview') return overview;
    if (r.path == '/runway/attention') {
      return {'needsReview': 8, 'needsAttention': 4};
    }
    if (r.path == '/products') {
      return {
        'products': [
          if (!noProducts)
            for (var n = 1; n <= 10; n++)
              {
                'id': 'product-$n',
                'name': 'Product $n',
                'sku': 'SKU-$n',
                'thumbnail': null,
              },
        ],
      };
    }
    if (r.path == '/runway/quote') {
      return {
        'postCount': batch ? 10 : 22,
        'estimate': {
          'total': 132,
          'remainingTotal': 132,
          'perFormat': <String, dynamic>{},
        },
        'fitPreview': {'total': 90, 'downgraded': 4},
        'creditsRemaining': 100,
        'unlimitedImages': false,
        'videoEligible': true,
      };
    }
    if (r.path == '/runway/plans') {
      stage = 'planning';
      return {'plan': plan};
    }
    if (r.path.endsWith('/approve')) {
      stage = 'active';
      return {'creditWarning': false};
    }
    if (r.path.endsWith('/archive')) {
      stage = 'setup';
      return {'archived': true};
    }
    if (r.path.endsWith('/revise')) {
      revision = 'applying';
      return {'plan': plan};
    }
    if (r.path == '/runway/plans/plan-1') return {'plan': plan};
    if (r.path.contains('/items')) return {'item': makeItem(0, 'ready')};
    if (r.path.contains('/connections')) return {'ok': true};
    throw StateError('Unexpected request ${r.method} ${r.path}');
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
      responseStatus,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
