import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/features/create_content/di/content_providers.dart';
import 'package:look_atlas/features/create_content/domain/entities/content_models.dart';
import 'package:look_atlas/features/create_content/domain/errors/content_api_exception.dart';
import 'package:look_atlas/features/create_content/domain/use_cases/save_content_draft_use_case.dart';
import 'package:look_atlas/features/create_content/presentation/controllers/content_session.dart';
import 'package:look_atlas/features/create_content/presentation/screens/create_content_screen.dart';
import 'package:look_atlas/features/dashboard/di/dashboard_providers.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_data.dart';
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
      Future<void> pump({ContentFormat? format, bool review = false}) async {
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
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      Future<void> capture(String name) async {
        await tester.pump(const Duration(milliseconds: 900));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const ValueKey('capture')),
          matchesGoldenFile('goldens/$name-$width.png'),
        );
      }

      await pump();
      await capture('hub');
      await pump(format: ContentFormat.slideshow);
      await tester.tap(find.text('Brief'));
      await tester.pumpAndSettle();
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
      await capture('publishing');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await capture('review');
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
      expect(find.text('Caption & hashtags'.toUpperCase()), findsOneWidget);
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
}
