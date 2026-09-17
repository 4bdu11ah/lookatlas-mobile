import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart' show ImageSource;
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/create_content/di/content_providers.dart';
import 'package:look_atlas/features/create_content/domain/entities/content_models.dart';
import 'package:look_atlas/features/create_content/presentation/controllers/content_session.dart';
import 'package:look_atlas/features/create_content/presentation/controllers/create_content_controller.dart';
import 'package:look_atlas/features/create_content/presentation/widgets/content_canvas_controls.dart';
import 'package:look_atlas/features/create_content/presentation/widgets/content_generation_filmstrip.dart';
import 'package:look_atlas/features/create_content/presentation/widgets/content_generation_loading_overlay.dart';
import 'package:look_atlas/features/create_content/presentation/widgets/content_widgets.dart';
import 'package:look_atlas/shared/image_picker/image_picker_providers.dart';
import 'package:look_atlas/shared/widgets/app_snack_bar.dart';
import 'package:look_atlas/shared/widgets/app_text_field.dart';
import 'package:look_atlas/shared/widgets/bar_spinner.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ContentBriefScreen extends ConsumerStatefulWidget {
  const ContentBriefScreen({
    required this.format,
    super.key,
  });

  final ContentFormat format;

  @override
  ConsumerState<ContentBriefScreen> createState() => _ContentBriefScreenState();
}

