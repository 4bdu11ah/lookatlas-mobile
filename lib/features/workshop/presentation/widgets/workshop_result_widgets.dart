part of '../screens/workshop_screen.dart';

class _WorkshopResultPanel extends StatelessWidget {
  const _WorkshopResultPanel({
    required this.state,
    required this.onDownload,
    required this.onUseAsBase,
  });

  final WorkshopState state;
  final VoidCallback onDownload;
  final VoidCallback onUseAsBase;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WorkshopFieldLabel(
          title: state.isProcessing ? 'Generating' : 'Result',
        ),
        const SizedBox(height: 8),
        _WorkshopShell(
          child: state.isProcessing
              ? _GenerationProgress(
                  generation: state.activeGeneration!,
                  orientation: state.baseImage?.orientation,
                )
              : state.hasResult
              ? _CompletedResult(
                  generation: state.result!,
                  orientation: state.baseImage?.orientation,
                  onDownload: onDownload,
                  onUseAsBase: onUseAsBase,
                )
              : _EmptyResult(orientation: state.baseImage?.orientation),
        ),
      ],
    );
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult({required this.orientation});

  final WorkshopImageOrientation? orientation;

  @override
  Widget build(BuildContext context) {
    return AppDottedBorder(
      child: AspectRatio(
        aspectRatio: _orientationRatio(orientation),
        child: const ColoredBox(
          color: AppColors.neutral100,
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_fix_high_outlined,
                  size: 32,
                  color: AppColors.neutral400,
                ),
                SizedBox(height: 12),
                Text(
                  'Your edit will appear here',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: AppTypography.medium,
                    color: AppColors.inkAlpha80,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Try: "swap the background to a beach", "add a watch on the wrist", or "make this a flat-lay product shot".',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 19 / 12,
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GenerationProgress extends StatefulWidget {
  const _GenerationProgress({
    required this.generation,
    required this.orientation,
  });

  final WorkshopGeneration generation;
  final WorkshopImageOrientation? orientation;

  @override
  State<_GenerationProgress> createState() => _GenerationProgressState();
}

class _GenerationProgressState extends State<_GenerationProgress> {
  static const List<String> _hints = [
    'Reading your reference…',
    'Composing the scene…',
    'Polishing details…',
    'Almost there…',
  ];

  Timer? _timer;
  late int _elapsedSeconds;

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  @override
  void didUpdateWidget(covariant _GenerationProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.generation.id != widget.generation.id) _resetTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resetTimer() {
    _timer?.cancel();
    final createdAt = widget.generation.createdAt;
    _elapsedSeconds = createdAt == null
        ? 0
        : DateTime.now().difference(createdAt).inSeconds.clamp(0, 86400);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hint = _hints[(_elapsedSeconds ~/ 8) % _hints.length];
    return Column(
      children: [
        AspectRatio(
          aspectRatio: _orientationRatio(widget.orientation),
          child: const Stack(
            fit: StackFit.expand,
            children: [
              ShimmerBox(),
              Center(
                child: Icon(
                  Icons.auto_fix_high_outlined,
                  size: 40,
                  color: AppColors.blackAlpha20,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _WorkshopProgressTrack(),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            hint,
            key: ValueKey(hint),
            style: const TextStyle(fontSize: 14, height: 20 / 14),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.schedule, size: 12, color: AppColors.neutral500),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '${_formatElapsed(_elapsedSeconds)} elapsed · usually 30–90s · safe to leave this page',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  color: AppColors.neutral500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.whiteAlpha60,
            border: Border.all(color: AppColors.neutral200),
          ),
          child: const Text(
            "Your generation is running on our servers. Refresh, switch tabs, or come back later — it'll be here when you return.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 16 / 12,
              color: AppColors.neutral500,
            ),
          ),
        ),
      ],
    );
  }

  String _formatElapsed(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final remainder = (seconds % 60).toString().padLeft(2, '0');
    return '${seconds ~/ 60}:$remainder';
  }
}

class _WorkshopProgressTrack extends StatefulWidget {
  const _WorkshopProgressTrack();

  @override
  State<_WorkshopProgressTrack> createState() => _WorkshopProgressTrackState();
}

class _WorkshopProgressTrackState extends State<_WorkshopProgressTrack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 4,
      child: ColoredBox(
        color: AppColors.neutral100,
        child: ClipRect(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, child) => FractionalTranslation(
              translation: Offset(_controller.value * 4 - 1, 0),
              child: child,
            ),
            child: const FractionallySizedBox(
              widthFactor: 1 / 3,
              alignment: Alignment.centerLeft,
              child: ColoredBox(color: AppColors.black),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletedResult extends StatelessWidget {
  const _CompletedResult({
    required this.generation,
    required this.orientation,
    required this.onDownload,
    required this.onUseAsBase,
  });

  final WorkshopGeneration generation;
  final WorkshopImageOrientation? orientation;
  final VoidCallback onDownload;
  final VoidCallback onUseAsBase;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: _orientationRatio(orientation),
          child: AppImage(generation.imageUrl!),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _WorkshopOutlineButton(
              icon: Icons.download_outlined,
              label: 'Download',
              onTap: onDownload,
            ),
            _WorkshopOutlineButton(
              icon: Icons.auto_fix_high_outlined,
              label: 'Use as base',
              onTap: onUseAsBase,
            ),
          ],
        ),
      ],
    );
  }
}

class _WorkshopHistoryPanel extends StatelessWidget {
  const _WorkshopHistoryPanel({
    required this.isLoading,
    required this.history,
    required this.onSelect,
  });

  final bool isLoading;
  final List<WorkshopGeneration> history;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _WorkshopFieldLabel(title: 'Recent generations'),
        const SizedBox(height: 12),
        if (isLoading)
          const _HistoryLoading()
        else if (history.isEmpty)
          const Text(
            'Nothing yet. Generations land here so you can revisit, download, or chain edits.',
            style: TextStyle(
              fontSize: 14,
              height: 20 / 14,
              color: AppColors.neutral500,
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: history.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _HistoryTile(
                item: history[index],
                onTap: () => onSelect(index),
              ),
            ),
          ),
      ],
    );
  }
}

