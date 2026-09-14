import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/features/create_content/di/content_providers.dart';
import 'package:look_atlas/features/create_content/domain/entities/content_models.dart';
import 'package:look_atlas/features/create_content/domain/errors/content_api_exception.dart';
import 'package:look_atlas/features/create_content/domain/use_cases/save_content_draft_use_case.dart';
import 'package:look_atlas/features/create_content/presentation/controllers/content_session.dart';
import 'package:look_atlas/features/create_content/presentation/controllers/create_content_controller.dart';
import 'package:look_atlas/features/create_content/presentation/screens/create_content_screen.dart';
import 'package:look_atlas/features/create_content/presentation/widgets/content_generation_loading_overlay.dart';
import 'package:look_atlas/features/dashboard/di/dashboard_providers.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:look_atlas/features/products/domain/entities/product_catalog.dart';
import 'package:look_atlas/shared/widgets/bar_spinner.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';

import 'content_test_backend.dart';

class _Client extends Mock implements HttpClient {}

class _Request extends Mock implements HttpClientRequest {}

class _Headers extends Mock implements HttpHeaders {}

class _Response extends Mock implements HttpClientResponse {
  _Response(this.bytes);
  final List<int> bytes;
  @override
  int get statusCode => 200;
  @override
  int get contentLength => bytes.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(bytes).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final family in ['Satoshi', 'InstrumentSerif']) {
      final font = FontLoader(family);
      for (final weight
          in family == 'Satoshi'
              ? ['Regular', 'Medium', 'Bold', 'Black']
              : ['Regular']) {
        font.addFont(rootBundle.load('assets/fonts/$family-$weight.ttf'));
      }
      await font.load();
    }
    final icons = FontLoader('packages/lucide_icons_flutter/Lucide')
      ..addFont(
        rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'),
      );
    await icons.load();
    registerFallbackValue(Uri());
    // Georgia is a system fallback in the supplied HTML, not a redistributed
    // app asset. Load the host font only for the local reference comparison.
    final georgiaFile = File('/System/Library/Fonts/Supplemental/Georgia.ttf');
    if (georgiaFile.existsSync()) {
      final georgia = FontLoader('Georgia')
        ..addFont(
          Future.value(ByteData.sublistView(georgiaFile.readAsBytesSync())),
        );
      await georgia.load();
    }
  });

  test('generation phase labels match the documented design', () {
    expect(
      contentGenerationPhaseLabel('reading_product'),
      'Reading your product',
    );
    expect(
      contentGenerationPhaseLabel('directing_story'),
      'Directing the story',
    );
    expect(
      contentGenerationPhaseLabel('building_visuals'),
      'Building the visuals',
    );
    expect(
      contentGenerationPhaseLabel('writing_publishing_kit'),
      'Writing the publishing kit',
    );
    expect(contentGenerationPhaseLabel('finishing'), 'Finishing your content');
    expect(contentGenerationPhaseLabel('new_phase'), 'Working on your content');
  });
  for (final width in [320, 375, 390, 430]) {
    testWidgets('hub and nested screens at $width logical pixels', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width.toDouble(), 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final client = _Client();
      final request = _Request();
      final headers = _Headers();
      final bytes = File(
        'assets/images/create_content/slideshow-fur-hook-v2.webp',
      ).readAsBytesSync();
      when(() => client.getUrl(any())).thenAnswer((_) async => request);
      when(() => request.headers).thenReturn(headers);
      when(request.close).thenAnswer((_) async => _Response(bytes));
      debugNetworkImageHttpClientProvider = () => client;
      addTearDown(() => debugNetworkImageHttpClientProvider = null);
      final backend = ContentTestBackend();
      ContentSession? current;
      Future<void> pump({
        ContentFormat? format,
        bool review = false,
        bool openCaptionPanel = false,
      }) async {
        backend.format = format ?? ContentFormat.slideshow;
        backend.draft = {
          'id': 'draft-1',
          'format': backend.format.name,
          ...defaultContentBrief(backend.format),
          'productId': 'product-1',
        };
        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              contentRepositoryProvider.overrideWithValue(backend.repository),
              contentVideoEligibleProvider.overrideWith((ref) async => true),
              contentSessionFactoryProvider.overrideWithValue(
                (format, {generationId}) => current = ContentSession(
                  backend.repository,
                  format,
                  saveDraft: SaveContentDraftUseCase(backend.repository),
                  refreshCredits: () {},
                ),
              ),
              dashboardStatsProvider.overrideWith(
                (ref) async => const DashboardStats(
                  credits: 278,
                  creditsTotal: 300,
                  creditsUsed: 22,
                  totalRenders: 0,
                  activeJobs: 0,
                  completedJobs: 0,
                ),
              ),
            ],
            child: RepaintBoundary(
              key: const ValueKey('capture'),
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light(),
                home: CreateContentScreen(
                  initialFormat: format?.name,
                  contentId: review ? 'generation-1' : null,
                  openCaptionPanel: openCaptionPanel,
                ),
              ),
            ),
          ),
        );
        if (review && backend.status == 'processing') {
          for (var i = 0; i < 20; i++) {
            await tester.pump(const Duration(milliseconds: 10));
          }
        } else {
          await tester.pumpAndSettle();
        }
      }

      Future<void> capture(String name) async {
        await tester.pump(const Duration(milliseconds: 900));
        if (find.byType(BarSpinner).evaluate().isEmpty) {
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const ValueKey('capture')),
          matchesGoldenFile('goldens/$name-$width.png'),
        );
      }

      await pump();
      await capture('hub');
      await pump(format: ContentFormat.slideshow);
      final canvas = find.byKey(const ValueKey('content-canvas-card'));
      final fittedSize = tester.getSize(canvas);
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pumpAndSettle();
      expect(tester.getSize(canvas).height, greaterThan(fittedSize.height));
      await tester.tap(find.byTooltip('Zoom out'));
      await tester.pumpAndSettle();
      expect(tester.getSize(canvas).height, lessThan(fittedSize.height));
      await tester.tap(find.text('Fit'));
      await tester.pumpAndSettle();
      expect(tester.getSize(canvas), fittedSize);
      current!.updateBrief({
        'settings': {'lastStep': 3},
      });
      List<ProductCatalogItem>? originalProducts;
      if (width == 320) {
        originalProducts = List.of(current!.products);
        current!.products = const [
          ProductCatalogItem(
            id: 'product-1',
            name: 'Gun Metal Plated 3D Canyon Pattern Pendant with Box Chain',
            sku: 'Gun Metal Plated 3D Canyon Pattern Pendant with Box Chain',
            category: 'Jewelry',
            photos: [
              ProductPhoto(id: 'photo-1', url: '', sortOrder: 0),
              ProductPhoto(id: 'photo-2', url: '', sortOrder: 1),
              ProductPhoto(id: 'photo-3', url: '', sortOrder: 2),
            ],
          ),
        ];
        current!.changed();
      }
      await tester.pumpAndSettle();
      await tester.tap(canvas);
      await tester.pumpAndSettle();
      if (width == 320) {
        expect(tester.takeException(), isNull);
        current!
          ..products = originalProducts!
          ..changed();
        await tester.pumpAndSettle();
      }
      await capture('product');
      expect(
        tester.getSize(find.text('Choose a product.')).width,
        lessThan(width),
      );
      await tester.ensureVisible(find.text('Continue to direction'));
      await tester.tap(find.text('Continue to direction'));
      await tester.pumpAndSettle();
      await capture('direction');
      await tester.tap(find.text('Guide the direction'));
      await tester.pumpAndSettle();
      await capture('guided');
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await capture('output');
      await pump(format: ContentFormat.slideshow, review: true);
      await tester.tap(find.byTooltip('Open caption and hashtags'));
      await tester.pumpAndSettle();
      await capture('publishing');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await capture('review');
      await pump(
        format: ContentFormat.slideshow,
        review: true,
        openCaptionPanel: true,
      );
      expect(find.text('CAPTION & HASHTAGS'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tools'));
      await tester.pumpAndSettle();
      await capture('tools');
      await tester.tap(find.text('Crop & position'));
      await tester.pumpAndSettle();
      await capture('crop');
      await tester.tap(find.text('‹ All tools'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Replace variation'));
      await tester.pumpAndSettle();
      await capture('replace');
      await tester.tap(find.text('‹ All tools'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retouch'));
      await tester.pumpAndSettle();
      await capture('retouch');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Download'));
      await tester.pumpAndSettle();
      await capture('export');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Preview Slideshow'));
      await tester.pumpAndSettle();
      await capture('preview');
      for (final format in [ContentFormat.single, ContentFormat.video]) {
        await pump(format: format);
        current!.updateBrief({
          'settings': {'lastStep': 3},
        });
        await tester.pumpAndSettle();
        await tester.tap(find.text('Brief'));
        await tester.pumpAndSettle();
        await capture('${format.name}-output');
      }
      current!.reportFailure(
        const ContentApiException('Credits required', status: 402),
      );
      await tester.pumpAndSettle();
      await capture('credits');
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      backend.status = 'failed';
      await pump(format: ContentFormat.slideshow, review: true);
      await capture('failed');
      backend.status = 'completed';
      await tester.tap(find.text('Retry generation'));
      await tester.pumpAndSettle();
      expect(find.text('READY TO REVIEW'), findsOneWidget);
      expect(find.text('Caption & hashtags'.toUpperCase()), findsNothing);
      backend.status = 'processing';
      await pump(format: ContentFormat.slideshow, review: true);
      await capture('generating');
      backend.status = 'completed';
      backend.handler = (request) => request.path == '/products'
          ? {'products': <dynamic>[]}
          : backend.respond(request);
      await pump(format: ContentFormat.slideshow);
      await tester.tap(find.text('Brief'));
      await tester.pumpAndSettle();
      await capture('empty-products');
      backend.handler = (request) {
        if (request.path == '/products') {
          throw const ContentApiException('Product load failure');
        }
        return backend.respond(request);
      };
      await pump(format: ContentFormat.slideshow);
      await tester.tap(find.text('Brief'));
      await tester.pumpAndSettle();
      await capture('product-error');
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      debugNetworkImageHttpClientProvider = null;
    });
  }

  testWidgets('video format displays BETA badge in a dark container', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final backend = ContentTestBackend();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWithValue(backend.repository),
          contentVideoEligibleProvider.overrideWith((ref) async => true),
          dashboardStatsProvider.overrideWith(
            (ref) async => const DashboardStats(
              credits: 278,
              creditsTotal: 300,
              creditsUsed: 22,
              totalRenders: 0,
              activeJobs: 0,
              completedJobs: 0,
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const CreateContentScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('BETA'), 200);
    expect(find.text('BETA'), findsOneWidget);

    final betaContainer = tester.widget<Container>(
      find
          .ancestor(of: find.text('BETA'), matching: find.byType(Container))
          .first,
    );
    expect(betaContainer.color, const Color(0xff171715));
  });

  testWidgets(
    'draft card displays continue brief and can be discarded with confirmation',
    (tester) async {
      final backend = ContentTestBackend()
        ..draft = {
          'id': 'draft-1',
          'format': 'slideshow',
          'title': 'The Isolde Petite Knife Edge',
          'updatedAt': DateTime.now().toIso8601String(),
        };
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contentRepositoryProvider.overrideWithValue(backend.repository),
            contentVideoEligibleProvider.overrideWith((ref) async => true),
            dashboardStatsProvider.overrideWith(
              (ref) async => const DashboardStats(
                credits: 278,
                creditsTotal: 300,
                creditsUsed: 22,
                totalRenders: 0,
                activeJobs: 0,
                completedJobs: 0,
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const CreateContentScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('The Isolde Petite Knife Edge'),
        200,
      );
      expect(find.text('The Isolde Petite Knife Edge'), findsOneWidget);
      expect(
        find.text('Continue brief • Slideshow • Today'),
        findsOneWidget,
      );
      expect(find.byIcon(LucideIcons.x), findsOneWidget);
      expect(find.text('Discard?'), findsNothing);

      // Tap X icon to enter discard confirmation
      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pumpAndSettle();

      expect(find.text('Discard?'), findsOneWidget);

      // Tap Discard? to delete
      await tester.tap(find.text('Discard?'));
      await tester.pumpAndSettle();

      expect(find.text('The Isolde Petite Knife Edge'), findsNothing);
      expect(backend.draft, isNull);
    },
  );

  testWidgets(
    'featured case study card displays dark theme with stats and read action',
    (tester) async {
      final backend = ContentTestBackend();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contentRepositoryProvider.overrideWithValue(backend.repository),
            contentVideoEligibleProvider.overrideWith((ref) async => true),
            dashboardStatsProvider.overrideWith(
              (ref) async => const DashboardStats(
                credits: 278,
                creditsTotal: 300,
                creditsUsed: 22,
                totalRenders: 0,
                activeJobs: 0,
                completedJobs: 0,
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const CreateContentScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('FEATURED CASE STUDY'),
        300,
      );
      expect(find.text('FEATURED CASE STUDY'), findsOneWidget);
      expect(
        find.text('How one launch became fourteen days of content.'),
        findsOneWidget,
      );
      expect(find.text('SOURCE\nPRODUCT'), findsOneWidget);
      expect(find.text('CAMPAIGN\nASSETS'), findsOneWidget);
      expect(find.text('14-DAY SYSTEM'), findsOneWidget);
      expect(find.text('01'), findsOneWidget);
      expect(find.text('Campaign source'), findsOneWidget);
      expect(find.text('03'), findsOneWidget);
      expect(find.text('Content formats'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      expect(find.text('Day content plan'), findsOneWidget);
      expect(find.text('READ THE CASE STUDY'), findsOneWidget);
    },
  );

  testWidgets('brief screen clears stale leaving state on entry', (
    tester,
  ) async {
    final backend = ContentTestBackend();
    final session = ContentSession(
      backend.repository,
      ContentFormat.slideshow,
      saveDraft: SaveContentDraftUseCase(backend.repository),
      refreshCredits: () {},
    );
    final overrides = [
      contentRepositoryProvider.overrideWithValue(backend.repository),
      contentSessionFactoryProvider.overrideWithValue(
        (format, {generationId}) => session,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: const MaterialApp(home: SizedBox()),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    container
        .read(createContentControllerProvider.notifier)
        .setLeaving(leaving: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ContentBriefScreen(format: ContentFormat.slideshow),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(container.read(createContentControllerProvider).leaving, isFalse);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('generate shows progress then opens the running content', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final startRequest = Completer<ContentJson>();
    final backend = ContentTestBackend()
      ..status = 'processing'
      ..draft = {
        'id': 'draft-1',
        'format': 'slideshow',
        ...defaultContentBrief(ContentFormat.slideshow),
        'productId': 'product-1',
        'settings': {
          ...contentObject(
            defaultContentBrief(ContentFormat.slideshow)['settings'],
          ),
          'lastStep': 3,
        },
      };
    backend.handler = (request) {
      if (request.path == '/content/generations' && request.method == 'POST') {
        return startRequest.future;
      }
      if (request.path == '/content/generations/generation-1') {
        return backend.status == 'processing'
            ? {...backend.generation, 'frames': <dynamic>[]}
            : backend.generation;
      }
      return backend.respond(request);
    };
    final router = GoRouter(
      initialLocation: '/create-content/slideshow',
      routes: [
        GoRoute(
          path: '/create-content/slideshow',
          builder: (_, _) => const CreateContentScreen(
            initialFormat: 'slideshow',
          ),
        ),
        GoRoute(
          path: '/create-content/item/:contentId',
          builder: (_, state) => CreateContentScreen(
            contentId: state.pathParameters['contentId'],
            previewImageUrl: state.extra as String?,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWithValue(backend.repository),
          contentVideoEligibleProvider.overrideWith((ref) async => true),
          contentSessionFactoryProvider.overrideWithValue(
            (format, {generationId}) => ContentSession(
              backend.repository,
              format,
              saveDraft: SaveContentDraftUseCase(backend.repository),
              refreshCredits: () {},
            ),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Generate · 10 credits').first);
    await tester.pump();
    await tester.pump();

    expect(find.text('Reading your product'), findsNWidgets(2));
    expect(
      find.text('Building one connected visual world, frame by frame.'),
      findsOneWidget,
    );
    expect(find.text('Frames'), findsOneWidget);
    expect(find.text('5 total'), findsOneWidget);
    expect(find.text('Building sequence'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('content-frame-background-2')),
      findsOneWidget,
    );

    startRequest.complete({
      'id': 'generation-1',
      'status': 'pending',
      'creditCost': 10,
      'retryOf': null,
    });
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }

    expect(
      router.routeInformationProvider.value.uri.path,
      '/create-content/item/generation-1',
    );
    expect(find.text('Building the visuals'), findsNWidgets(2));
    expect(
      find.text('Building one connected visual world, frame by frame.'),
      findsOneWidget,
    );
    expect(find.text('Building sequence'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('content-frame-background-2')),
      findsOneWidget,
    );

    backend.status = 'completed';
    await tester.pump(const Duration(seconds: 3));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }

    expect(
      router.routeInformationProvider.value.uri.path,
      '/create-content/item/generation-1',
    );
    expect(find.text('READY TO REVIEW'), findsOneWidget);
    expect(find.text('The hook'), findsOneWidget);
    expect(find.text('Building the visuals'), findsNothing);
    expect(find.text('CAPTION & HASHTAGS'), findsNothing);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    expect(container.read(createContentControllerProvider).rightOpen, isFalse);
  });
}
