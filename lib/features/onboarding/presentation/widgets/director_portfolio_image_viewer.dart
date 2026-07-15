part of 'director_portfolio_modal.dart';

Future<void> _showImageViewer(
  BuildContext context, {
  required List<String> urls,
  required List<String> captions,
  required int initialIndex,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close image preview',
    barrierColor: AppColors.black.withValues(alpha: 0.95),
    pageBuilder: (context, _, _) => _PortfolioImageViewer(
      urls: urls,
      captions: captions,
      initialIndex: initialIndex,
    ),
  );
}

class _PortfolioImageViewer extends StatefulWidget {
  const _PortfolioImageViewer({
    required this.urls,
    required this.captions,
    required this.initialIndex,
  });

  final List<String> urls;
  final List<String> captions;
  final int initialIndex;

  @override
  State<_PortfolioImageViewer> createState() => _PortfolioImageViewerState();
}

class _PortfolioImageViewerState extends State<_PortfolioImageViewer> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index >= widget.urls.length) return;
    unawaited(
      _controller.animateToPage(
        index,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 62, 16, 86),
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: widget.urls.length,
                      onPageChanged: (index) => setState(() => _index = index),
                      itemBuilder: (context, index) => Center(
                        child: ShotImage(widget.urls[index], dark: true),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.captions[_index],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.whiteAlpha82,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${_index + 1} / ${widget.urls.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      color: AppColors.whiteAlpha48,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 18,
              right: 16,
              child: _IconSquareButton(
                icon: Icons.close,
                semanticLabel: 'Close image preview',
                onTap: () => Navigator.of(context).pop(),
                background: AppColors.white.withValues(alpha: 0.12),
              ),
            ),
            Positioned(
              left: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: _ViewerNavButton(
                  icon: Icons.chevron_left,
                  onTap: _index == 0 ? null : () => _goTo(_index - 1),
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: _ViewerNavButton(
                  icon: Icons.chevron_right,
                  onTap: _index == widget.urls.length - 1
                      ? null
                      : () => _goTo(_index + 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewerNavButton extends StatelessWidget {
  const _ViewerNavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.35 : 1,
      child: Material(
        color: AppColors.white.withValues(alpha: 0.12),
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 42,
            height: 48,
            child: Icon(icon, size: 24, color: AppColors.white),
          ),
        ),
      ),
    );
  }
}
