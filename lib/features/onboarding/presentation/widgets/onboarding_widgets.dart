import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/shared/widgets/app_image.dart';
import 'package:look_atlas/shared/widgets/shimmer_box.dart';

/// The 4px step-progress track pinned above the wizard content.
class WizardProgressBar extends StatelessWidget {
  const WizardProgressBar({required this.fraction, super.key});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 4,
      color: scheme.outline,
      alignment: Alignment.centerLeft,
      child: AnimatedFractionallySizedBox(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        alignment: Alignment.centerLeft,
        widthFactor: fraction.clamp(0, 1),
        heightFactor: 1,
        child: ColoredBox(color: scheme.onSurface),
      ),
    );
  }
}

/// Sharp-cornered black button matching the mockup `.btn` (and `.btn.outline`
/// / `.btn.sm` variants).
class WizardButton extends StatelessWidget {
  const WizardButton({
    required this.label,
    required this.onTap,
    this.outlined = false,
    this.small = false,
    this.leading,
    this.trailing,
    this.expand = false,
    super.key,
  });

  final String label;

  /// Null renders the disabled (50% opacity) state.
  final VoidCallback? onTap;
  final bool outlined;
  final bool small;
  final IconData? leading;
  final IconData? trailing;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = outlined ? scheme.onSurface : scheme.surface;
    final iconSize = small ? 16.0 : 20.0;

    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 8,
      children: [
        if (leading != null) Icon(leading, size: iconSize, color: fg),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: small ? 13 : 14,
              height: 1.2,
              fontWeight: AppTypography.semiBold,
              color: fg,
            ),
          ),
        ),
        if (trailing != null) Icon(trailing, size: iconSize, color: fg),
      ],
    );

    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Material(
        color: outlined ? AppColors.transparent : scheme.onSurface,
        shape: outlined
            ? RoundedRectangleBorder(side: BorderSide(color: scheme.outline))
            : const RoundedRectangleBorder(),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: small
                ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                : const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Wizard bottom bar: outlined Back on the left, filled Continue on the
/// right, separated from content by a hairline.
class WizardNavBar extends StatelessWidget {
  const WizardNavBar({
    required this.onBack,
    this.onContinue,
    this.continueLabel = 'Continue',
    this.showContinue = true,
    super.key,
  });

  final VoidCallback onBack;

  /// Null renders Continue disabled.
  final VoidCallback? onContinue;
  final String continueLabel;
  final bool showContinue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          WizardButton(
            label: 'Back',
            onTap: onBack,
            small: true,
            leading: Icons.arrow_back,
          ),
          if (showContinue)
            WizardButton(
              label: continueLabel,
              onTap: onContinue,
              small: true,
              trailing: Icons.arrow_forward,
            ),
        ],
      ),
    );
  }
}

/// Photo that fills its box: seeded network image with a shimmer while it
/// loads and the mockup's gray gradient if it fails, so layouts look right
/// before (or without) network.
class ShotImage extends StatelessWidget {
  const ShotImage(this.url, {this.dark = false, super.key});

  final String url;

  /// Dark placeholder variant for the black paywall/success screens.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [AppColors.neutral950, AppColors.neutral925]
              : const [AppColors.neutral250, AppColors.neutralMedium],
        ),
      ),
    );
    return AppImage(
      url,
      fit: BoxFit.cover,
      placeholder: ShimmerBox(dark: dark),
      errorWidget: fallback,
    );
  }
}

/// 2px dashed rectangle, matching the mockup's `border-2 border-dashed`
/// upload drop zones.
class DashedBorder extends StatelessWidget {
  const DashedBorder({
    required this.child,
    required this.color,
    this.radius = 8,
    super.key,
  });

  final Widget child;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedBorderPainter(color: color, radius: radius),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 6.0;
    const gap = 5.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

/// Centered section heading + optional subtitle used by every wizard step.
class WizardStepHeader extends StatelessWidget {
  const WizardStepHeader({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            height: 1.2,
            fontWeight: AppTypography.bold,
            color: scheme.onSurface,
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 330),
              child: Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A checkmark bullet line ("White or plain background", ...).
class CheckLine extends StatelessWidget {
  const CheckLine(this.text, {this.fontSize = 14, super.key});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Icon(Icons.check, size: fontSize + 2, color: scheme.onSurface),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              height: 1.43,
              color: scheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }
}