class _HistoryLoading extends StatelessWidget {
  const _HistoryLoading();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, _) => const SizedBox.square(
          dimension: 112,
          child: ShimmerBox(),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.item, required this.onTap});

  final WorkshopGeneration item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.neutral100,
      child: InkWell(
        key: Key('workshop-history-${item.id}'),
        onTap: onTap,
        child: SizedBox.square(
          dimension: 112,
          child: item.hasImage
              ? AppImage(item.imageUrl!, fit: BoxFit.cover)
              : item.isActive
              ? const ShimmerBox()
              : Icon(
                  item.status == WorkshopGenerationStatus.failed
                      ? Icons.error_outline
                      : Icons.hourglass_empty,
                  color: AppColors.neutral500,
                ),
        ),
      ),
    );
  }
}

class _WorkshopPreviewDialog extends StatelessWidget {
  const _WorkshopPreviewDialog({
    required this.item,
    required this.position,
    required this.total,
    required this.onDownload,
    required this.onUseAsBase,
    required this.onDelete,
  });

  final WorkshopGeneration item;
  final int position;
  final int total;
  final VoidCallback onDownload;
  final VoidCallback onUseAsBase;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: AppColors.transparent,
      shape: const RoundedRectangleBorder(),
      child: SizedBox.expand(
        key: const Key('workshop-history-preview'),
        child: ColoredBox(
          color: AppColors.black,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final contentWidth = math.min<double>(
                  398,
                  constraints.maxWidth - 32,
                );
                final heightLimitedWidth = math.max<double>(
                  160,
                  (constraints.maxHeight - 308) * 2 / 3,
                );
                final imageWidth = math.min<double>(
                  contentWidth,
                  heightLimitedWidth,
                );
                return Stack(
                  children: [
                    Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 56),
                        child: SizedBox(
                          width: contentWidth,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _PreviewImage(
                                item: item,
                                width: imageWidth,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                item.prompt,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 22 / 15,
                                  color: AppColors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$position of $total',
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 20 / 13,
                                  color: AppColors.whiteAlpha60,
                                ),
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: math.min<double>(280, contentWidth),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _PreviewActionButton(
                                        key: const Key(
                                          'workshop-preview-download',
                                        ),
                                        icon: Icons.download_outlined,
                                        label: 'Download',
                                        onTap: item.hasImage
                                            ? onDownload
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _PreviewActionButton(
                                        key: const Key(
                                          'workshop-preview-use-base',
                                        ),
                                        icon: Icons.auto_fix_high_outlined,
                                        label: 'Use as base',
                                        onTap: item.hasImage
                                            ? onUseAsBase
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              _PreviewActionButton(
                                key: const Key('workshop-preview-delete'),
                                icon: Icons.delete_outline,
                                label: 'Delete',
                                dark: true,
                                onTap: onDelete,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: _WorkshopIconButton(
                        key: const Key('workshop-preview-close'),
                        icon: Icons.close,
                        label: 'Close preview',
                        dimension: 40,
                        iconSize: 26,
                        backgroundColor: AppColors.whiteAlpha10,
                        onTap: () => Navigator.pop(context),
                        dark: true,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewImage extends StatelessWidget {
  const _PreviewImage({required this.item, required this.width});

  final WorkshopGeneration item;
  final double width;

  @override
  Widget build(BuildContext context) {
    final source = item.imageUrl;
    return SizedBox(
      key: const Key('workshop-history-preview-image'),
      width: width,
      height: width * 3 / 2,
      child: source != null && source.isNotEmpty
          ? source.startsWith('assets/')
                ? AppImage(source)
                : AppImage(source)
          : const Center(
              child: Text(
                'Image is still processing.',
                style: TextStyle(color: AppColors.white),
              ),
            ),
    );
  }
}
