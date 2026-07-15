part of '../screens/workshop_screen.dart';

enum _WorkshopAlertTone { warning, danger }

class _WorkshopHero extends StatelessWidget {
  const _WorkshopHero();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Reshape any photo with a sentence. Swap a face, recolor a product, drop a new model into the same shot. 1 credit per generation.',
      style: TextStyle(
        fontSize: 14,
        height: 1.45,
        color: AppColors.neutral800,
      ),
    );
  }
}

class _WorkshopAlert extends StatelessWidget {
  const _WorkshopAlert({
    required this.icon,
    required this.text,
    required this.tone,
  });

  final IconData icon;
  final String text;
  final _WorkshopAlertTone tone;

  @override
  Widget build(BuildContext context) {
    final danger = tone == _WorkshopAlertTone.danger;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: danger ? AppColors.dangerLight : AppColors.warningLight,
        border: Border.all(
          color: danger ? AppColors.dangerBorder : AppColors.warningBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: danger ? AppColors.dangerDark : AppColors.warningDark,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                fontWeight: AppTypography.medium,
                color: danger ? AppColors.dangerDark : AppColors.warningDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BaseImagePanel extends StatelessWidget {
  const _BaseImagePanel({
    required this.image,
    required this.onUpload,
    required this.onRemove,
  });

  final WorkshopBaseImage? image;
  final VoidCallback onUpload;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelHeader(
          title: 'BASE IMAGE',
          trailing: '*',
          trailingColor: AppColors.danger,
        ),
        const SizedBox(height: 12),
        InkWell(
          key: const Key('workshop-upload-tile'),
          onTap: onUpload,
          child: image == null
              ? AppDottedBorder(
                  child: SizedBox(
                    height: 248,
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          color: AppColors.black,
                          padding: const EdgeInsets.all(12),
                          child: const Icon(
                            Icons.file_upload_outlined,
                            size: 34,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Click or drop a base image',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: AppTypography.bold,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'JPG, PNG - up to 30MB.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.neutral500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _Panel(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          ClipRect(
                            child: AspectRatio(
                              aspectRatio: 3 / 4,
                              child: SizedBox.expand(
                                key: const Key('workshop-base-image-preview'),
                                child: AppImage(
                                  image!.source,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Semantics(
                              label: 'Remove base image',
                              button: true,
                              child: Material(
                                color: AppColors.black,
                                child: InkWell(
                                  key: const Key(
                                    'workshop-base-image-remove-button',
                                  ),
                                  onTap: onRemove,
                                  child: const SizedBox.square(
                                    dimension: 35,
                                    child: Icon(
                                      Icons.close,
                                      size: 20,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (image!.orientation != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            border: Border.all(color: AppColors.neutral200),
                          ),
                          child: Text(
                            image!.orientation!.label,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: AppTypography.bold,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _ModePicker extends StatelessWidget {
  const _ModePicker({
    required this.selected,
    required this.onChanged,
  });

  final WorkshopEditMode selected;
  final ValueChanged<WorkshopEditMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _PanelHeader(
          title: 'EDIT MODE',
          trailing: '*',
          trailingColor: AppColors.danger,
        ),
        const SizedBox(height: 12),
        for (final mode in WorkshopEditMode.values) ...[
          _ModeCard(
            mode: mode,
            selected: mode == selected,
            onTap: () => onChanged(mode),
          ),
          if (mode != WorkshopEditMode.values.last) const SizedBox(height: 10),
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
    return InkWell(
      key: Key('workshop-mode-${mode.name}'),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.black : AppColors.neutral100,
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
                      : Icons.auto_awesome_outlined,
                  size: 18,
                  color: selected ? AppColors.white : AppColors.black,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _FitText(
                    mode.title,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.1,
                      fontWeight: AppTypography.bold,
                      color: selected ? AppColors.white : AppColors.black,
                    ),
                  ),
                ),
                if (mode == WorkshopEditMode.lock) ...[
                  const SizedBox(width: 8),
                  Container(
                    key: const Key('workshop-default-mode-tag'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 3,
                    ),
                    color: AppColors.white,
                    child: const Text(
                      'DEFAULT',
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w900,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              mode.body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                height: 1.25,
                color: selected ? AppColors.whiteAlpha70 : AppColors.neutral500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferenceStrip extends StatelessWidget {
  const _ReferenceStrip({
    required this.references,
    required this.onAdd,
    required this.onRemove,
  });

  final List<WorkshopSample> references;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelHeader(
          title: 'References',
          trailing: '(Optional, up to 4)',
        ),
        const SizedBox(height: 12),
        _Panel(
          padding: const EdgeInsets.all(14),
          child: SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: references.length + (references.length < 4 ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                if (index == references.length) {
                  return _ReferenceAddTile(onTap: onAdd);
                }
                final reference = references[index];
                return _ReferenceTile(
                  reference: reference,
                  onRemove: () => onRemove(reference.id),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ReferenceAddTile extends StatelessWidget {
  const _ReferenceAddTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('workshop-reference-add-button'),
      onTap: onTap,
      child: const AppDottedBorder(
        child: SizedBox(
          width: 76,
          child: Icon(Icons.add, size: 24, color: AppColors.neutral500),
        ),
      ),
    );
  }
}

class _ReferenceTile extends StatelessWidget {
  const _ReferenceTile({
    required this.reference,
    required this.onRemove,
  });

  final WorkshopSample reference;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      child: Stack(
        children: [
          Positioned.fill(
            child: AppImage(
              reference.asset,
              width: 76,
              height: 76,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: _MiniRemoveButton(onTap: onRemove),
          ),
        ],
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelHeader(
          title: 'PROMPT',
          trailing: '*',
          trailingColor: AppColors.danger,
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: controller,
          onChanged: onChanged,
          minLines: 5,
          maxLines: 6,
          maxLength: 1000,
          hintText:
              "Describe the edit. e.g place the watch from Image 2 on the model's wrist, keep the studio lighting.",
        ),
      ],
    );
  }
}

class _GenerateButton extends StatelessWidget {
  const _GenerateButton({
    required this.locked,
    required this.busy,
    required this.enabled,
    required this.onTap,
  });

  final bool locked;
  final bool busy;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !busy;
    return InkWell(
      key: const Key('workshop-generate-button'),
      onTap: busy ? null : onTap,
      child: Container(
        height: 54,
        width: double.infinity,
        color: active ? AppColors.black : AppColors.neutral200,
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              locked ? Icons.lock_outline : Icons.auto_fix_high_outlined,
              size: 18,
              color: active ? AppColors.white : AppColors.neutral500,
            ),
            const SizedBox(width: 8),
            _FitText(
              busy ? 'Generating' : 'Generate - 1 credit',
              style: TextStyle(
                fontSize: 15,
                fontWeight: AppTypography.bold,
                color: active ? AppColors.white : AppColors.neutral500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
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
        const _PanelHeader(title: 'RESULT', trailing: ''),
        const SizedBox(height: 12),
        if (state.isGenerating)
          const _GeneratingBox()
        else if (state.hasResult)
          Column(
            children: [
              AspectRatio(
                aspectRatio: 3 / 4,
                child: Image.asset(
                  state.resultImage!,
                  fit: BoxFit.cover,
                  cacheWidth: 780,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _SecondaryButton(
                      icon: Icons.download_outlined,
                      label: 'Download',
                      onTap: onDownload,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PrimarySmallButton(
                      icon: Icons.layers_outlined,
                      label: 'Use as base',
                      onTap: onUseAsBase,
                    ),
                  ),
                ],
              ),
            ],
          )
        else
          _Panel(
            padding: const EdgeInsets.all(14),
            child: AppDottedBorder(
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Container(
                  color: AppColors.neutral100,
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 28,
                        color: AppColors.black,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Your edit will appear here.',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: AppTypography.medium,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Try: "swap the background to a beach", "add a watch on the wrist", or "make this a flat-lay product shot".',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.neutral500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GeneratingBox extends StatelessWidget {
  const _GeneratingBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: AppColors.neutral100,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.black,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Generating edit',
            style: TextStyle(
              fontSize: 16,
              fontWeight: AppTypography.bold,
              color: AppColors.black,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Matching prompt, base image, and references.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.neutral500),
          ),
        ],
      ),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({
    required this.history,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<WorkshopHistoryItem> history;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(
            title: 'RECENT GENERATIONS',
            trailing: '',
          ),
          const SizedBox(height: 12),
          if (history.isEmpty)
            Container(
              height: 88,
              width: double.infinity,
              alignment: Alignment.center,
              color: AppColors.neutral100,
              child: const Text(
                'Nothing yet. Generations land here so you can revisit, download, or chain edits.',
                style: TextStyle(fontSize: 13, color: AppColors.neutral500),
              ),
            )
          else
            SizedBox(
              height: 86,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: history.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final item = history[index];
                  return InkWell(
                    onTap: () => onSelect(index),
                    child: Container(
                      width: 86,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: index == selectedIndex
                              ? AppColors.black
                              : AppColors.neutral200,
                          width: index == selectedIndex ? 2 : 1,
                        ),
                      ),
                      child: Image.asset(
                        item.image,
                        fit: BoxFit.cover,
                        cacheWidth: 172,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _WorkshopPreviewDialog extends StatelessWidget {
  const _WorkshopPreviewDialog({required this.item});

  final WorkshopHistoryItem item;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: AppColors.black,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Preview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: AppTypography.bold,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  _SquareIconButton.dark(
                    icon: Icons.close,
                    label: 'Close preview',
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Center(
                  child: Image.asset(item.image, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                item.prompt,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: AppColors.whiteAlpha80,
                ),
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(
                    child: _PreviewAction(
                      icon: Icons.download_outlined,
                      label: 'Download',
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _PreviewAction(
                      icon: Icons.layers_outlined,
                      label: 'Use as base',
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

class _PreviewAction extends StatelessWidget {
  const _PreviewAction({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.whiteAlpha10,
        border: Border.all(color: AppColors.whiteAlpha20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.white),
          const SizedBox(width: 8),
          Flexible(
            child: _FitText(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: AppTypography.bold,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkshopGuideContent extends StatelessWidget {
  const _WorkshopGuideContent({required this.onClose});

  final VoidCallback onClose;

  static const List<_GuideExampleData> _examples = [
    _GuideExampleData(
      title: 'Change the background',
      caption: 'Same model. Drop them into any scene.',
      before: AppAssets.showcaseDressBefore,
      after: AppAssets.showcaseDressAfter,
      prompt:
          'Re-render this photo as if she was actually photographed at a sunlit Paris cafe terrace at golden hour. Keep her face, outfit, hair, and pose exactly the same. Re-light her body and hair to match the warm directional sunlight, add a soft natural shadow on the ground behind her, and let the background fall into soft bokeh. Shot on a 50mm lens with shallow depth of field.',
    ),
    _GuideExampleData(
      title: 'Restyle a product',
      caption: 'Recolor a product without losing its shape.',
      before: AppAssets.showcaseShoesBefore,
      after: AppAssets.showcaseShoesAfter,
      prompt:
          'Recolor the sneaker to deep navy blue suede. Keep the silhouette, laces, sole, stitching, and shadow exactly as they are.',
    ),
    _GuideExampleData(
      title: 'Swap the model, keep the product',
      caption: 'Same product. Different person.',
      before: AppAssets.stepModel,
      after: AppAssets.stepGenerate,
      prompt:
          'Replace the model with the person from Image 2. Keep the watch on the wrist, the pose, the hand position, the framing, and the lighting identical to the original.',
      note: 'Upload the new model as the second image.',
    ),
    _GuideExampleData(
      title: 'Swap the product, keep the model',
      caption: 'Same model. Different product.',
      before: AppAssets.showcaseBagBefore,
      after: AppAssets.showcaseBagAfter,
      prompt:
          "Replace the coffee cup in the model's hand with the wine glass from Image 2. Keep the model, hand position, pose, framing, lighting, and background identical.",
      note: 'Upload the new product as the second image.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.white,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.paddingOf(context).bottom + 28,
        ),
        children: [
          const _GuideHero(),
          const SizedBox(height: 24),
          const _GuideModeCard(
            icon: Icons.lock_outline,
            title: 'Lock this image',
            body:
                'Keeps your photo exactly as it is. Only the part you describe changes. Best for face swaps, color changes, or replacing one thing in the shot.',
          ),
          const SizedBox(height: 12),
          const _GuideModeCard(
            icon: Icons.lightbulb_outline,
            title: 'Use as inspiration',
            body:
                "Makes a brand new image inspired by your photo. The output won't match the original. Best for fresh shots in the same style.",
          ),
          const SizedBox(height: 24),
          const _GuideSectionHead(),
          const SizedBox(height: 16),
          for (final example in _examples) ...[
            _GuideExample(example: example),
            const SizedBox(height: 16),
          ],
          const _GuideTips(),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: PrimaryButton(
              label: 'Got it',
              onPressed: onClose,
              fitToContent: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideExampleData {
  const _GuideExampleData({
    required this.title,
    required this.caption,
    required this.before,
    required this.after,
    required this.prompt,
    this.note,
  });

  final String title;
  final String caption;
  final String before;
  final String after;
  final String prompt;
  final String? note;
}

class _GuideHero extends StatelessWidget {
  const _GuideHero();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(right: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GuideBadge(),
          SizedBox(height: 8),
          Text(
            'One image, one prompt, one credit.',
            maxLines: 2,
            style: TextStyle(
              fontSize: 20,
              fontWeight: AppTypography.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Drop a photo, type the change you want, get the result back. Works for faces, products, or whole scenes.',
            style: TextStyle(
              fontSize: 15,
              height: 1.55,
              color: AppColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideBadge extends StatelessWidget {
  const _GuideBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 13,
            color: AppColors.neutral500,
          ),
          SizedBox(width: 6),
          Text(
            'How Workshop works',
            style: TextStyle(
              fontSize: 11,
              height: 1,
              fontWeight: AppTypography.bold,
              letterSpacing: 1.21,
              color: AppColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideModeCard extends StatelessWidget {
  const _GuideModeCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.black),
              const SizedBox(width: 8),
              Expanded(
                child: _FitText(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.3,
                    fontWeight: AppTypography.bold,
                    color: AppColors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              height: 1.55,
              color: AppColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideSectionHead extends StatelessWidget {
  const _GuideSectionHead();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Examples',
          style: TextStyle(
            fontSize: 18,
            height: 1.35,
            fontWeight: AppTypography.bold,
            letterSpacing: 0.72,
            color: AppColors.black,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Four real prompts. Copy any of them straight into the editor.',
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: AppColors.neutral500,
          ),
        ),
      ],
    );
  }
}

class _GuideExample extends StatelessWidget {
  const _GuideExample({required this.example});

  final _GuideExampleData example;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  example.title,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.3,
                    fontWeight: AppTypography.bold,
                    color: AppColors.black,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const _ModePill(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            example.caption,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.neutral500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _GuideImage(label: 'Before', asset: example.before),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward,
                  size: 20,
                  color: AppColors.neutral500,
                ),
              ),
              Expanded(
                child: _GuideImage(label: 'After', asset: example.after),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _GuidePromptBlock(example: example),
        ],
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 11, color: AppColors.neutral500),
          SizedBox(width: 4),
          Text(
            'Lock this image',
            style: TextStyle(
              fontSize: 10,
              height: 1.2,
              fontWeight: AppTypography.bold,
              letterSpacing: 1,
              color: AppColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideImage extends StatelessWidget {
  const _GuideImage({
    required this.label,
    required this.asset,
  });

  final String label;
  final String asset;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            height: 1,
            fontWeight: AppTypography.bold,
            letterSpacing: 1.1,
            color: AppColors.neutral500,
          ),
        ),
        const SizedBox(height: 6),
        AspectRatio(
          aspectRatio: 3 / 4,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              border: Border.all(color: AppColors.neutral200),
            ),
            clipBehavior: Clip.hardEdge,
            child: Image.asset(asset, fit: BoxFit.cover, cacheWidth: 280),
          ),
        ),
      ],
    );
  }
}

class _GuidePromptBlock extends StatelessWidget {
  const _GuidePromptBlock({required this.example});

  final _GuideExampleData example;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.neutral100Alpha30,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What you type',
            style: TextStyle(
              fontSize: 11,
              height: 1,
              fontWeight: AppTypography.bold,
              letterSpacing: 1.1,
              color: AppColors.neutral500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            example.prompt,
            style: const TextStyle(
              fontSize: 14,
              height: 1.55,
              color: AppColors.black,
            ),
          ),
          if (example.note != null) ...[
            const SizedBox(height: 6),
            Text(
              example.note!,
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
                color: AppColors.neutral500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GuideTips extends StatelessWidget {
  const _GuideTips();

  static const List<String> _tips = [
    'Tell it what to keep, not just what to change. Keep the lighting and pose really helps.',
    'You can add up to 4 reference images to pull in a face, color, or texture from somewhere else.',
    'Each generation costs 1 credit. If it fails, you get the credit back automatically.',
    'Generations run on our servers. Switch tabs or close the page. It will be ready when you come back.',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.neutral200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tips',
            style: TextStyle(
              fontSize: 18,
              height: 1.35,
              fontWeight: AppTypography.bold,
              letterSpacing: 0.72,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 12),
          for (final tip in _tips) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '•',
                  style: TextStyle(fontSize: 14, color: AppColors.neutral500),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.55,
                      color: AppColors.neutral500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _WorkshopPaywallSheet extends StatelessWidget {
  const _WorkshopPaywallSheet({required this.onUpgrade});

  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.paddingOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _FitText(
                  'Unlock Workshop',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: AppTypography.bold,
                    color: AppColors.black,
                  ),
                ),
              ),
              _SquareIconButton(
                icon: Icons.close,
                label: 'Close paywall',
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Workshop uses AI credits. Upgrade to generate edits, save history, and use results as new base images.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.neutral500,
            ),
          ),
          const SizedBox(height: 18),
          _PrimaryWideButton(
            icon: Icons.lock_open_outlined,
            label: 'Upgrade to continue',
            onTap: onUpgrade,
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: child,
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.title,
    required this.trailing,
    this.trailingColor,
  });

  final String title;
  final String trailing;
  final Color? trailingColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FitText(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: AppTypography.bold,
            color: AppColors.black,
          ),
        ),
        const SizedBox(width: 8),
        _FitText(
          trailing,
          style: TextStyle(
            fontSize: 11,
            fontWeight: AppTypography.bold,
            color: trailingColor ?? AppColors.neutral500,
          ),
        ),
      ],
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  }) : dark = false;

  const _SquareIconButton.dark({
    required this.icon,
    required this.label,
    required this.onTap,
  }) : dark = true;

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: dark ? AppColors.whiteAlpha10 : AppColors.white,
            border: Border.all(
              color: dark ? AppColors.whiteAlpha20 : AppColors.neutral200,
            ),
          ),
          child: Icon(
            icon,
            size: 19,
            color: dark ? AppColors.white : AppColors.black,
          ),
        ),
      ),
    );
  }
}

class _PrimaryWideButton extends StatelessWidget {
  const _PrimaryWideButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 54,
        width: double.infinity,
        color: AppColors.black,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.white),
            const SizedBox(width: 8),
            _FitText(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: AppTypography.bold,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: AppColors.black),
            const SizedBox(width: 7),
            Flexible(
              child: _FitText(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: AppTypography.bold,
                  color: AppColors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimarySmallButton extends StatelessWidget {
  const _PrimarySmallButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 46,
        color: AppColors.black,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: AppColors.white),
            const SizedBox(width: 7),
            Flexible(
              child: _FitText(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: AppTypography.bold,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniRemoveButton extends StatelessWidget {
  const _MiniRemoveButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        color: AppColors.blackAlpha70,
        child: const Icon(Icons.close, size: 14, color: AppColors.white),
      ),
    );
  }
}

class _FitText extends StatelessWidget {
  const _FitText(
    this.text, {
    required this.style,
    this.maxLines = 1,
  });

  final String text;
  final TextStyle style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}
