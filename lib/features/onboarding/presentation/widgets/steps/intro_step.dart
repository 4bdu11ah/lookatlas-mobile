import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/onboarding/domain/onboarding_models.dart';
import 'package:look_atlas/features/onboarding/presentation/providers/wizard_controller.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/onboarding_widgets.dart';

/// Wizard step 1 — the free-shoot pitch with an auto-rotating before/after
/// showcase (mockup 01).
class IntroStep extends ConsumerStatefulWidget {
  const IntroStep({super.key});

  @override
  ConsumerState<IntroStep> createState() => _IntroStepState();
}

class _IntroStepState extends ConsumerState<IntroStep> {
  static const _rotateEvery = Duration(seconds: 3);

  Timer? _timer;
  int _active = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_rotateEvery, (_) {
      setState(() => _active = (_active + 1) % showcaseItems.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _select(int index) {
    setState(() => _active = index);
    // Restart the cycle so a manual pick isn't immediately rotated away.
    _timer?.cancel();
    _timer = Timer.periodic(_rotateEvery, (_) {
      setState(() => _active = (_active + 1) % showcaseItems.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final item = showcaseItems[_active];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
        child: Column(
          children: [
            const _BadgePill(),
            const SizedBox(height: 16),
            _Headline(scheme: scheme),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Text(
                "We'll put your product on a real model and give you 15 "
                r'studio-quality photos. Brands pay $1,500+ for this. '
                'Yours is free.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _BeforeAfter(item: item),
            const SizedBox(height: 12),
            _Thumbs(active: _active, onSelect: _select),
            const SizedBox(height: 24),
            WizardButton(
              label: 'Get My Free Photos',
              trailing: Icons.arrow_forward,
              expand: true,
              onTap: () => ref.read(wizardControllerProvider.notifier).next(),
            ),
            const SizedBox(height: 16),
            const Wrap(
              alignment: WrapAlignment.center,
              spacing: 20,
              runSpacing: 4,
              children: [
                CheckLine('No credit card required', fontSize: 12),
                CheckLine('15 professional photos', fontSize: 12),
                CheckLine('Ready in under 15 min', fontSize: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        'FOR BRANDS THAT NEED PRODUCT PHOTOS',
        style: TextStyle(
          fontSize: 11,
          height: 1.2,
          fontWeight: AppTypography.medium,
          letterSpacing: 0.55,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 24,
      height: 1.1,
      fontWeight: AppTypography.bold,
      letterSpacing: -0.48,
      color: scheme.onSurface,
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'Product Photos That Sell. ', style: style),
          TextSpan(
            text: 'Ready in Minutes.',
            style: style.copyWith(
              decoration: TextDecoration.underline,
              decorationThickness: 2,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// The two-up before/after pair with corner tags.
class _BeforeAfter extends StatelessWidget {
  const _BeforeAfter({required this.item});

  final ShowcaseItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      spacing: 16,
      children: [
        Expanded(
          child: _Shot(
            key: ValueKey('before-${item.id}'),
            url: item.beforeUrl,
            tag: item.name,
            after: false,
            scheme: scheme,
          ),
        ),
        Expanded(
          child: _Shot(
            key: ValueKey('after-${item.id}'),
            url: item.afterUrl,
            tag: 'Look Atlas',
            after: true,
            scheme: scheme,
          ),
        ),
      ],
    );
  }
}

class _Shot extends StatelessWidget {
  const _Shot({
    required this.url,
    required this.tag,
    required this.after,
    required this.scheme,
    super.key,
  });

  final String url;
  final String tag;
  final bool after;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: Container(
              key: ValueKey(url),
              decoration: BoxDecoration(
                border: Border.all(
                  color: after
                      ? scheme.onSurface.withValues(alpha: 0.2)
                      : scheme.outline,
                ),
              ),
              child: ShotImage(url),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: after
                  ? BoxDecoration(color: scheme.onSurface)
                  : BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.9),
                      border: Border.all(color: scheme.outline),
                    ),
              child: Text(
                tag,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: after
                      ? AppTypography.semiBold
                      : AppTypography.medium,
                  color: after ? scheme.surface : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The row of six product thumbnails under the showcase.
class _Thumbs extends StatelessWidget {
  const _Thumbs({required this.active, required this.onSelect});

  final int active;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 8,
      children: [
        for (var i = 0; i < showcaseItems.length; i++)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onSelect(i),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: i == active ? 1 : 0.5,
              child: Container(
                width: 44,
                height: 44 * 4 / 3,
                decoration: BoxDecoration(
                  border: i == active
                      ? Border.all(color: scheme.onSurface, width: 2)
                      : Border.all(color: scheme.outline),
                ),
                child: ShotImage(showcaseItems[i].beforeUrl),
              ),
            ),
          ),
      ],
    );
  }
}
