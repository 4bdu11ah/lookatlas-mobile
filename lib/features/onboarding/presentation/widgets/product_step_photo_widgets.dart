part of 'steps/product_step.dart';

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
