import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/onboarding/domain/onboarding_models.dart';
import 'package:look_atlas/features/onboarding/presentation/providers/wizard_controller.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/onboarding_widgets.dart';
import 'package:look_atlas/shared/widgets/app_dialog.dart';

part 'director_portfolio_content.dart';
part 'director_portfolio_image_viewer.dart';
part 'director_portfolio_sections.dart';

Future<void> showDirectorPortfolio(
  BuildContext context, {
  required Director director,
}) {
  return showAppDialog<void>(
    context: context,
    config: AppDialogConfig.standard.copyWith(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      maxWidth: 430,
      maxHeightOffset: 32,
      barrierColor: AppColors.blackAlpha80,
    ),
    builder: (context) => _DirectorPortfolioModal(director: director),
  );
}

class _DirectorPortfolioModal extends ConsumerWidget {
  const _DirectorPortfolioModal({required this.director});

  final Director director;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(
      wizardControllerProvider.select(
        (state) => state.selectedDirector?.id == director.id,
      ),
    );
    final content = _DirectorPortfolioContent.from(director);

    return Column(
      children: [
        _PortfolioHeader(
          director: director,
          isSelected: isSelected,
          onClose: () => Navigator.of(context).pop(),
        ),
        Expanded(
          child: ColoredBox(
            color: AppColors.white,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PortfolioGrid(
                    director: director,
                    captions: content.captions,
                  ),
                  _StorySection(content: content),
                  _QuoteSection(director: director, quote: content.quote),
                  _ChipSection(content: content),
                  _InfoPanel(
                    label: 'Signature Approach',
                    text: content.signatureApproach,
                  ),
                  _InfoPanel(
                    label: 'Similar Brand Aesthetics',
                    text: content.similarBrands,
                    muted: true,
                  ),
                ],
              ),
            ),
          ),
        ),
        _PortfolioFooter(
          director: director,
          isSelected: isSelected,
          onClose: () => Navigator.of(context).pop(),
          onSelect: () {
            ref
                .read(wizardControllerProvider.notifier)
                .selectDirector(director);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class _PortfolioHeader extends StatelessWidget {
  const _PortfolioHeader({
    required this.director,
    required this.isSelected,
    required this.onClose,
  });

  final Director director;
  final bool isSelected;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.neutral150, AppColors.white],
        ),
        border: Border(bottom: BorderSide(color: AppColors.neutral200)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  border: Border.all(
                    color: AppColors.neutral200,
                    width: 2,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: ShotImage(director.imageUrl),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          director.name,
                          style: const TextStyle(
                            fontSize: 20,
                            height: 1.1,
                            fontWeight: FontWeight.w900,
                            color: AppColors.black,
                          ),
                        ),
                        if (isSelected) const _SelectedPill(),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      director.tagline,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.3,
                        fontWeight: AppTypography.bold,
                        color: AppColors.inkAlpha82,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _IconSquareButton(
                icon: Icons.close,
                semanticLabel: 'Close portfolio',
                onTap: onClose,
                foreground: AppColors.neutral500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PortfolioFooter extends StatelessWidget {
  const _PortfolioFooter({
    required this.director,
    required this.isSelected,
    required this.onClose,
    required this.onSelect,
  });

  final Director director;
  final bool isSelected;
  final VoidCallback onClose;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [AppColors.neutral175, AppColors.white],
        ),
        border: Border(top: BorderSide(color: AppColors.neutral200)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isSelected
                    ? '${director.name} is currently directing your shoot'
                    : 'Preview ${director.name} before choosing this style',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: AppColors.neutral500,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 78,
                    child: _PortfolioButton(
                      label: 'Close',
                      onTap: onClose,
                      outlined: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 122,
                    child: _PortfolioButton(
                      label: isSelected ? 'Selected' : 'Use Director',
                      icon: isSelected ? Icons.check : Icons.add,
                      onTap: isSelected ? null : onSelect,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PortfolioButton extends StatelessWidget {
  const _PortfolioButton({
    required this.label,
    this.icon,
    this.onTap,
    this.outlined = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final foreground = outlined ? AppColors.black : AppColors.white;
    return Opacity(
      opacity: onTap == null && !outlined ? 0.85 : 1,
      child: Material(
        color: outlined ? AppColors.white : AppColors.black,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: outlined ? AppColors.neutral200 : AppColors.black,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 46,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: [
                if (icon != null) Icon(icon, size: 14, color: foreground),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      color: foreground,
                    ),
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

class _Section extends StatelessWidget {
  const _Section({
    required this.child,
    this.title,
    this.icon,
    this.soft = false,
  });

  final String? title;
  final IconData? icon;
  final bool soft;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: soft ? AppColors.neutral100Alpha68 : AppColors.white,
        border: const Border(
          bottom: BorderSide(color: AppColors.neutral200),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 14,
                      color: AppColors.black,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    title!,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.96,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class _SelectedPill extends StatelessWidget {
  const _SelectedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      color: AppColors.black,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(Icons.check, size: 14, color: AppColors.white),
          Text(
            'Selected',
            style: TextStyle(
              fontSize: 10,
              height: 1.2,
              fontWeight: AppTypography.bold,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconSquareButton extends StatelessWidget {
  const _IconSquareButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.foreground = AppColors.white,
    this.background = AppColors.transparent,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: background,
        child: InkWell(
          onTap: onTap,
          child: SizedBox.square(
            dimension: 38,
            child: Icon(icon, size: 18, color: foreground),
          ),
        ),
      ),
    );
  }
}
