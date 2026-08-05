part of '../screens/workshop_screen.dart';

class _BaseImageField extends StatefulWidget {
  const _BaseImageField({
    required this.image,
    required this.onPick,
    required this.onRemove,
  });

  final WorkshopBaseImage? image;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  State<_BaseImageField> createState() => _BaseImageFieldState();
}

class _BaseImageFieldState extends State<_BaseImageField> {
  bool _highlighted = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _WorkshopFieldLabel(title: 'Base image', isRequired: true),
        const SizedBox(height: 8),
        Material(
          color: AppColors.transparent,
          child: InkWell(
            key: const Key('workshop-upload-tile'),
            onTap: widget.onPick,
            onHighlightChanged: (value) => setState(() => _highlighted = value),
            child: widget.image == null
                ? _EmptyBaseUpload(highlighted: _highlighted)
                : _BaseImagePreview(
                    image: widget.image!,
                    onRemove: widget.onRemove,
                  ),
          ),
        ),
      ],
    );
  }
}

class _EmptyBaseUpload extends StatelessWidget {
  const _EmptyBaseUpload({required this.highlighted});

  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 160),
      scale: highlighted ? 1.01 : 1,
      child: ColoredBox(
        color: highlighted ? AppColors.neutral100 : AppColors.transparent,
        child: AppDottedBorder(
          color: highlighted ? AppColors.black : AppColors.neutral200,
          strokeWidth: 2,
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    color: AppColors.black,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.file_upload_outlined,
                      size: 24,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    highlighted
                        ? 'Drop to upload'
                        : 'Click or drop a base image',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'JPG, PNG, or WebP — up to 30MB',
                    style: TextStyle(
                      fontSize: 12,
                      height: 16 / 12,
                      color: AppColors.neutral500,
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

class _BaseImagePreview extends StatelessWidget {
  const _BaseImagePreview({required this.image, required this.onRemove});

  final WorkshopBaseImage image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _WorkshopShell(
      child: Column(
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: _orientationRatio(image.orientation),
                child: SizedBox.expand(
                  key: const Key('workshop-base-image-preview'),
                  child: image.bytes == null
                      ? AppImage(image.source)
                      : AppImage.memory(image.bytes!),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: _WorkshopIconButton(
                  key: const Key('workshop-base-image-remove-button'),
                  icon: Icons.close,
                  label: 'Remove base image',
                  onTap: onRemove,
                  dark: true,
                ),
              ),
            ],
          ),
          if (image.orientation != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(color: AppColors.neutral200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.image_outlined, size: 12),
                      const SizedBox(width: 6),
                      Text(
                        image.orientation!.label,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 16 / 11,
                          fontWeight: AppTypography.semiBold,
                          letterSpacing: 0.55,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Tooltip(
                  message:
                      'Detected automatically from your base image. The output will match this orientation.',
                  child: Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ModePicker extends StatelessWidget {
  const _ModePicker({required this.selected, required this.onChanged});

  final WorkshopEditMode selected;
  final ValueChanged<WorkshopEditMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _WorkshopFieldLabel(title: 'Edit mode', isRequired: true),
        const SizedBox(height: 8),
        for (final mode in WorkshopEditMode.values) ...[
          _ModeCard(
            mode: mode,
            selected: mode == selected,
            onTap: () => onChanged(mode),
          ),
          if (mode != WorkshopEditMode.values.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final WorkshopEditMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.white : AppColors.black;
    return Material(
      color: selected ? AppColors.black : AppColors.white,
      child: InkWell(
        key: Key('workshop-mode-${mode.name}'),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? AppColors.black : AppColors.neutral200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    mode == WorkshopEditMode.lock
                        ? Icons.lock_outline
                        : Icons.lightbulb_outline,
                    size: 14,
                    color: foreground,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      mode.title,
                      style: TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: AppTypography.bold,
                        color: foreground,
                      ),
                    ),
                  ),
                  if (mode == WorkshopEditMode.lock)
                    Container(
                      key: const Key('workshop-default-mode-tag'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      color: selected ? AppColors.white : AppColors.neutral100,
                      child: Text(
                        'DEFAULT',
                        style: TextStyle(
                          fontSize: 10,
                          height: 1.5,
                          letterSpacing: 0.5,
                          color: selected
                              ? AppColors.black
                              : AppColors.neutral500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                mode.body,
                style: TextStyle(
                  fontSize: 12,
                  height: 19 / 12,
                  color: selected
                      ? AppColors.whiteAlpha80
                      : AppColors.neutral500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
