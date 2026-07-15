import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/onboarding/domain/onboarding_models.dart';
import 'package:look_atlas/features/onboarding/presentation/providers/wizard_controller.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/onboarding_widgets.dart';
import 'package:look_atlas/shared/image_picker/image_source_sheet.dart';
import 'package:look_atlas/shared/widgets/app_image.dart';
import 'package:look_atlas/shared/widgets/app_snack_bar.dart';
import 'package:look_atlas/shared/widgets/bar_spinner.dart';

/// Wizard step 2 — product category picker, then photo upload with per-photo
/// angle tagging (mockup 02, states A–C). Stateless: every bit of state,
/// including the pick-in-flight flag, lives in [wizardControllerProvider].
class ProductStep extends ConsumerWidget {
  const ProductStep({required this.phase, super.key});

  /// Which sub-state to render. Passed in (rather than watched) so the
  /// outgoing copy of this widget keeps showing its own phase while the
  /// wizard's AnimatedSwitcher fades between the two.
  final ProductPhase phase;

  /// Camera-or-gallery chooser, then the pick itself via the controller.
  Future<void> _addPhotos(BuildContext context, WidgetRef ref) async {
    final source = await showImageSourceSheet(
      context,
      title: 'Add product photos',
    );
    if (source == null) return;
    final result = await ref
        .read(wizardControllerProvider.notifier)
        .addProductPhotosFrom(source);
    if (!context.mounted) return;
    switch (result) {
      case PhotoPickResult.truncated:
        AppSnackBar.show(
          context,
          'You can upload up to $maxWizardPhotos photos.',
        );
      case PhotoPickResult.failed:
        AppSnackBar.showError(
          context,
          'Could not open your camera or photo library.',
        );
      case PhotoPickResult.added:
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wizardControllerProvider);
    return phase == ProductPhase.category
        ? _CategoryPicker(
            selected: state.category,
            // Selecting only highlights the tile and enables Continue —
            // moving on is an explicit Continue tap.
            onSelect: (c) =>
                ref.read(wizardControllerProvider.notifier).selectCategory(c),
          )
        : _PhotoUpload(
            state: state,
            onAddPhotos: () => _addPhotos(context, ref),
          );
  }
}