class _ContentBriefScreenState extends ConsumerState<ContentBriefScreen>
    with WidgetsBindingObserver {
  late final ContentSessionArgs _args;
  late final TextEditingController _searchController;
  final FocusScopeNode _panelFocus = FocusScopeNode();
  bool _paywallVisible = false;

  CreateContentUIState get _ui => ref.watch(createContentControllerProvider);
  CreateContentController get _controller =>
      ref.read(createContentControllerProvider.notifier);

  bool get _leftOpen => _ui.leftOpen;
  bool get _leaving => _ui.leaving;
  double get _canvasZoom => _ui.canvasZoom;
  String get _search => _ui.search;

  @override
  void initState() {
    super.initState();
    _args = (format: widget.format, generationId: null);
    _searchController = TextEditingController();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.setLeaving(leaving: false);
        unawaited(ref.read(contentSessionProvider(_args)).initialize());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref
        .read(contentSessionProvider(_args))
        .setPaused(value: state != AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _panelFocus.dispose();
    super.dispose();
  }

  Future<void> _leave([String? target]) async {
    if (_leaving) return;
    final session = ref.read(contentSessionProvider(_args));
    if (session.uploading || session.submitting) {
      _message('Wait for the current request to finish before leaving.');
      return;
    }
    _controller.setLeaving(leaving: true);
    final saved = await session.flush();
    if (!mounted) return;
    if (!saved) {
      _controller.setLeaving(leaving: false);
      _message('Your changes are not saved. Retry saving before leaving.');
      return;
    }
    _controller.setLeaving(leaving: false);
    if (target != null) {
      context.go(target);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.createContent);
    }
  }

  Future<void> _closePanel() async {
    final session = ref.read(contentSessionProvider(_args));
    if (!await session.flushEdits() || !mounted) return;
    _controller.closePanels();
  }

  void _openPanel() {
    _controller.openPanel(left: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _panelFocus.requestFocus();
    });
  }

  void _openProductPicker(ContentSession session) {
    if (session.step != 1) {
      session.updateBrief({
        'settings': {'lastStep': 1},
      });
    }
    _openPanel();
  }

  void _message(String text) {
    if (mounted) {
      AppSnackBar.show(context, text);
    }
  }

  Future<void> _showPaywall(int status) async {
    if (!mounted) return;
    await showContentPaywallDialog(
      context: context,
      status: status,
      onSeePlans: () async {
        final session = ref.read(contentSessionProvider(_args));
        if (!await session.flush()) return;
        if (mounted) {
          await context.push<void>(AppRoutes.dashboardBilling);
        }
        if (mounted) {
          session.refreshCredits();
          unawaited(session.requote());
        }
      },
    );
    _paywallVisible = false;
    ref.read(contentSessionProvider(_args)).paywall = null;
  }

  Future<void> _generate({bool retry = false}) async {
    final session = ref.read(contentSessionProvider(_args));
    if (session.format == ContentFormat.video &&
        ref.read(contentVideoEligibleProvider).asData?.value == false) {
      await _showPaywall(403);
      return;
    }
    final generationRequest = session.generate(retry: retry);
    if (session.submitting) _controller.closePanels();
    await generationRequest;
    if (!mounted || session.generation == null || session.error != null) return;
    context.go(
      '${AppRoutes.createContent}/item/${Uri.encodeComponent(session.generation!.id)}',
      extra: session.selectedProduct?.imageUrl ?? session.uploadUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(createContentControllerProvider);
    final session = ref.watch(contentSessionProvider(_args));

    ref.listen<ContentSession>(contentSessionProvider(_args), (_, next) {
      if (next.paywall != null && !_paywallVisible) {
        _paywallVisible = true;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _showPaywall(next.paywall!),
        );
      }
    });

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: AppColors.paper,
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: AppColors.ink,
          displayColor: AppColors.ink,
          letterSpacingFactor: 0,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.zero),
          contentPadding: EdgeInsets.all(11),
        ),
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (_leftOpen) {
            unawaited(_closePanel());
          } else {
            unawaited(_leave());
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.paper,
          body: SafeArea(
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.escape): () {
                  if (_leftOpen) {
                    unawaited(_closePanel());
                  }
                },
              },
              child: Column(
                children: [
                  _buildHeader(session),
                  Expanded(
                    child: session.loading
                        ? const Center(
                            child: BarSpinner(
                              color: AppColors.ink,
                              size: 28,
                            ),
                          )
                        : Stack(
                            children: [
                              Positioned.fill(
                                child: ExcludeFocus(
                                  excluding: _leftOpen,
                                  child: ExcludeSemantics(
                                    excluding: _leftOpen,
                                    child: _buildCanvas(session),
                                  ),
                                ),
                              ),
                              if (_leftOpen)
                                Positioned.fill(
                                  child: Semantics(
                                    label: 'Close panel',
                                    button: true,
                                    child: GestureDetector(
                                      onTap: _closePanel,
                                      child: Container(
                                        color: AppColors.ink.withValues(
                                          alpha: .1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (_leftOpen)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: FocusScope(
                                    node: _panelFocus,
                                    child: Container(
                                      width: math.min(
                                        344,
                                        MediaQuery.sizeOf(context).width * .92,
                                      ),
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                        color: AppColors.paper,
                                        border: Border.all(
                                          color: AppColors.line,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.ink.withValues(
                                              alpha: .16,
                                            ),
                                            blurRadius: 64,
                                            offset: const Offset(28, 0),
                                          ),
                                        ],
                                      ),
                                      child: _buildBriefPanel(session),
                                    ),
                                  ),
                                ),
                               if (_leaving) contentLeavingOverlay(),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ContentSession session) {
    return ContentHeaderBar(
      onBack: _leave,
      backIconSize: 16,
      actions: [
        contentSmallTextButton(
          'Brief',
          _openPanel,
          color: Colors.white70,
          label: 'Open creative brief',
        ),
        if (session.step == 3 && !session.loading)
          contentHeaderAction(
            _generateLabel(session),
            LucideIcons.arrowRight,
            session.submitting || session.generation?.active == true
                ? null
                : _generate,
          ),
      ],
    );
  }

  Widget _buildCanvas(ContentSession session) {
    final generation = session.generation;
    final preparing = session.submitting && generation == null;
    final generating = generation?.active == true;
    final showGenerationLoading =
        session.error == null && (preparing || generating);
    final frameTotal = session.format == ContentFormat.slideshow
        ? (session.settings['frameCount'] as num? ?? 5).toInt()
        : 1;

    return Column(
      children: [
        ContentCanvasBar(
          statusLabel: showGenerationLoading
              ? contentGenerationPhaseLabel(
                  generation?.data['phase'] as String?,
                )
              : 'LIVE PREVIEW',
          zoom: _canvasZoom,
          onZoomOut: _controller.zoomCanvasOut,
          onFit: _controller.fitCanvas,
          onZoomIn: _controller.zoomCanvasIn,
        ),
        Expanded(
          child: ColoredBox(
            color: const Color(0xffe5e3dc),
            child: Stack(
              children: [
                const Positioned.fill(
                  child: CustomPaint(painter: StudioDots()),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final ratio = session.format == ContentFormat.video
                            ? 9 / 16
                            : 4 / 5;
                        final height = math.min(
                          540,
                          math.min(box.maxHeight - 18, box.maxWidth / ratio),
                        );
                        return Center(
                          child: Semantics(
                            button: true,
                            label: 'Choose product',
                            child: GestureDetector(
                              key: const ValueKey('content-canvas-card'),
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _openProductPicker(session),
                              child: SizedBox(
                                height: math.max(0, height * _canvasZoom),
                                width: math.max(
                                  0,
                                  height * ratio * _canvasZoom,
                                ),
                                child: DecoratedBox(
                                  decoration: const BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0x331f1c18),
                                        blurRadius: 38,
                                        offset: Offset(0, 20),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      contentImage(
                                        session.selectedProduct?.imageUrl ??
                                            session.uploadUrl,
                                      ),
                                      if (showGenerationLoading)
                                        ContentGenerationLoadingOverlay(
                                          format: session.format,
                                          generation: generation,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (session.error != null && !_leftOpen)
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: contentErrorBox(
                      session.error!,
                      () => unawaited(session.initialize()),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (showGenerationLoading)
          ContentGenerationFilmstrip(
            format: session.format,
            frames: generation?.frames ?? const [],
            total: frameTotal,
            generating: true,
            backgroundImageUrl:
                session.selectedProduct?.imageUrl ?? session.uploadUrl,
          ),
      ],
    );
  }

  Widget _buildBriefPanel(ContentSession session) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        contentPanelTitle(
          'Creative brief',
          'Step ${session.step} of 3',
          _closePanel,
        ),
        SizedBox(
          height: 48,
          child: Row(
            children: [
              for (var i = 1; i <= 3; i++)
                Expanded(
                  child: InkWell(
                    onTap: i <= session.furthestStep
                        ? () => session.updateBrief({
                            'settings': {'lastStep': i},
                          })
                        : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: i == session.step ? Colors.white : null,
                        border: Border(
                          right: const BorderSide(color: AppColors.line),
                          bottom: BorderSide(
                            color: i == session.step
                                ? AppColors.ink
                                : AppColors.line,
                            width: i == session.step ? 2 : 1,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Opacity(
                          opacity: i > session.furthestStep ? .4 : 1,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (i >= session.step) ...[
                                Container(
                                  width: 20,
                                  height: 20,
                                  alignment: Alignment.center,
                                  color: i == session.step
                                      ? AppColors.ink
                                      : AppColors.soft,
                                  child: Text(
                                    '0$i',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: i == session.step
                                          ? Colors.white
                                          : AppColors.muted,
                                      fontSize: 9,
                                      fontWeight: AppTypography.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Flexible(
                                child: Text(
                                  ['Product', 'Direction', 'Output'][i - 1],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  semanticsLabel: [
                                    'Product',
                                    'Direction',
                                    'Output',
                                  ][i - 1],
                                  style: textTheme.labelSmall?.copyWith(
                                    fontSize: 11,
                                    fontWeight: AppTypography.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 21, 16, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (session.latestCompleted != null) ...[
                          contentEyebrow(
                            'Your last ${session.format.label}',
                          ),
                          contentAction(
                            session.latestCompleted!.title,
                            () => _leave(
                              '${AppRoutes.createContent}/item/${Uri.encodeComponent(session.latestCompleted!.id)}',
                            ),
                            dark: false,
                            icon: LucideIcons.arrowRight,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: contentSmallTextButton(
                              'Start a new brief',
                              session.startNewBrief,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        if (session.otherActive != null) ...[
                          contentBody(
                            'A ${session.otherActive!.format.label.toLowerCase()} is already generating.',
                          ),
                          contentAction(
                            'Open running content',
                            () => _leave(
                              '${AppRoutes.createContent}/item/${Uri.encodeComponent(session.otherActive!.id)}',
                            ),
                            dark: false,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (session.step == 1) ..._buildProductStep(session),
                        if (session.step == 2) ..._buildDirectionStep(session),
                        if (session.step == 3) ..._buildOutputStep(session),
                        if (session.error != null)
                          contentErrorBox(
                            session.error!,
                            () => session.flush(),
                          ),
                        const Spacer(),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            if (session.step > 1) ...[
                              SizedBox(
                                width: 62,
                                child: contentAction(
                                  'Back',
                                  () => session.updateBrief({
                                    'settings': {'lastStep': session.step - 1},
                                  }),
                                  dark: false,
                                ),
                              ),
                              const SizedBox(width: 7),
                            ],
                            Expanded(
                              child: contentAction(
                                session.step == 1
                                    ? 'Continue to direction'
                                    : session.step == 2
                                    ? 'Continue'
                                    : _generateLabel(session),
                                session.uploading ||
                                        session.submitting ||
                                        !session.hasSource
                                    ? null
                                    : session.step < 3
                                    ? () => session.updateBrief({
                                        'settings': {
                                          'lastStep': session.step + 1,
                                        },
                                      })
                                    : _generate,
                                icon: LucideIcons.arrowRight,
                              ),
                            ),
                          ],
                        ),
                        if (session.saveState != ContentSaveState.saved)
                          Semantics(
                            liveRegion: true,
                            child: contentSmallTextButton(
                              session.saveState == ContentSaveState.saving
                                  ? 'Saving…'
                                  : session.saveState ==
                                        ContentSaveState.offline
                                  ? 'Offline · Retry save'
                                  : 'Unsaved',
                              () => session.flush(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildProductStep(ContentSession session) {
    final textTheme = Theme.of(context).textTheme;

    return [
      contentIntro(
        'Source',
        'Choose a product.',
        'The entire content package will be built around this piece.',
      ),
      AppTextField(
        controller: _searchController,
        fieldKey: const ValueKey('search-products-field'),
        hintText: 'Search your products',
        leading: const Icon(
          LucideIcons.search,
          size: 16,
          color: AppColors.muted,
        ),
        height: 48,
        textInputAction: TextInputAction.search,
        onChanged: (value) {
          _controller.setSearch(value);
          session.search(value);
        },
      ),
      const SizedBox(height: 30),
      if (session.productsLoading)
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: BarSpinner(color: AppColors.ink, size: 28)),
        ),
      if (session.productError != null)
        contentErrorBox(
          session.productError!,
          () => session.loadProducts(_search),
        ),
      if (!session.productsLoading &&
          session.productError == null &&
          session.products.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: contentBody(
            _search.isEmpty
                ? 'Your product library is empty. Upload a one-off image to get started.'
                : 'No products match your search.',
          ),
        ),
      if (!session.productsLoading && session.productError == null)
        for (final product in session.products)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Semantics(
              selected: session.brief['productId'] == product.id,
              child: InkWell(
                onTap: session.uploading
                    ? null
                    : () => session.selectProduct(product),
                child: Container(
                  height: 65,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: session.brief['productId'] == product.id
                        ? Colors.white
                        : AppColors.soft,
                    border: Border.all(
                      color: session.brief['productId'] == product.id
                          ? AppColors.ink
                          : AppColors.line,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 49,
                        height: 49,
                        child: contentImage(product.imageUrl),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.labelMedium?.copyWith(
                                fontWeight: AppTypography.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${product.sku} · ${product.photos.length.toString().padLeft(2, '0')} photos',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.labelSmall?.copyWith(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 21,
                        height: 21,
                        color: AppColors.ink,
                        child: session.brief['productId'] == product.id
                            ? const Icon(
                                LucideIcons.check,
                                color: Colors.white,
                                size: 13,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      contentAction(
        session.uploading
            ? 'Uploading…'
            : session.uploadUrl != null
            ? 'One-off image selected · Replace'
            : 'Upload a one-off image',
        session.uploading ? null : () => _uploadImage(session),
        dark: false,
        icon: LucideIcons.imagePlus,
      ),
      const SizedBox(height: 4),
      Text(
        'Use a photo that isn’t in your library yet',
        style: textTheme.labelSmall?.copyWith(
          fontSize: 10,
          color: AppColors.muted,
        ),
      ),
    ];
  }

  Future<void> _uploadImage(ContentSession session) async {
    try {
      final picked = await ref
          .read(imagePickerProvider)
          .pickImage(source: ImageSource.gallery);
      if (picked == null || !mounted) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      await session.upload(bytes, picked.name);
    } on Object {
      _message('Could not open this image. Please try again.');
    }
  }

  List<Widget> _buildDirectionStep(ContentSession session) {
    return [
      contentIntro(
        'Creative direction',
        'Shape the story.',
        'Let us lead, or guide the choices that matter to your brand.',
      ),
      const SizedBox(height: 20),
      contentChoice(
        'Look Atlas directs',
        selected: session.brief['directionMode'] == 'auto',
        onTap: () => session.updateBrief({'directionMode': 'auto'}),
        description: 'Composition, setting, crop, and copy handled for you.',
      ),
      const SizedBox(height: 7),
      contentChoice(
        'Guide the direction',
        selected: session.brief['directionMode'] == 'guided',
        onTap: () => session.updateBrief({'directionMode': 'guided'}),
        description: 'Choose the story and visual approach yourself.',
      ),
      const SizedBox(height: 18),
      if (session.format == ContentFormat.slideshow) ...[
        _buildSectionLabel('Number of frames'),
        _buildSegments(
          [3, 4, 5, 6, 7, 8],
          session.settings['frameCount'],
          (value) => session.updateBrief({
            'settings': {'frameCount': value},
          }),
        ),
        const SizedBox(height: 15),
        _buildDropdown(session, 'Story structure', 'story', [
          'Best story',
          'Product reveal',
          'Ways to style it',
          'Why it is made this way',
          'New drop',
        ]),
      ],
      if (session.format == ContentFormat.single)
        _buildDropdown(session, 'Post purpose', 'purpose', [
          'Spotlight a product',
          'Announce a drop',
          'Tell the product story',
          'Start a conversation',
        ]),
      if (session.format == ContentFormat.video) ...[
        _buildDropdown(session, 'Video direction', 'videoDirection', [
          'Campaign teaser',
          'Product detail',
          'Editorial montage',
          'Look in motion',
        ]),
        const SizedBox(height: 15),
        _buildSectionLabel('Duration'),
        _buildSegments(
          [6, 8],
          session.settings['durationSeconds'],
          (value) => session.updateBrief({
            'settings': {'durationSeconds': value},
          }),
          suffix: 's',
        ),
        if (ref.watch(contentVideoEligibleProvider).asData?.value == false) ...[
          const SizedBox(height: 15),
          contentBody('Video requires a Pro or Business plan.'),
          contentAction('View plans', () => _showPaywall(403), dark: false),
        ],
      ],
      if (session.brief['directionMode'] == 'guided') ...[
        const SizedBox(height: 17),
        _buildSectionLabel('Visual direction'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final style in [
              'Clean studio',
              'Editorial',
              'Warm lifestyle',
              'Bold graphic',
            ])
              SizedBox(
                width:
                    (math.min(344, MediaQuery.sizeOf(context).width * .92) -
                        40) /
                    2,
                child: contentAction(
                  style,
                  () => session.updateBrief({
                    'settings': {'visualDirection': style},
                  }),
                  dark: session.settings['visualDirection'] == style,
                ),
              ),
          ],
        ),
      ],
    ];
  }

  Widget _buildSectionLabel(String text) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: textTheme.labelSmall?.copyWith(
          fontSize: 11,
          color: const Color(0xff55554f),
          fontWeight: AppTypography.bold,
        ),
      ),
    );
  }

  Widget _buildSegments(
    List<int> values,
    Object? selected,
    ValueChanged<int> choose, {
    String suffix = '',
  }) => Row(
    children: [
      for (final value in values)
        Expanded(
          child: Semantics(
            selected: value == selected,
            child: Container(
              height: 38,
              margin: const EdgeInsets.only(right: 3),
              child: contentAction(
                '$value$suffix',
                () => choose(value),
                dark: value == selected,
              ),
            ),
          ),
        ),
    ],
  );

  Widget _buildDropdown(
    ContentSession session,
    String label,
    String key,
    List<String> values,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionLabel(label),
      Container(
        height: 39,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.line),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: values.contains(session.settings[key])
                ? session.settings[key] as String
                : values.first,
            isExpanded: true,
            style: const TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 12,
              color: AppColors.ink,
            ),
            items: [
              for (final value in values)
                DropdownMenuItem(
                  value: value,
                  child: Text(
                    value == 'Best story'
                        ? 'Best story for this product'
                        : value,
                  ),
                ),
            ],
            onChanged: (value) => session.updateBrief({
              'settings': {key: value},
            }),
          ),
        ),
      ),
    ],
  );

  List<Widget> _buildOutputStep(ContentSession session) {
    final textTheme = Theme.of(context).textTheme;

    return [
      contentIntro(
        'Output',
        'Prepare the package.',
        'Choose where it will be published and add any final direction.',
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          for (final option in [
            ('instagram', 'Instagram', LucideIcons.camera),
            ('tiktok', 'TikTok', LucideIcons.music2),
            ('both', 'Both', LucideIcons.layers),
          ])
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 5),
                child: InkWell(
                  onTap: () => session.updateBrief({'platform': option.$1}),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: session.brief['platform'] == option.$1
                          ? AppColors.ink
                          : AppColors.soft,
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          option.$3,
                          size: 16,
                          color: session.brief['platform'] == option.$1
                              ? Colors.white
                              : AppColors.ink,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          option.$2,
                          style: textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            fontWeight: AppTypography.bold,
                            color: session.brief['platform'] == option.$1
                                ? AppColors.white
                                : AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 19),
      Row(
        children: [
          _buildSectionLabel('Final notes'),
          const Spacer(),
          Text(
            'Optional',
            style: textTheme.labelSmall?.copyWith(
              fontSize: 11,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
      contentField(
        session.brief['notes'] as String? ?? '',
        (text) => session.updateBrief({'notes': text}),
        hint: 'Anything else we should know?',
        lines: 3,
      ),
      const SizedBox(height: 18),
      contentRule(),
      const SizedBox(height: 14),
      contentEyebrow('Included'),
      for (final item in [
        if (session.format == ContentFormat.single)
          'One 4:5 visual'
        else if (session.format == ContentFormat.video)
          '${session.settings['durationSeconds']}s video + cover frames'
        else
          '${session.settings['frameCount']} connected visuals',
        'Caption',
        'Hashtag set',
        if (session.format != ContentFormat.single) 'Music direction',
      ])
        Container(
          constraints: const BoxConstraints(minHeight: 34),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xffdfdfd8))),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.layers, size: 16),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item,
                  style: textTheme.labelSmall?.copyWith(
                    fontSize: 12,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ),
              const Icon(LucideIcons.check, size: 14),
            ],
          ),
        ),
      if (session.quoteError != null)
        contentSmallTextButton(
          '${session.quoteError} Retry',
          session.requote,
        ),
    ];
  }

  String _generateLabel(ContentSession session) => session.submitting
      ? 'Generating…'
      : session.quote == null
      ? 'Generate'
      : session.quote!.cost == 0
      ? 'Generate · Included in your plan'
      : 'Generate · ${session.quote!.cost} credits';
}
