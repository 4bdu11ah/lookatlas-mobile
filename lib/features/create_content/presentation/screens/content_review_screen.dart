import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/network/request_cancellation.dart';
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
import 'package:look_atlas/shared/widgets/app_icon_button.dart';
import 'package:look_atlas/shared/widgets/app_snack_bar.dart';
import 'package:look_atlas/shared/widgets/app_text_button.dart';
import 'package:look_atlas/shared/widgets/app_text_field.dart';
import 'package:look_atlas/shared/widgets/bar_spinner.dart';
import 'package:look_atlas/shared/widgets/primary_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

class ContentReviewScreen extends ConsumerStatefulWidget {
  const ContentReviewScreen({
    required this.contentId,
    super.key,
    this.format,
    this.previewImageUrl,
    this.openCaptionPanel = false,
  });

  final String contentId;
  final ContentFormat? format;
  final String? previewImageUrl;
  final bool openCaptionPanel;

  @override
  ConsumerState<ContentReviewScreen> createState() =>
      _ContentReviewScreenState();
}

class _ContentReviewScreenState extends ConsumerState<ContentReviewScreen>
    with WidgetsBindingObserver {
  late final ContentSessionArgs _args;
  RequestCancellation? _downloadToken;
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _hashtagController = TextEditingController();
  final TextEditingController _retouchController = TextEditingController();
  final FocusScopeNode _panelFocus = FocusScopeNode();

  String? _syncedCaptionGenerationId;
  bool _paywallVisible = false;

  CreateContentUIState get _ui => ref.watch(createContentControllerProvider);
  CreateContentController get _controller =>
      ref.read(createContentControllerProvider.notifier);

  bool get _leftOpen => _ui.leftOpen;
  bool get _rightOpen => _ui.rightOpen;
  bool get _preview => _ui.preview;
  double get _canvasZoom => _ui.canvasZoom;
  bool get _exportOpen => _ui.exportOpen;
  bool get _leaving => _ui.leaving;
  String? get _tool => _ui.tool;
  String get _exportStatus => _ui.exportStatus;
  double? get _exportProgress => _ui.exportProgress;
  String? get _exportError => _ui.exportError;
  String? get _signedUrl => _ui.signedUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _args = (
      format: widget.format ?? ContentFormat.slideshow,
      generationId: widget.contentId,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller
          ..setLeaving(leaving: false)
          ..closePanels();
        if (widget.openCaptionPanel) _controller.openRightPanel();
        final session = ref.read(contentSessionProvider(_args));
        unawaited(
          session.initialize(generationId: widget.contentId),
        );
      }
    });
  }

  @override
  void didUpdateWidget(covariant ContentReviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.openCaptionPanel && widget.openCaptionPanel) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openPanel(left: false);
      });
    }
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
    _downloadToken?.cancel();
    _captionController.dispose();
    _hashtagController.dispose();
    _retouchController.dispose();
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

  void _openPanel({required bool left, bool export = false}) {
    _controller.openPanel(left: left, export: export);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _panelFocus.requestFocus();
    });
  }

  void _message(String text) {
    if (mounted) {
      AppSnackBar.show(context, text);
    }
  }

  Future<void> _copy(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      _message('Copied');
    } on Object {
      _message('Could not copy. Please try again.');
    }
  }

  Future<void> _showPaywall(int status) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierColor: const Color(0xbf000000),
      builder: (dialogContext) {
        final textTheme = Theme.of(dialogContext).textTheme;
        return Dialog(
          alignment: Alignment.bottomCenter,
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: const Color(0xff0a0a0a),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0x1affffff)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          'UPGRADE',
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.white70,
                            fontSize: 10,
                            letterSpacing: 1.8,
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      AppIconButton(
                        icon: LucideIcons.x,
                        tooltip: 'Close paywall',
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        color: Colors.white60,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    status == 403
                        ? 'Unlock video posts'
                        : 'Keep creating content',
                    style: textTheme.headlineSmall?.copyWith(
                      fontFamily: AppTypography.displayFontFamily,
                      fontSize: 24,
                      height: 1.15,
                      letterSpacing: -.5,
                      fontWeight: AppTypography.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    status == 403
                        ? 'Video posts are part of the Pro and Business plans. Upgrade to turn your products into short vertical films.'
                        : 'You are out of credits for this run. Upgrade or top up to generate this content package.',
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      height: 1.625,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),
                  for (final item in [
                    'Unlimited photos on Business',
                    'Human touch-ups by real retouchers',
                    'Manage cancellation anytime in Billing',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            LucideIcons.check,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item,
                              style: textTheme.bodyMedium?.copyWith(
                                fontSize: 15,
                                color: const Color(0xd9ffffff),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: 'See plans',
                    icon: LucideIcons.arrowRight,
                    iconAlignment: IconAlignment.end,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    textStyle: textTheme.titleSmall?.copyWith(
                      fontSize: 15,
                      fontWeight: AppTypography.bold,
                      color: Colors.black,
                    ),
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
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
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: contentSmallTextButton(
                      'Not now',
                      () => Navigator.of(dialogContext).pop(),
                      color: Colors.white54,
                    ),
                  ),
                  Center(
                    child: Text(
                      'Fair usage terms apply to all plans.',
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
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
    await session.generate(retry: retry);
    if (mounted && session.generation?.active == true) {
      _controller.closePanels();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(createContentControllerProvider);
    final session = ref.watch(contentSessionProvider(_args));

    ref.listen<ContentSession>(contentSessionProvider(_args), (_, next) {
      if (next.generation?.kit != null &&
          _syncedCaptionGenerationId != next.generation!.id) {
        _syncedCaptionGenerationId = next.generation!.id;
        _captionController.text =
            next.generation!.kit!['caption'] as String? ?? '';
      }

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
          if (_leftOpen || _rightOpen) {
            unawaited(_closePanel());
          } else if (_preview) {
            _controller.setPreview(preview: false);
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
                  if (_leftOpen || _rightOpen) {
                    unawaited(_closePanel());
                  } else {
                    _controller.setPreview(preview: false);
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
                        : session.restorationFailed
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: contentErrorBox(
                                session.error ??
                                    'Could not restore your content.',
                                () => session.initialize(
                                  generationId: widget.contentId,
                                ),
                              ),
                            ),
                          )
                        : Stack(
                            children: [
                              Positioned.fill(
                                child: ExcludeFocus(
                                  excluding: _leftOpen || _rightOpen,
                                  child: ExcludeSemantics(
                                    excluding: _leftOpen || _rightOpen,
                                    child: _buildCanvas(session),
                                  ),
                                ),
                              ),
                              if (_leftOpen || _rightOpen)
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
                              if (_leftOpen || _rightOpen)
                                Align(
                                  alignment: _leftOpen
                                      ? Alignment.centerLeft
                                      : Alignment.centerRight,
                                  child: FocusScope(
                                    node: _panelFocus,
                                    child: Container(
                                      width: _leftOpen
                                          ? math.min(
                                              344,
                                              MediaQuery.sizeOf(context).width *
                                                  .92,
                                            )
                                          : math.min(
                                              376,
                                              MediaQuery.sizeOf(context).width,
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
                                            offset: Offset(
                                              _leftOpen ? 28 : -28,
                                              0,
                                            ),
                                          ),
                                        ],
                                      ),
                                      child: _leftOpen
                                          ? _buildTools(session)
                                          : (_exportOpen
                                                ? _buildExport(session)
                                                : _buildPublishing(session)),
                                    ),
                                  ),
                                ),
                              if (_leaving)
                                const Positioned.fill(
                                  child: ColoredBox(
                                    color: Color(0x99fbfaf7),
                                    child: Center(
                                      child: BarSpinner(
                                        color: AppColors.ink,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                ),
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
    return Container(
      height: 56,
      color: AppColors.ink,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          AppIconButton(
            icon: LucideIcons.arrowLeft,
            tooltip: 'Back to Create Content',
            onPressed: _leave,
            color: Colors.white70,
          ),
          const Spacer(),
          contentSmallTextButton(
            session.reviewing ? 'Tools' : 'Brief',
            () => _openPanel(left: true),
            color: Colors.white70,
            label: session.reviewing
                ? 'Open frame tools'
                : 'Open creative brief',
          ),
          if (session.reviewing) ...[
            AppIconButton(
              icon: _preview ? LucideIcons.pause : LucideIcons.play,
              tooltip: _preview
                  ? 'Exit preview'
                  : 'Preview ${session.format.label}',
              onPressed: () async {
                if (!await session.flushEdits() || !mounted) return;
                _controller.togglePreview();
              },
              color: Colors.white70,
            ),
            ColoredBox(
              color: _rightOpen && !_exportOpen
                  ? const Color(0xff2e2e2b)
                  : Colors.transparent,
              child: AppIconButton(
                icon: LucideIcons.captions,
                tooltip: 'Open caption and hashtags',
                onPressed: () => _openPanel(left: false),
                color: Colors.white70,
              ),
            ),
            contentHeaderAction(
              'Download',
              LucideIcons.download,
              () => _openPanel(left: false, export: true),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCanvas(ContentSession session) {
    final textTheme = Theme.of(context).textTheme;
    final generation = session.generation;
    final frames = generation?.frames ?? [];
    final current = session.frame;
    final active = generation?.active ?? false;
    final failed = generation?.failed ?? false;
    final frameTotal = session.format == ContentFormat.slideshow
        ? (session.settings['frameCount'] as num? ?? 5).toInt()
        : 1;

    return Column(
      children: [
        if (!_preview)
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: const BoxDecoration(
              color: AppColors.paper,
              border: Border(bottom: BorderSide(color: AppColors.line)),
            ),
            child: Row(
              children: [
                Flexible(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: session.reviewing
                            ? const Color(0xffe8eee9)
                            : AppColors.soft,
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Text(
                        active
                            ? contentGenerationPhaseLabel(
                                generation?.data['phase'] as String?,
                              )
                            : session.reviewing
                            ? 'READY TO REVIEW'
                            : 'LIVE PREVIEW',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: AppTypography.bold,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ContentCanvasControls(
                  zoom: _canvasZoom,
                  onZoomOut: _controller.zoomCanvasOut,
                  onFit: _controller.fitCanvas,
                  onZoomIn: _controller.zoomCanvasIn,
                ),
              ],
            ),
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
                          _preview ? 760.0 : 540.0,
                          math.min(box.maxHeight - 18, box.maxWidth / ratio),
                        );
                        return Center(
                          child: SizedBox(
                            height: math.max(0, height * _canvasZoom),
                            width: math.max(0, height * ratio * _canvasZoom),
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
                                  if (generation?.video?['url'] != null &&
                                      _preview)
                                    _ContentVideo(
                                      url: generation!.video!['url'] as String,
                                    )
                                  else if (current != null)
                                    _frameImage(current)
                                  else
                                    contentImage(
                                      widget.previewImageUrl ??
                                          session.selectedProduct?.imageUrl ??
                                          session.uploadUrl,
                                    ),
                                  if (active)
                                    ContentGenerationLoadingOverlay(
                                      format: session.format,
                                      generation: generation,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (failed)
                  Positioned.fill(
                    child: Container(
                      color: AppColors.paper.withValues(alpha: .94),
                      padding: const EdgeInsets.all(26),
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.circleAlert, size: 32),
                              const SizedBox(height: 20),
                              contentDisplay('This run needs another try.', 32),
                              const SizedBox(height: 14),
                              contentBody(
                                'We couldn’t finish this content package. Your brief is preserved.',
                              ),
                              const SizedBox(height: 22),
                              if (generation!.retryable)
                                contentAction(
                                  'Retry generation',
                                  session.submitting
                                      ? null
                                      : () => _generate(retry: true),
                                ),
                              const SizedBox(height: 8),
                              contentAction('Adjust brief', () async {
                                await session.adjustBrief();
                                if (!mounted) return;
                                _openPanel(left: true);
                              }, dark: false),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (session.error != null && !_leftOpen && !_rightOpen)
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: contentErrorBox(session.error!, () {
                      if (session.loading || session.generation == null) {
                        unawaited(
                          session.initialize(generationId: widget.contentId),
                        );
                      } else {
                        unawaited(session.pollGeneration());
                      }
                    }),
                  ),
                if (session.reviewing && frames.length > 1)
                  Align(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ColoredBox(
                            color: AppColors.paper.withValues(alpha: .9),
                            child: AppIconButton(
                              icon: LucideIcons.chevronLeft,
                              tooltip: 'Previous frame',
                              color: session.selectedFrame > 0
                                  ? AppColors.ink
                                  : AppColors.muted,
                              size: 16,
                              onPressed: session.selectedFrame > 0
                                  ? () => session.selectFrame(
                                      session.selectedFrame - 1,
                                    )
                                  : null,
                            ),
                          ),
                          ColoredBox(
                            color: AppColors.paper.withValues(alpha: .9),
                            child: AppIconButton(
                              icon: LucideIcons.chevronRight,
                              tooltip: 'Next frame',
                              color: session.selectedFrame < frames.length - 1
                                  ? AppColors.ink
                                  : AppColors.muted,
                              size: 16,
                              onPressed:
                                  session.selectedFrame < frames.length - 1
                                  ? () => session.selectFrame(
                                      session.selectedFrame + 1,
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_preview && frames.isNotEmpty)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        color: AppColors.paper,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        child: Text(
                          '${session.selectedFrame + 1} / ${frames.length}',
                          style: textTheme.labelMedium,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (!_preview && active)
          ContentGenerationFilmstrip(
            format: session.format,
            frames: frames,
            total: frameTotal,
            generating: true,
            backgroundImageUrl:
                widget.previewImageUrl ??
                session.selectedProduct?.imageUrl ??
                session.uploadUrl,
          ),
        if (!_preview && !active && frames.isNotEmpty)
          Container(
            height: 116,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.paper,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 76,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Frames',
                        style: textTheme.labelMedium?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${frames.length} total',
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: AppColors.muted,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Select to review',
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: frames.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 7),
                    itemBuilder: (context, index) => Semantics(
                      selected: index == session.selectedFrame,
                      button: true,
                      label: 'Frame ${index + 1}: ${frames[index].label}',
                      child: InkWell(
                        onTap: () => session.selectFrame(index),
                        child: SizedBox(
                          width: 66,
                          child: Column(
                            children: [
                              Container(
                                width: 66,
                                height: 80,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: index == session.selectedFrame
                                        ? AppColors.ink
                                        : AppColors.line,
                                    width: index == session.selectedFrame
                                        ? 2
                                        : 1,
                                  ),
                                ),
                                child: _frameImage(frames[index]),
                              ),
                              Text(
                                frames[index].label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.labelSmall?.copyWith(
                                  fontSize: 9,
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
      ],
    );
  }

  Widget _frameImage(ContentFrame frame) => LayoutBuilder(
    builder: (context, box) {
      final crop = frame.crop;
      final scale = (crop?['scale'] as num? ?? 1).toDouble();
      final x = (crop?['x'] as num? ?? 50).toDouble() / 100;
      final y = (crop?['y'] as num? ?? 50).toDouble() / 100;
      return ClipRect(
        child: Transform.scale(
          scale: scale,
          child: contentImage(
            frame.imageUrl,
            alignment: Alignment(x * 2 - 1, y * 2 - 1),
          ),
        ),
      );
    },
  );

  Widget _buildTools(ContentSession session) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        contentPanelTitle(
          'Frame tools',
          'Frame ${(session.selectedFrame + 1).toString().padLeft(2, '0')}',
          _closePanel,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 21, 16, 18),
            children: [
              if (_tool != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: contentSmallTextButton(
                    '‹ All tools',
                    () => _controller.setTool(null),
                  ),
                ),
              if (session.editBusy) ...[
                const LinearProgressIndicator(color: AppColors.ink),
                const SizedBox(height: 10),
                contentBody('Editing this frame…'),
              ],
              if (session.editError != null)
                contentErrorBox(session.editError!, session.flushEdits),
              if (session.error != null)
                contentErrorBox(session.error!, session.flushEdits),
              if (_tool == null) ...[
                contentIntro(
                  'Edit frame',
                  session.frame?.label ?? 'Select a frame',
                  'Fine-tune the image without changing the rest of the story.',
                ),
                const SizedBox(height: 24),
                for (final entry in [
                  ('crop', 'Crop & position'),
                  if (session.frame?.variants.isNotEmpty ?? false)
                    ('replace', 'Replace variation'),
                  ('retouch', 'Retouch'),
                  ('regenerate', 'Regenerate frame'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: contentAction(
                      entry.$2,
                      session.editBusy
                          ? null
                          : () => _controller.setTool(entry.$1),
                      dark: false,
                      icon: LucideIcons.chevronRight,
                    ),
                  ),
                if (session.format == ContentFormat.video) ...[
                  const SizedBox(height: 12),
                  contentAction(
                    session.generation?.video?['coverFrameIndex'] ==
                            session.frame?.index
                        ? 'Selected video cover'
                        : 'Use as video cover',
                    session.editBusy || session.frame == null
                        ? null
                        : () => session.updatePublishing({
                            'coverFrameIndex': session.frame!.index,
                          }),
                    dark: false,
                  ),
                ],
                const SizedBox(height: 24),
                contentAction(
                  'Adjust brief',
                  session.editBusy
                      ? null
                      : () async {
                          await session.adjustBrief();
                          if (!mounted) return;
                          _controller.setTool(null);
                        },
                  dark: false,
                ),
              ],
              if (_tool == 'crop') ...[
                contentIntro(
                  'Image',
                  'Crop & position',
                  'Changes save as you go and apply to every download of this frame.',
                ),
                const SizedBox(height: 24),
                for (final field in [
                  ('scale', 'Image scale', 1.0, 1.55, 1.0),
                  ('x', 'Horizontal', 0.0, 100.0, 50.0),
                  ('y', 'Vertical', 0.0, 100.0, 50.0),
                ]) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          field.$2,
                          style: textTheme.labelMedium?.copyWith(
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${((session.frame?.crop?[field.$1] as num? ?? field.$5) * (field.$1 == 'scale' ? 100 : 1)).round()}%',
                        style: textTheme.labelSmall,
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.ink,
                      thumbColor: AppColors.ink,
                      thumbShape: const SquareSliderThumb(),
                      trackHeight: 2,
                    ),
                    child: Slider(
                      label: field.$2,
                      min: field.$3,
                      max: field.$4,
                      value:
                          (session.frame?.crop?[field.$1] as num? ?? field.$5)
                              .toDouble()
                              .clamp(field.$3, field.$4),
                      onChanged: session.editBusy
                          ? null
                          : (value) => session.updateCrop({
                              'scale': 1.0,
                              'x': 50.0,
                              'y': 50.0,
                              ...?session.frame?.crop,
                              field.$1: value,
                            }),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Row(
                  children: [
                    Expanded(
                      child: contentAction(
                        'Reset',
                        session.editBusy
                            ? null
                            : () => session.updateCrop(null),
                        dark: false,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(child: contentAction('Done', _closePanel)),
                  ],
                ),
              ],
              if (_tool == 'replace') ...[
                contentIntro(
                  'Image',
                  'Replace variation',
                  'Choose a variation for this frame.',
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final variant
                        in session.frame?.variants ?? <ContentJson>[])
                      SizedBox(
                        width:
                            (math.min(
                                  344,
                                  MediaQuery.sizeOf(context).width * .92,
                                ) -
                                46) /
                            3,
                        height:
                            (math.min(
                                  344,
                                  MediaQuery.sizeOf(context).width * .92,
                                ) -
                                46) /
                            3 *
                            1.25,
                        child: Semantics(
                          selected:
                              variant['variantId'] ==
                              session.frame?.data['selectedVariantId'],
                          label: 'Select variation',
                          button: true,
                          child: InkWell(
                            onTap: session.editBusy
                                ? null
                                : () => session.selectVariant(
                                    variant['variantId'] as String,
                                  ),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color:
                                      variant['variantId'] ==
                                          session
                                              .frame
                                              ?.data['selectedVariantId']
                                      ? AppColors.ink
                                      : AppColors.line,
                                  width: 2,
                                ),
                              ),
                              child: contentImage(
                                variant['imageUrl'] as String?,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              if (_tool == 'retouch') ...[
                contentIntro(
                  'Image',
                  'Retouch this frame.',
                  'Describe the detail you want to change.',
                ),
                const SizedBox(height: 24),
                Text(
                  'What should change?',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _retouchController,
                  onChanged: (_) => _controller.notifySessionChanged(),
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 1000,
                  hintText: 'Describe your retouch…',
                  textStyle: textTheme.labelMedium,
                ),
                const SizedBox(height: 22),
                contentAction(
                  'Apply retouch · 1 credit',
                  session.editBusy || _retouchController.text.trim().isEmpty
                      ? null
                      : () =>
                            session.editFrame(prompt: _retouchController.text),
                ),
              ],
              if (_tool == 'regenerate') ...[
                contentIntro(
                  'Image',
                  'Regenerate this frame.',
                  'Create a fresh variation while keeping the rest of your content.',
                ),
                const SizedBox(height: 24),
                contentAction(
                  'Regenerate frame · 1 credit',
                  session.editBusy ? null : session.editFrame,
                ),
              ],
              if (session.editSaveState != ContentSaveState.saved)
                contentSmallTextButton(
                  session.editSaveState == ContentSaveState.saving
                      ? 'Saving…'
                      : 'Unsaved · Retry',
                  session.flushEdits,
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<String> _hashtags(ContentSession session) =>
      (session.generation?.kit?['hashtags'] as List? ?? []).cast<String>();

  String _hashText(ContentSession session) =>
      _hashtags(session).map((tag) => '#$tag').join(' ');

  String _publishingText(ContentSession session) {
    final music = session.generation?.kit?['musicDirection'] as String? ?? '';
    return [
      _captionController.text.trim(),
      _hashText(session),
      if (music.isNotEmpty) 'Music direction: $music',
    ].where((part) => part.isNotEmpty).join('\n\n');
  }

  Widget _buildPublishing(ContentSession session) {
    final textTheme = Theme.of(context).textTheme;
    final kit = session.generation?.kit;
    final hashtags = _hashtags(session);
    final hashText = _hashText(session);
    final music = kit?['musicDirection'] as String? ?? '';

    return Column(
      children: [
        contentPanelTitle(
          'Caption & hashtags',
          session.generation?.title ?? session.format.label,
          _closePanel,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              if (kit == null)
                contentBody(
                  'The caption and hashtags will appear here when your content is ready.',
                )
              else ...[
                _copyHeading('Caption', _captionController.text),
                SizedBox(
                  height: 150,
                  child: AppTextField(
                    controller: _captionController,
                    onChanged: (text) => session.updatePublishing({
                      'caption': text,
                    }, debounce: true),
                    maxLines: null,
                    minLines: null,
                    expands: true,
                    textStyle: textTheme.bodyLarge,
                    contentPadding: const EdgeInsets.all(11),
                  ),
                ),
                const SizedBox(height: 24),
                contentRule(),
                const SizedBox(height: 12),
                _copyHeading('Hashtags', hashText),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tag in hashtags)
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.soft,
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                '#$tag',
                                style: textTheme.labelSmall?.copyWith(
                                  fontWeight: AppTypography.bold,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 28,
                              height: 30,
                              child: AppIconButton(
                                icon: LucideIcons.x,
                                tooltip: 'Remove hashtag $tag',
                                color: AppColors.ink,
                                size: 16,
                                onPressed: () => session.updatePublishing({
                                  'hashtags': hashtags
                                      .where((t) => t != tag)
                                      .toList(),
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _hashtagController,
                        hintText: 'Add hashtags',
                        height: 40,
                        onFieldSubmitted: (_) => _addTags(session),
                        textInputAction: TextInputAction.done,
                      ),
                    ),
                    const SizedBox(width: 7),
                    contentSmallTextButton('Add', () => _addTags(session)),
                  ],
                ),
                const SizedBox(height: 18),
                contentRule(),
                if (music.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _copyHeading('Music direction', music),
                  Text(
                    music,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  contentRule(),
                ],
                const SizedBox(height: 20),
                contentAction(
                  'Copy caption + hashtags',
                  () => _copy(
                    [_captionController.text.trim(), hashText].join('\n\n'),
                  ),
                  icon: LucideIcons.copy,
                ),
                const SizedBox(height: 8),
                contentAction(
                  'Download publishing kit',
                  () => _downloadKit(session),
                  dark: false,
                  icon: LucideIcons.download,
                ),
                if (session.editSaveState != ContentSaveState.saved)
                  contentSmallTextButton(
                    session.editSaveState == ContentSaveState.saving
                        ? 'Saving…'
                        : 'Unsaved · Retry',
                    session.flushEdits,
                  ),
                if (session.editError != null)
                  contentErrorBox(session.editError!, session.flushEdits),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _copyHeading(String title, String text) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: textTheme.labelMedium?.copyWith(
              fontWeight: AppTypography.bold,
            ),
          ),
        ),
        AppTextButton(
          label: 'Copy',
          icon: LucideIcons.copy,
          fitToContent: true,
          showBorder: false,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          textColor: AppColors.muted,
          textStyle: textTheme.labelSmall?.copyWith(
            fontWeight: AppTypography.bold,
          ),
          onPressed: () => _copy(text),
        ),
      ],
    );
  }

  void _addTags(ContentSession session) {
    final tag = _hashtagController.text.trim();
    if (tag.isEmpty) return;
    session.updatePublishing({
      'hashtags': [..._hashtags(session), tag],
    });
    _hashtagController.clear();
  }

  Future<void> _downloadKit(ContentSession session) async {
    if (!await session.flushEdits() || !mounted) return;
    try {
      await _shareBytes(
        Uint8List.fromList(utf8.encode(_publishingText(session))),
        'publishing-kit.txt',
        'text/plain',
      );
    } on Object {
      _message('Could not save the publishing kit. Please try again.');
    }
  }

  Future<ShareResult> _shareBytes(Uint8List bytes, String name, String mime) =>
      SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: mime, name: name)],
          fileNameOverrides: [name],
          sharePositionOrigin: Rect.fromLTWH(
            MediaQuery.sizeOf(context).width / 2,
            56,
            1,
            1,
          ),
        ),
      );

  Widget _buildExport(ContentSession session) {
    final textTheme = Theme.of(context).textTheme;
    final platform = session.generation?.data['platform'];

    return Column(
      children: [
        contentPanelTitle('Download', 'Your content package', _closePanel),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            children: [
              contentIntro(
                'Download',
                'Everything in one zip.',
                'The visuals, platform-sized crops, and the caption and hashtags as a text file.',
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.line),
                    bottom: BorderSide(color: AppColors.line),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.layers, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.format == ContentFormat.video
                                ? 'Video, cover, and crops'
                                : '${session.generation?.frames.length ?? 0} finished ${session.format == ContentFormat.slideshow ? 'frames' : 'assets'}',
                            style: textTheme.labelMedium?.copyWith(
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            platform == 'both'
                                ? 'Instagram 4:5 and 1:1 plus TikTok 9:16 crops included.'
                                : platform == 'tiktok'
                                ? 'TikTok 9:16 crops included.'
                                : 'Instagram 4:5 and 1:1 crops included.',
                            style: textTheme.labelSmall?.copyWith(
                              height: 1.5,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_exportStatus == 'preparing') ...[
                LinearProgressIndicator(
                  value: _exportProgress,
                  color: AppColors.ink,
                ),
                const SizedBox(height: 12),
              ],
              contentAction(
                _exportStatus == 'preparing'
                    ? 'Preparing files…'
                    : _exportStatus == 'done'
                    ? 'Downloaded · Save again'
                    : _exportStatus == 'error'
                    ? 'Download failed · Retry'
                    : 'Download zip',
                _exportStatus == 'preparing' || session.editBusy
                    ? null
                    : () => _downloadExport(session),
                icon: _exportStatus == 'done'
                    ? LucideIcons.check
                    : LucideIcons.download,
              ),
              if (_exportError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: contentBody(_exportError!),
                ),
              if (_signedUrl != null && _exportStatus == 'error')
                contentSmallTextButton(
                  'Share signed download link',
                  () => SharePlus.instance.share(ShareParams(text: _signedUrl)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _downloadExport(ContentSession session) async {
    if (_exportStatus == 'preparing' ||
        session.generation == null ||
        session.editBusy) {
      return;
    }
    _controller.startExport();
    try {
      if (!await session.flush()) throw StateError('Save failed');
      final archive = await ref.read(contentArchiveDownloadProvider)(
        session.generation!.id,
        cancellation: _downloadToken = RequestCancellation(),
        onProgress: (received, total) {
          if (mounted) {
            _controller.updateExportProgress(
              total > 0 ? received / total : null,
            );
          }
        },
      );
      if (!mounted) return;
      final shared = await _shareBytes(
        archive.bytes,
        archive.name,
        'application/zip',
      );
      if (shared.status == ShareResultStatus.dismissed) {
        if (mounted) _controller.setExportIdle();
        return;
      }
      if (mounted) _controller.setExportDone();
    } on Object catch (error) {
      session.reportFailure(error);
      if (mounted) {
        _controller.setExportError(
          'Could not download your package. Retry to request a fresh download link.',
        );
      }
    }
  }
}

class _ContentVideo extends ConsumerStatefulWidget {
  const _ContentVideo({required this.url});
  final String url;
  @override
  ConsumerState<_ContentVideo> createState() => _ContentVideoState();
}

class _ContentVideoState extends ConsumerState<_ContentVideo>
    with WidgetsBindingObserver {
  VideoPlayerController? player;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
  }

  Future<void> _load() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    player = controller;
    try {
      await controller.initialize();
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref
                .read(videoReviewStateProvider(widget.url).notifier)
                .setInitialized();
          }
        });
      }
    } on Object {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref
                .read(videoReviewStateProvider(widget.url).notifier)
                .setFailed(failed: true);
          }
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(player?.pause());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(player?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoState = ref.watch(videoReviewStateProvider(widget.url));
    return ColoredBox(
      color: Colors.black,
      child: videoState.failed
          ? Center(
              child: contentAction('Video could not load · Retry', () async {
                await player?.dispose();
                ref.read(videoReviewStateProvider(widget.url).notifier).reset();
                await _load();
              }),
            )
          : !videoState.isInitialized || player?.value.isInitialized != true
          ? const Center(
              child: BarSpinner(color: Colors.white, size: 28),
            )
          : ValueListenableBuilder(
              valueListenable: player!,
              builder: (context, value, _) => Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: value.aspectRatio,
                    child: VideoPlayer(player!),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        VideoProgressIndicator(player!, allowScrubbing: true),
                        AppIconButton(
                          icon: value.isPlaying
                              ? LucideIcons.pause
                              : LucideIcons.play,
                          tooltip: value.isPlaying
                              ? 'Pause video'
                              : 'Play video',
                          color: AppColors.ink,
                          size: 16,
                          onPressed: () {
                            if (value.isPlaying) {
                              unawaited(player!.pause());
                            } else {
                              unawaited(player!.play());
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