// --- State A: category picker ----------------------------------------------

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({required this.selected, required this.onSelect});

  final ProductCategory? selected;
  final ValueChanged<ProductCategory> onSelect;

  @override
  Widget build(BuildContext context) {
    // "Other" gets its own full-width tile at the end.
    final regular = ProductCategory.values
        .where((c) => c != ProductCategory.other)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
      child: Column(
        spacing: 24,
        children: [
          const WizardStepHeader(
            title: 'What are you shooting?',
            subtitle:
                'This helps us show you the best way to photograph '
                'your product.',
          ),
          Column(
            spacing: 12,
            children: [
              for (var i = 0; i < regular.length; i += 2)
                Row(
                  spacing: 12,
                  children: [
                    for (var j = i; j < i + 2 && j < regular.length; j++)
                      Expanded(
                        child: _CategoryTile(
                          category: regular[j],
                          selected: selected == regular[j],
                          onTap: () => onSelect(regular[j]),
                        ),
                      ),
                  ],
                ),
              _OtherTile(
                selected: selected == ProductCategory.other,
                onTap: () => onSelect(ProductCategory.other),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final ProductCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border.all(
            color: selected ? scheme.onSurface : scheme.outline,
          ),
        ),
        child: Column(
          children: [
            AspectRatio(aspectRatio: 1, child: ShotImage(category.imageUrl)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                category.label,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.2,
                  fontWeight: AppTypography.medium,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtherTile extends StatelessWidget {
  const _OtherTile({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border.all(
            color: selected ? scheme.onSurface : scheme.outline,
          ),
        ),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 2.2,
              child: ColoredBox(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 32,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Other',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.2,
                  fontWeight: AppTypography.medium,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- States B/C: photo upload ------------------------------------------------

class _PhotoUpload extends ConsumerWidget {
  const _PhotoUpload({required this.state, required this.onAddPhotos});

  final WizardState state;
  final VoidCallback onAddPhotos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final category = state.category?.label.toLowerCase() ?? 'product';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 24,
        children: [
          WizardStepHeader(
            title: 'Upload your $category photos',
            subtitle:
                'More photos from different sides help our AI recreate your '
                'product accurately. Upload up to $maxWizardPhotos.',
          ),
          _AngleGuidance(category: state.category),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              CheckLine('White or plain background'),
              CheckLine('Show the full product'),
              CheckLine('Capture logos and unique details'),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                Text(
                  'Your photos',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.43,
                    fontWeight: AppTypography.medium,
                    color: scheme.onSurface,
                  ),
                ),
                if (state.addingPhotos)
                  const _UploadingIndicator()
                else if (state.photos.isEmpty)
                  _DropZone(onTap: onAddPhotos)
                else
                  _PhotoGrid(state: state, onAddPhotos: onAddPhotos),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AngleGuidance extends StatelessWidget {
  const _AngleGuidance({required this.category});

  final ProductCategory? category;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Category-specific example shots (e.g. shoes: Front/Side/Top).
    final guides = (category ?? ProductCategory.other).angleGuides;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Text(
          'For best results, capture these sides',
          style: TextStyle(
            fontSize: 16,
            height: 1.5,
            fontWeight: AppTypography.medium,
            color: scheme.onSurface,
          ),
        ),
        Row(
          spacing: 12,
          children: [
            for (final (label, asset) in guides)
              Expanded(
                child: Column(
                  spacing: 8,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: scheme.outline),
                        ),
                        child: ShotImage(asset),
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.43,
                        fontWeight: AppTypography.medium,
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        Text(
          "Don't have all of these? No worries, upload what you have.",
          style: TextStyle(
            fontSize: 14,
            height: 1.43,
            color: scheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _UploadingIndicator extends StatelessWidget {
  const _UploadingIndicator();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 160,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            const BarSpinner(size: 28),
            Text(
              'Adding your photos...',
              style: TextStyle(
                fontSize: 14,
                height: 1.43,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The empty full-square drop target (mockup state C).
class _DropZone extends StatelessWidget {
  const _DropZone({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DashedBorder(
        color: scheme.onSurface.withValues(alpha: 0.2),
        child: AspectRatio(
          aspectRatio: 1,
          child: ColoredBox(
            color: scheme.surface.withValues(alpha: 0.5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: scheme.onSurface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.upload, size: 28, color: scheme.surface),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tap to add photos',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.4,
                    fontWeight: AppTypography.semiBold,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'JPG or PNG, up to 10MB',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: scheme.onSurface.withValues(alpha: 0.5),
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

/// Uploaded photos in a 2-column grid with per-photo angle dropdowns, an
/// "Add more" tile and the "Looking good · Clear all" footer.
class _PhotoGrid extends ConsumerWidget {
  const _PhotoGrid({required this.state, required this.onAddPhotos});

  final WizardState state;
  final VoidCallback onAddPhotos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final controller = ref.read(wizardControllerProvider.notifier);

    final cells = <Widget>[
      for (var i = 0; i < state.photos.length; i++)
        _PhotoCell(
          photo: state.photos[i],
          onRemove: () => controller.removePhoto(i),
          onAngleChanged: (angle) => controller.setPhotoAngle(i, angle),
        ),
      if (state.photos.length < maxWizardPhotos)
        _AddMoreTile(onTap: onAddPhotos),
    ];

    return Column(
      spacing: 16,
      children: [
        for (var i = 0; i < cells.length; i += 2)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Expanded(child: cells[i]),
              Expanded(
                child: i + 1 < cells.length
                    ? cells[i + 1]
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${switch (state.photos.length) {
                1 => 'Add a few more for better results',
                2 => 'Looking good',
                3 => 'Great coverage',
                _ => 'Perfect',
              }} · ',
              style: TextStyle(
                fontSize: 14,
                height: 1.43,
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: controller.clearPhotos,
              child: Text(
                'Clear all',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.43,
                  decoration: TextDecoration.underline,
                  color: scheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PhotoCell extends StatelessWidget {
  const _PhotoCell({
    required this.photo,
    required this.onRemove,
    required this.onAngleChanged,
  });

  final WizardPhoto photo;
  final VoidCallback onRemove;
  final ValueChanged<String> onAngleChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppImage.memory(
                photo.bytes,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(8),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Material(
                  color: scheme.onSurface,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onRemove,
                    child: SizedBox.square(
                      dimension: 32,
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: scheme.surface,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        _AnglePicker(angle: photo.angle, onChanged: onAngleChanged),
      ],
    );
  }
}

/// Themed angle dropdown: a [MenuAnchor] panel styled like every other card
/// in the app (white surface, hairline border, soft shadow) with a check on
/// the selected angle and a chevron that rotates while open. The unset state
/// keeps the mockup's orange warning border so untagged photos stand out.
class _AnglePicker extends StatefulWidget {
  const _AnglePicker({required this.angle, required this.onChanged});

  final String? angle;
  final ValueChanged<String> onChanged;

  @override
  State<_AnglePicker> createState() => _AnglePickerState();
}

class _AnglePickerState extends State<_AnglePicker> {
  final MenuController _menu = MenuController();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final unset = widget.angle == null;
    final borderColor = unset
        ? AppColors.orange.withValues(alpha: 0.6)
        : scheme.onSurface.withValues(alpha: 0.2);

    // Match the menu panel to the trigger's width so it reads as one unit.
    return LayoutBuilder(
      builder: (context, constraints) => MenuAnchor(
        controller: _menu,
        alignmentOffset: const Offset(0, 4),
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(scheme.surface),
          surfaceTintColor: const WidgetStatePropertyAll(AppColors.transparent),
          elevation: const WidgetStatePropertyAll(6),
          shadowColor: const WidgetStatePropertyAll(AppColors.blackAlpha15),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(color: scheme.outline),
            ),
          ),
          minimumSize: WidgetStatePropertyAll(Size(constraints.maxWidth, 0)),
          maximumSize: WidgetStatePropertyAll(
            Size(constraints.maxWidth, double.infinity),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 4),
          ),
        ),
        menuChildren: [
          for (final option in wizardAngles)
            _AngleOption(
              label: option,
              selected: option == widget.angle,
              width: constraints.maxWidth,
              onTap: () {
                _menu.close();
                widget.onChanged(option);
              },
            ),
        ],
        builder: (context, controller, _) => Material(
          color: scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(color: borderColor),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () =>
                controller.isOpen ? controller.close() : controller.open(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.angle ?? 'Select angle',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.33,
                        fontWeight: unset
                            ? AppTypography.regular
                            : AppTypography.medium,
                        color: unset
                            ? scheme.onSurface.withValues(alpha: 0.5)
                            : scheme.onSurface,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 180),
                    turns: controller.isOpen ? 0.5 : 0,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: scheme.onSurface.withValues(alpha: 0.5),
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
}

class _AngleOption extends StatelessWidget {
  const _AngleOption({
    required this.label,
    required this.selected,
    required this.width,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      hoverColor: scheme.surfaceContainerHighest,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        color: selected
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.6)
            : AppColors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.33,
                  fontWeight: selected
                      ? AppTypography.semiBold
                      : AppTypography.regular,
                  color: scheme.onSurface,
                ),
              ),
            ),
            if (selected) Icon(Icons.check, size: 14, color: scheme.onSurface),
          ],
        ),
      ),
    );
  }
}

class _AddMoreTile extends StatelessWidget {
  const _AddMoreTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DashedBorder(
        color: scheme.onSurface.withValues(alpha: 0.2),
        child: AspectRatio(
          aspectRatio: 1,
          child: ColoredBox(
            color: scheme.surface.withValues(alpha: 0.5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 4,
              children: [
                Icon(
                  Icons.upload,
                  size: 20,
                  color: scheme.onSurface.withValues(alpha: 0.5),
                ),
                Text(
                  'Add more',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.33,
                    color: scheme.onSurface.withValues(alpha: 0.5),
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
