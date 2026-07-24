import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/onboarding/presentation/providers/generation_controller.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/onboarding_widgets.dart';
import 'package:look_atlas/shared/widgets/bar_spinner.dart';

/// The 15-image generation grid (mockup 08), filled from the live job layout
/// in live, with watermark + lock badges on finished trial images. Redirects
/// to the swipe view shortly after every image is ready.
class GenerationProgressScreen extends ConsumerStatefulWidget {
  const GenerationProgressScreen({super.key});

  @override
  ConsumerState<GenerationProgressScreen> createState() =>
      _GenerationProgressScreenState();
}

class _GenerationProgressScreenState
    extends ConsumerState<GenerationProgressScreen> {
  Timer? _redirect;

  @override
  void initState() {
    super.initState();
    // A shoot must be running to have anything to show; covers deep links.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final generation = ref.read(generationControllerProvider);
      if (!generation.started) {
        ref.read(generationControllerProvider.notifier).start();
      }
      _maybeScheduleRedirect(generation);
    });
  }

  void _maybeScheduleRedirect(GenerationState generation) {
    if (!generation.isComplete || _redirect != null || !mounted) return;
    _redirect = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) context.go(AppRoutes.onboardingSwipe);
    });
  }

  @override
  void dispose() {
    _redirect?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final generation = ref.watch(generationControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    ref.listen(generationControllerProvider, (_, next) {
      _maybeScheduleRedirect(next);
    });

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            _Header(generation: generation, scheme: scheme),
            const SizedBox(height: 48),
            _PreviewLabel(scheme: scheme),
            const SizedBox(height: 32),
            for (var shot = 1; shot <= generation.shotCount; shot++) ...[
              _ShotGroup(
                shot: shot,
                images: generation.imagesForShot(shot),
                scheme: scheme,
              ),
              const SizedBox(height: 32),
            ],
            _Footer(complete: generation.isComplete, scheme: scheme),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.generation, required this.scheme});

  final GenerationState generation;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outline)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                _PulsingIcon(
                  child: Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  'Generating Your Photos',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: AppTypography.medium,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Creating your photos',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 36,
              height: 1.15,
              fontWeight: AppTypography.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              'Our AI is generating professional product photos based on '
              'your selections.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 40),
          // One dot per image.
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final image in generation.images)
                AnimatedScale(
                  duration: const Duration(milliseconds: 250),
                  scale: image.isReady ? 1 : 0.9,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 12,
                    height: 12,
                    color: image.isReady ? scheme.onSurface : scheme.outline,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: 12,
            children: [
              _CounterNumber(text: '${generation.readyCount}', scheme: scheme),
              _CounterWord(text: 'of', scheme: scheme),
              _CounterNumber(
                text: '${generation.images.length}',
                scheme: scheme,
              ),
              _CounterWord(text: 'images', scheme: scheme),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              Icon(Icons.schedule, size: 16, color: scheme.onSurfaceVariant),
              Text(
                generation.isComplete
                    ? 'All images generated!'
                    : '~${generation.etaMinutes} '
                          'minute${generation.etaMinutes == 1 ? '' : 's'} '
                          'remaining',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CounterNumber extends StatelessWidget {
  const _CounterNumber({required this.text, required this.scheme});

  final String text;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 30,
        height: 1.2,
        fontWeight: AppTypography.bold,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: scheme.onSurface,
      ),
    );
  }
}

class _CounterWord extends StatelessWidget {
  const _CounterWord({required this.text, required this.scheme});

  final String text;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        height: 1.4,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}

class _PreviewLabel extends StatelessWidget {
  const _PreviewLabel({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        Container(width: 32, height: 1, color: scheme.outline),
        Text(
          'Preview',
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            fontWeight: AppTypography.medium,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ShotGroup extends StatelessWidget {
  const _ShotGroup({
    required this.shot,
    required this.images,
    required this.scheme,
  });

  final int shot;
  final List<GeneratedImage> images;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Row(
          spacing: 12,
          children: [
            Container(
              width: 24,
              height: 24,
              color: scheme.onSurface,
              alignment: Alignment.center,
              child: Text(
                '$shot',
                style: TextStyle(
                  fontSize: 12,
                  height: 1,
                  fontWeight: AppTypography.bold,
                  color: scheme.surface,
                ),
              ),
            ),
            Text(
              'Shot $shot',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                fontWeight: AppTypography.semiBold,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
        for (var i = 0; i < images.length; i += 2)
          Row(
            spacing: 12,
            children: [
              for (var j = i; j < i + 2; j++)
                Expanded(
                  child: j < images.length
                      ? _Cell(image: images[j], scheme: scheme)
                      : const SizedBox.shrink(),
                ),
            ],
          ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.image, required this.scheme});

  final GeneratedImage image;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    if (!image.isReady) {
      return DashedBorder(
        color: scheme.outline.withValues(alpha: 0.9),
        radius: 0,
        child: AspectRatio(
          aspectRatio: 4 / 5,
          child: ColoredBox(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 12,
              children: [
                BarSpinner(
                  size: 36,
                  color: scheme.onSurface.withValues(alpha: 0.5),
                ),
                Text(
                  'V${image.variation}',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.33,
                    fontWeight: AppTypography.medium,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 4 / 5,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: 1,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outline, width: 2),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ShotImage(image.url),
              // Trial watermark.
              Center(
                child: Text(
                  'LOOK ATLAS',
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.6,
                    color: AppColors.white.withValues(alpha: 0.5),
                    shadows: const [
                      Shadow(color: AppColors.blackAlpha50, blurRadius: 8),
                    ],
                  ),
                ),
              ),
              // HD locked in trial.
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  width: 28,
                  height: 28,
                  color: AppColors.inkAlpha80,
                  child: const Icon(
                    Icons.lock_outline,
                    size: 14,
                    color: AppColors.white,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 28,
                  height: 28,
                  color: scheme.onSurface,
                  child: Icon(Icons.check, size: 16, color: scheme.surface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.complete, required this.scheme});

  final bool complete;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 40),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: Column(
        spacing: 16,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: complete ? scheme.onSurface : scheme.surface,
              border: Border.all(
                color: complete ? scheme.onSurface : scheme.outline,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                if (complete)
                  Icon(Icons.check, size: 14, color: scheme.surface)
                else
                  _PulsingIcon(
                    child: Container(
                      width: 8,
                      height: 8,
                      color: scheme.onSurface,
                    ),
                  ),
                Flexible(
                  child: Text(
                    complete
                        ? 'All images generated! Redirecting...'
                        : 'Updates automatically as images are generated',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: complete
                          ? AppTypography.medium
                          : AppTypography.regular,
                      color: complete
                          ? scheme.surface
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            "You can leave this page — we'll keep generating in the "
            'background.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Slow opacity pulse used by the header pill and status chip.
class _PulsingIcon extends StatefulWidget {
  const _PulsingIcon({required this.child});

  final Widget child;

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.35).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}
